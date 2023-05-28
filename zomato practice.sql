create database zomato
;
show databases
;
use zomato
;
create table users(
user_id serial,
signup_date date
);
select * from users;
describe users;

alter table users
modify column signup_date date;

alter table users
modify column user_id int;


insert into users (user_id , signup_date)
values
( 1 , '2014-09-02'),
(2 , '2015-01-15'),
(3, '2014-04-11');

select * from users;

create table  product(
product_id int unique,
product_name varchar(50),
price int
);

select * from product;
describe product;

insert into product(product_id,product_name, price)
values
(1,'p1',980),
(2,'p1',980),
(3,'p1',980)
;

select * from product;

update product 
set product_name = ('p2')
where product_id = (2);

update product
set product_name = case                
                     when product_id = 2 then 'p2'
                     when product_id = 3 then 'p3'
                     else product_id
                     end,
				price = case
			when product_id = 2 then 870
            when product_id = 3 then 330
            else price
            end
            
where product_id in (2 ,3);

select * from product;

create table goldusers_signup(
users_id int unique,
gold_signup_date date

);

select * from goldusers_signup;
describe goldusers_signup;

insert into goldusers_signup(users_id, gold_signup_date)
values
(1, '2017-09-22'),
(3, '2017-04-21')
;
create table sales(
user_id int,
created_at date,
product_id int
);
select * from sales;

insert into sales(user_id, created_at, product_id)
values
(
1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3)
;
use zomato;
select * from sales;
-- checking all teh tables in the database zomato:
SELECT table_name
FROM information_schema.tables
WHERE table_type='BASE TABLE'
      AND table_schema = 'zomato';

-- 1 what is the total amount each customer spent on the zomato?

select  s.user_id ,sum(p.price) as total_sales from sales s left join product p on s.product_id = p.product_id group by s.user_id order by total_sales desc limit 2;

-- 2 How many days has each customer visted zomato?
select count(distinct created_at) AS total_visits_day , user_id  from sales group by user_id ;

-- 3 what was the first product purachased by customer?

select * from (select *, rank() over (partition by user_id order by created_at) as rnk from sales) as ranking
where rnk = 1;

-- 4 what is the most purchased item on the menu and how many times it was purchased by all customer?

select user_id , count(product_id) as top_pdct_purch from sales
where product_id = (select product_id  FROM sales 
group by product_id
order by count(product_id) desc
limit 1) 
group by user_id;

-- 5 which item was most popular for each customer?
select* from 
(select *, rank() over (partition by user_id order by count_of_p desc) as rnk from
(select user_id , product_id, count(product_id) count_of_p from sales
group by user_id, product_id) cnt) as d
where rnk =1
;

-- 6 which item was purchased first by the customer after they became a gold member?


select * from sales;
select * from goldusers_signup;

select * from
(select *, rank() over (partition by user_id order by created_at) as rnk from
(select s.user_id, s.created_at, s.product_id, g.gold_signup_date from sales s inner join goldusers_signup g on s.user_id = g.users_id 
where created_at >= gold_signup_date) x) y
where rnk = 1
;
-- 7 which item was purchased by the customer just before they became a gold member?
select * from
(select *, rank() over (partition by user_id order by created_at desc) rnk from 
(select s.user_id , s.created_at, s.product_id, g.gold_signup_date from sales s inner join goldusers_signup g on s.user_id = g.users_id
where created_at < gold_signup_date) x) y
where rnk = 1
;
-- 8 what is the order and amount spent by each member befor they became gold member?


select user_id , count(x.product_id) as product_count , sum(price) as total_amt_spent from 
(select s.user_id, s.created_at, s.product_id, g.gold_signup_date from sales s 
inner join goldusers_signup g on s.user_id = g.users_id
where s.created_at <= g.gold_signup_date) x
inner join product p on x.product_id = p.product_id
group by user_id
;
-- 9 If buying each product generates points eg: 5rs =2 points and each product has different purchasing points 
-- for eg: product 1 -> 5rs. =1 point , product 2 -> 10rs. =5, product 3 -> 5rs. =1 point,
-- calculate points collected by each user and for which products most points have been given till now?

--  part 1 calculate points collected by each user
SELECT table_name
FROM information_schema.tables
WHERE table_type='BASE TABLE'
      AND table_schema = 'zomato';
select user_id , sum(total_points) as grand_total from
(select c.*, round(total_amt/points) as total_points from
(select b.* , case when product_id = 1 then 5
                  when product_id = 2 then 2
                  when product_id = 3 then 5  
                  end
                  points from
(select user_id, product_id, sum(price) as total_amt from
(select s.user_id, s.created_at, s.product_id, p.price from sales s 
inner join product p on s.product_id= p.product_id) a
group by user_id , product_id) b) c)d
group by user_id;

-- part 2 If buying each product generates points eg: 5rs =2 points

select user_id , sum(total_points)*2.5 as total_amt_wallet from
(select c.*, round(total_amt/points) as total_points from
(select b.* , case when product_id = 1 then 5
                  when product_id = 2 then 2
                  when product_id = 3 then 5  
                  end
                  points from
(select user_id, product_id, sum(price) as total_amt from
(select s.user_id, s.created_at, s.product_id, p.price from sales s 
inner join product p on s.product_id= p.product_id) a
group by user_id , product_id) b) c)d
group by user_id;

-- part 3 which products most points have been given till now

select * from
(select * , rank() over (order by total_p_points desc ) as rnk from
(select product_id, sum( total_points) as total_p_points  from
(select c.*, round(total_amt/points) as total_points from
(select b.* , case when product_id = 1 then 5
                  when product_id = 2 then 2
                  when product_id = 3 then 5  
                  end
                  points from
(select user_id, product_id, sum(price) as total_amt from
(select s.user_id, s.created_at, s.product_id, p.price from sales s 
inner join product p on s.product_id= p.product_id) a
group by user_id, product_id) b) c) d
group by product_id) e) f
where rnk = 1
;
-- 10 In the first one year after a customer  joins the gold program ( including thier joining date) irrespective 
-- of what the customer has purchased they earn 5 zomato points for every 10rs spent. Who earned more 1 and 3,
-- what was there points earning in thier first year? 

select * from goldusers_signup; -- Checking foreign Key
select * from product;

-- merging tables
select * from
(select *, rank() over (order by points desc) as rnk from
(select user_id, created_at, product_id, gold_signup_date, price , round((price*5)/10) as points  from
(select user_id, created_at, product_id, gold_signup_date, price from 
(select user_id, created_at, s.product_id, g.gold_signup_date, p.price from sales s  
inner join goldusers_signup g on  s.user_id = g.users_id
inner join product p on s.product_id = p.product_id) a
where created_at>= gold_signup_date and created_at <= date_add(gold_signup_date, interval 1 year)) b)c ) d
where rnk =1 

