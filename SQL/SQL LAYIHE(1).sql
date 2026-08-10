--1.
--IMDB_Movies excel faylındakı ilk ikisheetə uyğun table yaradın.(tb_IMDB_Movies və tb_rating_info)
--Hər iki table arasında relationu düzgün təyin etmək lazımdır. Diagram window-da əlaqəni təsvir etmək lazımdır.

CREATE TABLE tb_rating_info(
    rating_code   VARCHAR2(20) NOT NULL,
    rating_name   VARCHAR2(100),
    min_age       NUMBER(3),
    description   VARCHAR2(500),
    country_scope VARCHAR2(50),
    active_flag   CHAR(1),
    CONSTRAINT pk_rating_info PRIMARY KEY(rating_code));
    
CREATE TABLE tb_imdb_movies(
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
    imdb_score          NUMBER(3,1),
    total_reviews       NUMBER, 
    duration_min        NUMBER,
    gross_revenue       NUMBER(15),
    budget              NUMBER(15),
    CONSTRAINT fk_movies_rating FOREIGN KEY(rating_id) REFERENCES tb_rating_info(rating_code),
    CONSTRAINT chk_imdb_score CHECK(imdb_score BETWEEN 0 AND 10));

SELECT * FROM tb_rating_info;
SELECT * FROM tb_imdb_movies

