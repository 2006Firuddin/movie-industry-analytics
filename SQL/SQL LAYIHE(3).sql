--2.
--Excel Table-dəki dataları Oracle-a import edib aşağıdakı tapşırıqları həll edin.
--Hər bir table-da Constraintlərdən ən azı 1-i  təyin olunmalıdır.

SELECT * FROM tb_rating_info FOR UPDATE;
SELECT COUNT(*) FROM tb_rating_info ;

SELECT * FROM tb_imdb_movies FOR UPDATE;
SELECT COUNT(*) FROM tb_imdb_movies
