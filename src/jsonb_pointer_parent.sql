-- FUNCTION: public.jsonb_pointer_parent(jsonb_pointer)

-- DROP FUNCTION public.jsonb_pointer_parent(jsonb_pointer);

CREATE OR REPLACE FUNCTION public.jsonb_pointer_parent(
    pointer jsonb_pointer)
    RETURNS jsonb_pointer
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF
AS $function$

DECLARE
    path text[];
    n int;
BEGIN
    IF pointer IS NULL THEN
        RETURN NULL;
    END IF;
    n := array_length(pointer.path, 1);
    IF n IS NULL THEN
        RETURN NULL;
    END IF;
    path := pointer.path[1:n-1];
    RETURN (pointer.root, path, pointer.root #> path);
END;

$function$;

ALTER FUNCTION public.jsonb_pointer_parent(jsonb_pointer)
    OWNER TO pt;
