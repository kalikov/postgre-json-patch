-- FUNCTION: public.jsonb_patch(jsonb, jsonb)

-- DROP FUNCTION public.jsonb_patch(jsonb, jsonb);

CREATE OR REPLACE FUNCTION public.jsonb_patch(
    document jsonb,
    patch jsonb)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE NOT LEAKPROOF
AS $function$
DECLARE
    n int;
    i int;
    operation jsonb;
    pointer jsonb_pointer;
    parent_pointer jsonb_pointer;
    from_pointer jsonb_pointer;
BEGIN
    IF patch IS NULL THEN
        RETURN document;
    END IF;
    IF jsonb_typeof(patch) <> 'array' THEN
        RAISE 'invalid_patch_document' USING MESSAGE = 'Patch document is not an array of operations';
    END IF;
    n := jsonb_array_length(patch);
    FOR i IN 0 .. n - 1 LOOP
        operation = patch -> i;
        IF jsonb_typeof(operation) <> 'object' THEN
            RAISE 'invalid_patch_document' USING MESSAGE = 'Patch operation is not an object';
        END IF;
        IF NOT operation ? 'op' THEN
            RAISE 'invalid_patch_document' USING MESSAGE = 'Patch operation is missing "op" member';
        END IF;
        IF NOT operation ? 'path' THEN
            RAISE 'invalid_patch_document' USING MESSAGE = 'Patch operation is missing "path" member';
        END IF;
        pointer := to_jsonb_pointer(document, operation ->> 'path');
        CASE operation ->> 'op'
            WHEN 'add' THEN
                IF NOT operation ? 'value' THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "add" operation is missing "value" member';
                END IF;
                IF array_length(pointer.path, 1) IS NULL THEN
                    document := operation -> 'value';
                ELSE
                    parent_pointer := jsonb_pointer_parent(pointer);
                    IF jsonb_typeof(parent_pointer.value) = 'array' THEN
                        document := jsonb_insert(document, pointer.path, operation -> 'value');
                    ELSE
                        document := jsonb_set(document, pointer.path, operation -> 'value');
                    END IF;
                END IF;
            WHEN 'remove' THEN
                IF array_length(pointer.path, 1) IS NULL THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "remove" operation does not support removal of the root';
                END IF;
                IF pointer.value IS NULL THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "remove" operation "path" member does not reference an existing value';
                END IF;
                document := document #- pointer.path;
            WHEN 'replace' THEN
                IF NOT operation ? 'value' THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "replace" operation is missing "value" member';
                END IF;
                IF array_length(pointer.path, 1) IS NULL THEN
                    document := operation -> 'value';
                ELSE
                    IF pointer.value IS NULL THEN
                        RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "replace" operation "path" member does not reference an existing value';
                    END IF;
                    document := jsonb_set(document, pointer.path, operation -> 'value');
                END IF;
            WHEN 'move' THEN
                IF NOT operation ? 'from' THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "move" operation is missing "from" member';
                END IF;
                from_pointer := to_jsonb_pointer(document, operation ->> 'from');
                IF array_length(from_pointer.path, 1) IS NULL THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "move" operation does not support movement of the root';
                END IF;
                IF from_pointer.value IS NULL THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "move" operation "from" member does not reference an existing value';
                END IF;
                document := document #- from_pointer.path;
                IF array_length(pointer.path, 1) IS NULL THEN
                    document := from_pointer.value;
                ELSE
                    parent_pointer := jsonb_pointer_parent(pointer);
                    IF jsonb_typeof(parent_pointer.value) = 'array' THEN
                        document := jsonb_insert(document, pointer.path, from_pointer.value);
                    ELSE
                        document := jsonb_set(document, pointer.path, from_pointer.value);
                    END IF;
                END IF;
            WHEN 'copy' THEN
                IF NOT operation ? 'from' THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "copy" operation is missing "from" member';
                END IF;
                from_pointer := to_jsonb_pointer(document, operation ->> 'from');
                IF from_pointer.value IS NULL THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "copy" operation "from" member does not reference an existing value';
                END IF;
                IF array_length(pointer.path, 1) IS NULL THEN
                    document := from_pointer.value;
                ELSE
                    parent_pointer := jsonb_pointer_parent(pointer);
                    IF jsonb_typeof(parent_pointer.value) = 'array' THEN
                        document := jsonb_insert(document, pointer.path, from_pointer.value);
                    ELSE
                        document := jsonb_set(document, pointer.path, from_pointer.value);
                    END IF;
                END IF;
            WHEN 'test' THEN
                IF NOT operation ? 'value' THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "test" operation is missing "value" member';
                END IF;
                IF pointer.value IS NULL THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "test" operation "path" member does not reference an existing value';
                END IF;
                IF pointer.value <> operation -> 'value' THEN
                    RAISE 'invalid_patch_document' USING MESSAGE = 'Patch "test" operation "value" member is not equal to referencing value';
                END IF;
            ELSE
                RAISE 'invalid_patch_document' USING MESSAGE = 'Unsupported operation type';
        END CASE;
    END LOOP;
    RETURN document;
END;

$function$;

ALTER FUNCTION public.jsonb_patch(jsonb, jsonb)
    OWNER TO pt;
