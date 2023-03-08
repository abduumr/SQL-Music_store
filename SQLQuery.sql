/* Q1: Siapa karyawan  senior berdasarkan jabatan? */

SELECT	Top 1 title, 
		last_name, 
		first_name 
FROM employee
ORDER BY levels DESC

/* Q2: Negara mana yang memiliki Faktur terbanyak? */

SELECT	COUNT(*) AS c, 
		billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY c DESC

/* Q3: 3 nilai teratas dari total tagihan? */

SELECT top 3 total 
FROM invoice
ORDER BY total DESC

/* Q4: Kota mana yang memiliki pelanggan terbaik? Kami ingin mengadakan Festival Musik promosi di kota tempat 
		kami menghasilkan uang paling banyak. */

SELECT	billing_city,
		SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC

/* Q5: Siapa pelanggan terbaik? Pelanggan yang menghabiskan uang paling banyak akan dinyatakan sebagai pelanggan terbaik.
.*/

SELECT	TOP 1 a.customer_id, 
		a.first_name + ' ' +  a.last_name AS nama_lengkap ,
		SUM(b.total) AS total_spending
FROM customer a
JOIN invoice  b
ON a.customer_id = b.customer_id
GROUP BY a.customer_id , 
		a.first_name + ' ' +  a.last_name 
ORDER BY SUM(b.total) DESC

/* Q6:	mengembalikan email, nama depan, nama belakang, & Genre semua pendengar Musik Rock.
		Kembalikan daftar Anda yang diurutkan menurut abjad melalui email yang dimulai dengan A. */

/*Method 1 */

SELECT	DISTINCT a.email,
		a.first_name + ' ' +  a.last_name AS nama_lengkap 
FROM customer a
JOIN invoice  b
ON a.customer_id = b.customer_id
JOIN invoice_line c 
ON b.invoice_id = c.invoice_id
WHERE track_id IN(
	SELECT track_id 
	FROM track d
	JOIN genre e
	ON d.genre_id = e.genre_id
	WHERE e.name LIKE 'Rock'
)
ORDER BY a.email;

/* Method 2 */

SELECT	DISTINCT a.email ,
		a.first_name + ' ' +  a.last_name AS nama_lengkap ,
		e.name AS Genre
FROM customer a
JOIN invoice  b
ON b.customer_id = a.customer_id
JOIN invoice_line c
ON c.invoice_id = b.invoice_id
JOIN track d
ON d.track_id = c.track_id
JOIN genre e
ON e.genre_id = d.genre_id
WHERE e.name LIKE 'Rock'
ORDER BY a.email;


/* Q7: Mari undang 10 artis yang paling banyak menulis musik rock dalam kumpulan data kita. */

SELECT	TOP 10 c.artist_id, 
		c.name,
		COUNT(c.artist_id) AS number_of_songs
FROM track  a
JOIN album  b
ON b.album_id = a.album_id
JOIN artist c
ON c.artist_id = b.artist_id
JOIN genre  d
ON d.genre_id = a.genre_id
WHERE d.name LIKE 'Rock'
GROUP BY c.artist_id , 
		 c.name
ORDER BY number_of_songs DESC


/* Q8:  Mengembalikan semua nama track yang memiliki panjang lagu lebih panjang dari rata-rata panjang lagu.
		Kembalikan Nama dan Milidetik untuk setiap trek. Diurutkan berdasarkan panjang lagu dengan lagu terpanjang 
		terdaftar terlebih dahulu. */

SELECT	name,
		milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;





/* Q9: Temukan berapa jumlah yang dibelanjakan oleh setiap pelanggan untuk artis?  */


WITH best_selling_artist AS (
	SELECT	TOP 1 d.artist_id AS artist_id, 
			d.name AS artist_name, 
			SUM(a.unit_price*a.quantity) AS total_sales
	FROM invoice_line a
	JOIN track b
	ON b.track_id = a.track_id
	JOIN album c
	ON c.album_id = b.album_id
	JOIN artist d
	ON d.artist_id = c.artist_id
	GROUP BY d.artist_id , d.name
	ORDER BY 3 DESC
)
SELECT	f.customer_id, 
		f.first_name + ' ' +  f.last_name AS nama_lengkap ,
		bsa.artist_name, 
		SUM(g.unit_price*g.quantity) AS amount_spent
FROM invoice e
JOIN customer f 
ON f.customer_id = e.customer_id
JOIN invoice_line g 
ON g.invoice_id = e.invoice_id
JOIN track h
ON h.track_id = g.track_id
JOIN album i
ON i.album_id = h.album_id
JOIN best_selling_artist bsa 
ON bsa.artist_id = i.artist_id
GROUP BY f.customer_id, 
		 f.first_name + ' ' +  f.last_name ,
		 bsa.artist_name
ORDER BY 4 DESC;

/* Q10 : Kami ingin mengetahui Genre musik paling populer untuk setiap negara. */

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT	COUNT(a.quantity) AS purchases, 
			c.country, 
			e.name, 
			e.genre_id, 
			ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(a.quantity) DESC) AS RowNo 
    FROM invoice_line a
	JOIN invoice b
	ON b.invoice_id = a.invoice_id
	JOIN customer c
	ON c.customer_id = b.customer_id
	JOIN track d
	ON d.track_id = a.track_id
	JOIN genre e
	ON e.genre_id = d.genre_id
	GROUP BY c.country, 
			e.name, 
			e.genre_id
)
SELECT * 
FROM popular_genre 
WHERE RowNo <= 1
ORDER BY country ASC, purchases desc


/* Method 2: : Using Recursive */

WITH  sales_per_country AS(
		SELECT	COUNT(*) AS purchases_per_genre, 
				customer.country, 
				genre.name, 
				genre.genre_id
		FROM invoice_line
		JOIN invoice 
		ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer 
		ON customer.customer_id = invoice.customer_id
		JOIN track 
		ON track.track_id = invoice_line.track_id
		JOIN genre 
		ON genre.genre_id = track.genre_id
		GROUP BY customer.country, 
				 genre.name, 
				 genre.genre_id
		
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY country
		)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country 
ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number
order by 2;


/* Q3: Tulis kueri yang menentukan pelanggan yang paling banyak membelanjakan uang untuk musik di setiap negara. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT	customer.customer_id,
				first_name,
				last_name,
				billing_country,
				SUM(total) AS total_spending,
				ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer 
		ON customer.customer_id = invoice.customer_id
		GROUP BY customer.customer_id,
				 first_name,
				 last_name,
				 billing_country
		)
SELECT * 
FROM Customter_with_country 
WHERE RowNo <= 1
ORDER BY 4 ASC,5 DESC


/* Method 2: Using Recursive */

WITH    customter_with_country AS (
		SELECT	customer.customer_id,
				first_name,
				last_name,
				billing_country,
				SUM(total) AS total_spending
		FROM invoice
		JOIN customer 
		ON customer.customer_id = invoice.customer_id
		GROUP BY customer.customer_id,
				 first_name,
				 last_name,
				 billing_country
		),

	country_max_spending AS(
		SELECT billing_country,
		MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT	cc.billing_country, 
		cc.total_spending, 
		cc.first_name, 
		cc.last_name, 
		cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY cc.billing_country;