xquery version "3.1";

(:~
 : Tests for reading and parsing.
 :)

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

declare function test:dir($p) { concat(file:base-dir(), string-join($p,'/')) };
declare function test:text($f) { test:dir(('text',$f)) };
declare function test:xml($f) { test:dir(('xml',$f)) };
declare function test:csv($f) { test:dir(('csv',$f)) };
declare function test:html($f) { test:dir(('html',$f)) };
declare function test:json($f) { test:dir(('json',$f)) };

(: =========== TEXT =========== :)

(: @see https://github.com/BaseXdb/basex/issues/1181 error when $uri = () :)
declare %unit:test %unit:ignore function test:read-text-empty-uri() 
{
    unit:assert-equals(
        μ:read-text(()),
        (),
        "Empty $uri argument"
    ),
    
    unit:assert-equals(
        μ:read-text((), map { 'foo': 'bar'}),
        (),
        "Empty $uri argument and unknown map options"
    )
};

declare %unit:test function test:read-text-trailing-new-line() 
{
    unit:assert-equals(
        μ:read-text(test:text('test010.txt')),
        ("foo","bar"),
        "Second line ends with newline but is removed"
    )
};

declare %unit:test function test:read-text-unknown-options() 
{
    unit:assert-equals(
        μ:read-text(test:text('test001.txt'), map { 'foo': 'bar' }),
        ("foo","bar"),
        "Unknown options are silently ignored"
    )
};

declare %unit:test function test:read-text-line-endings() 
{
    (: Unix line-ending: &#xA; or &#10; :)
    (: Windows line-ending: &#xD;&#xA; or &#13;&#10; :)
    (: Mac line-ending: &#xD; or &#13; :)
    
    (: Tip: by parsing into lines (the default) these differences are automatically taken care of :)
    
    unit:assert-equals(
        μ:read-text(test:text('test001.txt')),
        ("foo","bar"),
        "Read test001.txt into separate lines (unix line-endings)"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test002.txt')),
        ("foo","bar"),
        "Read test002.txt into separate lines (windows line-endings)"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test003.txt')),
        ("foo","bar"),
        "Read test003.txt into separate lines (mac line-endings)"
    ),
    unit:assert-equals(
        μ:read-text(test:text('test001.txt'), map { 'lines': false()}),
        ("foo&#10;bar"),
        "Read test001.txt as one string item (unix line-endings)"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test002.txt'), map { 'lines': false()}),
        ("foo&#13;&#10;bar"),
        "Read test002.txt as one string item (windows line-endings)"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test003.txt'), map { 'lines': false()}),
        ("foo&#13;bar"),
        "Read test003.txt as one string item (mac line-endings)"
    )
};

declare %unit:test function test:read-text-encoding() 
{
    unit:assert-equals(
        μ:read-text(test:text('test004.txt')),
        ("折り紙"),
        "Read test004.txt without specified encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test004.txt'), map { 'encoding': 'utf-8'}),
        ("折り紙"),
        "Read test004.txt with utf-8 encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test005.txt')),
        ("折り紙"),
        "Read test005.txt without specified encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test005.txt'), map { 'encoding': 'utf-16'}),
        ("折り紙"),
        "Read test005.txt with utf-16 encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test006.txt')),
        ("折り紙"),
        "Read test006.txt without specified encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test006.txt'), map { 'encoding': 'utf-16'}),
        ("折り紙"),
        "Read test006.txt with utf-16"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test007.txt')),
        ("ωριγαμι"),
        "Read test007.txt without specified encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test008.txt'), map { 'encoding': 'windows-1253'}),
        ("ωριγαμι"),
        "Read test008.txt with windows-1253 encoding"
    ),
    
    unit:assert-equals(
        μ:read-text(test:text('test009.txt'), map { 'encoding': 'iso-8859-7'}),
        ("ωριγαμι"),
        "Read test009.txt with iso-8859-7 encoding"
    )
};

declare %unit:test function test:read-text-encoding-garbled()
{
    (: Greek can also be decoded with iso-8859-1 but this will result in the wrong characters :)
    unit:assert-equals(
        μ:read-text(test:text('test009.txt'), map { 'encoding': 'iso-8859-1'}),
        ("ùñéãáìé"),
        "Read iso-8859-7 (test009.txt) with iso-8859-1 encoding"
    )    
};

declare %unit:test("expected", "err:FOUT1190") function test:read-text-encoding-error()
{
    (: utf-8 text cannot be decoded with utf-16, btw without explicit encoding read-text will handle 
       detection of Unicode encoding automatically :)
    unit:assert-equals(
        μ:read-text(test:text('test004.txt'), map { 'encoding': 'utf-16'}),
        ("doenstmatter"),
        "Read utf-8 (test004.txt) with utf-16 encoding"
    )    

};

(: =========== XML =========== :)

declare %unit:test function test:read-xml()
{
    unit:assert-equals(
        μ:read-xml(()),
        (),
        "Empty $uri argument"
    ),
    
    unit:assert-equals(
        μ:read-xml(test:xml('test001.xml')),
        document { <μ:foo xmlns:μ="http://xokomola.com/xquery/origami/mu"><bar/></μ:foo> },
        "Read test001.xml"
    )    
};

declare %unit:test function test:read-xml-fetch()
{
    unit:assert-equals(
        μ:read-xml((), map { 'foo': 'bar' }),
        (),
        "Empty $uri arg"
    ),
    
    unit:assert-equals(
        μ:read-xml(test:xml('test001.xml'), map { 'foo': 'bar' }),
        document { <μ:foo xmlns:μ="http://xokomola.com/xquery/origami/mu"><bar/></μ:foo> },
        "Read test001.xml"
    )    
};

(: =========== HTML =========== :)

(: NOTE: that these tests will only work as expected when TagSoup is present on the classpath :)

(: @see https://github.com/BaseXdb/basex/issues/1181 error when $uri = () :)
declare %unit:test %unit:ignore function test:read-html-empty-uri()
{
    unit:assert-equals(
        μ:read-html(()),
        (),
        "Empty $uri argument"
    ),
    
    unit:assert-equals(
        μ:read-html((), map { 'foo': 'bar'}),
        (),
        "Empty $uri argument and unknown map options"
    )
};

(: The subject of text decoding and parsing with a tool like TagSoup and all the varieties
 : of HTML would require a lot more specific tests.
 :)
declare %unit:test function test:read-html()
{
    (: Note that reading external files may have extra whitespace text nodes so all
       HTML tests with external files have this extra whitespace removed. :)
    unit:assert-equals(
        μ:read-html(test:html('test001.html')),
        document {
            <html lang="en">
              <head>
                <meta charset="utf-8"/>
                <title>title</title>
              </head>
              <body>
                <p>Hellö</p>
              </body>
            </html>
        },
        "HTML5 utf8 (test001.html)"
    ),
    
    unit:assert-equals(
        μ:read-html(test:html('test002.html'), map { 'encoding': 'iso-8859-1' }),
        document {
            <html lang="en">
              <head>
                <title>title</title>
              </head>
              <body>
                <p>Hellö</p>
              </body>
            </html>
        },
        "HTML5 iso-8859-1 then we must be explicit about encoding (test002.html)"
    ),
    
    (: and if we get it wrong then things may work but will be garbled :)
    unit:assert-equals(
        μ:read-html(test:html('test002.html'), map {'encoding': 'iso-8859-7'}),
        document {
            <html lang="en">
              <head>
                <title>title</title>
              </head>
              <body>
                <p>Hellφ</p>
              </body>
            </html>
        },
        "HTML5 iso-8859-1 read with iso-8859-7 encoding option (test002.html)"
    ),
    
    unit:assert-equals(
        μ:read-html(test:html('test003.html'), map {'encoding': 'iso-8859-7'}),
        document {
            <html lang="en">
              <head>
                <meta charset="iso-8859-7"/>
                <title>title</title>
              </head>
              <body>
                <p>Hellω</p>
              </body>
            </html>
        },
        "HTML5 iso-8859-7 read with iso-8859-7 (test003.html)"
    )
};

declare %unit:test("expected", "err:FOUT1200") function test:read-html-decoding-error()
{
    (: note that TagSoup handles the encoding without being explicit :)
    unit:assert-equals(
        μ:read-html(test:html('test002.html')),
        document {
            <html lang="en">
              <head>
                <title>title</title>
              </head>
              <body>
                <p>Hellö</p>
              </body>
            </html>
        },
        "HTML5 iso-latin-8859-1 read as Unicode generates an error (test002.html)"
    )
};

(: Tests for parsing HTML via TagSoup :)
(: TODO: test more options :)
declare %unit:test function test:parse-html()
{
    unit:assert-equals(
        μ:parse-html("foo"),
        document {
            <html>
                <body>foo</body>
            </html>
        },
        "Insert html and body element"
    ),
    unit:assert-equals(
        μ:parse-html("<html>foo</html>"),
        document {
            <html>
                <body>foo</body>
            </html>
        },
        "Insert body element"
    ),

    unit:assert-equals(
        μ:parse-html(("<html>", "foo", "</html>")),
        document {
            <html>
                <body>foo</body>
            </html>
        },
        "HTML string passed in as a seq of strings"
    ),
    
    (: nobogons :)
    
    unit:assert-equals(
        μ:parse-html("foo<foo>bar</foo>"),
        document {
            <html>
              <body>foo<foo>bar</foo></body>
            </html>
        },
        "HTML5 with unknown element removed with default nobogons=false"
    ),
 
    unit:assert-equals(
        μ:parse-html("foo<foo>bar</foo>", map { 'nobogons': true() }),
        document {
            <html>
              <body>foobar</body>
            </html>
        },
        "HTML5 with unknown element removed with nobogons=true"
    ),
    
    unit:assert-equals(
        μ:parse-html("foo<foo>bar</foo>", map { 'nobogons': false() }),
        document {
            <html>
              <body>foo<foo>bar</foo></body>
            </html>
        },
        "HTML5 with unknown element and nobogons=false"
    ),
       
    (: nons :)
    
    unit:assert-equals(
        μ:parse-html("<html>foo</html>"),
        document {
            <html>
              <body>foo</body>
            </html>
        },
        "HTML5 with default nons=true"
    ),

    unit:assert-equals(
        μ:parse-html("<html>foo</html>", map { 'nons': true() }),
        document {
            <html>
              <body>foo</body>
            </html>
        },
        "HTML5 with nons=true"
    ),

    unit:assert-equals(
        μ:parse-html("<html>foo</html>", map { 'nons': false() }),
        document {
            <html xmlns="http://www.w3.org/1999/xhtml">
              <body>foo</body>
            </html>
        },
        "HTML5 with nons=false (adds the xhtml namespace)"
    )

};

(: =========== CSV =========== :)

(: @see https://github.com/BaseXdb/basex/issues/1181 error when $uri = () :)
declare %unit:test %unit:ignore function test:read-csv-empty-uri() 
{
    unit:assert-equals(
        μ:read-csv(()),
        (),
        "Empty $uri argument"
    ),
    
    unit:assert-equals(
        μ:read-csv((), map { 'foo': 'bar'}),
        (),
        "Empty $uri argument and unknown map options"
    )
};

declare %unit:test function test:read-csv() 
{
    unit:assert-equals(
        μ:read-csv(test:csv('test001.csv')),
        (
            ['A','B','C'],
            ['10','20','30']
        ),
        "Simple CSV, comma separator (test001.csv)"
    ),
    
    unit:assert-equals(
        μ:read-csv(test:csv('test002.csv'), map { 'separator': 'tab' }),
        (
            ['A','B','C'],
            ['10','20','30']
        ),
        "Simple CSV, tab separator (test002.csv)"
    ),
    
    unit:assert-equals(
        μ:read-csv(test:csv('test003.csv'), map { 'separator': 'semicolon' }),
        (
            ['A','B','C'],
            ['10','20','30']
        ),
        "Simple CSV, semicolon separator (test003.csv)"
    )
};

declare %unit:test function test:parse-csv()
{
    unit:assert-equals(
       μ:parse-csv(("A,B,C&#10;10,20,30")),
       (["A","B","C"],["10","20","30"])
    ),
    
    unit:assert-equals(
       μ:parse-csv(("A,B,C", "10,20,30")),
       (["A","B","C"],["10","20","30"])
    )
};

(: =========== JSON =========== :)

(: TODO test various parsing options :)

declare %unit:test function test:read-json() 
{
    unit:assert-equals(
        μ:read-json(()),
        (),
        "Empty $uri argument"
    ),

    unit:assert-equals(
        μ:read-json((), map { 'foo': 'bar'}),
        (),
        "Empty $uri argument and unknown map options"
    ),

    unit:assert-equals(
        μ:read-json(test:json('test001.json')),
        "foo",
        "Simple JSON string (test001.json)"
    ),
    
    unit:assert-equals(
        μ:read-json(test:json('test002.json')),
        (),
        "Simple JSON null (test002.json)"
    ),
    
    unit:assert-equals(
        μ:read-json(test:json('test003.json')),
        map { 'a': 10, 'b': '20' },
        "Simple JSON map (test003.json)"
    ),

    unit:assert-equals(
        μ:read-json(test:json('test004.json')),
        ['a',10,(),'20'],
        "Simple JSON array (test004.json)"
    )
};

declare %unit:test function test:parse-json() 
{
    unit:assert-equals(
        μ:parse-json("&quot;foo&quot;"),
        "foo",
        "Simple JSON string"
    ),
    
    unit:assert-equals(
        μ:parse-json("null"),
        (),
        "Simple JSON null"
    ),
    
    unit:assert-equals(
        μ:parse-json("[&quot;a&quot;,10,null,&quot;20&quot;]"),
        ['a',10,(),'20'],
        "Simple JSON array"
    )
};

declare %unit:test("expected", "err:FOJS0001") function test:parse-invalid-json() 
{
    unit:assert-equals(
        μ:parse-json("[&quot;foo&quot;"),
        "foo",
        "Invalid JSON array"
    )
};

