DROP FUNCTION IF EXISTS wickers.get_movie_by_id(UUID);

-- SELECT BY ID
CREATE OR REPLACE FUNCTION wickers.get_movie_by_id(
    p_movie_id UUID
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
LANGUAGE sql
AS $$
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
$$;