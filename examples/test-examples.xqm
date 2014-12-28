xquery version "3.0";

(:~
 : Origami tests: examples
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:~
 : code-samples.xq
 :)
declare %unit:test function test:code-samples() {
    let $example := 'code-samples.xq'
    let $result := xquery:invoke($example)
    return (
        unit:assert(count($result) gt 10, 
            'Expected more than 10 code samples, found only ' || count($result))
    )
};

(:~
 : coupland-original.xq
 :)
declare %unit:test function test:coupland-original() {
    let $example := 'coupland-original.xq'
    let $result := xquery:invoke($example)
    return (
        (: only do some fingerprinting to ensure output is okay :)
        unit:assert($result instance of element(html)),
        unit:assert-equals(
            crypto:hmac(string-join($result//@href,' '), 'not-a-secret','md5','base64'),
            'l0yW9+9lXhb+VEILdWjOTA==',
            'Differences in @hrefs')
    )
};

(:~
 : coupland.xq
 :)
 declare %unit:test function test:coupland() {
    let $example := 'coupland.xq'
    let $result := xquery:invoke($example)
    return (
        (: only do some fingerprinting to ensure output is okay :)
        unit:assert($result instance of document-node()),
        unit:assert($result/* instance of element(html)),
        unit:assert-equals(
            crypto:hmac(string-join($result//@href,' '), 'not-a-secret','md5','base64'),
            'rA//EbsHdorZaiRKIn4SQg==',
            'Differences in @hrefs')
    )
};

(:~
 : create-table-origami.xq
 :)
declare %unit:test function test:create-table-origami() {
    let $example := 'create-table-origami.xq'
    let $bindings := map { 'rows': 10 }
    let $result := xquery:invoke($example, $bindings)
    return (
        unit:assert($result instance of element(table),
            'Expected "table" element, found "' || node-name($result) || '"'),
        unit:assert-equals(count($result/tr), $bindings('rows'),
            'Expected exactly ' || $bindings('rows') || 'rows, found ' || count($result/tr))
    )
};

(:~
 : create-table-xquery.xq
 :)
declare %unit:test function test:create-table-xquery() {
    let $example := 'create-table-xquery.xq'
    let $bindings := map { 'rows': 10 }
    let $result := xquery:invoke($example, $bindings)
    return (
        unit:assert($result instance of element(table),
            'Expected "table" element, found "' || node-name($result) || '"'),
        unit:assert-equals(count($result/tr), $bindings('rows'),
            'Expected exactly ' || $bindings('rows') || 'rows, found ' || count($result/tr))
    )
};

(:~
 : extract-1.xq
 :)
declare %unit:test function test:extract-1() {
    let $example := 'extract-1.xq'
    let $result := xquery:invoke($example)
    return
        unit:assert-equals(
            $result,
            (<li id="first">item 1</li>, <li id="last">item 3</li>))
};


(:~
 : extract-2.xq
 :)
declare %unit:test function test:extract-2() {
    let $example := 'extract-2.xq'
    let $result := xquery:invoke($example)
    return
        unit:assert-equals(
            $result,
            (<li id="first">item 1</li>,<li>item 2</li>,<li id="last">item 3</li>))
};

(:~
 : extract-3.xq
 :)
declare %unit:test function test:extract-3() {
    let $example := 'extract-3.xq'
    let $result := xquery:invoke($example)
    return
        unit:assert-equals(
            $result,
            <ul>
                <li id="first">item 1</li>
                <li>item 2</li>
                <li id="last">item 3</li>
            </ul>)
};

(:~
 : identity.xq
 :)
declare %unit:test function test:identity() {
    let $example := 'identity.xq'
    let $result := xquery:invoke($example)
    return
        unit:assert-equals(
            $result,
            <a x="10">
                <b y="20">
                    <c/>
                </b>
                <p/>
            </a>)
};

(:~
 : nolen.xq
 :)
declare %unit:test function test:nolen() {
    let $example := 'nolen.xq'
    let $result := xquery:invoke($example)
    return
        unit:assert-equals($result,
        document { <html>
          <head>
            <title id="title">My Index</title>
            <link rel="stylesheet" type="text/css" href="main.css"/>
          </head>
          <body>
            <div class="column" id="header">A boring header</div>
            <div class="column" id="main">
              <div id="main">
                <div class="column" id="left">
                  <div class="nav column" id="nav1">
                    <div>
                      <span class="count">3</span>
                    </div>
                    <div>One</div>
                    <div>Two</div>
                    <div>Three</div>
                  </div>
                </div>
                <div class="column" id="middle">
                  <div class="nav column" id="nav2">
                    <div>A</div>
                    <div>B</div>
                    <div>C</div>
                    <div>D</div>
                  </div>
                </div>
                <div class="column" id="right">
                  <div class="nav column" id="nav3">
                    <div>One</div>
                    <div>Two</div>
                    <div>Three</div>
                  </div>
                </div>
              </div>
            </div>
            <div class="column" id="footer">A boring footer</div>
          </body>
        </html> })
};

(:~
 : ny-times.xq
 :)
declare %unit:test function test:ny-times() {
    let $example := 'ny-times.xq'
    let $result := xquery:invoke($example)
    return (
        unit:assert(every $e in $result satisfies $e instance of element(story),
            'Expected a sequence of only story elements, found ' || string-join(distinct-values($result/name()),', ')),
        unit:assert-equals(count($result), 12,
            'Expected exactly 12 complete stories, found ' || count($result))
    )
};

(:~
 : uppercase.xq
 :)
declare %unit:test function test:uppercase() {
    let $example := 'uppercase.xq'
    let $result := xquery:invoke($example)
    return
        unit:assert-equals(
            $result,
            document { <A>
                <B>
                    <C/>
                </B>
                <P/>
                <A/>
            </A>})
};
