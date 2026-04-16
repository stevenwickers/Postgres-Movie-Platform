CREATE OR REPLACE FUNCTION wickers.get_genres()
RETURNS TABLE (
    id UUID,
    name TEXT
)
LANGUAGE sql
AS $$
SELECT g.id, g.name
FROM wickers.genres g
ORDER BY g.name;
$$;


