CREATE OR REPLACE FUNCTION wickers.get_genre_by_id(
	p_genre_id uuid)
    RETURNS TABLE(id uuid, name text)
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
SELECT
    m.id,
    m.name
FROM wickers.genres m
WHERE m.id = p_genre_id
GROUP BY m.id;
$BODY$;