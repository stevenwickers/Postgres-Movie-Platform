DROP FUNCTION IF EXISTS wickers.update_movie(UUID, TEXT, DATE, NUMERIC, NUMERIC, TEXT, NUMERIC, TEXT[]);
DROP FUNCTION IF EXISTS wickers.update_movie(UUID, TEXT, DATE, NUMERIC, NUMERIC, NUMERIC, TEXT[]);

-- UPDATE
CREATE OR REPLACE FUNCTION wickers.update_movie(
    p_movie_id UUID,
    p_movie_name TEXT,
    p_release_date DATE,
    p_worldwide_gross NUMERIC(15,2) DEFAULT NULL,
    p_production_budget NUMERIC(15,2) DEFAULT NULL,
    p_domestic_gross NUMERIC(15,2) DEFAULT NULL,
    p_genre_names TEXT[] DEFAULT ARRAY[]::TEXT[]
)
RETURNS TABLE (
    id UUID,
    movie_name TEXT,
    release_date DATE,
    worldwide_gross NUMERIC(15,2),
    production_budget NUMERIC(15,2),
    domestic_gross NUMERIC(15,2),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    genres TEXT[]
)
LANGUAGE plpgsql
AS $$
BEGIN
UPDATE wickers.movies
SET
    movie_name = p_movie_name,
    release_date = p_release_date,
    worldwide_gross = p_worldwide_gross,
    production_budget = p_production_budget,
    domestic_gross = p_domestic_gross
WHERE wickers.movies.id = p_movie_id;

IF NOT FOUND THEN
        RETURN;
END IF;

DELETE FROM wickers.movie_genres
WHERE movie_id = p_movie_id;

IF array_length(p_genre_names, 1) IS NOT NULL THEN
        INSERT INTO wickers.genres (name)
SELECT DISTINCT trim(g)
FROM unnest(p_genre_names) AS g
WHERE trim(g) <> ''
    ON CONFLICT (name) DO NOTHING;

INSERT INTO wickers.movie_genres (movie_id, genre_id)
SELECT p_movie_id, g.id
FROM wickers.genres g
WHERE g.name = ANY(
    ARRAY(
        SELECT trim(name)
                FROM unnest(p_genre_names) AS name
                WHERE trim(name) <> ''
            )
    )
    ON CONFLICT DO NOTHING;
END IF;

RETURN QUERY
SELECT
    m.id,
    m.movie_name,
    m.release_date,
    m.worldwide_gross,
    m.production_budget,
    m.domestic_gross,
    m.created_at,
    m.updated_at,
    COALESCE(array_agg(DISTINCT g.name) FILTER (WHERE g.name IS NOT NULL), ARRAY[]::TEXT[]) AS genres
FROM wickers.movies m
         LEFT JOIN wickers.movie_genres mg ON mg.movie_id = m.id
         LEFT JOIN wickers.genres g ON g.id = mg.genre_id
WHERE m.id = p_movie_id
GROUP BY m.id;
END;
$$;

COMMIT;