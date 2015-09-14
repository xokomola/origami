xquery version "3.1";

module namespace μ = 'http://xokomola.com/xquery/origami/mu';

import module namespace u = 'http://xokomola.com/xquery/origami/utils' at 'utils.xqm'; 

declare %private variable $μ:ns := μ:ns();

(: TODO: combine template and snippet :)
(:~ 
 : Origami μ-documents
 :)

(: Reading from external entities :)

declare function μ:read-xml($uri as xs:string)
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
declare function μ:read-xml($uri as xs:string, $options as map(xs:string, item()))
as document-node()?
{
    fetch:xml($uri, u:select-keys($options, $μ:xml-options))
};

declare variable $μ:xml-options :=
    ('chop', 'stripns', 'intparse', 'dtd', 'xinclude', 'catfile', 'skipcorrupt');

(:~
 : Read and parse HTML with the Tagsoup parser (although this could be changed).
 : If Tagsoup is not available it will fallback to parsing well-formed XML.
 :
 : For options see: http://docs.basex.org/wiki/Parsers#TagSoup_Options
 :)
declare function  μ:read-html($uri as xs:string)
as document-node()?
{
    μ:read-html($uri, map { 'lines': false() })   
};

declare function μ:read-html($uri as xs:string, $options as map(xs:string, item()))
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
declare function μ:read-text($uri as xs:string)
as xs:string*
{
    μ:read-text($uri, map { })
};

declare function μ:read-text($uri as xs:string, $options as map(xs:string, item()))
as xs:string*
{
    let $parse-into-lines := ($options?lines, true())[1]
    let $encoding := $options?encoding
    return
        if ($parse-into-lines)
        then if ($encoding) then unparsed-text-lines($uri, $encoding) else unparsed-text-lines($uri) 
        else if ($encoding) then unparsed-text($uri, $encoding) else unparsed-text($uri)
};

declare function μ:read-json($uri as xs:string)
as item()?
{
    μ:read-json($uri, map {})
};

declare function μ:read-json($uri as xs:string, $options as map(xs:string, item()))
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
declare function μ:read-csv($uri as xs:string)
as array(*)*
{
    μ:read-csv($uri, map {})
};

declare function μ:read-csv($uri as xs:string, $options as map(xs:string, item()))
as array(*)*
{
    μ:parse-csv(
        μ:read-text(
            $uri, 
            map:merge(($options, map { 'lines': false() }))
        ), 
        $options
    )
};

declare function μ:parse-csv($text as xs:string*)
as array(*)*
{
    μ:parse-csv($text, map {})
};

declare function μ:parse-csv($text as xs:string*, $options as map(xs:string, item()))
as array(*)*
{
    μ:csv-normal-form(
        csv:parse(
            string-join($text,'&#10;'), 
            map:merge((u:select-keys($options, $μ:csv-options), map { 'format': 'map' }))
        )
    )
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
    map:keys($csv) ! array { $csv(.) }
};

(: Parsing into μ nodes :)

(:~
 : Convert XML nodes to a μ-document. 
 :)
declare function μ:doc($items as item()*)
as item()*
{
    $items ! μ:doc-node(., map {})
};

(:~
 : Convert XML nodes to a μ-document and attaching transformation functions
 : to some of the element nodes.
 :)
declare function μ:doc($items as item()*, $rules as map(*))
as item()*
{
    $items ! μ:doc-node(., $rules)
};

declare %private function μ:doc-node($item as item())
{
    μ:doc-node($item, map {})
};

declare %private function μ:doc-node($item as item(), $rules as map(*))
as item()?
{
    typeswitch($item)
    case document-node() return μ:doc-node($item/*, $rules)
    case processing-instruction() return ()
    case comment() return ()
    case element()
    return
        array { 
            name($item), 
            if ($item/@* or map:contains($rules, name($item))) 
            then 
                map:merge((
                    for $a in $item/@* except $item/@μ:path
                    return map:entry(name($a), data($a)),
                    let $path := 
                        if ($item[@μ:path])
                        then string($item/@μ:path) 
                        else name($item)
                    return
                        if (map:contains($rules, $path))
                        then map:entry('μ:fn', $rules($path))
                        else ()
                ))
            else (),
            $item/node() ! μ:doc-node(., $rules)
        }
    case array(*)
    return
        let $tag := μ:tag($item)
        let $atts := μ:attributes($item)
        let $content := μ:content($item)
        return
            array { $tag, $atts, $content ! μ:doc-node(., $rules) }
    case text() return string($item)
    default return $item
};

(: "Serializing" :)

(:~
 : Converts μ-nodes to XML nodes with the default name resolver.
 :)
declare function μ:xml($mu as item()*)
as node()*
{
    μ:to-xml($mu, μ:qname-resolver(μ:ns()), map {})
};

(:~
 : Converts μ-nodes to XML nodes using a map of options. Currently it will
 : only use the options 'ns' whose value must be a namespace map and 'default-ns'
 : whose value must be a valide namespace URI.
 :)
declare function μ:xml($mu as item()*, $options as map(*)) 
as node()*
{
    μ:to-xml($mu, μ:qname-resolver(μ:ns($options?ns), $options?default-ns), $options)
};

(: TODO: namespace handling, especially to-attributes :)
(: TODO: default namespaces was set to XSLT μ:qname-resolver($ns-map, $ns-map?xsl) 
         but this isn't the right approach :)
declare %private function μ:to-xml($mu as item()*, $name-resolver as function(xs:string) as xs:QName, $options as map(*))
as node()*
{
    $mu ! (   
        typeswitch (.)
        case array(*) return μ:to-element(., $name-resolver, $options)
        case map(*) return  μ:to-attributes(., $name-resolver)
        case function(*) return ()
        case empty-sequence() return ()
        case node()  return .
        default return text { . }
    )
};

(: TODO: need more common map manipulation functions :)
(: TODO: change ns handling to using a map to construct them at the top (sane namespaces) :)
(: TODO: in mu we should not get xmlns attributes so change μ:doc to take them off :)
declare %private function μ:to-element($mu as array(*), $name-resolver as function(*), $options)
as item()*
{
    let $tag := μ:tag($mu)
    let $atts := 
        map:merge((
            map:for-each(
                (μ:attributes($mu),map{})[1], 
                function($k, $v) { 
                    if (starts-with($k, 'xmlns:')) then () 
                    else map:entry($k, $v) 
                }
            )
        ))
    let $content := μ:content($mu)
    let $fn := $atts('μ:fn')
    where $tag
    return
        (: TODO: args and att function checking :)
        typeswitch ($fn)
        case array(*) return $fn
        case map(*) return $fn
        case function(*) return
            (: need to call to-xml with fn removed from fn :)
            μ:to-xml(apply($atts('μ:fn'), [[$tag, map:remove($atts,'μ:fn'), $content]]), $name-resolver, $options)
        default return     
            element { $name-resolver($tag) } {
                (: TODO: this shouldn't be in here but was here for compile template, move it there :)
                namespace μ { 'http://xokomola.com/xquery/origami/mu' },
                if ($options?ns instance of map(*))
                then
                    for $prefix in map:keys($options?ns)
                    let $uri := $options?ns($prefix)
                    where $prefix != '' and $uri != ''
                    return
                        namespace { $prefix } { $uri }
                else
                    (),
                μ:to-attributes($atts, $name-resolver),
                fold-left($content, (),
                    function($n, $i) {
                        ($n, μ:to-xml($i, $name-resolver, $options))
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
            if (starts-with($k,'μ:')) then ()
            else
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
        }
    )
};

(:~
 : Converts μ-nodes to JSON with the default name resolver.
 :)
declare function μ:json($mu as item()*)
as xs:string
{
    μ:json($mu, function($name) { $name })
};

(:~
 : Converts μ-nodes to JSON using a name-resolver.
 :)
(: TODO: probably should be symmetrical with μ:xml (options) :)
declare function μ:json($mu as item()*, $name-resolver as function(*)) 
as xs:string
{
    serialize(
        μ:to-json(if (count($mu) gt 1) then array { $mu } else $mu, $name-resolver), 
        map { 'method': 'json' }
    )
};

(: TODO: prefix attribute names with @?, plus general improvement :)
declare %private function μ:to-json($mu as item()*, $name-resolver as function(*))
as item()*
{
    $mu ! (
        typeswitch (.)
        
        case array(*) return
            let $tag := μ:tag(.)
            let $atts := μ:attributes(.)
            let $children := μ:content(.)
            return
                map:entry($tag, μ:to-json(($atts, $children), $name-resolver))
                
        case map(*) return 
            map:merge(
                map:for-each(., 
                    function($a,$b) { 
                        map:entry(concat('@',$a), μ:to-json($b, $name-resolver)) }))
                        
        case function(*) return ()
        (: FIXME: I think this should be using to-json as well :)
        case node() return μ:doc(.)
        default return .
    )
};

(: Namespace support :)

(:~
 : Returns a name resolver function with the HTML namespace as default.
 :)
declare function μ:html-resolver()
as function(xs:string) as xs:QName
{
    μ:qname(?, μ:ns(), 'http://www.w3.org/1999/xhtml')
};

(:~
 : Returns a name resolver function from the default namespace map (nsmap.xml).
 :)
declare function μ:qname-resolver()
as function(xs:string) as xs:QName
{
    μ:qname(?, $μ:ns, ())
};

(:~
 : Returns a name resolver function from the namespace map passed as it's argument.
 :)
declare function μ:qname-resolver($ns-map as map(*))
as function(xs:string) as xs:QName
{
    μ:qname(?, $ns-map, ())
};

(:~
 : Returns a name resolver function from the namespace map passed as it's first
 : argument and using the second argument as the default namespace.
 :)
declare function μ:qname-resolver($ns-map as map(*), $default-ns as xs:string?)
as function(xs:string) as xs:QName
{
    μ:qname(?, $ns-map, $default-ns)
};

(:~
 : Get a namespace map from XML nodes. Note that this assumes somewhat sane[1] 
 : namespace usage. The resulting map will contain a prefix/URI entry for each
 : used prefix but it will not re-binding a prefix to a different URI at 
 : descendant nodes. Unused prefixes are dropped.
 : The result can be used when serializing back to XML but results may be not
 : what you expect if you pass insane XML fragments.
 :
 : [1] http://lists.xml.org/archives/xml-dev/200204/msg00170.html
 :)
declare function μ:ns-map-from-nodes($nodes as node()*)
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
 : Get a namespace map from XML nodes. Will throw an exception with insane
 : namespace usage. Unused prefixes will not be dropped. However, unused prefixes
 : cannot be added to an XML fragment due to a limitation in current XPath [1].
 : In Origami XML may be built from dynamic parts which means that when a prefix
 : isn't used in the $nodes it may still be used when serializing to XML.
 :
 : [1] http://thread.gmane.org/gmane.text.xml.xsl.general.mulberrytech/54436
 :)
declare function μ:sane-ns-map-from-nodes($nodes as node()*)
{
    'TODO'
};

(:~
 : Returns a QName in "no namespace".
 : Throws a dynamic error FOCA0002 with a prefixed name.
 :)
declare function μ:qname($name as xs:string)
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
declare function μ:qname($name as xs:string, $ns-map as map(*))
as xs:QName
{
    μ:qname($name, $ns-map, ())
};

(:~
 : Same as μ:qname#2 but uses a third argument to specify a default namespace URI.
 :)
declare function μ:qname($name as xs:string, $ns-map as map(*), $default-ns as xs:string?)
as xs:QName
{
    if (contains($name, ':')) 
    then
        let $prefix := substring-before($name,':')
        let $local := substring-after($name, ':')
        let $ns := ($ns-map($prefix), concat('ns:prefix:', $prefix))[1]
        return
            if ($ns = $default-ns) 
            then QName($ns, $local)
            else QName($ns, concat($prefix, ':', $local))
    else
        if ($default-ns) 
        then QName($default-ns, $name)
        else QName((), $name)
};

(:~
 : Builds a namespace map from the default namespace map provided in the
 : XML file nsmap.xml.
 :)
declare function μ:ns()
as map(*)
{
    μ:ns(())
};

(:~
 : Builds a namespace map from the default namespace map provided in the
 : XML file nsmap.xml and adding extra namespace mappings from a map provided
 : as the argument. The latter mappings will override existing mappings in the
 : default namespace map.
 :)
declare function μ:ns($ns-map as map(*)?)
as map(*)
{
    map:merge((
        ($ns-map, map {})[1],
        for $ns in doc(concat(file:base-dir(),'/nsmap.xml'))/nsmap/*
        return
            map:entry(string($ns/@prefix), string($ns/@uri))
    ))
};

(: μ-node information :)

declare function μ:head($mu as array(*)?)
as item()*
{
    if (exists($mu)) then array:head($mu) else ()
};

declare function μ:tail($mu as array(*)?)
as item()*
{
    tail($mu?*)
};

declare function μ:tag($mu as array(*)?)
as xs:string?
{
    if (empty($mu)) then () else array:head($mu)
};

declare function μ:content($mu as array(*)?)
as item()*
{
    if (array:size($mu) > 0) then
        let $c := array:tail($mu)
        return
            if (array:size($c) > 0 and array:head($c) instance of map(*)) 
            then array:tail($c)?* else $c?*
    else ()
};

declare function μ:attributes($mu as array(*)?)
as map(*)?
{
    if (array:size($mu) gt 1 and $mu?2 instance of map(*)) 
    then $mu?2 else ()
};

(:~
 : Returns the size of contents (child nodes not attributes).
 :)
declare function μ:size($mu as array(*)?)
as item()*
{
    count(μ:content($mu))
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

declare function μ:template($template as item(), $rules as array(*)*)
as item()*
{
    μ:compile-template($template, μ:compile-rules($rules))
};

(:~
 : Create a template snippet using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
(: TODO: consider naming this fragment :)
declare function μ:snippet($template as item(), $rules as array(*)*)
as item()*
{
    μ:compile-snippet($template, μ:compile-rules($rules))
};


(: TODO: ['p', fn1#2, fn2#2, fn3#2] compose a node transformer/pipeline :)
declare function μ:compile-rules($rules as array(*)*)
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
    let $template := μ:xml($template)
    return
        μ:doc(
            xslt:transform(
                $template, 
                μ:compile-transformer(
                    $rules, 
                    map { 
                        'extract': false(),
                        'ns': μ:ns-map-from-nodes($template)
                    }
                )
            ), 
            $rules
        )
};

(: TODO: consider naming this fragment :)
(: TODO: implement same changes as compile-transformer :)
declare function μ:compile-snippet($template as item(), $rules as map(*))
as array(*)*
{
    μ:content(
        μ:doc(
            xslt:transform(
                μ:xml($template), 
                μ:compile-transformer($rules, map { 'extract': true() })
            ),
            $rules
        )
    )
};

declare function μ:compile-transformer($rules as map(*)?)
as element(*)
{
    μ:compile-transformer($rules, map {})
};

(: TODO: if I do ns handling differently we could write without the xls: prefix :)
declare function μ:compile-transformer($rules as map(*)?, $options as map(*))
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
                ['template', map { 'match': '/' }, ['μ:seq', ['apply-templates']]],
                ['template', map { 'match': 'text()' }]
            )
            else 
                μ:identity-transform(),
            for $selector in map:keys(($rules, map {})[1])
            return
                ['template', map { 'match': $selector },
                    ['copy',
                        ['copy-of', map { 'select': '@*' }],
                        ['attribute', map { 'name': 'μ:path' }, $selector],
                        ['apply-templates', map { 'select': 'node()' }]
                    ]
                ]
        ],
        map { 'ns': $options?ns, 'default-ns': 'http://www.w3.org/1999/XSL/Transform' }
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

(: TODO: empty $args is not allowed for apply :)
declare %private function μ:data($node as item(), $args as array(*)?)
{
    typeswitch ((μ:attributes($node), map {})[1]('μ:data'))
    case empty-sequence() return $args
    case $map as map(*) return $map
    case $array as array(*) return $array
    case $fn as function(*) return apply($fn, $args)
    default $data return $data
};

declare function μ:apply-attributes($atts as map(*)?, $data as array(*)?)
{
    map:merge((
        for $key in map:keys($atts)
        where not(starts-with($key, 'μ:'))
        return
            map:entry(
                $key,
                typeswitch($atts($key))
                case $fn as function(*) return apply($fn,$data)
                default $value return $value
            )
    ))
};

declare function μ:apply($nodes as item()*)
{
    μ:apply($nodes, ())
};

declare function μ:apply($nodes as item()*, $args as array(*)?)
as item()*
{  
    $nodes ! (
        typeswitch(.)
        case array(*)
        return
            let $tag := μ:tag(.)
            let $atts := (μ:attributes(.), map {})[1]
            let $has-handler := map:contains($atts, 'μ:fn')
            let $handler := $atts('μ:fn')
            let $content := μ:content(.)
            let $data := μ:data(., $args)
            let $atts := μ:apply-attributes($atts, $data)
            return
                typeswitch ($handler)
                case empty-sequence() return
                    (: This can mean that the handler is (), or that there is no handler :)
                    if ($has-handler) then ()
                    else
                        array { 
                            $tag, 
                            if (map:size($atts) gt 0) then $atts else (), 
                            μ:apply($content, $data) 
                        }
                case array(*) return $handler
                case map(*) return $handler
                case function(*) return
                    (: TODO: probably array { ... } is better here :)
                    if (exists($data))
                    then μ:apply(apply($handler, [[$tag, $atts, $content], $data]), $data)
                    else μ:apply(apply($handler, [[$tag, $atts, $content]]), $data)
                default return $handler
        case function(*) return μ:apply(apply(., $args), $args) 
        default return .
    )
};

(: μ-node transformers :)

declare function μ:identity($x) { $x };

(:~
 : Returns a sequence even if the argument is an array.
 :)
declare function μ:seq($x as item()*) 
{ 
    if ($x instance of array(*)) then $x?* else $x
};

(:~
 : Generic walker function that traverses the μ-node (depth-first).
 :)
declare function μ:postwalk($fn as function(*), $form as item())
{
    typeswitch ($form)
    case array(*) return
        $fn(array { 
            for $item in $form?*
            return μ:postwalk($fn, $item)
        })
    default return $form
};

(:~
 : Generic walker function that traverses the μ-node (breadth-first).
 :)
declare function μ:prewalk($fn as function(*), $form as array(*))
{
    let $walked := $fn($form)
    return
        typeswitch ($walked)
        case array(*) return
            array { 
                for $item in $walked?*
                return 
                    if ($item instance of array(*))
                    then μ:prewalk($fn, $item)
                    else $item
            }
        default return $walked
};

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function μ:insert($content as item()*)
as function(*) 
{
    function($mu as array(*)) {
        array { μ:tag($mu), μ:attributes($mu), $content }
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
    if (exists($mu))
    then
        function($content as item()*) {
            array { μ:tag($mu), μ:attributes($mu), $content }
        }
    else
        function($content as item()*) {
            $content
        }
};

declare function μ:wrap($content as item()*, $mu as array(*)?)
as item()*
{
    μ:wrap($mu)($content)
};

(:~
 : Create a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :)
declare function μ:unwrap()
as function(item()*) as item()*
{
    function($content as item()*) {
        $content ! (
            typeswitch(.)
            case array(*) return μ:content(.)
            default return .
        )
    }    
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function μ:unwrap($content as item()*)
as item()*
{
    μ:unwrap()($content)
};

(:~
 : Copy nodes without any transformation.
 :)
declare function μ:copy()
as function(item()*) as item()*
{
    function($content as item()*) {
        $content
    }
};

declare function μ:copy($content as item()*)
as item()*
{
    μ:copy()($content)
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
declare function μ:insert-after($append as item()*)
as function(item()*) as item()*
{
   function($mu as array(*)) {
        array { μ:tag($mu), μ:attributes($mu), μ:content($mu), $append }
    }
};

(:~
 : Inserts `$append` nodes to the child nodes of each element in
 : `$nodes`.
 :)
declare function μ:insert-after($nodes as item()*, $append as item()*) 
as item()*
{
    μ:insert-after($append)($nodes)
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function μ:insert-before($prepend as item()*)
as function(item()*) as item()*
{
   function($mu as array(*)) {
        array { μ:tag($mu), μ:attributes($mu), $prepend, μ:content($mu) }
    }
};

(:~
 : Inserts `$prepend` nodes before the first child node of each element
 : in `$nodes`.
 :)
declare function μ:insert-before($nodes as item()*, $prepend as item()*) 
as item()*
{
    μ:insert-before($prepend)($nodes)
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function μ:text()
as function(item()*) as item()*
{
    function($nodes as item()*) as xs:string* {    
        $nodes ! (
            typeswitch (.)
            case map(*) return ()
            case array(*) return μ:text(μ:content(.))
            case function(*) return ()
            default return string(.)
        )
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
 :)
declare function μ:set-attr($attributes as map(*))
as function(item()*) as item()*
{
    function($node as array(*)) {
        array { 
            μ:tag($node), 
            map:merge((μ:attributes($node), $attributes)), 
            μ:content($node) 
        }
    }
};

(:~
 : Set attributes using a map on each element in `$nodes`.
 :)
declare function μ:set-attr($nodes as item()*, $attributes as map(*)) 
as item()*
{
    μ:set-attr($attributes)($nodes)
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :
 : TODO: better testing and clean up code.
 :)
declare function μ:remove-attr($remove-atts as xs:string*)
as function(item()*) as item()*
{
    function($node as array(*)) {
        let $atts :=
            map:merge((
                map:for-each((μ:attributes($node), map {})[1], 
                    function($k,$v) {
                        if ($k = $remove-atts) then () else map:entry($k,$v)
                    }
                )
            ))
        return
            array { 
                μ:tag($node),
                if (map:size($atts) = 0) then () else $atts,
                μ:content($node) 
            }   
    }
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
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function μ:add-class($names as xs:string*)
as function(item()*) as item()*
{
    function($node as array(*)) {  
        let $atts := (μ:attributes($node),map {})[1]
        return
            array {
                μ:tag($node),
                map:merge((
                    $atts,
                    map:entry('class',
                        string-join(
                            distinct-values(
                                tokenize(
                                    string-join(($atts?class,$names),' '), '\s+')), ' ')
                    )
                )),
                μ:content($node)
            }
    }
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
   function($node as array(*)) {  
        let $atts := (μ:attributes($node),map {})[1]
        let $classes := tokenize($atts?class,'\s+')
        let $new-classes :=
            for $class in $classes
            where not($class = $names)
            return $class
        let $new-atts :=
            if (count($new-classes) = 0)
            then map:remove($atts,'class')
            else
                map:merge((
                    $atts,
                    map:entry('class', string-join($new-classes, ' '))
                ))        
        return
            array {
                μ:tag($node),
                if (map:size($new-atts) = 0) then () else $new-atts,
                μ:content($node)
            }
    }
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
 : Create a node-transformer that renames element nodes, passing non-element 
 : nodes and element child nodes through unmodified.
 :
 : Renaming can be done using a:
 :
 : - `xs:string`: renames all elements
 : - `map(*)`: looks up the element name in the map and uses the value as the 
 :   new name
 :)
declare function μ:rename($name as item()) 
as function(item()*) as item()*
{
    function($node as array(*)) {
        let $new-name :=
            if ($name instance of map(*)) then $name(μ:tag($node)) else $name
        return
            if ($new-name)
            then 
                array { 
                    $new-name,
                    μ:attributes($node), 
                    μ:content($node) 
                }
            else
                $node
    }
};

(:~
 : Renames elements in `$nodes`.
 :)
declare function μ:rename($nodes as item()*, $name as item())
as item()*
{
    μ:rename($name)($nodes)
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 : TODO: maybe template and snippet should also use this function.
 :)
declare function μ:xslt($options as map(*)) 
as function(item()?) as array(*)?
{
    function($nodes as item()?) as array(*)? {
        μ:doc(
            xslt:transform(
                μ:xml($nodes), 
                $options('stylesheet-node'), 
                $options('stylesheet-params')
            )
        )        
    }
};

(:~
 : Transform `$nodes` using XSLT stylesheet.
 :)
declare function μ:xslt($nodes as item()?, $options as map(*))
as array(*)?
{
    μ:xslt($options)($nodes)
};
