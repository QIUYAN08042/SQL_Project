use sakila;

------------------------------------------------------------------------------
-- Part 1
------------------------------------------------------------------------------

-- Which actors have the first name 'Scarlett'
SELECT * 
FROM actor
where first_name='Scarlett';

-- Which actors have the last name 'Johansson'
SELECT * 
FROM actor
where last_name='Johansson';

-- How many distinct actors last names are there?
SELECT count(distinct last_name) as NUM_distinct_name
FROM actor;

-- Which last names are not repeated?
SELECT last_name as distinct_name
FROM actor
group by last_name
having count(last_name) = 1;

-- Which last names appear more than once?
SELECT last_name
FROM actor
group by last_name
having count(last_name)> 1;

-- Which actor has appeared in the most films?
set @max_film_actor=
(
select max(num_film) as max_film_actor
from(
SELECT count(distinct film_id) as num_film
FROM film_actor
group by actor_id
order by num_film desc)temp
);

SELECT a.actor_id, a.first_name, a.last_name, count(distinct f.film_id) as num_film
FROM film_actor f join actor a on f.actor_id=a.actor_id
group by f.actor_id
Having count(distinct f.film_id)= @max_film_actor
order by num_film desc;

-- Is 'Academy Dinosaur' available for rent from Store 1?
 
-- Step 1: which copies are at Store 1?

select *
from inventory 
where store_id = 1 and film_id in(
SELECT film_id FROM sakila.film
where title='Academy Dinosaur');


select *
from inventory a join film b on a.film_id=b.film_id
where a.store_id= 1 and b.title="Academy Dinosaur"; 

-- Step 2: pick an inventory_id to rent:
select inventory.inventory_id
from inventory join store using (store_id)
     join film using (film_id)
     join rental using (inventory_id)
where film.title = 'Academy Dinosaur'
      and store.store_id = 1
      and not exists (select * from rental
                      where rental.inventory_id = inventory.inventory_id
                      and rental.return_date is null);
                      
                      
-- Insert a record to represent Mary Smith renting 'Academy Dinosaur' from Mike Hillyer at Store 1 today.
insert into rental(rental_date,inventory_id,customer_id, staff_id)
values(now(),1,1,1);

 -- When is 'Academy Dinosaur' due?
-- Step 1: what is the rental duration?
select rental_duration from film where title='Academy Dinosaur';

-- Step 2: Which rental are we referring to -- the last one.
 select rental_id from rental order by rental_id desc limit 1;
 
-- Step 3: add the rental duration to the rental date.
-- ????
select rental_date,rental_date + interval(select rental_duration from film where title='Academy Dinosaur') day as due_date
from rental
where rental_id = (select rental_id from rental order by rental_id desc limit 1 );

-- What is that average length of all the films in the sakila DB?
 select avg(length) from film;
 
-- What is the average length of films by category?
select category.name, avg(length)
from film join film_category using (film_id) join category using (category_id)
group by category.name
order by avg(length) desc;

-- Which film categories are long? Long = lengh is longer than the average film length
select category.name, avg(length)
from film join film_category using (film_id) join category using (category_id)
group by category.name
having avg(length)> ( select avg(length) from film)
order by avg(length) desc;

------------------------------------------------------------------------------
-- Part 2
------------------------------------------------------------------------------
 
-- 1a. Display the first and last names of all actors from the table actor.
 select first_name, last_name
 from actor;
 
-- 1b. Display the first and last name of each actor in a single column in upper case letters. Name the column Actor Name.
 select ucase(concat(first_name,' ',last_name)) as 'Actor Name' 
 from actor;
 
-- 2a. You need to find the ID number, first name, and last name of an actor, of whom you know only the first name, "Joe."
--  	What is one query would you use to obtain this information?
 select actor_id, first_name,last_name
 from actor
 where first_name ='Joe';
 
 
-- 2b. Find all actors whose last name contain the letters GEN:
 select actor_id, first_name,last_name
 from actor
 where first_name like'%Gen%';
 
-- 2c. Find all actors whose last names contain the letters LI. This time, order the rows by last name and first name, in that order:
 select first_name, last_name
 from actor
 where last_name like '%LI%'
 order by last_name, first_name;
 
-- 2d. Using IN, display the country_id and country columns of the following countries: Afghanistan, Bangladesh, and China:
 select country_id,country
 from country
 where country in('Afghanistan', 'Bangladesh', 'China');
 
 
-- 3a. Add a middle_name column to the table actor. Position it between first_name and last_name. Hint: you will need to specify the data type.
 alter table actor
 add column middle_name varchar(30) after first_name;
 
 select* from actor;
 
-- 3b. You realize that some of these actors have tremendously long last names.
--  Change the data type of the middle_name column to blobs.

alter table actor
modify middle_name blob;

-- 3c. Now delete the middle_name column.
alter table actor
drop column middle_name; 

-- 4a. List the last names of actors, as well as how many actors have that last name.
 select last_name, count(last_name) as num_actors
 from actor
 group by last_name;
 
-- 4b. List last names of actors and the number of actors who have that last name,
-- 	but only for names that are shared by at least two actors
  select last_name, count(last_name) as num_actors
 from actor
 group by last_name
 having count(last_name)>=2;
 
-- 4c. Oh, no! The actor HARPO WILLIAMS was accidentally entered in the actor table as GROUCHO WILLIAMS,
-- 	the name of Harpo's second cousin's husband's yoga teacher. Write a query to fix the record.
update  actor 
set first_name= 'HARPO'
where first_name='GROUCHO'  and last_name='WILLIAMS';
 
-- 4d. Perhaps we were too hasty in changing GROUCHO to HARPO. It turns out that GROUCHO was the correct
-- name after all!
-- In a single query, if the first name of the actor is currently HARPO,
-- change it to GROUCHO. Otherwise, change the first name to MUCHO GROUCHO, as that is exactly what
-- the actor will be with the grievous error. BE CAREFUL NOT TO CHANGE THE FIRST NAME OF EVERY ACTOR
-- TO MUCHO GROUCHO, HOWEVER!
-- (Hint: update the record using a unique identifier.)

select first_name
from actor 
where first_name='HARPO'; 

-- solution1--
 select first_name
	from actor
	where first_name = 'Harpo';

	update actor
	set first_name = 'GROUCHO'
	where first_name = 'Harpo';

	update actor
	set first_name = case
		when first_name = 'Harpo' THEN 'GROUCHO'
    	when first_name = 'Groucho' THEN 'MUCHO GROUCHO'
    	else first_name
	END;
    
-- solution 2--

UPDATE actor 
SET first_name = (
		CASE WHEN first_name = 'HARPO' 
		THEN 'GROUCHO' 
		ELSE 'MUCHO GROUCHO'
        END
	)
 WHERE actor_id = 172;
 
 
	
	select *
	from actor;
 
 
-- 5a. You cannot locate the schema of the address table. Which query would you use to re-create it?
 create table new_address(
 address_id integer(15) NOT NULL,
 address varchar(30) NOT NULL,
 adress2 varchar(30) NOT NULL,
 district varchar(30) NOT NULL,
 city_id integer(15) NOT NULL,
 postal_code integer(10) NOT NULL,
 phone integer(10) NOT NULL,
 location varchar(30) NOT NULL,
 last_update datetime
 );
 
 
-- 6a. Use JOIN to display the first and last names, as well as the address, of each staff member. Use the tables staff and address:
 select s.first_name as 'First Name', s.last_name as 'Last Name', a.address as 'Address'
 from staff as s join address as a ON a.address_id = s.address_id;
 
 
-- 6b. Use JOIN to display the total amount rung up by each staff member in August of 2005. Use tables staff and payment.
select concat(s.first_name,' ',s.last_name) as 'staff member', sum(p.amount) as 'total amount'    -- count计算单元格数总和，sum计算单元格内值的总和
from staff s join payment p on s.staff_id=p.staff_id
where p.payment_date like '2005-08%'
group by p.staff_id;

 
-- 6c. List each film and the number of actors who are listed for that film. Use tables film_actor and film. Use inner join.
select f.title as film, count(a.actor_id) as 'number of actors'
from film f inner join film_actor a on f.film_id = a.film_id
group by f.film_id;
 

 
-- 6d. How many copies of the film Hunchback Impossible exist in the inventory system?
 select count(i.inventory_id) as 'num of copies', f.title asfilm
 from film f join inventory i on f.film_id=i.film_id
 where f.title = 'Hunchback Impossible'
 group by f.film_id;
 
-- 6e. Using the tables payment and customer and the JOIN command, list the total paid by each customer.
-- 	List the customers alphabetically by last name:
 select sum(p.amount) as 'total payment', concat(c.first_name, ' ', c.last_name) as 'customer name'
 from customer c join payment p on c.customer_id=p.customer_id
 group by p.customer_id
 order by c.last_name;


-- 7a. The music of Queen and Kris Kristofferson have seen an unlikely resurgence. As an unintended consequence,
--  films starting with the letters K and Q have also soared in popularity. Use subqueries to display the titles of
--  movies starting with the letters K and Q whose language is English.
 select title
 from film
 where title like'K%' or 'Q%' and language_id =(
 select  language_id
 from language
 where  name= 'English');
 
 
-- 7b. Use subqueries to display all actors who appear in the film Alone Trip.
select concat(first_name,' ',last_name) as 'actor name in alone trip'
from actor where actor_id in(
select actor_id
from film_actor where film_id in(
select film_id from film where title='Alone Trip'));

 
-- 7c. You want to run an email marketing campaign in Canada, for which you will need the names and
-- 	email addresses of all Canadian customers.
-- 	Use joins to retrieve this information.
select concat(c.first_name,' ', c.last_name) as 'customer name', email
from customer c join address a on c.address_id=a.address_id
join city ct on ct.city_id=a.city_id
join country cy on cy.country_id=ct.country_id
where country='canada';


-- 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion.
--  Identify all movies categorized as famiy films.
 select title as movies, cg.name as category
 from film f join film_category c on f.film_id=c.film_id
 join category cg on cg.category_id= c.category_id
 where cg.name= 'family';
 
 
-- 7e. Display the most frequently rented movies in descending order.
select f.title as 'Movie', count(r.rental_date) as 'Times Rented'
from film as f join inventory as i on i.film_id = f.film_id
join rental as r on r.inventory_id = i.inventory_id
group by f.title
order by count(r.rental_date) desc;
 
-- 7f. Write a query to display how much business, in dollars, each store brought in.
	select concat(c.city,', ',cy.country) as `Store`, s.store_id as 'Store ID', sum(p.amount) as `Total Sales` 
	from payment as p
	join rental as r on r.rental_id = p.rental_id
	join inventory as i on i.inventory_id = r.inventory_id
	join store as s on s.store_id = i.store_id
	join address as a on a.address_id = s.address_id
	join city as c on c.city_id = a.city_id
	join country as cy on cy.country_id = c.country_id
	group by s.store_id;


 
-- 7g. Write a query to display for each store its store ID, city, and country.
select s.store_id as 'Store ID', c.city as 'City', cy.country as 'Country'
	from store as s
	join address as a on a.address_id = s.address_id
	join city as c on c.city_id = a.city_id
	join country as cy on cy.country_id = c.country_id
	order by s.store_id;
 
-- 7h. List the top five genres in gross revenue in descending order.
-- (Hint: you may need to use the following tables: category, film_category, inventory, payment, and rental.)
 select c.name as 'Film', sum(p.amount) as 'Gross Revenue'
	from category as c
	join film_category as fc on fc.category_id = c.category_id
	join inventory as i on i.film_id = fc.film_id
	join rental as r on r.inventory_id = i.inventory_id
	join payment as p on p.rental_id = r.rental_id
	group by c.name
	order by sum(p.amount) desc
	limit 5;
 
-- 8a. In your new role as an executive, you would like to have an easy way of viewing
--  	the Top five genres by gross revenue. Use the solution from the problem above to create a view.
--  	If you haven't solved 7h, you can substitute another query to create a view.
  	create view top_5_genre_revenue as (
	SELECT c.name as 'Film', sum(p.amount) as 'Gross Revenue'
	from category as c
	join film_category as fc on fc.category_id = c.category_id
	join inventory as i on i.film_id = fc.film_id
	join rental as r on r.inventory_id = i.inventory_id
	join payment as p on p.rental_id = r.rental_id
	group by c.name
	order by sum(p.amount) desc
	limit 5);
  
-- 8b. How would you display the view that you created in 8a?
select*
from top_5_genre_revenue;
 
-- 8c. You find that you no longer need the view top_five_genres. Write a query to delete it.
 drop view top_5_genre_revenue;
 

