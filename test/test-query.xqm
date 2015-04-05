xquery version "3.0";

(:~
 : Origami tests: xf:query
 :
 : NOTE: this way of querying is very slow and doesn't add much
 :       over regular XQuery code, also, I'm not sure if this function
 :       should be part of Origami.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:query-default-env() {
    unit:assert-equals(
        xf:query('self::p/@name', xf:context(<p name="foo"/>)),
        attribute name { 'foo' }
    ),
    unit:assert-equals(
        xf:query('self::html:p/@name', xf:context(<p name="foo" xmlns="http://www.w3.org/1999/xhtml"/>)),
        attribute name { 'foo' }
    ),
    unit:assert-equals(
        xf:query('self::html:p/@name', xf:context(<foo:p name="foo" xmlns:foo="http://www.w3.org/1999/xhtml"/>)),
        attribute name { 'foo' }
    ),
    unit:assert-equals(
        xf:query('self::html:p/@name', xf:context(<foo:p name="foo" xmlns:foo="urn:foo"/>)),
        ()
    )
};

declare %unit:test function test:query-env() {
    unit:assert-equals(
        xf:query('self::p/@name', xf:context(<p name="foo"/>, xf:env((xf:ns('foo', 'urn:foo'))))),
        attribute name { 'foo' }
    ),
    unit:assert-equals(
        xf:query('self::foo:p/@name', xf:context(<p name="foo" xmlns:foo="urn:foo"/>, xf:env((xf:ns('foo', 'urn:foo'))))),
        ()
    ),
    unit:assert-equals(
        xf:query('self::foo:p/@name', xf:context(<p name="foo" xmlns="urn:foo"/>, xf:env((xf:ns('foo', 'urn:foo'))))),
        attribute name { 'foo' }
    )
};

(:~
 : NOTE: test timings indicate that it's as slow as the above.
 : query-default-env: 0.27s, query-env: 0.2s, query-compiled: 0.26s
 :
 : NOTE: I could take namespaces from the context nodes but that would
 : still pose a problem fro default namespace as it doesn't have a prefix.
 : Therefore, I think it's cleaner to have to explicitly specify them in
 : the environment.
 :)
declare %unit:test function test:query-compiled() {
    let $q := xf:query(xf:context(<p name="foo" xmlns="urn:foo"/>, xf:env((xf:ns('foo', 'urn:foo')))))
    return (
        unit:assert-equals(
            $q('self::foo:p/@name'),
            attribute name { 'foo' }
        ),
        unit:assert-equals(
            $q('count(".")'),
            1
        ),
        unit:assert-equals(
            $q('count(".//@*")'),
            1
        ),
        (: NOTE: this does not return foo:p as the prefix isn't in scope for the context node :)
        unit:assert-equals(
            $q('name(.)'),
            'p'
        )
    )
};