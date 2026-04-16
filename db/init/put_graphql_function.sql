DROP FUNCTION IF EXISTS wickers.update_graphql_movie(UUID, JSONB);

CREATE OR REPLACE FUNCTION wickers.update_graphql_movie(
    p_movie_id uuid,
    p_patch jsonb
)
RETURNS TABLE (
    id uuid,
    movie_name text,
    release_date date,
    worldwide_gross numeric,
    production_budget numeric,
    domestic_gross numeric,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    genres text[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_movie_name text;
    v_genre_names text[];
BEGIN
    -- Make sure the movie exists first
    IF NOT EXISTS (
        SELECT 1
        FROM wickers.movies m
        WHERE m.id = p_movie_id
    ) THEN
        RAISE EXCEPTION 'Movie with id % not found', p_movie_id;
    END IF;

    -- If movie_name is being updated, normalize and validate it
    IF p_patch ? 'movie_name' THEN
        v_movie_name := NULLIF(trim(p_patch ->> 'movie_name'), '');

        IF v_movie_name IS NULL THEN
            RAISE EXCEPTION 'movie_name cannot be null or empty';
        END IF;

        IF EXISTS (
            SELECT 1
            FROM wickers.movies m
            WHERE lower(trim(m.movie_name)) = lower(v_movie_name)
              AND m.id <> p_movie_id
        ) THEN
            RAISE EXCEPTION 'Movie name "%" already exists', v_movie_name;
        END IF;
    END IF;

    UPDATE wickers.movies m
    SET
        movie_name = CASE
            WHEN p_patch ? 'movie_name' THEN NULLIF(trim(p_patch ->> 'movie_name'), '')
            ELSE m.movie_name
        END,
        release_date = CASE
            WHEN p_patch ? 'release_date' THEN (p_patch ->> 'release_date')::date
            ELSE m.release_date
        END,
        worldwide_gross = CASE
            WHEN p_patch ? 'worldwide_gross' THEN (p_patch ->> 'worldwide_gross')::numeric
            ELSE m.worldwide_gross
        END,
        production_budget = CASE
            WHEN p_patch ? 'production_budget' THEN (p_patch ->> 'production_budget')::numeric
            ELSE m.production_budget
        END,
        domestic_gross = CASE
            WHEN p_patch ? 'domestic_gross' THEN (p_patch ->> 'domestic_gross')::numeric
            ELSE m.domestic_gross
        END,
        updated_at = now()
    WHERE m.id = p_movie_id;

    -- Only touch genres if the key was provided
    IF p_patch ? 'genre_names' THEN
        v_genre_names := ARRAY(
            SELECT DISTINCT trim(value)
            FROM jsonb_array_elements_text(COALESCE(p_patch -> 'genre_names', '[]'::jsonb)) AS t(value)
            WHERE trim(value) <> ''
        );

        -- Replace genres
        DELETE FROM wickers.movie_genres
        WHERE movie_id = p_movie_id;

        IF array_length(v_genre_names, 1) IS NOT NULL THEN
            INSERT INTO wickers.genres (name)
            SELECT DISTINCT g
            FROM unnest(v_genre_names) AS g
            ON CONFLICT (name) DO NOTHING;

            INSERT INTO wickers.movie_genres (movie_id, genre_id)
            SELECT p_movie_id, g.id
            FROM wickers.genres g
            WHERE g.name = ANY(v_genre_names)
            ON CONFLICT DO NOTHING;
        END IF;
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
        COALESCE(
            array_agg(DISTINCT g.name) FILTER (WHERE g.name IS NOT NULL),
            ARRAY[]::text[]
        ) AS genres
    FROM wickers.movies m
    LEFT JOIN wickers.movie_genres mg ON mg.movie_id = m.id
    LEFT JOIN wickers.genres g ON g.id = mg.genre_id
    WHERE m.id = p_movie_id
    GROUP BY
        m.id,
        m.movie_name,
        m.release_date,
        m.worldwide_gross,
        m.production_budget,
        m.domestic_gross,
        m.created_at,
        m.updated_at;
END;
$$;