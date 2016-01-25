xquery version "3.1";

(:~
 : Origami - micro-templating library for XQuery 3.1
 :)

(: TODO: maybe use serialize for o:xml? :)

module namespace o = 'http://xokomola.com/xquery/origami';

declare %private variable $o:version := '0.6';

declare variable $o:ns :=
    map {
        'origami': 'http://xokomola.com/xquery/origami',
        'html': 'http://www.w3.org/1999/xhtml',
        'xsl': 'http://www.w3.org/1999/XSL/Transform',
        'xs': 'http://www.w3.org/2001/XMLSchema'
    };
declare %private variable $o:origami-ns := $o:ns?origami;
declare %private variable $o:handler-att := '@';
declare %private variable $o:doc-handler-key := '!doc';
(: TODO: review the code that uses this :)
declare %private variable $o:is-element := true();
declare %private variable $o:is-handler := false();
declare %private variable $o:internal-att := ($o:handler-att);

(: errors :)
declare %private variable $o:err-invalid-argument := xs:QName('o:invalid-argument');
declare %private variable $o:err-invalid-handler := xs:QName('o:invalid-handler');
declare %private variable $o:err-invalid-rule := xs:QName('o:invalid-rule');
declare %private variable $o:err-xslt := xs:QName('o:xslt-error');
declare %private variable $o:err-unwellformed := xs:QName('o:unwellformed');

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
    fetch:xml($uri, o:select-keys($options, $o:xml-options))
};

declare variable $o:xml-options :=
    ('chop', 'stripns', 'intparse', 'dtd', 'xinclude', 'catfile', 'skipcorrupt');

(:~
 : Read and parse HTML with the Tagsoup parser (although this could be changed).
 : If Tagsoup is not available it will fallback to parsing well-formed XML.
 :
 : For options see: http://docs.basex.org/wiki/Parsers#TagSoup_Options
 :)
declare function  o:read-html($uri as xs:string?)
as element()
{
    o:read-html($uri, map { 'lines': false() })
};

declare function o:read-html($uri as xs:string?, $options as map(xs:string, item()))
as element()
{
    o:parse-html(o:read-text($uri, map:merge(($options, map { 'lines': false() }))), $options)
};

(: TODO: review this function :)
declare function o:get-html($uri as xs:string)
{
    o:get-html($uri, map {})
};

declare function o:get-html($uri as xs:string, $options as map(xs:string, xs:string))
{
    let $req :=
        <http:request method="get"
            override-media-type="application/octet-stream"
            href="{ $uri }">
            <http:header name="User-Agent" value="{ $options('user-agent') }"/>
            <http:header name="Accept" value="text/html"/>
            <http:header name="Accept-Language" value="en-US,en;q=0.8"/>
        </http:request>
    let $binary := http:send-request($req)[2]
    return 
        try {
            html:parse($binary)
        } catch * {
            'Conversion to XML failed: ' || $err:description
        }
};

(:~
 : Note that binary or strings can be passed to html:parse, in which case encoding
 : can be used to override automatic detection.
 : We can also just pass in a seq of strings.
 :)
declare function o:parse-html($text as xs:string*)
as element()
{
    html:parse(string-join($text, ''))/*
};

declare function o:parse-html($text as xs:string*, $options as map(xs:string, item()))
as element()
{
    html:parse(string-join($text, ''), o:select-keys($options, $o:html-options))/*
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
declare function o:read-text($uri as xs:string?)
as xs:string*
{
    o:read-text($uri, map { })
};

declare function o:read-text($uri as xs:string?, $options as map(xs:string, item()))
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
    json-doc($uri, o:select-keys($options, $o:xml-options))
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
    parse-json(string-join($text, ''))
};

declare function o:parse-json($text as xs:string*, $options as map(xs:string, item()))
as item()?
{
    parse-json(string-join($text, ''), $options?($o:json-options))
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
            string-join($text, '&#10;'),
            map:merge((o:select-keys($options, $o:csv-options), map { 'format': 'map' }))
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

(:~
 : Converts input nodes to an Origami document.
 :)
declare function o:doc($items as item()*)
as item()*
{
    o:to-doc($items, ())
};

declare function o:doc($nodes as item()*, $builder as item()*)
as item()*
{
    let $builder :=        
        if (o:is-builder($builder)) then
            $builder
        else
            o:builder($builder)
    return
        if (exists($builder)) then
            if  (map:contains($builder, $o:doc-handler-key)) then
                $builder($o:doc-handler-key)($nodes)
            else if ($builder?xf instance of function(item()*) as item()*) then
                o:to-doc($builder?xf($nodes), ())
            else
                o:to-doc($nodes, $builder)
        else
            o:to-doc($nodes, ())
};

declare %private function o:to-doc($nodes as item()*, $builder as map(*)?)
as item()*
{
    let $rules :=
        if ($builder?rules instance of map(*)) then
            $builder?rules
        else
            ()
    return
        $nodes ! (
            typeswitch(.)
            case document-node() return
                o:to-doc(./*, $builder)
            case processing-instruction() return
                ()
            case comment() return
                ()
            case attribute() return
                error($o:err-unwellformed, "Standalone attribute nodes are not supported", .)
            case element() return
                if  (name(.) = 'o:seq') then
                    ./node() ! o:to-doc(., $builder)
                else
                    let $attrs :=
                        map:merge((
                            for $att in ./@*
                            return map:entry(name($att), data($att))
                        ))
                    let $attrs :=
                        if (exists($rules)) then
                            (: add current element tag to map :)
                            o:bind-node-handlers(
                                map:merge(($attrs, map:entry($o:handler-att, name(.)))),
                                $rules
                            )
                        else
                            $attrs
                    return
                        array {
                            name(.),
                            if (map:size($attrs) > 0) then $attrs else (),
                            ./node() ! o:to-doc(., $builder)
                        }
            case array(*) return
                if (o:is-handler(.)) then
                    o:prepare-handler(.)
                else
                    let $tag := o:tag(.)
                    return
                        if ($tag instance of xs:string) then
                            let $attrs :=
                                map:merge((
                                    map:for-each(
                                        o:attrs(.),
                                        function($k,$v) {
                                            if ($k instance of xs:string) then
                                                if (o:is-handler($v)) then
                                                    map:entry($k, o:prepare-handler($v))
                                                else
                                                    map:entry($k, $v)
                                            else
                                                error($o:err-unwellformed, "Attribute name must be a string", $k)
                                        }
                                    )
                                ))
                            let $attrs :=
                                if (exists($rules)) then
                                    (: add current element tag to map :)
                                    o:bind-node-handlers(
                                        map:merge(($attrs, map:entry($o:handler-att, $tag))),
                                        $rules
                                    )
                                else
                                    $attrs
                            return
                                array {
                                    $tag,
                                    if (map:size($attrs) > 0) then $attrs else(),
                                    o:children(.) ! o:to-doc(., $builder)
                                }
                        else
                            error($o:err-unwellformed, "Element tag must be a string", $tag)
            case map(*) return
                error($o:err-unwellformed, "Map found in non-attribute position", .)
            case function(*) return
                o:prepare-handler(.)
            case text() return
                o:normalize-text-node(.)
            default return .
        )
};

declare %private function o:bind-node-handlers($attrs as map(*), $rules as map(*))
as map(*)
{
    map:merge((
        map:for-each(
            $attrs,
            function($name,$value) {
                switch($name)
                case $o:handler-att return
                    if (map:contains($rules, $value)) then
                        map:entry($o:handler-att, o:prepare-handler($rules($value)))
                    else
                        ()
                default return
                    let $tag-attr-selector := concat($attrs($o:handler-att), '@', $name)
                    let $attr-selector := concat('@', $name)
                    return
                        if (map:contains($rules, $tag-attr-selector)) then
                            map:entry($name, o:prepare-handler($rules($tag-attr-selector)))
                        else if (map:contains($rules, $attr-selector)) then
                            map:entry($name, o:prepare-handler($rules($attr-selector)))
                        else
                            map:entry($name, $value)
            }
        )
    ))
};

(:~
 : Execute the extractor stylesheet and and attach the node handlers
 : to the correct nodes as defined by the rules.
 : TODO: rename as this is the real transforming function!!!
 :)
declare function o:transformer($rules)
as function(*)
{
    o:transformer($rules, map {})
};

(: TODO: currently $options only takes namespace map :)
declare function o:transformer($rules as array(*)+, $options as map(*))
as function(*)
{
    let $compiled-rules := o:compile-rules($rules)
    let $stylesheet := o:compile-stylesheet($compiled-rules, $options)
    return
        function($nodes as item()*) {
            o:prewalk(
                o:prewalk(
                    o:xslt($stylesheet)($nodes),
                    o:bind-handlers-to-node($compiled-rules)
                ),
                o:merge-node-handlers#1
            )
        }
};

declare function o:transform($nodes as item()*, $rules as array(*)+)
as item()*
{
    o:transformer($rules)($nodes)
};

declare function o:transform($nodes as item()*, $rules as array(*)+, $options as map(*))
as item()*
{
    o:transformer($rules, $options)($nodes)
};

(:~
 : Attribute and text handlers are attached to pseudo elements (o:attribute and o:text).
 : This merges them with the original element node (attribute node handlers) or turns
 : them into inline handlers (text node handlers)
 :)
declare %private function o:merge-node-handlers($e)
as item()?
{
  let $tag := o:tag($e)
  return
    if ($tag = 'o:text') then
        if (map:contains(o:attrs($e),'@')) then
            o:attrs($e)('@')
        else
            o:children($e)
    else if ($tag = 'o:attribute') then
        (: an attribute without a parent element :)
        (: TODO: REVIEW :)
        if (map:contains(o:attrs($e),'@')) then
            o:attrs($e)('@')($e,())
        else
            o:children($e)        
    else
      let $attrs := o:attributes($e)
      let $children := o:children($e)
      let $attrs :=
        fold-left(
            $children,
            $attrs,
            function($result,$child) {
              if (o:is-element($child) and o:tag($child) = 'o:attribute') then
                map:merge(($result, map:entry(o:attrs($child)?name, o:attrs($child)('@'))))
              else
                $result
            }
        )
      let $children :=
        fold-left(
            $children,
            (),
            function($result,$child) {
              if (o:is-element($child) and o:tag($child) = 'o:attribute') then
                ()
              else
                ($result,$child)
            }
        )
      return
        array {
          $tag,
          $attrs,
          $children
        }
};

(:~
 : Given an extracted element node and adds the matching rules to it.
 :)
declare %private function o:bind-handlers-to-node($rules as map(*)*)
as function(*)
{
    function($element as array(*)) {
        let $tag := o:tag($element)
        let $attrs := o:attrs($element)
        let $content := o:children($element)
        let $rule :=
            if (map:contains($attrs, 'o:id')) then
                $rules($attrs('o:id'))
            else
                map {}
        let $merged-attributes :=
            map:merge((
                map:for-each($attrs,
                    function($k, $v) { if ($k = ('o:id', 'o:path')) then () else map:entry($k, $v) }
                ),
                if (map:contains($rule, 'handler') and exists($rule?handler)) then
                    map:entry($o:handler-att, o:prepare-handler($rule?handler))
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
 : Ensure spurious whitespace text nodes are filtered out.
 : When XML is parsed it may contain a lot of whitespace nodes.
 : This cleans it up a little.
 :)
declare %private function o:normalize-text-node($node as text())
{
    if (string-length(normalize-space($node)) = 0) then
        ()
    else
        let $normalized := normalize-space(concat('|', $node, '|'))
        return
            substring($normalized,2,string-length($normalized)-2)
};

declare function o:builder()
as map(*)
{
    map { 'type': 'builder' }
};

declare function o:builder($rules as item()*)
as map(*)
{
    (: TODO: review :)
    typeswitch ($rules)
    case node() return
        o:ns-builder($rules)
    default return 
        o:builder($rules, map { })
};

declare function o:builder($rules as item()*, $options as map(*))
as map(*)
{
    typeswitch ($rules)
    case array(*)+ return
        o:xslt-builder($rules, $options)
    case map(*)+ return
        o:map-builder($rules, $options)
    default return
        o:builder()
};

declare function o:map-builder($rules as map(*), $options as map(*))
as map(*)
{
    map:merge((
        $options,            
        map:entry('rules', $rules),
        map:entry('type', 'builder')
    ))    
};

declare function o:xf-builder($transformer as function(item()*) as item()*)
as map(*)
{
    map:merge((
        map:entry('xf', $transformer),
        map:entry('type', 'builder')
    ))
};

declare function o:xslt-builder($rules as array(*)+, $options as map(*))
as map(*)
{
    map:merge((
        $options,            
        map:entry(
            $o:doc-handler-key,
            o:transformer($rules, $options)
        ),
        map:entry('type', 'builder')
    ))
};

declare %private function o:is-builder($builder as item()*)
as xs:boolean
{
    $builder instance of map(*) and $builder?type = 'builder'
};

(:~
 : Converts mu-nodes to XML nodes with the default name resolver.
 :)
declare function o:xml($nodes as item()*)
as node()*
{
    o:xml($nodes, map {})
};

(:~
 : Converts mu-nodes to XML nodes using a map of options. Currently it will
 : only use the option 'ns' whose value must be a namespace map and 'qname'
 : function that translates strings into QNames.
 :)
declare function o:xml($nodes as item()*, $builder as map(*))
as node()*
{
    let $builder :=
        if (map:contains($builder, 'ns')) then
            $builder
        else
            o:ns-builder($builder)
    let $builder :=
        if (map:contains($builder, 'qname')) then
            $builder
        else
            map:merge(($builder, map:entry('qname', o:qname-resolver($builder?ns))))
    return
        o:to-xml($nodes, $builder)
};

declare %private function o:to-xml($nodes as item()*, $builder as map(*))
as node()*
{
    $nodes ! (
        typeswitch (.)
        case array(*) return
            o:to-element(., $builder)
        case map(*) return
            error($o:err-unwellformed, "A map is only allowed preceded by an element tag.", .)
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

declare %private function o:to-element($element as array(*), $builder as map(*))
as item()*
{
    let $tag := o:tag($element)
    let $atts := o:attrs($element)
    let $content := o:children($element)
    where exists($tag)
    return
        if ($tag instance of xs:string) then
            element { $builder?qname($tag) } {
                (: add namespace :)
                (: TODO:REVIEW :)
                if ($builder?ns instance of map(*)) then
                    for $prefix in map:keys($builder?ns)
                    let $uri := $builder?ns($prefix)
                    where $prefix != '' and $uri != ''
                    return
                        namespace { $prefix } { $uri }
                else
                    ()
                ,
                o:to-attributes($atts, $builder),
                fold-left($content, (),
                    function($n, $i) {
                        ($n, o:to-xml($i, $builder))
                    }
                )
            }
        else
           error($o:err-unwellformed, 'Tag must be a string', $tag)
};

declare %private function o:to-attributes($atts as map(*), $builder as map(*))
as item()*
{
    map:for-each($atts,
        function($k, $v) {
            if ($k = $o:internal-att) then
                ()
            else
                let $value := 
                    typeswitch ($v)
                    case map(*) return
                        ()
                    case array(*) return
                        ()
                    case function(*) return
                        concat(function-name($v),'#',function-arity($v))
                    default return
                        data($v)
                where exists($value)
                return
                    attribute { o:qname($k, $builder) } {
                        $value
                    }
        }
    ),
    (: expand complex attribute values into elements :)
    map:for-each($atts,
        function($k, $v) {
            if ($k = $o:internal-att) then
                ()
            else
                typeswitch ($v)
                case array(*) return
                    o:to-element(
                        [$k, $v?*],
                        $builder
                    )
                case map(*) return
                    o:to-element(
                        [$k, $v], 
                        $builder
                    )
                default return
                    ()
        }
    )
};

declare %private function o:prepare-handler($handler as item())
{
    typeswitch ($handler)
    case array(*) return
        o:compile-handler(array:head($handler), array:tail($handler))
    case map(*) return
        error($o:err-invalid-handler, "A map is not a valid handler")
    case function(*) return
        o:compile-handler($handler, [])
    default return
        error($o:err-invalid-handler, "Unrecognized handler type")
};

(:~
 : Wrap handlers with in-place args and return a handler function.
 : Multiple calls to o:doc will not wrap already prepared handlers so it's
 : safe to call o:doc on an already processed document.
 :)
declare %private function o:compile-handler($handler as function(*), $args as array(*))
as function(*)
{
    if (o:is-handler($args)) then
        (: allow functions with arity > 2 only if a second arg handler is provided that returns an array (an adapter basically) :)
        (: TODO: put a stricter typecheck on the arg handler function. It must return an array for apply :)
        if (function-arity(array:head($args)) = 2) then
            function ($node as array(*), $data as item()*) {
                apply($handler, array:head($args)($node, $data)) }
        else
            error($o:err-invalid-handler, 
                'Argument handler must be of arity 2', $args)
    else
        switch (function-arity($handler))
        case 0 return
            function($node as array(*), $data as item()*) {
                $handler() }
        case 1 return
            function($node as array(*), $data as item()*) {
                $handler($node) }
        case 2 return
            if (array:size($args) = 0) then
                $handler
            else
                function($node as array(*), $data as item()*) {
                    $handler($node, ($args?*, $data)) }
        default return
            error($o:err-invalid-handler, 
                'Handlers with more than two arguments are not supported ', $handler)
};

(:
 : TODO:
 : - in order to fire multiple rules in same context we need to call apply templates in same mode
 : - we can add current mode on apply templates if there are no subrules.
 :)
declare function o:compile-rules($rules as array(*)+)
as map(*)*
{
    map:merge($rules ! o:compile-rule(., (), ()))
};

(: TODO: look at o:tag, o:attributes etc for ideas for cleaning this up :)
declare %private function o:compile-rule($rule as array(*), $context as xs:string*, $parent as map(*)?)
as item()*
{
    let $selectors := array:head($rule)
    let $selectors :=
        if ($selectors instance of xs:string+) then
            $selectors
        else
            error($o:err-invalid-rule, 'A rule must start with a string sequence', $rule)
    let $rule-selector := o:xpath($selectors)
    let $rule-id := o:rule-id(($context, $rule-selector))
    let $rule-mode := o:rule-id($context)
    let $tail := array:tail($rule)
    let $handler :=
        if (array:size($tail) > 0 and o:is-handler($tail?*[1])) then
            $tail?*[1]
        else
            ()
    let $op :=
        if (array:size($tail) = 0
            or (array:size($tail) > 0
                and not($tail?1 instance of empty-sequence()))) then
            'copy'
        else
            'remove'
    let $subrules :=
        if (array:size($tail) > 0
            and ($tail?1 instance of empty-sequence()
                 or exists($handler))) then
            array:tail($tail)?*
        else
            $tail?*
    let $compiled-rule :=
        map {
            'id': $rule-id,
            'match': $rule-selector,
            'context': $context, (: for dbg :)
            'mode': $rule-mode,
            'subrules': count($subrules),
            'nextmode': if (count($subrules) > 0) then $rule-id else $rule-mode,
            'nextop': if (count($subrules) > 0) then $op else ($parent?op,'remove')[1],
            'op': $op,
            'handler': $handler
        }
    return (
        map:entry($rule-id, $compiled-rule),
        for $subrule in $subrules
        where $subrule instance of array(*)
        return
            o:compile-rule($subrule, ($context, $rule-selector), $compiled-rule)
    )
};

declare %private function o:rule-id($paths as xs:string*)
as xs:string?
{
    if (exists($paths)) then
        concat('_', xs:hexBinary(hash:md5(string-join($paths, '//'))))
    else
        ()
};

(:~
 : Helper function to return only those rules that have subrules
 : and therefore need a set of identity transform templates added.
 :)
declare %private function o:context-rules($rules as map(*))
as map(*)*
{
    for $key in map:keys($rules)
    where $rules($key)?subrules > 0
    return
        $rules($key)
};

declare function o:compile-stylesheet($rules as map(*))
as element(*)
{
    o:compile-stylesheet($rules, map {})
};

declare function o:compile-stylesheet($rules as map(*), $namespaces as map(*))
as element(*)
{
    o:xml(
        ['stylesheet',
            o:xslt-preamble(),
            map:for-each($rules, o:xslt-rule-templates(?,?)),
            o:xslt-identity-transform(map { 'op': 'remove' }),
            for-each(o:context-rules($rules), o:xslt-identity-transform#1)
        ],
        o:ns((
            $namespaces,
            ['o', $o:ns?origami], 
            ['', 'http://www.w3.org/1999/XSL/Transform']
        ))
    )
};

declare %private function o:xslt-preamble()
as item()*
{
    map { 'version': '1.0' },
    ['output',
        map {
            'method': 'xml',
            'indent': 'no'
        }
    ],
    ['strip-space',
        map { 'elements': '*' }
    ],
    ['template',
        map { 'match': '/' },
        ['o:seq',
            ['apply-templates',
                ['with-param',
                    map { 'name': 'op' },
                    'remove'
                ]
            ]
        ]
    ]
};

declare %private function o:xslt-rule-templates($rule-id as xs:string, $rule as map(*))
as array(*)
{
    ['template', 
        map:merge((
            map:entry('match', $rule?match),
            if (exists($rule?context)) then
                map:entry('mode', $rule?mode)
            else
                ()
        )),
        if ($rule?op = 'copy') then (
            ['variable', 
                map { 'name': 'o:id' }, 
                $rule?id
            ],
            ['variable', 
                map { 'name': 'o:path' }, 
                string-join(($rule?context, $rule?match),' ')
            ],
            ['choose',
                ['when',
                    map { 'test': 'self::text()' },
                    o:xslt-copy-text-node($rule)
                ],
                ['when',
                    map { 'test': 'count(.|../@*)=count(../@*)' },
                    o:xslt-copy-attr-node($rule)
                ],
                ['when',
                    map { 'test': 'self::*' },
                    o:xslt-copy-element-node($rule)
                ]
            ])
        else (
            o:xslt-remove-nodes($rule)
        )
    ]
};

declare %private function o:xslt-remove-nodes($rule)
{
    ['apply-templates',
        map:merge((
            map:entry('select', 'node()|@*|text()'),
            if ($rule?nextmode) then 
                map:entry('mode', $rule?nextmode)
            else
                ()
        )),
        ['with-param',
            map { 'name': 'op' },
            'remove'
        ]
    ]
};

declare %private function o:xslt-copy-nodes($rule)
{
    ['apply-templates',
        map:merge((
            map:entry('select', 'node()|@*'),
            if ($rule?nextmode) then 
                map:entry('mode', $rule?nextmode)
            else
                ()
        )),
        ['with-param',
            map { 'name': 'op' },
            $rule?op
        ]
    ]
};

declare %private function o:xslt-copy-text-node($rule as map(*))
as array(*)
{
    ['o:text',
        o:xslt-origami-attrs(),
        ['value-of',
            map { 'select': '.' }
        ]
    ]
};

declare %private function o:xslt-copy-attr-node($rule as map(*))
as array(*)
{
    ['o:attribute', 
        map:merge((map { 'name': '{name(.)}' }, o:xslt-origami-attrs())),
        ['value-of', map { 'select': '.' }]
    ]
};

declare %private function o:xslt-copy-element-node($rule as map(*))
as array(*)
{
    ['copy', 
        ['attribute', map { 'name': 'o:id' }, ['value-of', map { 'select': '$o:id' }]],
        (: o:path attribute is not really needed but makes debugging easier :)
        ['attribute', map { 'name': 'o:path' }, ['value-of', map { 'select': '$o:path' }]],
        o:xslt-copy-nodes($rule)
    ]
};

declare %private function o:xslt-origami-attrs()
{
    map { 'o:id': '{$o:id}', 'o:path': '{$o:path}' }
};

declare %private function o:xslt-identity-transform($rule as map(*))
as array(*)*
{
    ['template',
        o:xslt-identity-template-attrs('processing-instruction()|comment()', $rule)
    ],
    ['template',
        o:xslt-identity-template-attrs('*|@*|text()', $rule),
        ['param',
            map { 'name': 'op' }
        ],
        ['choose',
            ['when',
                map { 'test': "$op = 'copy'" },
                ['copy',
                    ['apply-templates',
                        map:merge((
                            map:entry('select', '*|@*|text()'),
                            o:xslt-mode-attr($rule)
                        )),
                        ['with-param',
                            map { 'name': 'op', 'select': '$op' }
                        ]
                    ]
                ]
            ],
            ['otherwise',
                ['apply-templates',
                    map:merge((
                        map:entry('select', '*|@*|text()'),
                        o:xslt-mode-attr($rule)
                    )),
                    ['with-param',
                        map { 'name': 'op', 'select': '$op' }
                    ]
                ]
            ]
        ]
    ]
};

declare %private function o:xslt-mode-attr($rule as map(*))
as map(*)?
{
    let $mode-attr := map:entry('mode', $rule?nextmode)
    where $rule?nextmode
    return $mode-attr
};

declare %private function o:xslt-identity-template-attrs($match as xs:string, $rule as map(*))
{
    map:merge((
        map:entry('priority', -10),
        map:entry('match', $match),
        o:xslt-mode-attr($rule)
    ))
};

declare %private function o:xpath($exprs as xs:string+)
as xs:string?
{
    translate(string-join($exprs,'//'), "&quot;", "'")
};

(:~
 : Converts mu-nodes to JSON with the default name resolver.
 :)
declare function o:json($nodes as item()*)
as xs:string
{
    o:json($nodes, function($name) { $name })
};

(:~
 : Converts mu-nodes to JSON using a name-resolver.
 :)
declare function o:json($nodes as item()*, $name-resolver as function(*))
as xs:string
{
    serialize(
        o:to-json(
            if (count($nodes) > 1) then 
                array { $nodes } 
            else 
                $nodes, $name-resolver
        ),
        map { 'method': 'json' }
    )
};

declare %private function o:to-json($nodes as item()*, $name-resolver as function(*))
as item()*
{
    $nodes ! (
        typeswitch (.)
        case array(*) return
            let $tag := o:tag(.)
            let $atts := o:attributes(.)
            let $children := o:children(.)
            return
                map:entry(
                    $tag,
                    o:to-json(($atts, $children), $name-resolver)
                )
        case map(*) return
            map:merge(
                map:for-each(.,
                    function($a, $b) {
                        map:entry(
                            concat(o:handler-att, $a),
                            o:to-json($b, $name-resolver)
                        )
                    }
                )
            )
        case function(*) return
            ()
        (: TODO: I think this should be using to-json as well :)
        case node() return
            o:doc(.)
        default return
            .
    )
};

(: Node information :)

declare function o:head($node as array(*)?)
as item()?
{
    $node?*[1]
};

declare function o:tag($node as array(*)?)
as item()?
{
    $node?*[1]
};

declare function o:tail($node as array(*)?)
as item()*
{
    $node?*[position() > 1]
};

declare function o:children($node as array(*)?)
as item()*
{
    $node?*[position() > 1 and not(. instance of map(*))]
};

declare function o:handler($node as array(*)?)
{
    o:attrs($node)('@')
};

declare function o:attributes($node as array(*)?)
as map(*)?
{
    $node?*[2][. instance of map(*)]
};

(:~
 : Always returns a map even if element has no attributes.
 :)
declare function o:attrs($node as array(*)?)
as map(*)
{
    (o:attributes($node), map {})[1]
};

(:~
 : Outputs the text value of `$nodes`.
 :)
declare function o:text($nodes as item()*)
as xs:string?
{
    string-join(o:postwalk($nodes, o:children#1), '')
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function o:ntext($nodes as item()*)
as xs:string?
{
    normalize-space(o:text($nodes))
};

(:~
 : Returns the size of contents (child nodes not attributes).
 :)
declare function o:size($node as array(*)?)
as xs:integer
{
    count(o:children($node))
};


declare function o:is-text-node($node as item()?)
as xs:boolean
{
    not($node instance of function(*))
};

declare function o:is-element($node as item()?)
as xs:boolean
{
    o:is-element-or-handler($node) = true()
};

declare function o:is-handler($node as item()?)
as xs:boolean
{
    o:is-element-or-handler($node) != true()
};

(:~
 : Returns true if this is an element, false if this is a handler or 
 : nil if it is neither 
 :)
declare %private function o:is-element-or-handler($node as item()?)
as xs:boolean?
{
    typeswitch ($node)
    case array(*) return
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

declare function o:has-attr($node as item()?, $attr as xs:string)
as xs:boolean
{
    map:contains(o:attrs($node), $attr)
};

declare function o:has-attrs($node as item()?)
as xs:boolean
{
    map:size(o:attrs($node)) > 0
};

declare function o:has-handler($element as array(*))
as xs:boolean
{
    map:contains(o:attrs($element), $o:handler-att)
};

(: Node apply :)

declare function o:apply($nodes as item()*)
as item()*
{
    o:apply($nodes, [], ())
};

declare function o:apply($nodes as item()*, $data as item()*)
as item()*
{
    o:apply($nodes, [], $data)
};

declare function o:apply($nodes as item()*, $current as array(*), $data as item()*)
as item()*
{
    $nodes ! (
        typeswitch (.)
        case array(*) return o:apply-element(., $data)
        case map(*) return .
        case function(*) return o:apply-handler(., $current, $data)
        default return .
    )
};

declare %private function o:apply-rules($data as item()*)
as item()*
{
    o:apply(?, $data)
};

declare %private function o:apply-element($element as array(*), $data as item()*)
as item()*
{
    let $tag := o:tag($element)
    let $handler := o:attrs($element)($o:handler-att)
    let $atts := o:apply-attributes($element, $data)
    let $content := o:children($element)
    let $element := array { $tag, $atts, $content }
    return
        if (exists($handler)) then
            o:apply(o:apply-handler($handler, $element, $data), $data)
        else
            o:insert($element, o:apply($content, $element, $data))
};

declare %private function o:apply-attributes($element as array(*), $data as item()*)
as item()*
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
                                o:apply-handler($att-value, $element, $data)
                            default return
                                $att-value
                        )
                }
            )
        ))
    where map:size($atts) > 0
    return $atts
};

(: TODO: if @ handlers attached manually they may not be 2 arity :)
declare %private function o:apply-handler($handler as item(), $owner as array(*)?, $data as item()*)
as item()*
{
    switch (function-arity($handler))
    case 0 return
        $handler()
    case 1 return
        $handler($owner)
    case 2 return
        $handler($owner, $data)
    default return
        $handler
};

(:~
 : Node transformers.
 :)

(:~
 : Returns a function that composes the passed functions. All functions
 : have arity 1.
 : TODO: what about other arities?
 : TODO: in Clojure do evaluates in sequence, maybe use compose.
 :)
declare function o:comp($fns)
as function(item()*) as item()*
{
    function($input) {
        fold-left($fns, $input,
              function($args, $fn) {
                    $fn($args)
              }
        )
    }
};

(:~
 : Returns the argument unmodified.
 :)
declare function o:identity($x as item()*)
as item()*
{ 
    $x 
};

(:~
 : Returns a function that conjoins items to a sequence.
 : The type of sequence is determined by the type of the $seq
 : argument.
 :)
declare function o:conj($items as item()*)
as item()*
{
    o:conj(?, $items)
};

declare function o:conj($seq as item()*, $items as item()*)
as item()*
{
    typeswitch ($seq)
    case array(*) return
        array { $seq?*, $items }
    default return
        ($seq, $items)
};

(:~
 : Returns a function that transforms an array or map into a sequence.
 : A map item will be transformed into a sequence of two item arrays.
 :)
declare function o:seq()
as function(item()*) as item()*
{
    o:seq(?)
};

(:~
 : Transforms an array or map item into a sequence.
 :)
declare function o:seq($nodes as item()*)
as item()*
{
    if ($nodes instance of array(*)) then
        $nodes?*
    else if ($nodes instance of map(*)) then
        map:for-each($nodes, function($k, $v) { [$k, $v] })
    else
        $nodes
};

declare function o:for-each($nodes as item()*, $fn as function(item()) as item()*)
as item()*
{
    for-each($nodes, $fn)
};

declare function o:for-each($fn as function(item()) as item()*)
as item()*
{
    for-each(?, $fn)
};

declare function o:filter($nodes as item()*, $fn as function(item()) as xs:boolean)
as item()*
{
    filter($nodes, $fn)
};

declare function o:filter($fn as function(item()) as xs:boolean)
as item()*
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

declare function o:sort()
as function(item()*) as item()*
{
    sort(?)
};

(:~
 : Repeat the incoming nodes and feed them through the function.
 :)
declare function o:repeat($node as item()*, $repeat-seq as item()*, $fn as function(*))
as item()*
{
    o:repeat($repeat-seq, $fn)($node)
};

(:~
 : A node repeating function, also works with prepped node handlers 
 :)
declare function o:repeat($repeat-seq as item()*, $fn as function(*))
as function(item()*) as item()*
{
    let $arity := function-arity($fn)
    return
        function($node as item()*) {
            fold-left(
                $repeat-seq,
                (),
                function($n, $i) {
                    if ($arity = 2) then
                        ($n, $fn($node, $i))
                    else
                        (: assume the default arity = 1, otherwise let it crash :)
                        ($n, $fn($node))
                }
            )
        }
};

declare function o:repeat($repeat-seq as item()*)
as item()*
{
    o:repeat($repeat-seq, o:identity#1)
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
            function($node as item()) {
                $selector
            }
        default return
            ()
    return
        function($node as item()) {
            $selector($node) ! (
                typeswitch($choices(.))
                case $choice as array(*) | map(*) return
                    $choice
                case $choice as function(*) return
                    $choice($node)
                default $choice return
                    $choice
            )
        }
};

declare function o:choose($node as item(), $selector as item()*, $choices as function(*))
as item()*
{
    o:choose($selector, $choices)($node)
};

declare function o:select($steps as array(*))
as function(item()*) as item()*
{
    o:select(?, $steps)
};

declare function o:select($nodes as item()*, $steps as array(*))
as item()*
{
    for $node in $nodes
    where o:is-element($node) and array:size($steps) > 0
    let $step := array:head($steps)
    let $next-steps := array:tail($steps)
    return
        if (o:is-match($node, $step)) then
            if (array:size($next-steps) = 0) then
                $node
            else
                o:select(o:children($node), $next-steps)
        else
            o:select(o:children($node), $steps)         
};

declare %private function o:is-match($node as item(), $step)
as xs:boolean
{
    typeswitch ($step)
    case xs:string+ return
        o:tag($node) = $step
    default return
        false()
};

declare function o:tree-seq($nodes as item()*)
as item()*
{
    o:tree-seq($nodes, o:is-element#1, o:identity#1)
};

declare function o:tree-seq($nodes as item()*, $children as function(*))
as item()*
{
    o:tree-seq($nodes, o:is-element#1, $children)
};

declare function o:tree-seq($nodes as item()*, $is-branch as function(*), $children as function(*))
as item()*
{
    for $node in $nodes
    let $branch := $is-branch($node)
    return
        if ($branch) then
            ($children($node), o:tree-seq(o:children($node), $is-branch, $children))
        else
            $node
};

(: Return a function for flattening a sequence :)
declare function o:flatten()
as function(item()*) as item()*
{
    o:flatten(?)
};

(: Flatten returns a sequence of child nodes. No elements :)
declare function o:flatten($nodes as item()*)
as item()*
{
    o:postwalk($nodes, o:children#1)
};

(:~
 : Generic walker function (depth-first).
 :)
declare function o:postwalk($form as item()*, $fn as function(*))
as item()*
{
    $form ! (
        typeswitch (.)
        case array(*) return
            $fn(array {
                o:for-each(
                    $form?*,
                    o:postwalk(?, $fn)
                )
            })
        default return
            $form
    )
};

(:~
 : Generic walker function (breadth-first).
 :)
declare function o:prewalk($form as item()*, $fn as function(*))
as item()*
{
    $form ! (
        let $walked := $fn(.)
        return
            typeswitch ($walked)
            case array(*) return
                array {
                    o:for-each(
                        $walked?*,
                        function($n) {
                            if ($n instance of array(*)) then
                                o:prewalk($n, $fn)
                            else
                                $n
                        }
                    )
                }
            default return
                $walked
    )
};

declare function o:set-handler($element as array(*), $handler as function(*)?)
as array(*)
{
    o:set-handler($handler)($element)
};

declare function o:set-handler($handler as function(*)?)
as function(*)
{
    o:set-attrs(map { $o:handler-att: o:prepare-handler($handler) })
};

declare function o:remove-handler($element as array(*))
as array(*)
{
    o:remove-handler()($element)
};

(: TODO: verify function(*)? what when handler is ()? :)
declare function o:remove-handler()
as function(*)
{
    o:remove-attr($o:handler-att)
};

declare function o:set-attr-handlers($element as array(*), $handlers as map(xs:string, function(*)))
as array(*)
{
    array {
        o:tag($element),
        map:merge((
            map:for-each(
                o:attrs($element),
                function($name,$value) {
                    map:entry($name,
                        if (map:contains($handlers,$name)) then
                            o:prepare-handler($handlers($name))
                        else
                            $value
                    )
                }
            )
        )),
        o:children($element)
    }
};

declare function o:set-attr-handlers($handlers as map(xs:string, function(*)))
as function(*)
{
    o:set-attr-handlers(?, $handlers)
};

declare function o:remove-attr-handlers($element as array(*))
as array(*)
{
    let $attrs :=
        map:merge((
            map:for-each(
                o:attrs($element),
                function($name,$value) {
                    if (o:is-handler($value)) then
                        ()
                    else
                        map:entry($name,$value)
                }
            )
        ))
    return
        array {
            o:tag($element),
            if (map:size($attrs) > 0) then $attrs else (),
            o:children($element)
        }
};

declare function o:remove-attr-handlers()
as function(*)
{
    o:remove-attr-handlers(?)
};

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function o:insert($content as item()*)
as function(*)
{
    o:insert(?, $content)
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function o:insert($node as array(*), $content as item()*)
as item()*
{
    if (o:is-function($content)) then
        array { o:tag($node), o:attributes($node), $content($node) }
    else
        array { o:tag($node), o:attributes($node), $content }
};

declare function o:replace()
as function(*) {
    o:replace(?, ())
};

declare function o:replace($content as item()*)
as function(*) {
    o:replace(?, $content)
};

declare function o:replace($node as array(*), $content as item()*)
as item()*
{
    $content
};

declare function o:wrap($element as array(*)?)
as function(*)
{
    o:wrap(?, $element)
};

declare function o:wrap($nodes as item()*, $element as array(*)?)
as item()*
{
    if (exists($element)) then
        array { o:tag($element), o:attributes($element), $nodes }
    else
        $nodes
};

(:~
 : Create a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :)
declare function o:unwrap()
as function(item()*) as item()*
{
    o:unwrap(?)
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function o:unwrap($node as array(*))
as item()*
{
    o:children($node)
};

(:~
 : Copy nodes without any transformation.
 :)
declare function o:copy()
as function(item()*) as item()*
{
    o:copy(?)
};

declare function o:copy($node as item())
as item()*
{
    $node
};

(:~
 : Create a node transformer that inserts `$before` before
 : the nodes passed in.
 :)
declare function o:before($before as item()*)
as function(item()) as item()*
{
    o:before(?, $before)
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function o:before($node as item(), $before as item()*)
as item()*
{
    ($before, $node)
};

(:~
 : Create a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function o:after($after as item()*)
as function(item()) as item()*
{
    o:after(?, $after)
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function o:after($node as item(), $after as item()*)
as item()*
{
    ($node, $after)
};

(:~
 : Create a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function o:insert-after($append as item()*)
as function(array(*)) as array(*)
{
    o:insert-after(?, $append)
};

(:~
 : Inserts `$append` nodes to the child nodes of each element in
 : `$nodes`.
 :)
declare function o:insert-after($node as array(*), $append as item()*)
as array(*)
{
    array { 
        o:tag($node), 
        o:attributes($node), 
        o:children($node), 
        $append 
    }
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function o:insert-before($prepend as item()*)
as function(array(*)) as array(*)
{
    o:insert-before(?, $prepend)
};

(:~
 : Inserts `$prepend` nodes before the first child node of each element
 : in `$nodes`.
 :)
declare function o:insert-before($node as array(*), $prepend as item()*)
as array(*)
{
    array { 
        o:tag($node), 
        o:attributes($node), 
        $prepend, 
        o:children($node) 
    }
};

declare function o:set-attr($name as xs:string, $value as item()*)
as function(array(*)) as array(*)
{
    o:set-attr(?, $name, $value)
};

declare function o:set-attr($node as array(*), $name as xs:string, $value as item()*)
as array(*)
{
    array {
        o:tag($node),
        map:merge((o:attributes($node), map:entry($name, $value))),
        o:children($node)
    }
};

declare function o:advise-attr($name as xs:string, $value as item()*)
as function(array(*)) as array(*)
{
    o:advise-attr(?, $name, $value)
};

declare function o:advise-attr($node as array(*), $name as xs:string, $value as item()*)
as array(*)
{
    array {
        o:tag($node),
        map:merge((map:entry($name, $value), o:attributes($node))),
        o:children($node)
    }
};

(:~
 : Create a node transformer that sets attributes using a map
 : on each element in the nodes passed.
 :)
declare function o:set-attrs($attrs as map(*))
as function(array(*)) as array(*)
{
    o:set-attrs(?, $attrs)
};

(:~
 : Set attributes using a map on `$node`.
 :)
declare function o:set-attrs($node as array(*), $attrs as map(*))
as array(*)
{
    array {
        o:tag($node),
        map:merge((o:attributes($node), $attrs)),
        o:children($node)
    }
};

(:~
 : Set attributes that aren't already set on `$node`.
 :)
declare function o:advise-attrs($attrs as map(*))
as function(array(*)) as array(*)
{
    o:advise-attrs(?, $attrs)
};

declare function o:advise-attrs($node as array(*), $attrs as map(*))
as array(*)
{
    array {
        o:tag($node),
        map:merge((
            o:attributes($node),
            map:for-each(
                $attrs,
                function($k,$v) {
                    if (o:has-attr($node,$k)) then
                        ()
                    else
                        map:entry($k,$v)
                }
            )
        )),
        map:merge((o:attributes($node), $attrs)),
        o:children($node)
    }
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :)
declare function o:remove-attr($attr-names as xs:string*)
as function(array(*)) as array(*)
{
    o:remove-attr(?, $attr-names)
};

(:~
 : Remove attributes from each element in `$nodes`.
 :)
declare function o:remove-attr($node as array(*), $attr-names as xs:string*)
as array(*)
{
    let $attrs :=
        map:merge((
            map:for-each(o:attrs($node),
                function($k, $v) {
                    if ($k = $attr-names) then
                        ()
                    else
                        map:entry($k, $v)
                }
            )
        ))
    return
        array {
            o:tag($node),
            if (map:size($attrs) = 0) then
                ()
            else
                $attrs,
            o:children($node)
        }
};

declare function o:add-attr-token($attr as xs:string, $tokens as xs:string*)
as function(array(*)) as array(*)
{
    o:add-attr-token(?, $attr, $tokens)    
};

declare function o:add-attr-token($node as array(*), $attr as xs:string, $tokens as xs:string*)
as array(*)
{
    let $attrs := o:attrs($node)
    return
        array {
            o:tag($node),
            map:merge((
                $attrs,
                map:entry($attr,
                    string-join(
                        distinct-values(
                            tokenize(
                                string-join(($attrs($attr), $tokens), ' '), 
                                '\s+'
                            )
                        ), 
                        ' '
                    )
                )
            )),
            o:children($node)
        }    
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function o:add-class($class-names as xs:string*)
as function(array(*)) as array(*)
{
    o:add-attr-token(?, 'class', $class-names)
};

(:~
 : Add one or more `$names` to the class attribute of `$element`.
 : If it doesn't exist it is added.
 :)
declare function o:add-class($node as array(*), $class-names as xs:string*)
as array(*)
{
    o:add-attr-token($node, 'class', $class-names)
};

declare function o:remove-att-token($att as xs:string, $tokens as xs:string*)
as function(array(*)) as array(*)
{
    o:remove-att-token(?, $att, $tokens)
};

declare function o:remove-att-token($node as array(*), $att as xs:string, $tokens as xs:string*)
as array(*)
{
    let $attrs := o:attrs($node)
    let $tokens :=
        for $token in tokenize($attrs($att), '\s+')
        where not($token = $tokens)
        return $token
    let $attrs :=
        if (count($tokens) = 0) then
            map:remove($attrs, $att)
        else
            map:merge((
                $attrs,
                map:entry($att, string-join($tokens, ' '))
            ))
    return
        array {
            o:tag($node),
            if (map:size($attrs) = 0) then
                ()
            else
                $attrs,
            o:children($node)
        }    
};

(:~
 : Create a node transformer that removes one or more `$names` from the
 : class attribute. If the class attribute is empty after removing names it will
 : be removed from the element.
 :)

declare function o:remove-class($class-names as xs:string*)
as function(array(*)) as array(*)
{
    o:remove-att-token(?, 'class', $class-names)
};

(:~
 : Remove one or more `$names` from the class attribute of `$element`.
 : If the class attribute is empty after removing names it will be removed
 : from the element.
 :)
declare function o:remove-class($node as array(*), $class-names as xs:string*)
as array(*)
{
    o:remove-att-token($node, 'class', $class-names)
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
declare function o:rename($element-name as item())
as function(array(*)) as array(*)
{
    o:rename(?, $element-name)
};

(:~
 : Renames elements in `$nodes`.
 :)
declare function o:rename($node as array(*), $element-name as item())
as array(*)
{
    let $element-name :=
        if ($element-name instance of map(*)) then
            $element-name(o:tag($node))
        else
            $element-name
    return
        if (exists($element-name)) then
            array {
                $element-name,
                o:attributes($node),
                o:children($node)
            }
        else
            $node
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 :)
declare function o:xslt($stylesheet as item()*)
as function(item()*) as item()*
{
    o:xslt(?, $stylesheet, map {})
};

declare function o:xslt($stylesheet as item()*, $params as map(*))
as function(item()* ) as item()*
{
    o:xslt(?, $stylesheet, $params)
};

(:~
 : Transform nodes using XSLT stylesheet.
 :)
declare function o:xslt($nodes as item()*, $stylesheet as item()*, $params as map(*))
as item()*
{
    if (exists($stylesheet)) then
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
                    error($o:err-xslt,
                        'Error [' || $err:code || ']: '
                        || $err:description
                        || '&#xa;'
                        || serialize($stylesheet))
                }
        )
    else
        ()
};

(: Namespace support :)

(:~
 : Returns a QName in "no namespace".
 : Throws a dynamic error FOCA0002 with a prefixed name.
 :)
declare function o:qname($name as xs:string)
as xs:QName
{
    o:qname($name, map {})
};

(:~
 : Returns a QName from a string taking the namespace URI from the
 : namespace map passed as it's second argument.
 : Throws a dynamic error FOCA0002 with a name which is not in correct lexical form.
 : Returns a QName in a made-up namespace URI if the prefix is not defined in the
 : namespace map.
 :)
declare function o:qname($name as xs:string, $resolver as item())
as xs:QName
{
    if ($resolver instance of map(*)) then
        if (contains($name, ':')) then
            let $prefix := substring-before($name, ':')
            let $local := substring-after($name, ':')
            let $default-ns := $resolver('')
            let $ns := ($resolver($prefix), concat('urn:x-prefix:', $prefix))[1]
            return
                if ($ns = $default-ns) then
                    QName($ns, $local)
                else
                    QName($ns, $name)
        else
            if (map:contains($resolver, '')) then
                QName($resolver(''), $name)
            else
                QName((), $name)
    else if ($resolver instance of function(*) and not($resolver instance of array(*))) then
        $resolver($name)
    else
        error($o:err-invalid-argument, "Invalid QName resolver")
};

(:~
 : Returns a QName resolver function from the namespace map passed as it's argument.
 :)
declare function o:qname-resolver($resolver as item())
as function(xs:string) as xs:QName
{
    typeswitch ($resolver)
    case map(*) return
        o:qname(?, $resolver)
    case array(*) return
        o:qname(?)
    case function(*) return
        o:qname(?, $resolver)
    case node() return
        o:qname(?, o:ns($resolver))
    default return
        o:qname(?)
};

(:~
 : Resolve a name using the resolver function (may be a map). If the resolver
 : returns the empty sequence this will return the original name.
 :)
declare function o:name($name as xs:string, $resolver as function(xs:string) as xs:string?)
as xs:string
{
    ($resolver($name), $name)[1]
};

(:~
 : Returns a name resolver function from the namespace map passed as it's argument.
 :)
declare function o:name-resolver($resolver as function(xs:string) as xs:string?)
as function(xs:string) as xs:string
{
    o:name(?, $resolver)
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
declare function o:ns($namespaces as item()*)
as map(*)
{
    fold-left(
        $namespaces,
        map {},
        function ($ns-map, $arg) {
            typeswitch ($arg)
            case map(*) return
                map:merge(($ns-map, $arg))
            case array(*) return
                if (array:size($arg) = 2) then
                    map:merge(($ns-map, map:entry($arg(1), $arg(2)))) 
                else
                    error($o:err-invalid-argument, 'Namespace binding requires two array elements [$prefix,$uri]')
            case node() return
                map:merge(($ns-map,
                    for $node in reverse($arg/descendant-or-self::*)
                    let $qname := node-name($node)
                    return (
                        for $att in $node/@*
                        let $qname := node-name($att)
                        return
                            map:entry(
                                (prefix-from-QName($qname), '')[1], 
                                namespace-uri-from-QName($qname)
                            ),
                        map:entry(
                            (prefix-from-QName($qname), '')[1], 
                            namespace-uri-from-QName($qname)
                        )
                    )
                ))
            default return
                error($o:err-invalid-argument, "Invalid namespace map argument")        
        }
    )
};

declare function o:ns-builder($namespaces as item()*)
as map(*)
{
    o:ns-builder(o:builder(), $namespaces)
};

declare function o:ns-builder($builder as map(*), $namespaces as item()*)
as map(*)
{
    let $ns := o:ns($namespaces)
    return
        map:merge((
            $builder,
            map:entry('ns', $ns),
            map:entry('qname', o:qname-resolver($ns))
        ))
};

declare %private function o:handler-repr($h as item())
as item()
{
    if ($h instance of array(*)) then
        array { o:function-repr(array:head($h)), array:tail($h)?* }
    else
        o:function-repr($h)
};

declare %private function o:function-repr($fn as function(*))
as xs:string
{
    concat((function-name($fn),'fn#')[1], function-arity($fn))
};

(:~
 : Renders a representation of a document where all functions
 : are shown with a string representation.
 : This can be used for inspection and in tests. Function items
 : cannot be atomized or compared.
 :)
declare function o:repr($nodes as item()*)
as item()*
{
    o:prewalk(
        $nodes,
        function($n) {
            if (o:is-handler($n)) then
                o:handler-repr($n)
            else
                let $tag := o:tag($n)
                let $attrs := o:attributes($n)
                let $attrs :=
                    if (exists($attrs)) then
                        map:merge((
                            map:for-each(
                                o:attrs($n),
                                function($k,$v) {
                                    if (o:is-handler($v)) then
                                        map:entry($k, o:handler-repr($v))
                                    else
                                        map:entry($k, $v)
                                }
                            )
                        ))
                    else
                        ()
                let $children := o:children($n)
                return
                    [
                        $tag,
                        $attrs,
                        (: need to get repr of inline functions which are not visited by walker :)
                        for $child in $children
                        return
                            if (o:is-handler($child)) then
                                o:handler-repr($child)
                            else
                                $child
                    ]
        }
    )
};

(:~
 : Extract some entries from a map into a new map.
 :)
declare function o:select-keys($map as map(*), $keys as xs:anyAtomicType*)
as map(*)
{
    map:merge((
        for $k in map:keys($map)
        where $k = $keys
        return map:entry($k, $map($k))
    ))
};

(:~
 : Predicate function, returns true if the item is a real function.
 :)
declare %private function o:is-function($item as item()*)
{
    $item instance of function(*) and 
        not($item instance of map(*) or $item instance of array(*))
};
