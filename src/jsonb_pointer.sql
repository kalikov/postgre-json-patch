-- Type: jsonb_pointer

-- DROP TYPE public.jsonb_pointer;

CREATE TYPE public.jsonb_pointer AS
(
    root jsonb,
    path text[],
    value jsonb
);

ALTER TYPE public.jsonb_pointer
    OWNER TO pt;
