
DROP FUNCTION IF EXISTS wickers.get_movies(
    text, text, integer, integer, text, text,
    date, date,
    numeric, numeric,
    numeric, numeric,
    numeric, numeric,
    text[]
    );

CREATE OR REPLACE FUNCTION wickers.get_movies(
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
LANGUAGE sql
AS $$
SELECT *
FROM wickers.get_movies_core(
        p_search,
        p_search_mode,
        p_page,
        p_page_size,
        p_sort_by,
        p_sort_direction,
        p_release_date_from,
        p_release_date_to,
        p_worldwide_gross_min,
        p_worldwide_gross_max,
        p_production_budget_min,
        p_production_budget_max,
        p_domestic_gross_min,
        p_domestic_gross_max,
        p_genres
     );
$$;