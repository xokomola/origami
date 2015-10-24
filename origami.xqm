xquery version "3.1";

(:~
 : Origami 0.6
 :)

(: TODO: o:content => o:children :)
(: TODO: zippers? :)
(: TODO: deserialize into mu (hints: e.g. @class to ('cl1','cl2') :)

module namespace o = 'http://xokomola.com/xquery/origami';

import module namespace u = 'http://xokomola.com/xquery/origami/utils' 
    at 'utils.xqm';

declare %private variable $o:e := xs:QName('o:element');
declare %private variable $o:d := xs:QName('o:data');
declare %private variable $o:ns := o:ns-map();
declare %private variable $o:handler-att := '@';
declare %private variable $o:data-att := '!';
declare %private variable $o:is-element := true();
declare %private variable $o:is-handler := false();
declare %private variable $o:internal-att := ($o:data-att,$o:handler-att);

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
        if ($parse-into-lines) then 
            if ($encoding) then 
                unparsed-text-lines($uri, $encoding) 
            else 
                unparsed-text-lines($uri) 
        else 
            if ($encoding) then 
                unparsed-text($uri, $encoding) 
            else unparsed-text($uri)
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

(: Create Origami documents :)

(:~
 : Transforms input nodes using the supplied transformer to an Origami document.
 :)
declare function o:doc($nodes as item()*, $xform as function(item()*) as item()*)
as item()*
{
    $xform($nodes)
};

(:~
 : Converts input nodes to an Origami document.
 :)
declare function o:doc($nodes as item()*)
as item()*
{
    $nodes ! o:doc-node(., map {})
};

(:~
 : Returns a transformer function that takes input nodes and
 : returns an origami document with the rules applied to the
 : nodes (event handlers attached).
 :)
declare function o:xform($rules as item()*, $options as map(*))
as item()*
{
    typeswitch ($rules)
    case empty-sequence() return
        function($nodes) { $nodes ! o:doc-node(., map {}) }
    case array(*)+ return
        let $rules := map:merge($rules ! o:compile-rule(., ()))
        let $extractor := o:compile-stylesheet($rules, map { 'ns': $o:ns })
        return o:merge-handlers($extractor, $rules, $options)
    case map(*) return 
        function($nodes) { $nodes ! o:doc-node(., $rules) }
    default return 
        function($nodes) { $nodes ! o:doc-node(., map {}) }
};

declare function o:xform($rules as item()*)
as item()*
{
    o:xform($rules, map {})
};

declare function o:xform()
{
    o:xform((), map {})
};

declare %private function o:doc-node($item as item())
{
    o:doc-node($item, map {})
};

(: TODO: how to deal with namespace QNames, name() doesn't cut it :)
declare %private function o:doc-node($item as item(), $rules as map(*))
as item()*
{
    typeswitch($item)
    case document-node() return 
        o:doc-node($item/*, $rules)
    case processing-instruction() return 
        ()
    case comment() return 
        ()
    case attribute() return
        map:entry(name($item), string($item))
    case element() return
        if  (name($item) = 'o:seq') then
            $item/node() ! o:doc-node(., $rules)
        else
            array {
                name($item),
                if ($item/@* or map:contains($rules, name($item))) then
                    map:merge((
                        for $a in $item/@* except $item/@o:path
                        return map:entry(name($a), data($a)),
                        let $path :=
                            if ($item[@o:path])
                            then string($item/@o:path)
                            else name($item)
                        return
                            if (map:contains($rules, $path))
                            then map:entry($o:handler-att, $rules($path))
                            else ()
                    ))
                else 
                    (),
                $item/node() ! o:doc-node(., $rules)
            }
    case array(*) return
        let $tag := o:tag($item)
        let $atts := o:attributes($item)
        let $content := o:content($item)
        return
            array { $tag, $atts, $content ! o:doc-node(., $rules) }
    case text() return
        string($item)
    default return 
        $item
};

(: "Serializing" :)
(:~
 : Converts μ-nodes to XML nodes with the default name resolver.
 :)
declare function o:xml($mu as item()*)
as node()*
{
    o:to-xml($mu, o:qname-resolver(o:ns-map()), map {})
};

(:~
 : Converts μ-nodes to XML nodes using a map of options. Currently it will
 : only use the options 'ns' whose value must be a namespace map and 'default-ns'
 : whose value must be a valide namespace URI.
 :)
declare function o:xml($mu as item()*, $options as map(*))
as node()*
{
    o:to-xml(
        $mu, 
        o:qname-resolver(o:ns-map($options?ns), $options?default-ns), 
        $options
    )
};

declare %private function o:to-xml($mu as item()*, $name-resolver as function(xs:string) as xs:QName, $options as map(*))
as node()*
{
    $mu ! (
        typeswitch (.)
        case array(*) return 
            o:to-element(., $name-resolver, $options)
        case map(*) return  
            o:to-attributes(., $name-resolver)
        case function(*) return 
            ()
        case empty-sequence() return 
            ()
        case node() return 
            .
        default return 
            text { . }
    )
};

declare %private function o:to-element($element as array(*), $name-resolver as function(*), $options)
as item()*
{
    let $tag := o:tag($element)
    let $atts := o:attrs($element)
    let $content := o:content($element)
    where $tag
    return
        element { $name-resolver($tag) } {
            (: namespace μ { 'http://xokomola.com/xquery/origami/mu' }, :)
            namespace o { 'http://xokomola.com/xquery/origami' },
            if ($options?ns instance of map(*)) then
                for $prefix in map:keys($options?ns)
                let $uri := $options?ns($prefix)
                where $prefix != '' and $uri != ''
                return
                    namespace { $prefix } { $uri }
            else
                (),
            o:to-attributes($atts, $name-resolver),
            fold-left($content, (),
                function($n, $i) {
                    ($n, o:to-xml($i, $name-resolver, $options))
                }
            )
        }
};

declare %private function o:to-attributes($atts as map(*), $name-resolver as function(*))
as attribute()*
{
    map:for-each($atts,
        function($k,$v) {
            if ($k = $o:internal-att 
                or namespace-uri-from-QName($name-resolver($k)) 
                = 'http://xokomola.com/xquery/origami') then 
                ()
            else
                (: should not add default ns to attributes if name has no prefix :)
                attribute { if (contains($k,':')) then $name-resolver($k) else $k } {
                    data(
                        typeswitch ($v)
                        case array(*) return 
                            $v
                        case map(*) return 
                            $v
                        case function(*) return 
                            ()
                        default return 
                            $v
                    )
                }
        }
    )
};

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
declare function o:stylesheet($rules as array(*)*)
{
    o:compile-stylesheet(o:compile-rules($rules, map {}), map {})
};

declare function o:stylesheet($rules as array(*)*, $options as map(*))
{
    o:compile-stylesheet(o:compile-rules($rules, $options), $options)
};

declare function o:rules($rules as item()*)
{
    o:compile-rules($rules, map {})
};

declare function o:rules($rules as item()*, $options as map(*))
{
    o:compile-rules($rules, $options)
};

(:~
 : Execute the extractor stylesheet and and attach the node handlers
 : to the correct nodes as defined by the rules.
 :)
declare %private function o:merge-handlers($extractor, $rules, $options)
{
    function($nodes) {
        o:prewalk(
            o:xslt($extractor, $options)($nodes), 
            o:merge-handlers-on-node($rules))
    }
};

(:~
 : Given an extracted element node and adds the matching rules to it.
 : TODO: attach attribute handlers.
 :)
declare %private function o:merge-handlers-on-node($rules)
{
    function($element as array(*)) {
        let $tag := o:tag($element)
        let $attrs := o:attrs($element)
        let $content := o:content($element)
        let $rule := 
            if (map:contains($attrs,'o:id')) then 
                $rules(QName('http://xokomola.com/xquery/origami', $attrs('o:id'))) 
            else
                map {} 
        let $merged-attributes :=
            map:merge((
                map:for-each($attrs,
                    function($k,$v) { if ($k = 'o:id') then () else map:entry($k,$v) }
                ),
                if (map:contains($rule,'handler')) then
                    map:entry($o:handler-att, $rule?handler)
                else
                    ()                
            ))
        return
            array { 
                $tag, 
                if (map:size($merged-attributes) > 0) then 
                    $merged-attributes 
                else 
                    (), 
                $content 
            }
    }
};

(:~
 : 
 : Prepare a map that is used in a transformer to attach the correct
 : handler to the correct mu-node.
 : TODO: Also has prepares the tail of the rule to compose pipelines (?)
 :)
declare %private function o:compile-rules($rules as item()*, $options as map(*))
as map(*)
{
    typeswitch ($rules)
    case array(*)+ return
        let $rules := map:merge($rules ! o:compile-rule(., ()))
        let $extractor := o:compile-stylesheet($rules)
        return o:merge-handlers($extractor, $rules, $options)
    case map(*) return 
        function($nodes) { $nodes ! o:doc-node(., $rules) }
    default return 
        function($nodes) { $nodes ! o:doc-node(., map {}) }
};

(:~
 : Compiles a rule structure into a series of template descriptions which
 : can be compiled into an XSLT stylesheet using o:compile-stylesheet.
 :)
declare %private function o:compile-rule($rule as array(*), $context as xs:string*)
as item()*
{
    let $head := array:head($rule)
    let $hash := o:mode(($context, $head))
    let $mode := o:mode($context)
    let $tail := array:tail($rule)
    let $handler := 
        if (array:size($tail) > 0) then 
            typeswitch(array:head($tail))
            case map(*) return 
                ()
            case array(*) return 
                ()
            case function(*) return 
                array:head($tail)
            default return 
                ()
        else 
            ()
    let $op := 
        if (array:size($tail) = 0 
            or (array:size($tail) > 0 
                and not(array:head($tail) instance of empty-sequence()))) then 
            'copy'
        else 
            'remove'
    let $rules := 
        if (array:size($tail) > 0 
            and array:head($tail) instance of empty-sequence()) then
            array:tail($tail) 
        else 
            $tail
    return (
        map:entry($hash,
            map:merge((
                map:entry('xpath', $head),
                map:entry('context', $context),
                map:entry('mode', $mode),
                map:entry('op', $op),
                if (exists($handler)) then
                    map:entry('handler', $handler)
                else
                    ()
            ))
        ),
        for $rule in $rules?*
        return
            typeswitch ($rule)
            case array(*) return 
                o:compile-rule($rule, ($context,$head))
            case map(*) return 
                ()
            case function(*) return 
                () (: for now :)
            default return 
                ()
    )
};

(:~
 : Generate a QName string unique for the context and suitable for use in XSLT mode attribute.
 :) 

declare %private function o:mode($paths as xs:string*)
as xs:QName {
    QName(
        'http://xokomola.com/xquery/origami',
        concat('_', xs:hexBinary(hash:md5(string-join($paths,' * '))))
    )
};

declare %private function o:compile-stylesheet($rules as map(*))
as element(*)
{
    o:compile-stylesheet($rules, map {})
};

declare %private function o:compile-stylesheet($rules as map(*), $options as map(*))
as element(*)
{
    o:xml(
        ['stylesheet', 
            map:merge((
                map:entry('version', '1.0')
            )),
            ['output', map { 'method': 'xml' }],
            ['template', map { 'match': '/' }, 
                ['o:seq',
                    map:for-each($rules,
                        function($hash, $rule) {
                            if (empty($rule?context)) then
                                ['apply-templates']
                            else
                                ()
                        }
                    )
                ]
            ], 
            ['template', map { 'match': 'text()' }],
            map:for-each($rules,
                function($hash, $rule) {
                    let $xpath := translate($rule?xpath, "&quot;","'")
                    let $context := $rule?context
                    let $mode := $rule?mode
                    let $op := $rule?op
                    return
                        ['template', 
                            map:merge((
                                map:entry('match', $xpath),
                                if (empty($context)) then 
                                    ()
                                else
                                    map:entry('mode', $mode)
                            )),
                            if ($op = 'copy') then
                                ['copy',
                                    ['attribute', map { 'name': 'o:id' }, $hash ],
                                    (: for debugging :)
                                    ['attribute', map { 'name': 'o:path' }, string-join(($context,$xpath),' * ') ],                                    
                                    ['apply-templates', map { 'select': 'node()|@*', 'mode': $hash }]
                                ]
                            else
                                ['apply-templates', map { 'select': 'node()|@*', 'mode': $hash }]
                        ]
                }
            ),
            map:for-each($rules,
                function($mode, $rule) {
                    if ($rule?op = 'remove') then 
                        (
                            ['template', map { 'match': 'text()|processing-instruction()|comment()', 'mode': $mode }],
                            ['template', map { 'priority': -10, 'match': '@*|*', 'mode': $mode },
                                ['apply-templates', map { 'select': '*|@*|text()', 'mode': $mode }]
                            ]
                        )
                    else 
                        (
                            ['template', map { 'match': 'processing-instruction()|comment()', 'mode': $mode }],                
                            ['template', map { 'priority': -10, 'match': '@*|*', 'mode': $mode },
                                ['copy',
                                    ['apply-templates', map { 'select': '*|@*|text()', 'mode': $mode }]
                                ]
                            ]
                        )
                }
            )
        ],
        map { 'ns': $options?ns, 'default-ns': 'http://www.w3.org/1999/XSL/Transform' }
    )
};

declare %private function o:identity-transform()
as array(*)+
{
    ['template', map { 'priority': -10, 'match': '@*|*' },
        ['copy',
            ['apply-templates', map { 'select': '*|@*|text()' }]
        ]
    ],
    ['template', map { 'match': 'processing-instruction()|comment()' }]
};

(:~
 : Converts μ-nodes to JSON with the default name resolver.
 :)
declare function o:json($mu as item()*)
as xs:string
{
    o:json($mu, function($name) { $name })
};

(:~
 : Converts μ-nodes to JSON using a name-resolver.
 :)
declare function o:json($mu as item()*, $name-resolver as function(*))
as xs:string
{
    serialize(
        o:to-json(if (count($mu) > 1) then array { $mu } else $mu, $name-resolver),
        map { 'method': 'json' }
    )
};

declare %private function o:to-json($mu as item()*, $name-resolver as function(*))
as item()*
{
    $mu ! (
        typeswitch (.)
        case array(*) return
            let $tag := o:tag(.)
            let $atts := o:attributes(.)
            let $children := o:content(.)
            return
                map:entry(
                    $tag, 
                    o:to-json(($atts, $children), $name-resolver)
                )
        case map(*) return
            map:merge(
                map:for-each(.,
                    function($a,$b) {
                        map:entry(
                            concat(o:handler-att, $a), 
                            o:to-json($b, $name-resolver)
                        ) 
                    }
                )
            )
        case function(*) return 
            ()
        (: FIXME: I think this should be using to-json as well :)
        case node() return 
            o:doc(.)
        default return 
            .
    )
};

(: μ-node information :)

declare function o:head($element as array(*)?)
as item()*
{
    if (exists($element)) then 
        array:head($element) 
    else
        ()
};

declare function o:tail($element as array(*)?)
as item()*
{
    tail($element?*)
};

declare function o:tag($element as item()?)
as xs:string?
{
    if ($element instance of array(*)) then 
        array:head($element) 
    else 
        () 
};

declare function o:content($element as item()?)
as item()*
{
    if (exists($element)
        and $element instance of array(*)
        and array:size($element) > 0) then
        let $c := array:tail($element)
        return
            if (array:size($c) > 0 and array:head($c) instance of map(*)) then 
                array:tail($c)?*
            else 
                $c?*
    else 
        ()
};

declare function o:attributes($element as array(*)?)
as map(*)?
{
    if (exists($element)
        and array:size($element) > 1 
        and $element?2 instance of map(*)) then 
        $element?2
    else 
        ()
};

(:~
 : Always returns a map even if element has no attributes.
 :
 : Note that for access to attributes in handlers using the lookup operator (?)
 : you can use both o:attrs($e)?foo as well as o:attributes($e)?foo because
 : ()?foo will work just like map{}?foo.
 :)
declare function o:attrs($element as array(*)?)
as map(*)
{
    (o:attributes($element), map {})[1]
};

(:~
 : Returns the size of contents (child nodes not attributes).
 :)
declare function o:size($element as array(*)?)
as item()*
{
    count(o:content($element))
};

(: TODO: in template we should be able to use o:apply with only $ctx (as a node transformer), maybe name it o:apply-rules($args) :)
declare function o:apply($nodes as item()*)
{
    o:apply($nodes, (), [])
};

declare function o:apply($nodes as item()*, $ctx as array(*))
as item()*
{
    o:apply($nodes, (), $ctx)
};

(: TODO: maybe merge $current into $ctx??? :)
declare function o:apply($nodes as item()*, $current as array(*)?, $ctx as array(*))
as item()*
{
    $nodes ! (
        switch (o:is-element-or-handler(.))
        case $o:is-element return 
            o:apply-element(., $ctx)
        case $o:is-handler return 
            o:apply-handler(., $current, $ctx)
        default return 
            .
    )
};

declare function o:apply-rules($ctx as array(*))
{
    o:apply(?, $ctx)
};

declare function o:apply-element($element as array(*), $ctx as array(*))
{
    let $tag := o:tag($element)
    let $handler := o:handler($element)
    let $ctx := o:context($element, $ctx)
    let $atts := o:apply-attributes($element, $ctx)
    let $content := o:content($element)
    return
        if (exists($handler)) then
            o:apply-handler(
                $handler, 
                array { $tag, $atts, $content },
                $ctx
            )
        else
            array { $tag, $atts, 
                o:apply($content, $element, $ctx) 
            }
};

declare function o:apply-attributes($element as array(*), $ctx as item()*)
{
    let $atts :=
        map:merge((
            map:for-each(
                o:attrs($element),
                function($att-name, $att-value) {
                    if ($att-name = $o:internal-att) then 
                        ()
                    else
                        map:entry(
                            $att-name,
                            switch (o:is-element-or-handler($att-value))
                            case $o:is-handler return 
                                o:apply-handler($att-value, $element, $ctx)
                            default return 
                                $att-value
                        )
                }
            )
        ))
    where map:size($atts) > 0
    return $atts
};

declare function o:is-element($node as item()?)
as xs:boolean
{
    typeswitch($node)
    case array(*)
    return true()
    default
    return false()
};

(: returns true if this is an element, false if this is a handler or nil it is neither :)
declare function o:is-element-or-handler($node as item()?)
as xs:boolean? {
    typeswitch ($node)
    case array(*)
    return
        if (array:size($node) = 0) then
            ()
        else
            typeswitch (array:head($node))
            case empty-sequence() return 
                ()
            case xs:string return 
                $o:is-element
            case array(*) return 
                ()
            case map(*) return 
                ()
            case function(*) return 
                $o:is-handler
            default return 
                ()
    case map(*) return 
        ()
    case function(*) return 
        $o:is-handler
    default return 
        ()
};

declare function o:apply-handler($handler as item(), $current as array(*)?, $ctx as array(*))
as item()*
{
    if ($handler instance of array(*)) then
        apply(array:head($handler), array:join(([$current], array:tail($handler), $ctx)))
    else 
        apply($handler, array:join(([$current], $ctx)))
};

(:~
 : Compose functions.
 :)
declare function o:do($fns) {
    function($input) {
        fold-left($fns, $input,
              function($args, $fn) { 
                    $fn($args) 
              }
        ) 
    }
};

(: μ-node transformers :)

declare function o:identity($x) { $x };

declare function o:tree-seq($nodes)
{
    o:tree-seq($nodes, o:is-element#1, o:identity#1)
};

declare function o:tree-seq($nodes, $children as function(*))
{
    o:tree-seq($nodes, o:is-element#1, $children)
};

declare function o:tree-seq($nodes, $is-branch as function(*), $children as function(*))
{
    $nodes ! ( 
        if ($is-branch(.)) then
            $children(.) 
        else
            .,
        o:tree-seq(o:content(.), $is-branch, $children)
    )
};

declare function o:map($nodes as item()*, $fn as function(item()) as item()*)
{
    for-each($nodes, $fn)
};

declare function o:map($fn as function(item()) as item()*)
{
    for-each(?, $fn)
};

declare function o:filter($nodes as item()*, $fn as function(item()) as xs:boolean)
{
    filter($nodes, $fn)   
};

declare function o:filter($fn as function(item()) as xs:boolean)
{
    filter(?, $fn)
};

declare function o:sort($input as item()*, $key as function(item()) as xs:anyAtomicType*)
as item()*
{
    sort($input, $key)   
};

declare function o:sort($key as function(item()) as xs:anyAtomicType*)
as item()*
{
    sort(?, $key)
};

(:~
 : Returns a sequence even if the argument is an array.
 :)
declare function o:seq($nodes as item()*)
{
    $nodes ! (
        if (. instance of array(*)) then
            .?*
        else if (. instance of map(*)) then
            map:for-each(., function($k,$v) { ($k,$v) })
        else 
            .
    )
};

(:~
 : Generic walker function (depth-first).
 :)
declare function o:postwalk($form as item()*, $fn as function(*))
{
    $form ! (
        typeswitch (.)
        case array(*) return
            $fn(array {
                for $item in $form?*
                return o:postwalk($item, $fn)
            })
        default return 
            $form
    )
};

(:~
 : Generic walker function (breadth-first).
 :)
declare function o:prewalk($form as item()*, $fn as function(*))
{
    $form ! (
        let $walked := $fn(.)
        return
            typeswitch ($walked)
            case array(*) return
                array {
                    for $item in $walked?*
                    return
                        if ($item instance of array(*)) then
                            o:prewalk($item, $fn)
                        else 
                            $item
                }
            default return 
                $walked
    )
};

declare function o:has-handler($element as array(*))
as xs:boolean
{
    map:contains(o:attrs($element), $o:handler-att)
};

declare function o:handler($element as array(*))
{
    o:attrs($element)($o:handler-att)
};

declare function o:set-handler($handler as array(*)?)
as function(*)
{
    function($element as array(*)) {
        array {
            o:tag($element),
            map:merge((o:attrs($element), map { $o:handler-att: $handler })),
            o:content($element)
        }
    }
};

declare function o:context($element as array(*)?)
{
    o:context($element, [])
};

(:~
 : Make a new context. Replacing head of $ctx with $element.
 :)
declare function o:context($element as array(*)?, $ctx as array(*))
{
    let $arg-handler := o:attrs($element)($o:data-att)
    return
        typeswitch ($arg-handler)
        case empty-sequence() return 
            $ctx
        case array(*) return 
            $arg-handler
        case map(*) return 
            [$arg-handler]
        case function(*) return 
            [apply($arg-handler, array:join(([$element], $ctx)))] 
        default return 
            [$arg-handler]
};

declare function o:set-data($element as array(*), $data as item()*)
as function(*)
{
    o:set-data($data)($element)
};

declare function o:set-data($data as item()*)
as function(*)
{
    function($element as array(*)) {
        array {
            o:tag($element),
            map:merge((o:attrs($element), map { $o:data-att: $data })),
            o:content($element)
        }
    }
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function o:set-handler($element as array(*), $handler as array(*)?)
as array(*)
{
    o:set-handler($handler)($element)
};

(:~
 : Repeat the incoming nodes and feed them through the functions.
 :)
declare function o:repeat($nodes as item()*, $repeat-seq as item()*, $fn as function(*))
{
    o:repeat($repeat-seq, $fn)($nodes)
};

declare function o:repeat($repeat-seq as item()*, $fn as function(*))
{
    let $arity := function-arity($fn)
    return
        function($nodes as item()*) {
            fold-left(
                $repeat-seq,
                (),
                function($n,$i) {
                    if ($arity = 2) then
                        ($n, $fn($nodes,$i))
                    else
                        (: assume the default arity = 1, otherwise let it crash :)
                        ($n, $fn($nodes))
                }
            )
        }
};

(:~
 : Selector:
 :
 : - function($node) => int*|key*
 : - int*
 : - key*
 : 
 : Choices:
 :
 : - array: selector => int
 : - map: selector => 
 : - function(int*|key*) => fn(nodes)
 :)
declare function o:choose($selector as item()*, $choices as function(*))
as item()*
{
    let $selector :=
        typeswitch($selector)
        case function(item()*) as item()* return 
            $selector
        case xs:integer* | xs:string* return 
            function($nodes as item()*) {
                $selector
            }
        default return
            (: TODO: raise error? :)
            ()
    return        
        function($nodes as item()*) {
            $nodes ! (
                let $node := .
                return
                    $selector($nodes) ! (
                        typeswitch($choices(.))
                        case $choice as array(*) | map(*) return
                            $choice
                        case $choice as function(*) return
                            $choice($node)
                        default $choice return
                            $choice
                    )
            )
        }
};

declare function o:choose($nodes as item()*, $selector as item()*, $choices as function(*))
as item()*
{
    o:choose($selector, $choices)($nodes)
};

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function o:insert($content as item()*)
as function(*)
{
    function($mu as array(*)) {
        array { o:tag($mu), o:attributes($mu), $content }
    }
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function o:insert($context as item()*, $content as item()*)
as item()*
{
    o:insert($content)($context)
};

declare function o:replace()
as function(*) {
    function($context as item()*) {
        ()
    }
};

declare function o:replace($content as item()*)
as function(*) {
    function($context as item()*) {
        $content
    }
};

declare function o:replace($context as item()*, $content as item()*)
as item()*
{
    o:replace($content)($context)
};

declare function o:wrap($mu as array(*)?)
as function(*)
{
    if (exists($mu)) then
        function($content as item()*) {
            array { o:tag($mu), o:attributes($mu), $content }
        }
    else
        function($content as item()*) {
            $content
        }
};

declare function o:wrap($content as item()*, $mu as array(*)?)
as item()*
{
    o:wrap($mu)($content)
};

(:~
 : Create a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :)
declare function o:unwrap()
as function(item()*) as item()*
{
    function($content as item()*) {
        $content ! (
            typeswitch(.)
            case array(*) return 
                o:content(.)
            default return 
                .
        )
    }
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function o:unwrap($content as item()*)
as item()*
{
    o:unwrap()($content)
};

(:~
 : Copy nodes without any transformation.
 :)
declare function o:copy()
as function(item()*) as item()*
{
    function($content as item()*) {
        $content
    }
};

declare function o:copy($content as item()*)
as item()*
{
    o:copy()($content)
};

(:~
 : Create a node transformer that inserts `$before` before
 : the nodes passed in.
 :)
declare function o:before($before as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($before, $nodes)
    }
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function o:before($nodes as item()*, $before as item()*)
as item()*
{
    o:before($before)($nodes)
};

(:~
 : Create a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function o:after($after as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($nodes, $after)
    }
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function o:after($nodes as item()*, $after as item()*)
as item()*
{
    o:after($after)($nodes)
};

(:~
 : Create a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function o:insert-after($append as item()*)
as function(item()*) as item()*
{
   function($mu as array(*)) {
        array { o:tag($mu), o:attributes($mu), o:content($mu), $append }
    }
};

(:~
 : Inserts `$append` nodes to the child nodes of each element in
 : `$nodes`.
 :)
declare function o:insert-after($nodes as item()*, $append as item()*)
as item()*
{
    o:insert-after($append)($nodes)
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function o:insert-before($prepend as item()*)
as function(item()*) as item()*
{
   function($mu as array(*)) {
        array { o:tag($mu), o:attributes($mu), $prepend, o:content($mu) }
    }
};

(:~
 : Inserts `$prepend` nodes before the first child node of each element
 : in `$nodes`.
 :)
declare function o:insert-before($nodes as item()*, $prepend as item()*)
as item()*
{
    o:insert-before($prepend)($nodes)
};

(:~
 : Outputs the text value of `$nodes`.
 :)
declare function o:text()
as function(item()*) as item()*
{
    function($nodes as item()*) as xs:string* {
        $nodes ! (
            typeswitch (.)
            case map(*) return 
                ()
            case array(*) return 
                o:text(o:content(.))
            case function(*) return 
                ()
            default return 
                string(.)
        )
    }
};

(:~
 : Outputs the text value of `$nodes`.
 :)
declare function o:text($nodes as item()*)
as item()*
{
    o:text()($nodes)
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function o:ntext()
as function(item()*) as item()*
{
    function($nodes as item()*) as xs:string* {
        normalize-space(string-join(
            $nodes ! (
                typeswitch (.)
                case map(*) return 
                    ()
                case array(*) return 
                    o:ntext(o:content(.))
                case function(*) return 
                    ()
                default return 
                    string(.)
            )
        ,''))
    }
};

declare function o:ntext($nodes as item()*)
as item()*
{
    o:ntext()($nodes)
};

(:~
 : Create a node transformer that sets attributes using a map
 : on each element in the nodes passed.
 :)
declare function o:set-attr($attributes as map(*))
as function(item()*) as item()*
{
    function($node as array(*)) {
        array {
            o:tag($node),
            map:merge((o:attributes($node), $attributes)),
            o:content($node)
        }
    }
};

(:~
 : Set attributes using a map on each element in `$nodes`.
 :)
declare function o:set-attr($nodes as item()*, $attributes as map(*))
as item()*
{
    o:set-attr($attributes)($nodes)
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :)
declare function o:remove-attr($remove-atts as xs:string*)
as function(item()*) as item()*
{
    function($element as array(*)) {
        let $atts :=
            map:merge((
                map:for-each(o:attrs($element),
                    function($k,$v) {
                        if ($k = $remove-atts) then 
                            () 
                        else 
                            map:entry($k,$v)
                    }
                )
            ))
        return
            array {
                o:tag($element),
                if (map:size($atts) = 0) then 
                    () 
                else 
                    $atts,
                o:content($element)
            }
    }
};

(:~
 : Remove attributes from each element in `$nodes`.
 :)
declare function o:remove-attr($element as array(*), $names as item()*)
as item()*
{
    o:remove-attr($names)($element)
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function o:add-class($names as xs:string*)
as function(item()*) as item()*
{
    function($element as array(*)) {
        let $atts := o:attrs($element)
        return
            array {
                o:tag($element),
                map:merge((
                    $atts,
                    map:entry('class',
                        string-join(
                            distinct-values(
                                tokenize(
                                    string-join(($atts?class,$names),' '), '\s+')), ' ')
                    )
                )),
                o:content($element)
            }
    }
};

(:~
 : Add one or more `$names` to the class attribute of `$element`.
 : If it doesn't exist it is added.
 :)
declare function o:add-class($element as array(*), $names as xs:string*)
as item()*
{
    o:add-class($names)($element)
};

(:~
 : Create a node transformer that removes one or more `$names` from the
 : class attribute. If the class attribute is empty after removing names it will
 : be removed from the element.
 :)

declare function o:remove-class($names as xs:string*)
as function(item()*) as item()*
{
   function($element as array(*)) {
        let $atts := o:attrs($element)
        let $classes := tokenize($atts?class,'\s+')
        let $new-classes :=
            for $class in $classes
            where not($class = $names)
            return $class
        let $new-atts :=
            if (count($new-classes) = 0) then
                map:remove($atts,'class')
            else
                map:merge((
                    $atts,
                    map:entry('class', string-join($new-classes, ' '))
                ))
        return
            array {
                o:tag($element),
                if (map:size($new-atts) = 0) then 
                    () 
                else 
                    $new-atts,
                o:content($element)
            }
    }
};

(:~
 : Remove one or more `$names` from the class attribute of `$element`.
 : If the class attribute is empty after removing names it will be removed
 : from the element.
 :)
declare function o:remove-class($element as array(*), $names as xs:string*)
as item()*
{
    o:remove-class($names)($element)
};

(:~
 : Create a node-transformer that renames element nodes, passing non-element
 : nodes and element child nodes through unmodified.
 :
 : Renaming can be done using a:
 :
 : - `xs:string`: renames all elements
 : - `map(*)`: looks up the element name in the map and uses the value as the
 :   new name
 :)
declare function o:rename($name as item())
as function(item()*) as item()*
{
    function($node as array(*)) {
        let $new-name :=
            if ($name instance of map(*)) then
                $name(o:tag($node)) 
            else 
                $name
        return
            if ($new-name) then
                array {
                    $new-name,
                    o:attributes($node),
                    o:content($node)
                }
            else
                $node
    }
};

(:~
 : Renames elements in `$nodes`.
 :)
declare function o:rename($nodes as item()*, $name as item())
as item()*
{
    o:rename($name)($nodes)
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 :)
declare function o:xslt($stylesheet as item()*)
as function(*)
{
    o:xslt($stylesheet, map {})
};

declare function o:xslt($stylesheet as item()*, $params as map(*))
as function(*)
{
    function($nodes as item()*) as item()* {
        if (exists($nodes) and exists($stylesheet)) then
            o:doc(
                for $node in $nodes
                return
                    try {
                        xslt:transform(
                            o:xml($nodes),
                            $stylesheet,
                            $params
                        )
                    } catch bxerr:BXSL0001 {
                        error(xs:QName('o:xslt'), 
                            'Error [' || $err:code || ']: ' 
                            || $err:description 
                            || '&#xa;'
                            || serialize($stylesheet)) 
                    }
            )
        else
            ()
    }
};

(:~
 : Transform nodes using XSLT stylesheet.
 :)
declare function o:xslt($nodes as item()*, $stylesheet as item()*, $params as map(*))
as function(*)
{
    o:xslt($stylesheet, $params)($nodes)
};

(: Namespace support :)
(:~
 : Returns a name resolver function with the HTML namespace as default.
 :)
declare function o:html-resolver()
as function(xs:string) as xs:QName
{
    o:qname(?, o:ns-map(), 'http://www.w3.org/1999/xhtml')
};

(:~
 : Returns a name resolver function from the default namespace map (nsmap.xml).
 :)
declare function o:qname-resolver()
as function(xs:string) as xs:QName
{
    o:qname(?, $o:ns, ())
};

(:~
 : Returns a name resolver function from the namespace map passed as it's argument.
 :)
declare function o:qname-resolver($ns-map as map(*))
as function(xs:string) as xs:QName
{
    o:qname(?, $ns-map, ())
};

(:~
 : Returns a name resolver function from the namespace map passed as it's first
 : argument and using the second argument as the default namespace.
 :)
declare function o:qname-resolver($ns-map as map(*), $default-ns as xs:string?)
as function(xs:string) as xs:QName
{
    o:qname(?, $ns-map, $default-ns)
};

(:~
 : Get a namespace map from XML nodes. Note that this assumes somewhat sane[1]
 : namespace usage. The resulting map will contain a prefix/URI entry for each
 : used prefix but it will not re-bind a prefix to a different URI at
 : descendant nodes. Unused prefixes are dropped.
 : The result can be used when serializing back to XML but results may be not
 : what you expect if you pass insane XML fragments.
 :
 : [1] http://lists.xml.org/archives/xml-dev/200204/msg00170.html
 :)
declare function o:ns-map-from-nodes($nodes as node()*)
as map(*)
{
    map:merge((
        for $node in reverse($nodes/descendant-or-self::*)
        let $qname := node-name($node)
        return (
            for $att in $node/@*
            let $qname := node-name($att)
            return
                map:entry((prefix-from-QName($qname),'')[1], namespace-uri-from-QName($qname)),
            map:entry((prefix-from-QName($qname),'')[1], namespace-uri-from-QName($qname))
        )
    ))
};

(:~
 : Returns a QName in "no namespace".
 : Throws a dynamic error FOCA0002 with a prefixed name.
 :)
declare function o:qname($name as xs:string)
as xs:QName
{
    QName((), $name)
};

(:~
 : Returns a QName from a string taking the namespace URI from the
 : namespace map passed as it's second argument.
 : Throws a dynamic error FOCA0002 with a name which is not in correct lexical form.
 : Returns a QName in a made-up namespace URI if the prefix is not defined in the
 : namespace map.
 :)
declare function o:qname($name as xs:string, $ns-map as map(*))
as xs:QName
{
    o:qname($name, $ns-map, ())
};

(:~
 : Same as o:qname#2 but uses a third argument to specify a default namespace URI.
 :)
declare function o:qname($name as xs:string, $ns-map as map(*), $default-ns as xs:string?)
as xs:QName
{
    if (contains($name, ':'))
    then
        let $prefix := substring-before($name,':')
        let $local := substring-after($name, ':')
        let $ns := ($ns-map($prefix), concat('ns:prefix:', $prefix))[1]
        return
            if ($ns = $default-ns) then
                QName($ns, $local)
            else
                QName($ns, concat($prefix, ':', $local))
    else
        if ($default-ns) then
            QName($default-ns, $name)
        else 
            QName((), $name)
};

(:~
 : Builds a namespace map from the default namespace map provided in the
 : XML file nsmap.xml.
 :)
declare function o:ns-map()
as map(*)
{
    o:ns-map(())
};

(:~
 : Builds a namespace map from the default namespace map provided in the
 : XML file nsmap.xml and adding extra namespace mappings from a map provided
 : as the argument. The latter mappings will override existing mappings in the
 : default namespace map.
 :)
declare function o:ns-map($ns-map as map(*)?)
as map(*)
{
    map:merge((
        ($ns-map, map {})[1],
        for $ns in doc(concat(file:base-dir(),'/nsmap.xml'))/nsmap/*
        return
            map:entry(string($ns/@prefix), string($ns/@uri))
    ))
};
