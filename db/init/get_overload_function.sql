DROP FUNCTION IF EXISTS wickers.get_movies(integer, integer);

CREATE OR REPLACE FUNCTION wickers.get_movies(
    p_page integer,
    p_page_size integer
)
RETURNS SETOF wickers.movie_row
LANGUAGE sql
AS $$
SELECT *
FROM wickers.get_movies_core(
        NULL,               -- p_search
        'general',          -- p_search_mode
        p_page,
        p_page_size,
        'movie_name',       -- p_sort_by
        'asc',              -- p_sort_direction
        NULL, NULL,
        NULL, NULL,
        NULL, NULL,
        NULL, NULL,
        NULL
     );
$$;