DROP FUNCTION IF EXISTS wickers.delete_movie(UUID);

-- DELETE
CREATE OR REPLACE FUNCTION wickers.delete_movie(
    p_movie_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
v_deleted_count INT;
BEGIN
DELETE FROM wickers.movies
WHERE id = p_movie_id;

GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

RETURN v_deleted_count > 0;
END;
$$;

COMMIT;