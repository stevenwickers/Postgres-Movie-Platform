DROP FUNCTION IF EXISTS wickers.search_movies_general(TEXT);
DROP FUNCTION IF EXISTS wickers.search_movies_advanced(TEXT, TEXT);


-- SEARCH GENERAL
CREATE OR REPLACE FUNCTION wickers.search_movies_general(
    p_search TEXT
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
    COALESCE(
            array_agg(DISTINCT g.name) FILTER (WHERE g.name IS NOT NULL),
            ARRAY[]::TEXT[]
    ) AS genres
FROM wickers.movies m
         LEFT JOIN wickers.movie_genres mg ON mg.movie_id = m.id
         LEFT JOIN wickers.genres g ON g.id = mg.genre_id
WHERE
    m.movie_name % p_search
        OR m.movie_name ILIKE '%' || p_search || '%'
GROUP BY m.id
ORDER BY
    CASE
    WHEN lower(m.movie_name) = lower(p_search) THEN 0
    WHEN m.movie_name ILIKE p_search || '%' THEN 1
    WHEN m.movie_name ILIKE '%' || p_search || '%' THEN 2
    ELSE 3
END,
        similarity(m.movie_name, p_search) DESC,
        m.movie_name;
$$;

-- SEARCH ADVANCED
DROP FUNCTION IF EXISTS wickers.search_movies_advanced(TEXT, TEXT);

CREATE OR REPLACE FUNCTION wickers.search_movies_advanced(
    p_search text,
    p_type text,
    p_page integer DEFAULT 1,
    p_page_size integer DEFAULT 10,
    p_sort_by text DEFAULT 'movie_name',
    p_sort_direction text DEFAULT 'asc'
)
RETURNS TABLE (
    id uuid,
    movie_name text,
    release_date date,
    worldwide_gross numeric(15,2),
    production_budget numeric(15,2),
    domestic_gross numeric(15,2),
    created_at timestamptz,
    updated_at timestamptz,
    genres text[]
)
LANGUAGE plpgsql
AS $$
DECLARE
v_sort_by text;
    v_sort_direction text;
    v_offset integer;
BEGIN
    v_sort_by := COALESCE(NULLIF(p_sort_by, ''), 'movie_name');

    v_sort_direction := CASE
        WHEN lower(p_sort_direction) = 'desc' THEN 'DESC'
        ELSE 'ASC'
END;

    v_offset := (GREATEST(p_page, 1) - 1) * GREATEST(p_page_size, 1);

RETURN QUERY EXECUTE format(
        $sql$
        SELECT
            pm.id,
            pm.movie_name,
            pm.release_date,
            pm.worldwide_gross,
            pm.production_budget,
            pm.domestic_gross,
            pm.created_at,
            pm.updated_at,
            COALESCE(ga.genres, ARRAY[]::text[]) AS genres
        FROM
        (
            SELECT
                m.id,
                m.movie_name,
                m.release_date,
                m.worldwide_gross,
                m.production_budget,
                m.domestic_gross,
                m.created_at,
                m.updated_at
            FROM wickers.movies m
            WHERE
                ($1 = 'starts' AND m.movie_name ILIKE $2 || '%%')
                OR ($1 = 'ends' AND m.movie_name ILIKE '%%' || $2)
                OR ($1 = 'contains' AND m.movie_name ILIKE '%%' || $2 || '%%')
            ORDER BY %I %s, m.id ASC
            LIMIT %s
            OFFSET %s
        ) pm
        LEFT JOIN LATERAL
        (
            SELECT
                array_agg(DISTINCT g.name ORDER BY g.name)
                    FILTER (WHERE g.name IS NOT NULL) AS genres
            FROM wickers.movie_genres mg
            LEFT JOIN wickers.genres g
                ON g.id = mg.genre_id
            WHERE mg.movie_id = pm.id
        ) ga ON true
        ORDER BY %I %s, pm.id ASC
        $sql$,
        v_sort_by,
        v_sort_direction,
        GREATEST(p_page_size, 1),
        v_offset,
        v_sort_by,
        v_sort_direction
    )
    USING p_type, p_search;
END;
$$;

COMMIT;