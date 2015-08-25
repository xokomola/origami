xquery version "3.1";

module namespace μ = 'http://xokomola.com/xquery/origami/mu';

import module namespace u = 'http://xokomola.com/xquery/origami/utils' at 'utils.xqm'; 

declare %private variable $μ:ns := 'http://xokomola.com/xquery/origami/mu';

(: TODO: combine template and snippet :)
(:~ 
 : Origami μ-documents
 :)

(: Reading from external entities :)

declare function μ:read-xml($uri as xs:string?)
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
declare function μ:read-xml($uri as xs:string?, $options as map(xs:string, item()))
as document-node()?
{
    if (empty($uri))
    then ()
    else fetch:xml($uri, u:select-keys($options, $μ:xml-options))
};

declare %private variable $μ:xml-options :=
    ('chop', 'stripns', 'intparse', 'dtd', 'xinclude', 'catfile', 'skipcorrupt');

(:~
 : Read and parse HTML with the Tagsoup parser (although this could be changed).
 : If Tagsoup is not available it will fallback to parsing well-formed XML.
 :
 : For options see: http://docs.basex.org/wiki/Parsers#TagSoup_Options
 :)
declare function  μ:read-html($uri as xs:string?)
as document-node()?
{
    μ:read-html($uri, map { 'lines': false() })   
};

declare function μ:read-html($uri as xs:string?, $options as map(xs:string, item()))
as document-node()?
{
    μ:parse-html(μ:read-text($uri, map:merge(($options, map { 'lines': false() }))), $options)
};

(:~
 : Note that binary or strings can be passed to html:parse, in which case encoding 
 : can be used to override automatic detection.
 : We can also just pass in a seq of strings.
 :)
declare function μ:parse-html($text as xs:string*)
as document-node()?
{
    html:parse(string-join($text, ''))
};

declare function μ:parse-html($text as xs:string*, $options as map(xs:string, item()))
as document-node()?
{
    html:parse(string-join($text, ''), u:select-keys($options, $μ:html-options))
};

(:~
 : TagSoup options not supported by BaseX: 
 : files, method, version, standalone, pyx, pyxin, output-encoding, reuse, help
 : Note that encoding is not passed as text read with $μ:read-text or provided
 : already is in Unicode. 
 :)
declare %private variable $μ:html-options :=
    ('html', 'omit-xml-declaration', 'doctype-system', 'doctype-public', 'nons', 
     'nobogons', 'nodefaults', 'nocolons', 'norestart', 'ignorable', 'empty-bogons', 'any',
     'norootbogons', 'lexical', 'nocdata');

(:~
 : Options:
 :
 : - lines: true() or false()
 : - encoding
 :)
declare function μ:read-text($uri as xs:string?)
as xs:string*
{
    μ:read-text($uri, map { })
};

declare function μ:read-text($uri as xs:string?, $options as map(xs:string, item()))
as xs:string*
{
    (: @see https://github.com/BaseXdb/basex/issues/1181 error when $uri = () :)
    if (empty($uri)) 
    then ()
    else
        let $parse-into-lines := ($options?lines, true())[1]
        let $encoding := $options?encoding
        return
            if ($parse-into-lines)
            then if ($encoding) then unparsed-text-lines($uri, $encoding) else unparsed-text-lines($uri) 
            else if ($encoding) then unparsed-text($uri, $encoding) else unparsed-text($uri)
};

declare function μ:read-json($uri as xs:string?)
as item()?
{
    μ:read-json($uri, map {})
};

declare function μ:read-json($uri as xs:string?, $options as map(xs:string, item()))
as item()?
{
    json-doc($uri, u:select-keys($options, $μ:xml-options))
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
declare function μ:parse-json($text as xs:string*)
as item()?
{
    parse-json(string-join($text,''))
};

declare function μ:parse-json($text as xs:string*, $options as map(xs:string, item()))
as item()?
{
    parse-json(string-join($text,''), $options?($μ:json-options))
};

declare %private variable $μ:json-options :=
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
declare function μ:read-csv($uri as xs:string?)
as array(*)*
{
    μ:read-csv($uri, map {})
};

declare function μ:read-csv($uri as xs:string?, $options as map(xs:string, item()))
as array(*)*
{
    μ:parse-csv(μ:read-text($uri, map:merge(($options, map { 'lines': false() }))), $options)
};

declare function μ:parse-csv($text as xs:string*)
as array(*)*
{
    μ:parse-csv($text, map {})
};

declare function μ:parse-csv($text as xs:string*, $options as map(xs:string, item()))
as array(*)*
{
    let $parse-options := map:merge((u:select-keys($options, $μ:csv-options), map { 'format': 'map' }))
    return
        μ:csv-normal-form(csv:parse(string-join($text,'&#10;'), $parse-options))
};

(: ignore format option (only supported normalized form), header is dealt with in μ:csv-object :)
declare %private variable $μ:csv-options :=
    ('separator', 'lax', 'quotes', 'backslashes');

(:~
 : BaseX csv:parse returns a map with keys, this turns it into
 : a sequence of arrays (each array corresponds with a row)
 :)
declare %private function μ:csv-normal-form($csv)
{
    for $i in map:keys($csv)
    return
        array { $csv($i) }
};

(: Parsing into μ nodes :)

(:~
 : The main function for converting sequence of items that are not yet
 : μ nodes into the proper format.
 : Arrays and maps will be written into explicit nodes.
 : In most cases however constructing μ nodes is done manually as this
 : is just a data-structure.
 : This function is most useful for converting XML nodes to μ nodes.
 :
 : Note that this may return a fragment only.
 :)
declare function μ:node($item as item())
{
    μ:node($item, map {})
};

declare function μ:node($item as item(), $rules as map(*))
as item()?
{
    typeswitch($item)
    
    case document-node()
    return μ:node($item/*, $rules)
    
    case element()
    return
        array { 
            name($item), 
            if ($item/@*) 
            then 
                map:merge((
                    for $a in $item/@* except $item/@μ:node
                    return map:entry(name($a), data($a)),
                    if ($item/@μ:node and map:contains($rules, string($item/@μ:node)))
                    then map:entry('μ:handler', $rules(string($item/@μ:node)))
                    else ()
                ))
            else (),
            $item/node() ! μ:node(., $rules)
        }

    case text() 
    return string($item)
    
    case xs:anyAtomicType
    return $item
    
    case array(*)
    return
        if (μ:tag($item) eq 'μ:object')
        then
            $item
        else
            array {
                'μ:array',
                $item?* ! μ:node(., $rules)
            }
            
    case map(*)
    return
        array {
            'μ:map',
            for $k in map:keys($item)
            return
                [$k, $item($k) ! μ:node(., $rules)]
        }
        
    default
    return ()
};

(:~
 : Convenience function to convert a seq of items.
 :)
declare function μ:nodes($items as item()*)
as item()*
{
    $items ! μ:node(.)
};

(:~
 : Get the nested objects inside the datastructure.
 :)
declare function μ:objects($mu as item()?)
{
    let $inner := function($el) {
        if (μ:tag($el) = 'μ:object')
        then $el
        else
            for $item in μ:content($el)
            where $item instance of array(*)
            return μ:objects($item)
    }
    let $outer := function($seq) { $seq }
    return
        u:walk($inner, $outer, $mu)
};

declare %private function μ:typed-object($type as xs:string, $content as item()*, $attributes as map(xs:string, item()))
as array(*)?
{
    let $attributes := map:merge(($attributes, map:entry('μ:type', $type)))
    where count($content) gt 0
    return
        ['μ:object', $attributes, $content]
};

declare function μ:json-object($json-xdm as item()?)
as array(*)?
{
    μ:json-object($json-xdm, map {})
};

declare function μ:json-object($json-xdm as item()?, $attributes as map(xs:string, item()))
as array(*)?
{
    μ:typed-object('json', $json-xdm, $attributes)
};

declare function μ:csv-object($csv-xdm as array(*)*)
as array(*)?
{
    μ:csv-object($csv-xdm, map {})
};

declare function μ:csv-object($csv-xdm as array(*)*, $attributes as map(xs:string, item()))
as array(*)?
{
    μ:typed-object('csv', $csv-xdm, $attributes)
};

declare function μ:text-object($text as xs:string*)
as array(*)?
{
    μ:text-object($text, map {})
};

declare function μ:text-object($text as xs:string*, $attributes as map(xs:string, item()))
as array(*)?
{
    
    μ:typed-object('text', $text, $attributes)
};

(: Object to XML transformers: provides default rendering of basic objects. :)
(: TODO: merge this with μ:doc :) 
declare function μ:object-doc($object as array(*))
{
    switch (μ:attributes($object)?('μ:type'))
    
    case 'text'
    return
        for $line in μ:content($object)
        return
            ['p', $line]
            
    case 'csv'
    return
        ['table',
            for $row in μ:content($object)
            return
                ['tr',
                    for $cell in $row?*
                    return
                        ['td', $cell]
                ]
        ]
        
    case 'json'
    return 'JSON'
    
    default
    return $object
};

(: Serializing :)

declare function μ:xml($mu as item()*)
as node()*
{
    μ:to-xml($mu, map {})
};

declare function μ:xml($mu as item()*, $options as map(*)) 
as node()*
{
    μ:to-xml($mu, $options)
};

declare function μ:json($mu as item()*)
as xs:string
{
    μ:json($mu, function($name) { $name })
};

declare function μ:json($mu as item()*, $name-resolver as function(*)) 
as xs:string
{
    serialize(
        μ:to-json(if (count($mu) gt 1) then array { $mu } else $mu, $name-resolver), 
        map { 'method': 'json' }
    )
};

(: General :)

(: TODO: prefix attribute names with @?, plus general improvement :)
declare %private function μ:to-json($mu as item()*, $name-resolver as function(*))
as item()*
{
    for $item in $mu
    return
        typeswitch ($item)
        
        case array(*)
        return
            let $tag := μ:tag($item)
            let $atts := μ:attributes($item)
            let $children := μ:content($item)
            return
                switch ($tag)
                
                case 'μ:json'
                return μ:to-json(($atts,$children), $name-resolver)
                
                case 'μ:array'
                return array { μ:to-json($children, $name-resolver) }
                
                case 'μ:obj'
                return map:merge(
                    for $child in $children
                    return μ:to-json($children, $name-resolver)
                )
                
                default
                return map:entry($tag, μ:to-json(($atts, $children), $name-resolver))
                
        case map(*)
        return 
            map:merge(
                map:for-each($item, 
                    function($a,$b) { 
                        map:entry(concat('@',$a), μ:to-json($b, $name-resolver)) }))
                        
        case function(*) return ()
        
        (: FIXME: I think this should be using to-json as well :)
        case node() 
        return μ:nodes($item)
        
        default 
        return $item
};

(: TODO: namespace handling, especially to-attributes :)
declare %private function μ:to-xml($mu as item()*, $options as map(*))
as node()*
{
    let $ns-map := μ:ns()
    let $name-resolver := μ:qname-resolver($ns-map, $ns-map?xsl)
    for $item in $mu
    return
        typeswitch ($item)
        
        case array(*) 
        return 
            if (μ:tag($item) = 'μ:object')
            then μ:to-xml((μ:attributes($item)?xml, μ:object-doc(?))[1]($item), $name-resolver)
            else μ:to-element($item, $name-resolver)
        
        case map(*) 
        return  μ:to-attributes($item, $name-resolver)
        
        case function(*) 
        return ()
        
        case empty-sequence() 
        return ()
        
        case node() 
        return $item
        
        default 
        return text { $item }
};

(: TODO: need more common map manipulation functions :)
(: TODO: change ns handling to using a map to construct them at the top (sane namespaces) :)
declare %private function μ:to-element($mu as array(*), $name-resolver as function(*))
as item()*
{
    let $tag := μ:tag($mu)
    let $atts := μ:attributes($mu)
    let $ns-atts := map:merge((map:for-each($atts, function($k, $v) { if (starts-with($k, 'xmlns:')) then map:entry($k, $v) else () })))
    let $atts := map:merge((map:for-each($atts, function($k, $v) { if (starts-with($k, 'xmlns:')) then () else map:entry($k, $v) })))
    let $content := μ:content($mu)
    where $tag
    return
        element { $name-resolver($tag) } {
            namespace μ { $μ:ns },
            μ:to-attributes($atts, $name-resolver),
            fold-left($content, (),
                function($n, $i) {
                    ($n, μ:to-xml($i, $name-resolver))
                }
            )
        }
};

(: NOTE: another reason why we should avoid names with :, conversion to json is easier? Maybe also makes JSON-LD easier :)
declare %private function μ:to-attributes($mu as map(*)?, $name-resolver as function(*))
as attribute()*
{
    map:for-each($mu, 
        function($k,$v) {
            (: should not add default ns to attributes if name has no prefix :)
            attribute { if (contains($k,':')) then $name-resolver($k) else $k } { 
                data(
                    typeswitch ($v)
                    case array(*) return $v
                    case map(*) return $v
                    case function(*) return ()
                    default return $v
                )
            }
        })
};

declare function μ:html-resolver()
as function(xs:string) as xs:QName
{
    μ:qname(?, μ:ns(), 'http://www.w3.org/1999/xhtml')
};

declare function μ:qname-resolver()
as function(xs:string) as xs:QName
{
    μ:qname(?, μ:ns(), ())
};

declare function μ:qname-resolver($ns-map as map(*))
as function(xs:string) as xs:QName
{
    μ:qname(?, $ns-map, ())
};

declare function μ:qname-resolver($ns-map as map(*), $default-ns as xs:string)
as function(xs:string) as xs:QName
{
    μ:qname(?, $ns-map, $default-ns)
};

(:~
 : As XQuery doesn't allow access to namespace nodes (as XSLT does)
 : construct them indirectly via QName#2.
 :)

declare function μ:qname($name as xs:string)
as xs:QName
{
    QName((), $name)
};

declare function μ:qname($name as xs:string, $ns-map as map(*))
as xs:QName
{
    μ:qname($name, $ns-map, ())
};

declare function μ:qname($name as xs:string, $ns-map as map(*), $default-ns as xs:string?)
as xs:QName
{
    if (contains($name, ':')) 
    then
        let $prefix := substring-before($name,':')
        let $local := substring-after($name, ':')
        let $ns := $ns-map($prefix)
        return
            if ($ns = $default-ns) 
            then QName($ns, $local)
            else QName($ns, concat($prefix, ':', $local))
    else
        if ($default-ns) 
        then QName($default-ns, $name)
        else QName((), $name)
};

declare function μ:ns()
as map(*)
{
    μ:ns(map {})
};

declare function μ:ns($ns-map as map(*))
as map(*)
{
    map:merge((
        $ns-map,
        for $ns in doc(concat(file:base-dir(),'/nsmap.xml'))/nsmap/*
        return
            map:entry(string($ns/@prefix), string($ns/@uri))
    ))
};

declare function μ:mix($mu as array(*)?) 
as array(*)?
{
    if (empty($mu)) 
    then ()
    else [(), $mu]
};

declare function μ:head($mu as array(*)?)
as item()*
{
    if (empty($mu)) 
    then ()
    else array:head($mu)
};

declare function μ:tail($mu as array(*)?)
as item()*
{
    tail($mu?*)
};

declare function μ:tag($mu as array(*)?)
as xs:string?
{
    if (empty($mu)) 
    then ()
    else array:head($mu)
};

declare function μ:content($mu as array(*)?)
as item()*
{
    if (array:size($mu) > 0) then
        let $c := array:tail($mu)
        return
            if (array:size($c) > 0 and array:head($c) instance of map(*)) 
            then array:tail($c)?*
            else $c?*
    else
        ()
};

declare function μ:attributes($mu as array(*)?)
as map(*)?
{
    if (array:size($mu) gt 1 and $mu(2) instance of map(*)) 
    then $mu(2) 
    else map {}
};

(:~
 : Returns the size of contents (child nodes not attributes).
 :)
declare function μ:size($mu as array(*)?)
as item()*
{
    count(μ:content($mu))
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
(: TODO: can't we simplify on always having an on array arg function as context corresp. to apply :)

declare function μ:template($template as item(), $rules as array(*)+)
as function(*)
{
    let $compiled-rules := μ:compile-rules($rules)  
    let $compiled-template := μ:compile-template($template, $compiled-rules)
    return
        function($args) { μ:apply($compiled-template, $args) }
};

(:~
 : Create a template snippet using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function μ:snippet($template as item(), $rules as array(*)+)
as function(*)
{
    let $compiled-rules := μ:compile-rules($rules)  
    let $compiled-template := μ:compile-snippet($template, $compiled-rules)
    return
        function($args) { μ:apply($compiled-template, $args) }
};


(: TODO: ['p', fn1#2, fn2#2, fn3#2] compose a node transformer/pipeline :)
declare function μ:compile-rules($rules as array(*)+)
as map(*)
{
    map:merge((
        for $rule in $rules
        let $selector := array:head($rule)
        let $handler := $rule(2)
        return
            map:entry($selector, $handler)
    ))
};

declare function μ:compile-template($template as item(), $rules as map(*))
as array(*)?
{
    μ:node(xslt:transform(μ:xml($template), μ:compile-transformer($rules, map { 'extract': false() })), $rules)
};

declare function μ:compile-snippet($template as item(), $rules as map(*))
as array(*)*
{
    μ:content(μ:node(xslt:transform(μ:xml($template), μ:compile-transformer($rules, map { 'extract': true() })), $rules))
};

(: TODO: if I do ns handling differently we could write without the xls: prefix :)
declare function μ:compile-transformer($rules as map(*)?, $options as map(*))
as element(*)
{
    μ:xml(
        ['stylesheet', map { 'version': '1.0' },
            ['output', map { 'method': 'xml' }],
            if ($options?extract) 
            then (
                ['template', map { 'match': '/' }, ['μ:seq', ['apply-templates']]],
                ['template', map { 'match': 'text()' }]
            )
            else 
                μ:identity-transform(),
            for $selector in map:keys($rules)
            return
                ['template', map { 'match': $selector },
                    ['copy',
                        ['copy-of', map { 'select': '@*' }],
                        ['attribute', map { 'name': 'μ:node' }, $selector],
                        ['apply-templates', map { 'select': 'node()' }]
                    ]
                ]
        ]
    )
};

declare function μ:identity-transform()
as array(*)+
{
    ['template', map { 'priority': -10, 'match': '@*|*' },
        ['copy',
            ['apply-templates', map { 'select': '*|@*|text()' }]
        ]
    ],
    ['template', map { 'match': 'processing-instruction()|comment()' }]
};

declare function μ:apply($nodes as item()*, $args as item()*)
as item()*
{  
    for $node in $nodes
    return
        typeswitch($node)
        case array(*)
        return
            let $tag := μ:tag($node)
            let $atts := μ:attributes($node)
            let $has-handler := map:contains($atts, 'μ:handler')
            let $handler := $atts('μ:handler')
            let $content := μ:content($node)
            let $atts := u:filter-keys($atts,'μ:handler')
            return
                typeswitch ($handler)
                case empty-sequence() 
                return
                    (: This can mean that the handler is (), or that there is no handler :)
                    if ($has-handler)
                    then
                        ()
                    else
                        array { 
                            $tag, 
                            if (map:size($atts) gt 0) then $atts else (), 
                            μ:apply($content, $args) 
                        }
                case array(*) return $handler
                case map(*) return $handler
                case function(*)
                return 
                    μ:apply(
                        $handler(
                            array { 
                                $tag, 
                                if (map:size($atts) gt 0) then $atts else (), 
                                $content 
                            }, 
                            $args
                        ), $args)
                default return $handler
        default
        return $node
};

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function μ:insert($content as item()*)
as function(*) 
{
    function($mu as array(*)) {
        array:append(μ:tag($mu), $content)
    }
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function μ:insert($context as item()*, $content as item()*) 
as item()*
{
    μ:insert($content)($context)
};

declare function μ:replace($content as item()*)
as function(*) {
    function($context as item()*) {
        $content
    }
};

declare function μ:replace($context as item()*, $content as item()*) 
as item()*
{
    μ:replace($content)($context)
};

declare function μ:wrap($mu as array(*)?)
as function(*)
{
    function($context as item()*) {
        array:append(μ:tag($mu), $context)
    }
};

declare function μ:wrap($context as item()*, $mu as array(*)?)
as item()*
{
    μ:wrap($mu)($context)
};

(: ========= :)

(:~
 : Create a node transformer that applies a node transformation rule to a
 : sequence of input nodes.
 :)
declare function μ:do(
$rule as array(*)) 
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        μ:do-nodes($nodes, $rule)
    }
};

(:~
 : Apply a node transformation rule to a sequence of nodes.
 :)
declare function μ:do(
$nodes as item()*, 
$rule as array(*)) 
as item()*
{
    μ:do-nodes($nodes, $rule)
};

(:~
 : Create a node transformer that applies a node transformation rule to each 
 : individual input node.
 :)
declare function μ:each(
$rule as array(*)) 
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        for $node in $nodes
            return μ:do-nodes($node, $rule)
    }
};

(:~
 : Apply a node transformation rule to each individual input node.
 :)
declare function μ:each(
$nodes as item()*, 
$rule as array(*)) 
as item()*
{
    for $node in $nodes
        return μ:do-nodes($node, $rule)
};

declare %private function μ:do-nodes(
$nodes as item()*, 
$rule as array(*))
as item()*
{
    array:fold-left(
        $rule, 
        $nodes,
        function($nodes, $step) {
            if ($step instance of function(*)) then
                $step($nodes)
            else
                $step
        }
    )     
};

declare %private function μ:invoke-transformer($fn as function(*), $content as item()*, $context as item()*)
{
    if ($context instance of array(*) and array:size($context) gt 0) then
        $fn(array:head($context), $content, array:tail($context))
    else 
        $fn($context, $content, [])    
};

declare %private function μ:context($context)
{
    if ($context instance of array(*) and array:size($context) gt 0) then
        (array:head($context), array:tail($context))
    else 
        ($context, [])        
};

(:~
 : Create a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :
 : This function is safe for use as a node selector.
 :)
(:
declare function μ:unwrap()
as function(item()*) as item()*
{
    function($context as item()*) {
        μ:invoke-transformer(μ:unwrap-nodes#3, (), $context)
    }    
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function μ:unwrap($context as item()*)
as item()*
{
    μ:unwrap()($context)
};
:)

(:~
 : Copy nodes without any transformation.
 :)
declare function μ:copy()
as function(*)
{
    function($node as array(*), $args as array(*)?) {
        $node
    }
};

(:~
 : Create a node transformer that inserts `$before` before
 : the nodes passed in.
 :)
declare function μ:before($before as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($before, $nodes)
    }
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function μ:before($nodes as item()*, $before as item()*)
as item()*
{
    μ:before($before)($nodes)
};

(:~
 : Create a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function μ:after($after as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($nodes, $after)
    }
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function μ:after($nodes as item()*, $after as item()*) 
as item()*
{
    μ:after($after)($nodes)
};

(:~
 : Create a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function μ:append($append as item()*)
as function(item()*) as item()*
{
    μ:element-transformer(
        function($node as element()) as element() {
            element { node-name($node) } {
                $node/(@*,node()), 
                $append
            }
        }
     (: HACK :)
    )(true())
};

(:~
 : Inserts `$append` nodes to the child nodes of each element in
 : `$nodes`.
 :)
declare function μ:append($nodes as item()*, $append as item()*) 
as item()*
{
    μ:append($append)($nodes)
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function μ:prepend($prepend as item()*)
as function(item()*) as item()*
{
    μ:element-transformer(
        function($node as element()) as element() {
            element { node-name($node) } {
                ($node/@*, $prepend, $node/node())
            }
        }
     (: HACK :)
    )(true())
};

(:~
 : Inserts `$prepend` nodes before the first child node of each element
 : in `$nodes`.
 :)
declare function μ:prepend($nodes as item()*, $prepend as item()*) 
as item()*
{
    μ:prepend($prepend)($nodes)
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function μ:text()
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        if (exists($nodes)) then
            for $node in $nodes
                return 
                    typeswitch ($node)
                    case map(*)
                    return
                        $node
                    case array(*)
                    return 
                        $node
                    case function(*)
                    return
                        $node
                    default
                    return
                        text { string($node) }
        else
            ()
    }
};

(:~
 : Outputs the text value of `$nodes`.
 :)
declare function μ:text($nodes as item()*)
as item()*
{
    μ:text()($nodes)
};

(:~
 : Create a node transformer that sets attributes using a map
 : on each element in the nodes passed.
 :
 : Map keys must be valid as QNames or they will be ignored.
 :)
declare function μ:set-attr($attributes as item())
as function(item()*) as item()*
{
    let $attributes := 
        typeswitch ($attributes)
        case map(*)
            return 
                map:for-each(
                    $attributes, 
                    function($name, $value) { 
                        if ($name castable as xs:QName) then
                            attribute { $name } { $value }
                        else
                            ()
                    }
                )
        case element()
            return $attributes/@*
        default
            return ()
    return
        μ:element-transformer(
            function($node as element()) as element() {
                element { node-name($node) } {
                    $attributes,
                    for $att in $node/@*
                    where not(node-name($att) = $attributes/node-name())
                    return $att,
                    $node/node()
                }
            }
        )($attributes)
};

(:~
 : Set attributes using a map on each element in `$nodes`.
 :)
declare function μ:set-attr($nodes as item()*, $attributes as item()) 
as item()*
{
    μ:set-attr($attributes)($nodes)
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function μ:add-class($names as xs:string*)
as function(item()*) as item()*
{
    μ:element-transformer(
        function($node as element()) as element() {
            element { node-name($node) } {
                $node/@*[not(name(.) = 'class')],
                attribute class {
                    string-join(
                        distinct-values(
                            tokenize(
                                string-join(($node/@class,$names),' '),
                                '\s+')), 
                        ' ')
                },
                $node/node()
            }
        }
    )($names)
};

(:~
 : Add one or more `$names` to the class attribute of `$element`. 
 : If it doesn't exist it is added.
 :)
declare function μ:add-class($nodes as item()*, $names as xs:string*) 
as item()*
{
    μ:add-class($names)($nodes)
};

(:~
 : Create a node transformer that removes one or more `$names` from the 
 : class attribute. If the class attribute is empty after removing names it will 
 : be removed from the element.
 :)
declare function μ:remove-class($names as xs:string*)
as function(item()*) as item()*
{
    μ:element-transformer(
        function($node as element()) as element() {
            element { node-name($node) } {
                $node/@*[not(name(.) =  'class')],
                let $classes := distinct-values(
                    tokenize(($node/@class,'')[1],'\s+')[not(. = $names)])
                where exists($classes)
                return
                    attribute class { string-join($classes,' ') },
                $node/node()
            }
        }   
    )($names)
};

(:~
 : Remove one or more `$names` from the class attribute of `$element`.
 : If the class attribute is empty after removing names it will be removed
 : from the element.
 :)
declare function μ:remove-class($nodes as item()*, $names as xs:string*) 
as item()*
{
    μ:remove-class($names)($nodes)
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :
 : TODO: better testing and clean up code.
 :)
declare function μ:remove-attr($attributes as item()*)
as function(item()*) as item()*
{
    let $names := 
        typeswitch ($attributes)
        case xs:string*
            return 
                for $name in $attributes 
                return
                    if ($name eq '*' or starts-with($name, '*:')) then
                        $name
                    else if ($name castable as xs:QName) then
                        xs:QName($name)
                    else
                        ()
        case element()
            return for $att in $attributes/@* return node-name($att)
        case map(*)
            return             
                map:for-each(
                    $attributes, 
                    function($name,$value) { 
                    if ($name castable as xs:QName) then
                        xs:QName($name)
                    else
                        ()
                })
        default
            return ()
    return
        μ:element-transformer(
            function($node as element()) as element() {
                element { node-name($node) } {
                    for $att in $node/@*
                        where not('*' = (for $name in $names return if ($name instance of xs:string) then $name else ())) and
                              not(local-name($att) = (for $name in $names return if ($name instance of xs:string and starts-with($name,'*:')) then substring-after($name,'*:') else ())) and
                              not(node-name($att) = (for $name in $names return if ($name instance of xs:QName) then $name else ()))
                        return $att
                }
            }
        )($attributes)
};

(:~
 : Remove attributes from each element in `$nodes`.
 :)
declare function μ:remove-attr($nodes as item()*, $names as item()*) 
as item()*
{
    μ:remove-attr($names)($nodes)
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
 : - `function($node as element()) as item()`: passes the element node to the 
 :   function using the return value as the new element name
 :)
declare function μ:rename($map as item()) 
as function(item()*) as item()*
{
    μ:element-transformer(
        function($node as element()) as element() {
            typeswitch ($map)
            case map(*)
                return
                    if ($map(node-name($node))) then    
                        element { $map(node-name($node)) } {
                            $node/(@*,node())
                        }
                    else if ($map(name($node))) then
                        element { $map(name($node)) } {
                            $node/(@*,node())
                        }
                    else
                        $node
             case function(*)
                 return
                    element { $map($node) } {
                        $node/(@*,node())
                    }             
             case xs:string
                 return
                    element { $map } {
                        $node/(@*,node())
                    }
             default
                 return $node
        }
    )(true())
};

(:~
 : Renames elements in `$nodes`.
 :)
declare function μ:rename($nodes as item()*, $map as item())
as item()*
{
    μ:rename($map)($nodes)
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 :)
declare function μ:xslt($stylesheet as item()) 
as function(node()*) as node()*
{
    μ:xslt($stylesheet, map {})
};

(:~
 : Create a node transformer that transforms nodes using
 : an XSLT stylesheet with parameters.
 :)
declare function μ:xslt($stylesheet as item(), $params as item()) 
as function(item()*) as item()*
{
    μ:element-transformer(
        function($node as element()) as element() {
            xslt:transform($node, $stylesheet, $params)/*
        }
    )($params)
};

(:~
 : Transform `$nodes` using XSLT stylesheet.
 :)
declare function μ:xslt($nodes as item()*, $stylesheet as item(), $params as item())
as item()*
{
    μ:xslt($stylesheet, $params)($nodes)
};

declare %private function μ:element-spec($spec as item())
{
    typeswitch ($spec)
    case node() | array(*) | map(*) | function(*)
    return $spec
    default
    return ()
};

declare %private function μ:element-transformer(
$transform as function(element(), item()*) as item()*) 
as function(*) 
{
    function($args as item()*) as function(*) {
        function($nodes as item()*, $ctx) as item()* {
            if (exists($args)) then
                for $node in $nodes
                    return
                        if ($node instance of element()) then
                            $transform($node, $ctx)
                        else
                            $node
            else
                $nodes
        }
    }
};