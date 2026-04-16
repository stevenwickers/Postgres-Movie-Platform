BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE SCHEMA IF NOT EXISTS wickers;
SET search_path TO wickers, public;

DROP TABLE IF EXISTS wickers.movie_genres;
DROP TABLE IF EXISTS wickers.movies;
DROP TABLE IF EXISTS wickers.genres;

-- FUNCTION: wickers.set_updated_at()
CREATE OR REPLACE FUNCTION wickers.set_updated_at()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    NEW.updated_at = now();
RETURN NEW;
END;
$BODY$;

ALTER FUNCTION wickers.set_updated_at()
    OWNER TO "user";

-- GENRES TABLE
CREATE TABLE wickers.genres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL
);

-- MOVIES TABLE
CREATE TABLE wickers.movies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movie_name TEXT NOT NULL UNIQUE,
    release_date DATE NOT NULL,
    worldwide_gross NUMERIC(15,2),
    production_budget NUMERIC(15,2),
    movie_link TEXT NULL,
    domestic_gross NUMERIC(15,2),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- MOVIE GENRES JOIN TALBE
CREATE TABLE wickers.movie_genres (
  movie_id UUID NOT NULL REFERENCES wickers.movies(id) ON DELETE CASCADE,
  genre_id UUID NOT NULL REFERENCES wickers.genres(id) ON DELETE CASCADE,
  PRIMARY KEY (movie_id, genre_id)
);

CREATE TRIGGER trg_movies_updated_at
    BEFORE UPDATE ON wickers.movies
    FOR EACH ROW
    EXECUTE FUNCTION wickers.set_updated_at();

CREATE INDEX idx_movies_name_trgm
    ON wickers.movies
    USING GIN (movie_name gin_trgm_ops);


-- temp seed table
CREATE TEMP TABLE movie_seed (
    movie_name TEXT,
    release_date DATE,
    worldwide_gross NUMERIC(15,2),
    production_budget NUMERIC(15,2),
    movie_link TEXT,
    domestic_gross NUMERIC(15,2),
    genre_names TEXT[]
) ON COMMIT DROP;

INSERT INTO movie_seed (
    movie_name,
    release_date,
    worldwide_gross,
    production_budget,
    movie_link,
    domestic_gross,
    genre_names
)
VALUES
    ('Avatar', '2009-12-18', 2783918982.00, 425000000.00, 'http://www.the-numbers.com/movie/Avatar#tab=summary', 760507625.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Star Wars Ep. VII: The Force Awakens', '2015-12-18', 2058662225.00, 306000000.00, 'http://www.the-numbers.com/movie/Star-Wars-Ep-VII-The-Force-Awakens#tab=summary', 936662225.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Pirates of the Caribbean: At World''s End', '2007-05-24', 963420425.00, 300000000.00, 'http://www.the-numbers.com/movie/Pirates-of-the-Caribbean-At-Worlds-End#tab=summary', 309420425.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Spectre', '2015-11-06', 879620923.00, 300000000.00, 'http://www.the-numbers.com/movie/Spectre#tab=summary', 200074175.00, ARRAY['Action','Adventure','Thriller']),
    ('The Dark Knight Rises', '2012-07-20', 1084439099.00, 275000000.00, 'http://www.the-numbers.com/movie/Dark-Knight-Rises-The#tab=summary', 448139099.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('The Lone Ranger', '2013-07-02', 260002115.00, 275000000.00, 'http://www.the-numbers.com/movie/Lone-Ranger-The#tab=summary', 89302115.00, ARRAY['Action','Adventure','Thriller']),
    ('John Carter', '2012-03-09', 282778100.00, 275000000.00, 'http://www.the-numbers.com/movie/John-Carter-of-Mars#tab=summary', 73058679.00, ARRAY['Action','Adventure','Thriller']),
    ('Tangled', '2010-11-24', 586581936.00, 260000000.00, 'http://www.the-numbers.com/movie/Tangled#tab=summary', 200821936.00, ARRAY['Action','Adventure','Comedy']),
    ('Spider-Man 3', '2007-05-04', 890875303.00, 258000000.00, 'http://www.the-numbers.com/movie/Spider-Man-3#tab=summary', 336530303.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Avengers: Age of Ultron', '2015-05-01', 1404705868.00, 250000000.00, 'http://www.the-numbers.com/movie/Avengers-Age-of-Ultron#tab=summary', 459005868.00, ARRAY['Action','Sci-Fi']),
    ('Captain America: Civil War', '2016-05-06', 1150864745.00, 250000000.00, 'http://www.the-numbers.com/movie/Captain-America-Civil-War#tab=summary', 407264745.00, ARRAY['Action','Sci-Fi']),
    ('Batman v Superman: Dawn of Justice', '2016-03-25', 868160194.00, 250000000.00, 'http://www.the-numbers.com/movie/Batman-v-Superman-Dawn-of-Justice#tab=summary', 330360194.00, ARRAY['Action','Sci-Fi']),
    ('The Hobbit: An Unexpected Journey', '2012-12-14', 1017003568.00, 250000000.00, 'http://www.the-numbers.com/movie/Hobbit-An-Unexpected-Journey-The#tab=summary', 303003568.00, ARRAY['Animation','Adventure','Family']),
    ('Harry Potter and the Half-Blood Prince', '2009-07-15', 935083686.00, 250000000.00, 'http://www.the-numbers.com/movie/Harry-Potter-and-the-Half-Blood-Prince#tab=summary', 301959197.00, ARRAY['Animation','Adventure','Family']),
    ('The Hobbit: The Desolation of Smaug', '2013-12-13', 960366855.00, 250000000.00, 'http://www.the-numbers.com/movie/Hobbit-The-Desolation-of-Smaug-The#tab=summary', 258366855.00, ARRAY['Animation','Adventure','Family']),
    ('The Hobbit: The Battle of the Five Armies', '2014-12-17', 955119788.00, 250000000.00, 'http://www.the-numbers.com/movie/Hobbit-The-Battle-of-the-Five-Armies-The#tab=summary', 255119788.00, ARRAY['Animation','Adventure','Family']),
    ('Pirates of the Caribbean: On Stranger Tides', '2011-05-20', 1045663875.00, 250000000.00, 'http://www.the-numbers.com/movie/Pirates-of-the-Caribbean-On-Stranger-Tides#tab=summary', 241063875.00, ARRAY['Comedy','Adventure','Family']),
    ('Superman Returns', '2006-06-28', 374085065.00, 232000000.00, 'http://www.the-numbers.com/movie/Superman-Returns#tab=summary', 200120000.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Quantum of Solace', '2008-11-14', 591692078.00, 230000000.00, 'http://www.the-numbers.com/movie/Quantum-of-Solace#tab=summary', 169368427.00, ARRAY['Action','Adventure','Thriller']),
    ('The Avengers', '2012-05-04', 1519479547.00, 225000000.00, 'http://www.the-numbers.com/movie/Avengers-The-(2011)#tab=summary', 623279547.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Pirates of the Caribbean: Dead Man''s Chest', '2006-07-07', 1066215812.00, 225000000.00, 'http://www.the-numbers.com/movie/Pirates-of-the-Caribbean-Dead-Mans-Chest#tab=summary', 423315812.00, ARRAY['Action','Adventure','Comedy']),
    ('Man of Steel', '2013-06-14', 667999518.00, 225000000.00, 'http://www.the-numbers.com/movie/Man-of-Steel#tab=summary', 291045518.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('The Chronicles of Narnia: Prince Caspian', '2008-05-16', 417341288.00, 225000000.00, 'http://www.the-numbers.com/movie/Chronicles-of-Narnia-Prince-Caspian-The#tab=summary', 141621490.00, ARRAY['Animation','Adventure','Comedy']),
    ('The Amazing Spider-Man', '2012-07-03', 757890267.00, 220000000.00, 'http://www.the-numbers.com/movie/Amazing-Spider-Man-The#tab=summary', 262030663.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Jurassic World', '2015-06-12', 1670328025.00, 215000000.00, 'http://www.the-numbers.com/movie/Jurassic-World#tab=summary', 652198010.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Men in Black 3', '2012-05-25', 654213485.00, 215000000.00, 'http://www.the-numbers.com/movie/Men-in-Black-3#tab=summary', 179020854.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Transformers: Revenge of the Fallen', '2009-06-24', 836519699.00, 210000000.00, 'http://www.the-numbers.com/movie/Transformers-Revenge-of-the-Fallen#tab=summary', 402111870.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Transformers: Age of Extinction', '2014-06-27', 1104039076.00, 210000000.00, 'http://www.the-numbers.com/movie/Transformers-Age-of-Extinction#tab=summary', 245439076.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('X-Men: The Last Stand', '2006-05-26', 459359555.00, 210000000.00, 'http://www.the-numbers.com/movie/X-Men-The-Last-Stand#tab=summary', 234362462.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Robin Hood', '2010-05-14', 322241588.00, 210000000.00, 'http://www.the-numbers.com/movie/Robin-Hood-(2010)#tab=summary', 105269730.00, ARRAY['Animation','Adventure','Comedy']),
    ('Battleship', '2012-05-18', 305218228.00, 209000000.00, 'http://www.the-numbers.com/movie/Battleship#tab=summary', 65233400.00, ARRAY['Action','Adventure','Thriller']),
    ('King Kong', '2005-12-14', 550517357.00, 207000000.00, 'http://www.the-numbers.com/movie/King-Kong-(2005)#tab=summary', 218080025.00, ARRAY['Action','Adventure','Thriller']),
    ('The Golden Compass', '2007-12-01', 367262558.00, 205000000.00, 'http://www.the-numbers.com/movie/His-Dark-Materials-The-Golden-Compass#tab=summary', 70107728.00, ARRAY['Animation','Adventure']),
    ('Titanic', '1997-12-19', 2207615668.00, 200000000.00, 'http://www.the-numbers.com/movie/Titanic#tab=summary', 658672302.00, ARRAY['Drama','Romance']),
    ('Toy Story 3', '2010-06-18', 1069818229.00, 200000000.00, 'http://www.the-numbers.com/movie/Toy-Story-3#tab=summary', 415004880.00, ARRAY['Animation','Adventure','Comedy']),
    ('Iron Man 3', '2013-05-03', 1215392272.00, 200000000.00, 'http://www.the-numbers.com/movie/Iron-Man-3#tab=summary', 408992272.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Spider-Man 2', '2004-06-30', 783705001.00, 200000000.00, 'http://www.the-numbers.com/movie/Spider-Man-2#tab=summary', 373524485.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Alice in Wonderland', '2010-03-05', 1025491110.00, 200000000.00, 'http://www.the-numbers.com/movie/Alice-in-Wonderland-(2010)#tab=summary', 334191110.00, ARRAY['Fantasy']),
    ('Skyfall', '2012-11-08', 1110526981.00, 200000000.00, 'http://www.the-numbers.com/movie/Skyfall#tab=summary', 304360277.00, ARRAY['Action','Adventure','Thriller']),
    ('Monsters University', '2013-06-21', 743588329.00, 200000000.00, 'http://www.the-numbers.com/movie/Monsters-University#tab=summary', 268488329.00, ARRAY['Animation','Adventure','Comedy']),
    ('Oz the Great and Powerful', '2013-03-08', 490359051.00, 200000000.00, 'http://www.the-numbers.com/movie/Oz-The-Great-and-Powerful#tab=summary', 234770996.00, ARRAY['Fantasy']),
    ('X-Men: Days of Future Past', '2014-05-23', 747862775.00, 200000000.00, 'http://www.the-numbers.com/movie/X-Men-Days-of-Future-Past#tab=summary', 233921534.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('The Amazing Spider-Man 2', '2014-05-02', 708996336.00, 200000000.00, 'http://www.the-numbers.com/movie/Amazing-Spider-Man-2-The#tab=summary', 202853933.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Cars 2', '2011-06-24', 560155383.00, 200000000.00, 'http://www.the-numbers.com/movie/Cars-2#tab=summary', 191450875.00, ARRAY['Animation','Adventure','Comedy']),
    ('Tron: Legacy', '2010-12-17', 397562763.00, 200000000.00, 'http://www.the-numbers.com/movie/Tron-Legacy#tab=summary', 172062763.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('2012', '2009-11-13', 788408539.00, 200000000.00, 'http://www.the-numbers.com/movie/2012#tab=summary', 166112167.00, ARRAY['Action','Adventure','Fantasy']),
    ('Terminator Salvation', '2009-05-21', 365491792.00, 200000000.00, 'http://www.the-numbers.com/movie/Terminator-Salvation#tab=summary', 125322469.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Green Lantern', '2011-06-17', 231201172.00, 200000000.00, 'http://www.the-numbers.com/movie/Green-Lantern#tab=summary', 116601172.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Prince of Persia: Sands of Time', '2010-05-28', 314594597.00, 200000000.00, 'http://www.the-numbers.com/movie/Prince-of-Persia-Sands-of-Time#tab=summary', 90759676.00, ARRAY['Action','Adventure','Fantasy']),
    ('Transformers: Dark of the Moon', '2011-06-29', 1123790543.00, 195000000.00, 'http://www.the-numbers.com/movie/Transformers-Dark-of-the-Moon#tab=summary', 352390543.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('Jack the Giant Slayer', '2013-03-01', 197687603.00, 195000000.00, 'http://www.the-numbers.com/movie/Jack-the-Giant-Slayer#tab=summary', 65187603.00, ARRAY['Action','Adventure','Fantasy']),
    ('Furious 7', '2015-04-03', 1514019071.00, 190000000.00, 'http://www.the-numbers.com/movie/Furious-7#tab=summary', 351032910.00, ARRAY['Action','Thriller']),
    ('Star Trek Into Darkness', '2013-05-15', 467381584.00, 190000000.00, 'http://www.the-numbers.com/movie/Star-Trek-Into-Darkness#tab=summary', 228778661.00, ARRAY['Action','Adventure','Sci-Fi']),
    ('World War Z', '2013-06-21', 531514650.00, 190000000.00, 'http://www.the-numbers.com/movie/World-War-Z#tab=summary', 202359711.00, ARRAY['Action','Adventure','Horror']),
    ('The Great Gatsby', '2013-05-10', 351040419.00, 190000000.00, 'http://www.the-numbers.com/movie/Great-Gatsby-The-(2011)#tab=summary', 144840419.00, ARRAY['Animation','Adventure','Family']);

INSERT INTO wickers.genres (name)
SELECT DISTINCT unnest(genre_names)
FROM movie_seed
    ON CONFLICT (name) DO NOTHING;

INSERT INTO wickers.movies (
    movie_name,
    release_date,
    worldwide_gross,
    production_budget,
    movie_link,
    domestic_gross
)
SELECT
    movie_name,
    release_date,
    worldwide_gross,
    production_budget,
    movie_link,
    domestic_gross
FROM movie_seed;

INSERT INTO wickers.movie_genres (movie_id, genre_id)
SELECT
    m.id,
    g.id
FROM movie_seed s
         CROSS JOIN LATERAL unnest(s.genre_names) AS genre_name(name)
JOIN wickers.movies m
ON m.movie_name = s.movie_name
    JOIN wickers.genres g
    ON g.name = genre_name.name
    ON CONFLICT DO NOTHING;


CREATE TYPE wickers.movie_row AS (
    id uuid,
    movie_name text,
    release_date date,
    worldwide_gross numeric(15,2),
    production_budget numeric(15,2),
    domestic_gross numeric(15,2),
    created_at timestamptz,
    updated_at timestamptz,
    genres text[]
    );

COMMIT;