--3.

--1)Ən uzun film və onun rejissorunu göstər 
SELECT title, director_name, duration_min
FROM tb_imdb_movies
WHERE duration_min =(SELECT MAX(duration_min) FROM tb_imdb_movies)
--2)Hər ölkə üzrə ən yüksək gəlir gətirən filmi tapın (analitik funksiya ilə həll)
SELECT country, title AS top_movie, gross_revenue AS max_revenue
FROM(SELECT country, title, gross_revenue,
     ROW_NUMBER() OVER(PARTITION BY country ORDER BY gross_revenue DESC NULLS LAST) AS rn
     FROM tb_imdb_movies
     WHERE country IS NOT NULL)
WHERE rn = 1
--3)NEW_IMDB_Movies excelini də yeni bir table yaradıb (tb_new_imdb_movies) import etmək
CREATE TABLE tb_new_imdb_movies(
    m_id                NUMBER PRIMARY KEY,
    title               VARCHAR2(255) NOT NULL,
    release_date        VARCHAR2(50),
    color_bw            VARCHAR2(20),
    genre               VARCHAR2(50),
    language            VARCHAR2(50),
    country             VARCHAR2(50),
    rating_id           VARCHAR2(20),
    lead_actor          VARCHAR2(100),
    director_name       VARCHAR2(100),
    lead_actor_fb_likes NUMBER,
    cast_fb_likes       NUMBER,
    director_fb_likes   NUMBER,
    movie_fb_likes      NUMBER,
    imdb_score          NUMBER(3, 1),
    total_reviews       NUMBER, 
    duration_min        NUMBER,
    gross_revenue       NUMBER(15),
    budget              NUMBER(15));
    
SELECT * FROM tb_new_imdb_movies

SELECT * FROM tb_new_imdb_movies FOR UPDATE;
SELECT COUNT(*) FROM tb_new_imdb_movies
--4)IMDB_Movies tablesi ilə NEW_IMDB_Movies tablesini merge etmək bütün sütunlar üzrə və merge nəticəsini analiz etmək 
MERGE INTO tb_imdb_movies m
USING tb_new_imdb_movies n
ON (m.m_id = n.m_id)
WHEN MATCHED THEN
  UPDATE SET 
    m.title = n.title, 
    m.release_date = n.release_date,
    m.color_bw = n.color_bw,
    m.genre = n.genre,
    m.language = n.language,
    m.country = n.country,
    m.rating_id = n.rating_id,
    m.lead_actor = n.lead_actor,
    m.director_name = n.director_name,
    m.lead_actor_fb_likes = n.lead_actor_fb_likes,
    m.cast_fb_likes = n.cast_fb_likes,
    m.director_fb_likes = n.director_fb_likes,
    m.movie_fb_likes = n.movie_fb_likes,
    m.imdb_score = n.imdb_score,
    m.total_reviews = n.total_reviews,
    m.duration_min = n.duration_min,
    m.gross_revenue = n.gross_revenue,
    m.budget = n.budget
WHEN NOT MATCHED THEN
  INSERT (m_id, title, release_date, color_bw, genre, language, country, rating_id, 
          lead_actor, director_name, lead_actor_fb_likes, cast_fb_likes, director_fb_likes, 
          movie_fb_likes, imdb_score, total_reviews, duration_min, gross_revenue, budget)
  VALUES (n.m_id, n.title, n.release_date, n.color_bw, n.genre, n.language, n.country, n.rating_id, 
          n.lead_actor, n.director_name, n.lead_actor_fb_likes, n.cast_fb_likes, n.director_fb_likes, 
          n.movie_fb_likes, n.imdb_score, n.total_reviews, n.duration_min, n.gross_revenue, n.budget);

COMMIT;

SELECT * FROM tb_imdb_movies
--5) Rejissorların orta IMDb balına görə ən yaxşı 5 rejissoru tap.
SELECT director_name, ROUND(AVG(imdb_score), 2) AS avg_score
FROM tb_imdb_movies
WHERE director_name IS NOT NULL
GROUP BY director_name
ORDER BY avg_score DESC
FETCH FIRST 5 ROWS ONLY
--6)Hər rejissorun çəkdiyi ən yeni filmi tap
SELECT director_name, title, release_date
FROM(SELECT 
        director_name, 
        title, 
        release_date,
        ROW_NUMBER() OVER (PARTITION BY director_name ORDER BY release_date DESC NULLS LAST) as rn
    FROM tb_imdb_movies
    WHERE director_name IS NOT NULL)
WHERE rn = 1
--7)Hər bir sorğunun costuna explain planda baxılmalıdır
EXPLAIN PLAN FOR
SELECT director_name, title, release_date
FROM(SELECT director_name, title, release_date,
     ROW_NUMBER() OVER (PARTITION BY director_name ORDER BY release_date DESC NULLS LAST) as rn
     FROM tb_imdb_movies
     WHERE director_name IS NOT NULL)
WHERE rn = 1;
SELECT operation, options, object_name, cost, cardinality, bytes FROM plan_table
--8)Ən çox Facebook izləyicisi olan aktyoru göstər.(subquery ilə)
SELECT DISTINCT lead_actor, lead_actor_fb_likes
FROM tb_imdb_movies
WHERE lead_actor_fb_likes =(SELECT MAX(lead_actor_fb_likes) 
                            FROM tb_imdb_movies)
--9)Hər ölkə üzrə IMDb balına görə ilk 2 filmi tap (analitik funksiya ilə)
SELECT country, title, imdb_score
FROM(SELECT country, 
            title, 
            imdb_score,
            ROW_NUMBER() OVER (PARTITION BY country ORDER BY imdb_score DESC NULLS LAST) AS rn
FROM tb_imdb_movies
WHERE country IS NOT NULL 
AND imdb_score IS NOT NULL)
WHERE rn <= 2
ORDER BY country, imdb_score DESC
--10)Facebook izləyici sayına görə filmləri populyarlıq dərəcəsinə ayır(‘çox populyar',orta populyar',az populyar')
-- - kateqoriya şərtini özünüz təyin edə bilərsiniz bölgü olaraq
SELECT title, movie_fb_likes,
       CASE 
           WHEN movie_fb_likes >= 50000 THEN 'Çox populyar'
           WHEN movie_fb_likes BETWEEN 10000 AND 49999 THEN 'Orta populyar'
           ELSE 'Az populyar'
       END AS popularity_category
FROM tb_imdb_movies
--11) Rejissorların ilk və son filmlərini ekrana çıxart
SELECT DISTINCT
    director_name,
    FIRST_VALUE(title) 
    OVER(PARTITION BY director_name 
         ORDER BY release_date ASC NULLS LAST) AS first_movie_title,
    FIRST_VALUE(release_date) 
    OVER(PARTITION BY director_name 
         ORDER BY release_date ASC NULLS LAST) AS first_movie_date,
    FIRST_VALUE(title) 
    OVER(PARTITION BY director_name 
         ORDER BY release_date DESC NULLS LAST) 
    AS last_movie_title,
    FIRST_VALUE(release_date) 
    OVER(PARTITION BY director_name 
         ORDER BY release_date DESC NULLS LAST) AS last_movie_date
FROM tb_imdb_movies
WHERE director_name IS NOT NULL 
AND release_date IS NOT NULL
--12) Büdcəsi gəlirindən çox olan filmləri tap
SELECT title, budget, gross_revenue, (budget - gross_revenue) AS loss_amount
FROM tb_imdb_movies
WHERE budget > gross_revenue
--13) Hər rejissorun ilk filmi ilə son filminin gəlir fərqini hesabla
SELECT DISTINCT
    director_name,
    first_movie_revenue,
    last_movie_revenue,
    (last_movie_revenue - first_movie_revenue) AS revenue_difference
FROM(SELECT 
        director_name,
        FIRST_VALUE(gross_revenue) 
        OVER(PARTITION BY director_name 
         ORDER BY release_date ASC NULLS LAST) AS first_movie_revenue,
        FIRST_VALUE(gross_revenue) 
        OVER(PARTITION BY director_name 
        ORDER BY release_date DESC NULLS LAST) AS last_movie_revenue
FROM tb_imdb_movies
WHERE director_name IS NOT NULL 
AND release_date IS NOT NULL 
AND gross_revenue IS NOT NULL)
ORDER BY revenue_difference DESC NULLS LAST
--14) Hər bir reytinq üzrə neçə film çəkilib?(rating codu, adı və kino sayı ekrana çıxsın)
SELECT 
    r.rating_code, 
    NVL(r.rating_name, r.rating_code) AS rating_name, 
    COUNT(m.m_id) AS total_movies
FROM tb_rating_info r
LEFT JOIN tb_imdb_movies m ON r.rating_code = m.rating_id
GROUP BY r.rating_code, r.rating_name
ORDER BY total_movies DESC
--15)Ən yüksək gəlir gətirən reytinq kateqoriyasını(rating_name) tap (subquery ilə)
SELECT NVL(rating_name, rating_code) AS rating_name
FROM tb_rating_info 
WHERE rating_code =(SELECT rating_id
                   FROM tb_imdb_movies
                   WHERE rating_id IS NOT NULL
                   GROUP BY rating_id
                   ORDER BY SUM(gross_revenue) DESC
                   FETCH FIRST 1 ROWS ONLY)
--16) Genre, həm də imdb_score üzərində Composite index yarat
CREATE INDEX idx_genre_imdb_score ON tb_imdb_movies (genre, imdb_score)
SELECT index_name, table_name, status
FROM user_indexes
WHERE index_name = 'IDX_GENRE_IMDB_SCORE'
--17)EXPLAIN PLAN ilə indeksli və indeksiz fərqi müqayisə et.
EXPLAIN PLAN SET STATEMENT_ID = 'no_index' FOR
SELECT * FROM tb_imdb_movies WHERE genre = 'Action';
EXPLAIN PLAN SET STATEMENT_ID = 'with_index' FOR
SELECT genre, imdb_score FROM tb_imdb_movies WHERE genre = 'Action';
SELECT statement_id, operation, options, object_name, cost
FROM plan_table
WHERE statement_id IN ('no_index', 'with_index')
--18)Filmin buraxılış tarixinə görə il və ay kimi nəticə qaytar (məs: filmin adı,“13 il, 2 ay əvvəl çıxıb”)
WITH formatted_dates 
AS(SELECT 
        title,
        release_date,
        TO_DATE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
        (LOWER(release_date),
            'yan', '01'), 'fev', '02'), 'mar', '03'), 'apr', '04'),
            'may', '05'), 'iyn', '06'), 'iyl', '07'), 'avq', '08'),
            'sen', '09'), 'okt', '10'), 'noy', '11'), 'dek', '12'),
            'dd.mm.rr') AS clean_date
        FROM tb_imdb_movies)
SELECT 
    title AS film_adi,
    release_date,
    CASE 
        WHEN release_date IS NULL THEN 'Tarix malum deyil'
        WHEN clean_date IS NOT NULL THEN
            TRUNC(MONTHS_BETWEEN(SYSDATE, clean_date) / 12) || ' il, ' ||
            MOD(TRUNC(MONTHS_BETWEEN(SYSDATE, clean_date)), 12) || ' ay evvel cixib'
        ELSE 'Format uygun deyil'
        END AS buraxilis_haqqinda FROM formatted_dates
        
       

