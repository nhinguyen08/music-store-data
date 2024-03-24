/** Q1: Who is the senior most employee based on job title?**/

SELECT TOP 1 *
FROM employee
ORDER BY levels DESC;
 
/** Q2: Which countries have the most Invoices?**/

select 
    count(invoice_id), 
    billing_country
from invoice
group by billing_country
order by count(invoice_id) desc

/** Q3: Top 3 values of total invoice**/

select top 3 total 
from invoice
order by total DESC

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select 
    sum(total) as 'invoice_total', 
    billing_city
from invoice
group by billing_city
order by sum(total) DESC

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT 
    top 1
    c.customer_id,
    c.first_name, 
    c.last_name,
    SUM(i.total) AS total
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY 
    SUM(i.total) DESC;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT 
    DISTINCT
    c.email, 
    c.first_name, 
    c.last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
WHERE track_id IN (
    SELECT t.track_id
    FROM track t 
    JOIN genre g ON t.genre_id = g.genre_id
    WHERE g.name = 'Rock'
)
ORDER BY c.email

SELECT 
    DISTINCT
    c.email, 
    c.first_name, 
    c.last_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN tracK t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT 
    TOP 10
    ar.artist_id,
    ar.name,
    COUNT(ar.artist_id) as number_of_songs
FROM track t
JOIN album a ON  t.album_id = a.album_id
JOIN artist ar ON a.artist_id = ar.artist_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id,  ar.name
ORDER BY number_of_songs DESC

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first. */

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG (milliseconds)
    FROM track    
)
ORDER BY milliseconds DESC

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. 
Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. 
Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, 
and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
    SELECT 
        TOP 1
        ar.artist_id,
        ar.name, 
        SUM(il.unit_price * il.quantity) as total_sales
    FROM invoice_line il
    JOIN track t ON il.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    JOIN artist ar ON a.artist_id = ar.artist_id
    GROUP BY  ar.artist_id, ar.name
    ORDER BY  SUM(il.unit_price * il.quantity) DESC
)

SELECT 
    c.customer_id, 
    c.first_name, 
    bsa.name, 
    SUM(il.unit_price * il.quantity) as amount_spend
FROM invoice i  
JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album a ON t.album_id = a.album_id
JOIN best_selling_artist bsa ON a.artist_id = bsa.artist_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    bsa.name
ORDER BY  SUM(il.unit_price * il.quantity) DESC

/* Q2: We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre 
with the highest amount of purchases.
 Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS 
(
    SELECT 
        COUNT(invoice_line.quantity) AS purchases, 
        customer.country, 
        genre.name, 
        genre.genre_id, 
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM 
        invoice_line 
    JOIN 
        invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN 
        customer ON customer.customer_id = invoice.customer_id
    JOIN 
        track ON track.track_id = invoice_line.track_id
    JOIN 
        genre ON genre.genre_id = track.genre_id
    GROUP BY 
        customer.country, genre.name, genre.genre_id
    
)
SELECT 
    * 
FROM 
    popular_genre
WHERE 
    RowNo = 1
ORDER BY 
    country ASC, purchases DESC


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

WITH Customter_with_country AS (
    SELECT 
        c.first_name,
        i.billing_country,
        SUM (i.total) as Total_spending,
        ROW_NUMBER () OVER (PARTITION BY billing_country ORDER BY  SUM (total)  DESC) as RowNo

    FROM invoice i
    JOIN 
        customer c ON i.customer_id = c.customer_id
    GROUP BY 
        c.first_name,
        i.billing_country
)

SELECT *
FROM Customter_with_country
WHERE RowNo = 1
ORDER BY billing_country, Total_spending DESC



