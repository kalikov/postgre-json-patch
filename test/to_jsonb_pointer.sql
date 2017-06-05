SELECT to_jsonb_pointer('{}'::jsonb, null) IS NULL
SELECT to_jsonb_pointer('{}'::jsonb, '') = ('{}','{}','{}')::jsonb_pointer
SELECT to_jsonb_pointer('{}'::jsonb, '/') = ('{}','{""}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"foo":"bar"}'::jsonb, '/') = ('{"foo":"bar"}','{""}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"foo":null}'::jsonb, '/foo') = ('{"foo":null}','{foo}','null')::jsonb_pointer
SELECT to_jsonb_pointer('[]'::jsonb, '/0') = ('[]','{0}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{}'::jsonb, '/foo') = ('{}','{foo}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('"foo"'::jsonb, '') = ('"foo"','{}','"foo"')::jsonb_pointer
SELECT to_jsonb_pointer('[]'::jsonb, '') = ('[]','{}','[]')::jsonb_pointer
SELECT to_jsonb_pointer('[]'::jsonb, '/-') = ('[]','{0}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"foo":1}'::jsonb, '/bar') = ('{"foo":1}','{bar}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"foo":1,"baz":[{"qux":"hello"}]}'::jsonb, '/baz/0/foo') = ('{"foo":1,"baz":[{"qux":"hello"}]}','{baz,0,foo}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"foo":1,"baz":[{"qux":"hello"}]}'::jsonb, '/baz/0/qux') = ('{"foo":1,"baz":[{"qux":"hello"}]}','{baz,0,qux}','"hello"')::jsonb_pointer
SELECT to_jsonb_pointer('{"bar":[1,2]}'::jsonb, '/bar/8') -- 'Array index out of bounds (upper)'
SELECT to_jsonb_pointer('{"bar":[1,2]}'::jsonb, '/bar/-1') -- 'Array index out of bounds (lower)'
SELECT to_jsonb_pointer('{"foo":1}'::jsonb, '/0') = ('{"foo":1}','{0}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('[""]'::jsonb, '/0') = ('[""]','{0}','""')::jsonb_pointer
SELECT to_jsonb_pointer('["foo"]'::jsonb, '/0') = ('["foo"]','{0}','"foo"')::jsonb_pointer
SELECT to_jsonb_pointer('["foo"]'::jsonb, '/1') = ('["foo"]','{1}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('["foo"]'::jsonb, '/00') -- 'Array is referenced with a non-numeric token'
SELECT to_jsonb_pointer('["foo"]'::jsonb, '/01') -- 'Array is referenced with a non-numeric token'
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/0') = ('["foo","bar"]','{0}','"foo"')::jsonb_pointer
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/1') = ('["foo","bar"]','{1}','"bar"')::jsonb_pointer
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/2') = ('["foo","bar"]','{2}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/3') -- 'Array index out of bounds (upper)'
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/-') = ('["foo","bar"]','{2}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"1e0":"foo"}'::jsonb, '/1e0') = ('{"1e0":"foo"}','{1e0}','"foo"')::jsonb_pointer
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/1e0') -- 'Array is referenced with a non-numeric token'
SELECT to_jsonb_pointer('["foo","bar"]'::jsonb, '/test') -- 'Array is referenced with a non-numeric token'
SELECT to_jsonb_pointer('[1,2,[3,[4,5]]]'::jsonb, '/2/1/-') = ('[1,2,[3,[4,5]]]','{2,1,2}',NULL)::jsonb_pointer
SELECT to_jsonb_pointer('{"foo":1,"bar":[1,2,3,4]}'::jsonb, '/bar') = ('{"foo":1,"bar":[1,2,3,4]}','{bar}','[1,2,3,4]')::jsonb_pointer
SELECT to_jsonb_pointer('{"a/b":1}'::jsonb, '/a~1b') = ('{"a/b":1}','{a/b}','1')::jsonb_pointer
SELECT to_jsonb_pointer('{"m~n":1}'::jsonb, '/m~0n') = ('{"m~n":1}','{m~n}','1')::jsonb_pointer
SELECT to_jsonb_pointer('{"m~1n":1}'::jsonb, '/m~01n') = ('{"m~1n":1}','{m~1n}','1')::jsonb_pointer
SELECT to_jsonb_pointer('{"c%d":{"e^d":{"g|h":1}}}'::jsonb, '/c%d/e^d/g|h') = ('{"c%d":{"e^d":{"g|h":1}}}','{"c%d","e^d","g|h"}','1')::jsonb_pointer
SELECT to_jsonb_pointer('{"i\\j":{"k\"l":{" ": 1}}}'::jsonb, '/i\j/k"l/ ') = ('{"i\\j":{"k\"l":{" ": 1}}}','{"i\\j","k\"l"," "}','1')::jsonb_pointer