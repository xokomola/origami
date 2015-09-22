xquery version "3.1";

module namespace o = 'http://xokomola.com/xquery/origami';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at 'mu.xqm';
import module namespace u = 'http://xokomola.com/xquery/origami/utils' at 'utils.xqm';

declare %private variable $o:ns := μ:ns();

(: TODO: combine template and snippet :)

(: Reading from external entities :)

declare function o:read-xml($uri as xs:string)
as document-node()?
{
    doc($uri)
};

(:~
 : XQuery does not support options for controlling the parsing of XML.
 : This function allows the use of proprietary fetch:xml to specify some
 : options to the XML parser.
 :
 : Also there's a difference with fn:doc in that each call fetches a
 : new document and it is discarded after the query ends.
 :
 : For options see: http://docs.basex.org/wiki/Options#Parsing
 :)
declare function o:read-xml($uri as xs:string, $options as map(xs:string, item()))
as document-node()?
{
    fetch:xml($uri, u:select-keys($options, $o:xml-options))
};

declare variable $o:xml-options :=
    ('chop', 'stripns', 'intparse', 'dtd', 'xinclude', 'catfile', 'skipcorrupt');

(:~
 : Read and parse HTML with the Tagsoup parser (although this could be changed).
 : If Tagsoup is not available it will fallback to parsing well-formed XML.
 :
 : For options see: http://docs.basex.org/wiki/Parsers#TagSoup_Options
 :)
declare function  o:read-html($uri as xs:string)
as document-node()?
{
    o:read-html($uri, map { 'lines': false() })   
};

declare function o:read-html($uri as xs:string, $options as map(xs:string, item()))
as document-node()?
{
    o:parse-html(o:read-text($uri, map:merge(($options, map { 'lines': false() }))), $options)
};

(:~
 : Note that binary or strings can be passed to html:parse, in which case encoding 
 : can be used to override automatic detection.
 : We can also just pass in a seq of strings.
 :)
declare function o:parse-html($text as xs:string*)
as document-node()?
{
    html:parse(string-join($text, ''))
};

declare function o:parse-html($text as xs:string*, $options as map(xs:string, item()))
as document-node()?
{
    html:parse(string-join($text, ''), u:select-keys($options, $o:html-options))
};

(:~
 : TagSoup options not supported by BaseX: 
 : files, method, version, standalone, pyx, pyxin, output-encoding, reuse, help
 : Note that encoding is not passed as text read with $o:read-text or provided
 : already is in Unicode. 
 :)
declare %private variable $o:html-options :=
    ('html', 'omit-xml-declaration', 'doctype-system', 'doctype-public', 'nons', 
     'nobogons', 'nodefaults', 'nocolons', 'norestart', 'ignorable', 'empty-bogons', 'any',
     'norootbogons', 'lexical', 'nocdata');

(:~
 : Options:
 :
 : - lines: true() or false()
 : - encoding
 :)
declare function o:read-text($uri as xs:string)
as xs:string*
{
    o:read-text($uri, map { })
};

declare function o:read-text($uri as xs:string, $options as map(xs:string, item()))
as xs:string*
{
    let $parse-into-lines := ($options?lines, true())[1]
    let $encoding := $options?encoding
    return
        if ($parse-into-lines)
        then if ($encoding) then unparsed-text-lines($uri, $encoding) else unparsed-text-lines($uri) 
        else if ($encoding) then unparsed-text($uri, $encoding) else unparsed-text($uri)
};

declare function o:read-json($uri as xs:string)
as item()?
{
    o:read-json($uri, map {})
};

declare function o:read-json($uri as xs:string, $options as map(xs:string, item()))
as item()?
{
    json-doc($uri, u:select-keys($options, $o:xml-options))
};

(:~
 : Options:
 :
 : - liberal: true() or false() [default, RFC7159 parsing]
 : - unescape: true() or false() [default true()]
 : - duplicates: reject, use-first, use-last [default use-last]
 :
 : See: http://www.w3.org/TR/xpath-functions-31/#func-parse-json
 :)
declare function o:parse-json($text as xs:string*)
as item()?
{
    parse-json(string-join($text,''))
};

declare function o:parse-json($text as xs:string*, $options as map(xs:string, item()))
as item()?
{
    parse-json(string-join($text,''), $options?($o:json-options))
};

declare %private variable $o:json-options :=
    ('liberal', 'unescape', 'duplicates');

(:~
 : Options:
 :
 : - encoding (for text decoding)
 : - separator: comma, semicolon, tab, space or any single character (default comma)
 : - lax: yes, no (yes) lax approach to parsing qnames to json names
 : - quotes: yes, no (yes)
 : - backslashes: yes, no (no)
 :
 : TODO: check which options are only meant for serialization.
 :)
declare function o:read-csv($uri as xs:string)
as array(*)*
{
    o:read-csv($uri, map {})
};

declare function o:read-csv($uri as xs:string, $options as map(xs:string, item()))
as array(*)*
{
    o:parse-csv(
        o:read-text(
            $uri, 
            map:merge(($options, map { 'lines': false() }))
        ), 
        $options
    )
};

declare function o:parse-csv($text as xs:string*)
as array(*)*
{
    o:parse-csv($text, map {})
};

declare function o:parse-csv($text as xs:string*, $options as map(xs:string, item()))
as array(*)*
{
    o:csv-normal-form(
        csv:parse(
            string-join($text,'&#10;'), 
            map:merge((u:select-keys($options, $o:csv-options), map { 'format': 'map' }))
        )
    )
};

(: ignore format option (only supported normalized form), header is dealt with in o:csv-object :)
declare %private variable $o:csv-options :=
    ('separator', 'lax', 'quotes', 'backslashes');

(:~
 : BaseX csv:parse returns a map with keys, this turns it into
 : a sequence of arrays (each array corresponds with a row)
 :)
declare %private function o:csv-normal-form($csv)
{
    map:keys($csv) ! array { $csv(.) }
};

(: Origami templating :)

(:~
 : Create a template using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)

(:~
 : Create a template using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
(: TODO: can't we simplify on always having an on array arg function as context corresp. to apply :)

declare function o:template($rules as array(*)*)
as item()*
{
    o:compile-template(?, o:compile-rules($rules))
};

declare function o:template($template as item(), $rules as array(*)*)
as item()*
{
    o:compile-template($template, o:compile-rules($rules))
};

(:~
 : Create a template snippet using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
(: TODO: consider naming this fragment or extract :)
declare function o:snippets($rules as array(*)*)
as item()*
{
    o:compile-snippet(?, o:compile-rules($rules))
};

declare function o:snippets($template as item(), $rules as array(*)*)
as item()*
{
    o:compile-snippet($template, o:compile-rules($rules))
};


(: TODO: ['p', fn1#2, fn2#2, fn3#2] compose a node transformer/pipeline :)
declare function o:compile-rules($rules as array(*)*)
as map(*)
{
    map:merge((
        for $rule in $rules
        let $selector := translate(array:head($rule), "&quot;","'")
        let $handler := $rule(2)
        return
            map:entry($selector, $handler)
    ))
};

declare function o:compile-template($template as item(), $rules as map(*))
as array(*)?
{
    let $template := μ:xml($template)
    return
        μ:doc(
            xslt:transform(
                $template, 
                o:compile-transformer(
                    $rules, 
                    map { 
                        'extract': false(),
                        'ns': map:merge(($o:ns, μ:ns-map-from-nodes($template)))
                    }
                )
            ), 
            $rules
        )
};

(: TODO: consider naming this fragment :)
(: TODO: remove code duplication :)

declare function o:compile-snippet($template as item(), $rules as map(*))
as array(*)*
{
    let $template := μ:xml($template)
    return
        μ:doc(
            xslt:transform(
                $template, 
                o:compile-transformer(
                    $rules, 
                    map { 
                        'extract': true(),
                        'ns': map:merge(($o:ns, μ:ns-map-from-nodes($template)))
                    }
                )
            ), 
            $rules
        )
};

declare function o:compile-transformer($rules as map(*)?)
as element(*)
{
    o:compile-transformer($rules, map {})
};

(: TODO: if I do ns handling differently we could write without the xls: prefix :)
declare function o:compile-transformer($rules as map(*)?, $options as map(*))
as element(*)
{
    μ:xml(
        ['stylesheet', 
            map:merge((
                map:entry('version', '1.0')
            )),
            ['output', map { 'method': 'xml' }],
            if ($options?extract) 
            then (
                ['template', map { 'match': '/' }, ['o:seq', ['apply-templates']]],
                ['template', map { 'match': 'text()' }]
            )
            else 
                o:identity-transform(),
            for $selector in map:keys(($rules, map {})[1])
            let $xpath := translate($selector, "&quot;","'")
            return
                ['template', map { 'match': $xpath },
                    ['copy',
                        ['copy-of', map { 'select': '@*' }],
                        ['attribute', map { 'name': 'o:path' }, $xpath],
                        if ($options?extract)
                        then ['copy-of', map { 'select': 'node()' }]
                        else ['apply-templates', map { 'select': 'node()' }]
                    ]
                ]
        ],
        map { 'ns': $options?ns, 'default-ns': 'http://www.w3.org/1999/XSL/Transform' }
    )
};

declare function o:identity-transform()
as array(*)+
{
    ['template', map { 'priority': -10, 'match': '@*|*' },
        ['copy',
            ['apply-templates', map { 'select': '*|@*|text()' }]
        ]
    ],
    ['template', map { 'match': 'processing-instruction()|comment()' }]
};

(:~ Aliases for some frequently used mu module functions :)

declare function o:xml($mu as item()*)
as node()*
{
    μ:xml($mu, map {})
};

declare function o:xml($mu as item()*, $options as map(*)) 
as node()*
{
    μ:xml($mu, $options)
};

declare function o:apply($nodes as item()*)
{
    μ:apply($nodes, [])
};

declare function o:apply($nodes as item()*, $args as array(*))
as item()*
{  
    μ:apply($nodes, $args)
};