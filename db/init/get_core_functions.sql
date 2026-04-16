-- GET MOVIES CORE
DROP FUNCTION IF EXISTS wickers.get_movies_core(
    text, text, integer, integer, text, text,
    date, date,
    numeric, numeric,
    numeric, numeric,
    numeric, numeric,
    text[]
    );

CREATE OR REPLACE FUNCTION wickers.get_movies_core(
    p_search text DEFAULT NULL,
    p_search_mode text DEFAULT NULL,
    p_page integer DEFAULT NULL,
    p_page_size integer DEFAULT NULL,
    p_sort_by text DEFAULT 'movie_name',
    p_sort_direction text DEFAULT 'asc',
    p_release_date_from date DEFAULT NULL,
    p_release_date_to date DEFAULT NULL,
    p_worldwide_gross_min numeric DEFAULT NULL,
    p_worldwide_gross_max numeric DEFAULT NULL,
    p_production_budget_min numeric DEFAULT NULL,
    p_production_budget_max numeric DEFAULT NULL,
    p_domestic_gross_min numeric DEFAULT NULL,
    p_domestic_gross_max numeric DEFAULT NULL,
    p_genres text[] DEFAULT NULL
)
RETURNS SETOF wickers.movie_row
LANGUAGE plpgsql
AS $BODY$
DECLARE
v_sort_by text;
    v_sort_direction text;
    v_offset integer;
    v_search text;
    v_search_mode text;
    v_limit_clause text;
    v_offset_clause text;
BEGIN
    v_search := NULLIF(trim(p_search), '');
    v_search_mode := lower(COALESCE(NULLIF(trim(p_search_mode), ''), 'general'));

    v_sort_by := CASE lower(COALESCE(NULLIF(trim(p_sort_by), ''), 'movie_name'))
        WHEN 'id' THEN 'id'
        WHEN 'movie_name' THEN 'movie_name'
        WHEN 'release_date' THEN 'release_date'
        WHEN 'worldwide_gross' THEN 'worldwide_gross'
        WHEN 'production_budget' THEN 'production_budget'
        WHEN 'domestic_gross' THEN 'domestic_gross'
        WHEN 'created_at' THEN 'created_at'
        WHEN 'updated_at' THEN 'updated_at'
        ELSE 'movie_name'
END;

    v_sort_direction := CASE
        WHEN lower(COALESCE(NULLIF(trim(p_sort_direction), ''), 'asc')) = 'desc' THEN 'DESC'
        ELSE 'ASC'
END;

    IF p_page IS NULL OR p_page_size IS NULL THEN
        v_limit_clause := 'LIMIT ALL';
        v_offset_clause := 'OFFSET 0';
ELSE
        v_offset := (GREATEST(p_page, 1) - 1) * GREATEST(p_page_size, 1);
        v_limit_clause := format('LIMIT %s', GREATEST(p_page_size, 1));
        v_offset_clause := format('OFFSET %s', v_offset);
END IF;

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
            (
                $1 IS NULL
                OR (
                    $2 = 'general'
                    AND (
                        m.movie_name %% $1
                        OR m.movie_name ILIKE '%%' || $1 || '%%'
                    )
                )
                OR (
                    $2 = 'starts'
                    AND m.movie_name ILIKE $1 || '%%'
                )
                OR (
                    $2 = 'ends'
                    AND m.movie_name ILIKE '%%' || $1
                )
                OR (
                    $2 = 'contains'
                    AND m.movie_name ILIKE '%%' || $1 || '%%'
                )
            )
            AND ($3 IS NULL OR m.release_date >= $3)
            AND ($4 IS NULL OR m.release_date <= $4)
            AND ($5 IS NULL OR m.worldwide_gross >= $5)
            AND ($6 IS NULL OR m.worldwide_gross <= $6)
            AND ($7 IS NULL OR m.production_budget >= $7)
            AND ($8 IS NULL OR m.production_budget <= $8)
            AND ($9 IS NULL OR m.domestic_gross >= $9)
            AND ($10 IS NULL OR m.domestic_gross <= $10)
            AND (
                $11 IS NULL
                OR cardinality($11) = 0
                OR EXISTS (
                    SELECT 1
                    FROM wickers.movie_genres mg
                    JOIN wickers.genres g
                      ON g.id = mg.genre_id
                    WHERE mg.movie_id = m.id
                      AND g.name = ANY($11)
                )
            )
            ORDER BY
                CASE
                    WHEN $1 IS NULL THEN 0
                    WHEN $2 = 'general' AND lower(m.movie_name) = lower($1) THEN 0
                    WHEN $2 = 'general' AND m.movie_name ILIKE $1 || '%%' THEN 1
                    WHEN $2 = 'general' AND m.movie_name ILIKE '%%' || $1 || '%%' THEN 2
                    ELSE 3
                END,
                CASE
                    WHEN $2 = 'general' AND $1 IS NOT NULL THEN similarity(m.movie_name, $1)
                    ELSE NULL
                END DESC,
                %I %s,
                m.id ASC
            %s
            %s
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
        v_limit_clause,
        v_offset_clause,
        v_sort_by,
        v_sort_direction
    )
    USING
        v_search,                 -- $1
        v_search_mode,            -- $2
        p_release_date_from,      -- $3
        p_release_date_to,        -- $4
        p_worldwide_gross_min,    -- $5
        p_worldwide_gross_max,    -- $6
        p_production_budget_min,  -- $7
        p_production_budget_max,  -- $8
        p_domestic_gross_min,     -- $9
        p_domestic_gross_max,     -- $10
        p_genres;                 -- $11
END;
$BODY$;

--ALTER FUNCTION wickers.get_movies_core(text, text, integer, integer, text, text, date, date, numeric, numeric, numeric, numeric, numeric, numeric, text[])
--    OWNER TO "user";