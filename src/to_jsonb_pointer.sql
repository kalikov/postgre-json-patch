-- FUNCTION: public.to_jsonb_pointer(jsonb, text)

-- DROP FUNCTION public.to_jsonb_pointer(jsonb, text);

CREATE OR REPLACE FUNCTION public.to_jsonb_pointer(
    document jsonb,
    string text)
    RETURNS jsonb_pointer
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF
AS $function$

DECLARE
    path text[];
    value jsonb;
    i int;
    n int;
BEGIN
    IF string IS NULL THEN
        RETURN NULL;
    END IF;
    IF string = '' THEN
        RETURN (document, ARRAY[]::text[], document);
    END IF;
    IF left(string, 1) <> '/' THEN
        RAISE 'invalid_pointer_syntax' USING MESSAGE = 'Reference token is not prefixed by /';
    END IF;
    path := regexp_split_to_array(substr(string, 2), E'/');
    value := document;
    n := array_length(path, 1);
    FOR i IN 1 .. n LOOP
        IF substring(path[i] FROM E'~[^01]|~$') IS NOT NULL THEN
            RAISE 'invalid_pointer_syntax' USING MESSAGE = 'Character ~ is not escaped';
        END IF;
        path[i] := replace(replace(path[i], '~1', '/'), '~0', '~');
        IF jsonb_typeof(value) = 'object' THEN
            IF value ? path[i] THEN
                value := value -> path[i];
            ELSE
                value := NULL;
            END IF;
        ELSIF jsonb_typeof(value) = 'array' THEN
            IF path[i] = '-' THEN
                path[i] = jsonb_array_length(value);
                value := NULL;
            ELSIF substring(path[i] from E'0|[1-9][0-9]*') <> path[i] THEN
                RAISE 'invalid_reference_token' USING MESSAGE = 'Array is referenced with a non-numeric token';
            ELSE
                BEGIN
                    IF (path[i]::int) > jsonb_array_length(value) THEN
                        RAISE 'invalid_reference_token' USING MESSAGE = 'Array index out of bounds (upper)';
                    ELSIF (path[i]::int) < 0 THEN
                        RAISE 'invalid_reference_token' USING MESSAGE = 'Array index out of bounds (lower)';
                    END IF;
                    value := value -> (path[i]::int);
                EXCEPTION WHEN OTHERS THEN
                    RAISE 'invalid_reference_token' USING MESSAGE = 'Array is referenced with a non-numeric token';
                END;
            END IF;
        ELSE
            RAISE 'invalid_reference_token' USING MESSAGE = 'Pointer references a nonexistent value';
        END IF;
    END LOOP;
    RETURN (document, path, value);
END;

$function$;

ALTER FUNCTION public.to_jsonb_pointer(jsonb, text)
    OWNER TO pt;
