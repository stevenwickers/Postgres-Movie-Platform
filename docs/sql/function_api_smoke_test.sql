-- PostgreSQL / pgAdmin function smoke test script
-- Copy/paste into the pgAdmin query tool to exercise the function API.
-- The script ends with ROLLBACK so your test writes do not persist.

BEGIN;

-- -----------------------------------------------------------------------------
-- Cleanup from any prior interrupted test run
-- -----------------------------------------------------------------------------
SELECT wickers.delete_movie(m.id)
FROM wickers.movies m
WHERE m.movie_name IN (
    'SQL Function Test Movie',
    'SQL Function Test Movie Updated',
    'SQL Function Test Movie GraphQL'
);

-- -----------------------------------------------------------------------------
-- Read function checks
-- -----------------------------------------------------------------------------
SELECT * FROM wickers.get_movies();
SELECT * FROM wickers.get_movies(1, 10);
SELECT * FROM wickers.get_movies(1, 10, 'movie_name', 'asc');
SELECT * FROM wickers.get_movies(1, 10, 'movie_name', 'desc');

SELECT * FROM wickers.get_movies('avatr');
SELECT * FROM wickers.get_movies('avatar', 'general');
SELECT * FROM wickers.get_movies('A', 'starts');
SELECT * FROM wickers.get_movies('S', 'ends', 1, 5, 'movie_name', 'desc');
SELECT * FROM wickers.get_movies('Z', 'contains', 1, 10);

SELECT * FROM wickers.get_movies(
    p_genres => ARRAY['Comedy']
);

SELECT * FROM wickers.get_movies(
    p_release_date_from => '2000-01-01',
    p_release_date_to => '2010-01-01'
);

SELECT * FROM wickers.get_movies(
    p_search => 'star',
    p_search_mode => 'starts',
    p_release_date_from => '1990-01-01',
    p_worldwide_gross_min => 100000000,
    p_genres => ARRAY['Sci-Fi']
);

SELECT wickers.get_movies_count();
SELECT wickers.get_movies_count(
    p_genres => ARRAY[]::text[]
);
SELECT wickers.get_movies_count(
    p_search => 'star',
    p_search_mode => 'starts',
    p_genres => ARRAY['Sci-Fi']
);

SELECT * FROM wickers.get_genres();

SELECT *
FROM wickers.get_genre_by_id(
    (SELECT g.id FROM wickers.genres g ORDER BY g.name LIMIT 1)
);

SELECT *
FROM wickers.get_movie_by_id(
    (SELECT m.id FROM wickers.movies m ORDER BY m.movie_name LIMIT 1)
);

-- -----------------------------------------------------------------------------
-- Write function checks
-- -----------------------------------------------------------------------------
SELECT * FROM wickers.create_movie(
    'SQL Function Test Movie',
    '2026-03-15',
    100.00,
    50.00,
    25.00,
    ARRAY['Action', 'Sci-Fi', 'Thriller']
);

SELECT *
FROM wickers.get_movie_by_id(
    (
        SELECT m.id
        FROM wickers.movies m
        WHERE m.movie_name = 'SQL Function Test Movie'
    )
);

SELECT * FROM wickers.update_movie(
    (
        SELECT m.id
        FROM wickers.movies m
        WHERE m.movie_name = 'SQL Function Test Movie'
    ),
    'SQL Function Test Movie Updated',
    '2026-03-16',
    125.00,
    60.00,
    35.00,
    ARRAY['Drama', 'Thriller']
);

SELECT * FROM wickers.update_graphql_movie(
    (
        SELECT m.id
        FROM wickers.movies m
        WHERE m.movie_name = 'SQL Function Test Movie Updated'
    ),
    '{
        "movie_name": "SQL Function Test Movie GraphQL",
        "domestic_gross": 45.00,
        "genre_names": ["Drama", "Mystery"]
    }'::jsonb
);

SELECT *
FROM wickers.get_movie_by_id(
    (
        SELECT m.id
        FROM wickers.movies m
        WHERE m.movie_name = 'SQL Function Test Movie GraphQL'
    )
);

SELECT wickers.delete_movie(
    (
        SELECT m.id
        FROM wickers.movies m
        WHERE m.movie_name = 'SQL Function Test Movie GraphQL'
    )
);

SELECT * FROM wickers.get_movies(
    p_search => 'SQL Function Test Movie',
    p_search_mode => 'contains'
);

ROLLBACK;
