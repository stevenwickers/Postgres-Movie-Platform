DROP FUNCTION IF EXISTS wickers.get_movies_count(
    text, text,
    date, date,
    numeric, numeric,
    numeric, numeric,
    numeric, numeric,
    text[]
    );

CREATE OR REPLACE FUNCTION wickers.get_movies_count(
    p_search text DEFAULT NULL,
    p_search_mode text DEFAULT NULL,
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
RETURNS integer
LANGUAGE sql
STABLE
AS $BODY$
SELECT COUNT(*)
FROM wickers.movies m
WHERE
    (
        NULLIF(trim(p_search), '') IS NULL
            OR
        (
            lower(COALESCE(NULLIF(trim(p_search_mode), ''), 'general')) = 'general'
                AND (
                m.movie_name % p_search
                OR m.movie_name ILIKE '%' || p_search || '%'
                )
            )
            OR
        (
            lower(COALESCE(NULLIF(trim(p_search_mode), ''), 'general')) = 'starts'
                AND m.movie_name ILIKE p_search || '%'
            )
            OR
        (
            lower(COALESCE(NULLIF(trim(p_search_mode), ''), 'general')) = 'ends'
                AND m.movie_name ILIKE '%' || p_search
            )
            OR
        (
            lower(COALESCE(NULLIF(trim(p_search_mode), ''), 'general')) = 'contains'
                AND m.movie_name ILIKE '%' || p_search || '%'
            )
        )
  AND (p_release_date_from IS NULL OR m.release_date >= p_release_date_from)
  AND (p_release_date_to IS NULL OR m.release_date <= p_release_date_to)
  AND (p_worldwide_gross_min IS NULL OR m.worldwide_gross >= p_worldwide_gross_min)
  AND (p_worldwide_gross_max IS NULL OR m.worldwide_gross <= p_worldwide_gross_max)
  AND (p_production_budget_min IS NULL OR m.production_budget >= p_production_budget_min)
  AND (p_production_budget_max IS NULL OR m.production_budget <= p_production_budget_max)
  AND (p_domestic_gross_min IS NULL OR m.domestic_gross >= p_domestic_gross_min)
  AND (p_domestic_gross_max IS NULL OR m.domestic_gross <= p_domestic_gross_max)
  AND (
    p_genres IS NULL
        OR cardinality(p_genres) = 0
        OR EXISTS (
        SELECT 1
        FROM wickers.movie_genres mg
                 JOIN wickers.genres g
                      ON g.id = mg.genre_id
        WHERE mg.movie_id = m.id
          AND g.name = ANY(p_genres)
    )
    );
$BODY$;

ALTER FUNCTION wickers.get_movies_count(
    text, text,
    date, date,
    numeric, numeric,
    numeric, numeric,
    numeric, numeric,
    text[]
    )
    OWNER TO "user";