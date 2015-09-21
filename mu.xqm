xquery version "3.1";
module namespace μ = 'http://xokomola.com/xquery/origami/mu';

declare variable $μ:e := xs:QName('μ:element');
declare variable $μ:d := xs:QName('μ:data');

declare %private variable $μ:ns := μ:ns();
declare %private variable $μ:handler-att := '@';
declare %private variable $μ:data-att := '!';

(:~
 : Origami μ-documents
 :)
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
    case element() return
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
                        then map:entry($μ:handler-att, $rules($path))
                        else ()
                ))
            else (),
            $item/node() ! μ:doc-node(., $rules)
        }
    case array(*) return
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
        case node() return .
        default return text { . }
    )
};

(: TODO: need more common map manipulation functions :)
(: TODO: change ns handling to using a map to construct them at the top (sane namespaces) :)
(: TODO: in mu we should not get xmlns attributes so change μ:doc to take them off :)
declare %private function μ:to-element($element as array(*), $name-resolver as function(*), $options)
as item()*
{
    let $tag := μ:tag($element)
    let $atts := μ:attrs($element)
    let $content := μ:content($element)
    where $tag
    return
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

(: TODO: we need an option for attribute serialization :)
(: NOTE: another reason why we should avoid names with :, conversion to json is easier? Maybe also makes JSON-LD easier :)
declare %private function μ:to-attributes($atts as map(*), $name-resolver as function(*))
as attribute()*
{
    map:for-each($atts,
        function($k,$v) {
            if ($k = ($μ:handler-att, $μ:data-att)) 
            then ()
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
        μ:to-json(if (count($mu) > 1) then array { $mu } else $mu, $name-resolver),
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
declare function μ:head($element as array(*)?)
as item()*
{
    if (exists($element)) then array:head($element) else ()
};

declare function μ:tail($element as array(*)?)
as item()*
{
    tail($element?*)
};

declare function μ:tag($element as array(*)?)
as xs:string?
{
    if (empty($element)) then () else array:head($element)
};

declare function μ:content($element as array(*)?)
as item()*
{
    if (array:size($element) > 0) then
        let $c := array:tail($element)
        return
            if (array:size($c) > 0 and array:head($c) instance of map(*))
            then array:tail($c)?*
            else $c?*
    else ()
};

declare function μ:attributes($element as array(*)?)
as map(*)?
{
    if ($element instance of array(*) and array:size($element) > 1 and $element?2 instance of map(*))
    then $element?2
    else ()
};

(:~
 : Always returns a map even if element has no attributes.
 :
 : Note that for access to attributes in handlers using the lookup operator (?)
 : you can use both μ:attrs($e)?foo as well as μ:attributes($e)?foo because
 : ()?foo will work just like map{}?foo.
 :)
declare function μ:attrs($element as array(*)?)
as map(*)
{
    (μ:attributes($element), map {})[1]
};

(:~
 : Returns the size of contents (child nodes not attributes).
 :)
declare function μ:size($element as array(*)?)
as item()*
{
    count(μ:content($element))
};

declare function μ:apply($nodes as item()*)
{
    $nodes ! (
        if (μ:is-element(.))
        then μ:apply-element(.)
        else
            if (μ:is-handler(.))
            then μ:apply-handler(., ())
            else .
    )
};

declare function μ:apply($nodes as item()*, $args as item()*)
as item()*
{
    $nodes ! (
        if (μ:is-element(.))
        then μ:apply-element(. => μ:set-data($args))
        else
            if (μ:is-handler(.))
            then μ:apply-handler(., ())
            else .
    )
};

declare function μ:apply-children($current-element as array(*)?, $nodes as item()*)
as item()*
{
    μ:apply-children($current-element, $nodes, ())
};

declare function μ:apply-children($current-element as array(*)?, $nodes as item()*, $args as item()*)
as item()*
{
    $nodes ! (
        if (μ:is-element(.))
        then μ:apply-element(. => μ:set-data(if (empty($args)) then μ:data($current-element) else $args))
        else
            if (μ:is-handler(.))
            then μ:apply-handler(., $current-element)
            else .
    )
};

declare function μ:apply-element($element as array(*))
{
    let $args := μ:data($element)
    let $tag := μ:tag($element)
    let $handler := μ:element-handler($element)
    let $atts := μ:apply-attributes($element, $args)
    return
        if (μ:is-handler($handler))
        then μ:apply-handler($handler, array { $tag, $atts, μ:content($element)})
        else array { $tag, $atts, μ:apply-children($element, μ:content($element), $args) }
};

declare function μ:apply-attributes($element as array(*), $args as item()*)
{
    let $atts :=
        map:merge((
            map:for-each(
                μ:attrs($element),
                function($att-name, $att-value) {
                    if ($att-name = $μ:handler-att)
                    then ()
                    else
                        map:entry(
                            $att-name,
                            if (μ:is-handler($att-value))
                            then μ:apply-handler($att-value, $element)
                            else $att-value
                        )
                }
            )
        ))
    where map:size($atts) > 0
    return $atts
};

declare function μ:is-handler($node as item()*)
{
    $node instance of function(*)
        and not($node instance of array(*))
        and not($node instance of map(*))
        
    or 
    
    $node instance of array(*)
        and array:size($node) > 0
        and array:head($node) instance of function(*)
        and not(array:head($node) instance of array(*))
        and not(array:head($node) instance of map(*))
};

declare function μ:is-element($node as item()*)
{
    $node instance of array(*)
        and array:size($node) > 0
        and array:head($node) instance of xs:string
};

declare function μ:element-handler($element as array(*))
{
    if (array:size($element) > 1 and $element(2) instance of map(*))
    then $element(2)($μ:handler-att)
    else ()
};

declare function μ:apply-handler($handler as array(*))
{
    μ:apply-handler($handler, ())
};

declare function μ:apply-handler($handler as item(), $element as array(*)?)
{
    typeswitch ($handler)
    case array(*)
    return apply(array:head($handler), μ:handler-args($handler, $element))
    case map(*)
    return $handler
    case function(*)
    return apply($handler, [$element])
    default
    return $handler
};

declare function μ:handler-args($handler as array(*), $element as array(*)?)
as array(*)
{
    let $args := array:tail($handler)
    return
        if (array:size($args) = 0) 
        then [$element]
        else array:join(([$element], $args))
};

(: μ-node transformers :)
declare function μ:identity($x) { $x };

(:~
 : Returns a sequence even if the argument is an array.
 : TODO: should this also flatten maps into a seq?
 :)
declare function μ:seq($x as item()*)
{
    if ($x instance of array(*)) then
        $x?*
    else if ($x instance of map(*)) then
        map:for-each($x, function($k,$v) { ($k,$v) })
    else $x
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

declare function μ:has-handler($element as array(*))
as xs:boolean
{
    map:contains(μ:attrs($element), $μ:handler-att)
};

declare function μ:handler($element as array(*))
{
    μ:attrs($element)($μ:handler-att)
};

declare function μ:set-handler($handler as array(*)?)
as function(*)
{
    function($element as array(*)) {
        array {
            μ:tag($element),
            map:merge((μ:attrs($element), map { $μ:handler-att: $handler })),
            μ:content($element)
        }
    }
};

declare function μ:data($element as array(*)?)
{
    μ:attrs($element)($μ:data-att)
};

declare function μ:set-data($element as array(*), $data as item()*)
as function(*)
{
    μ:set-data($data)($element)
};

declare function μ:set-data($data as item()*)
as function(*)
{
    function($element as array(*)) {
        array {
            μ:tag($element),
            map:merge((μ:attrs($element), map { $μ:data-att: $data })),
            μ:content($element)
        }
    }
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function μ:set-handler($element as array(*), $handler as array(*)?)
as array(*)
{
    μ:set-handler($handler)($element)
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
    function($element as array(*)) {
        let $atts :=
            map:merge((
                map:for-each(μ:attrs($element),
                    function($k,$v) {
                        if ($k = $remove-atts) then () else map:entry($k,$v)
                    }
                )
            ))
        return
            array {
                μ:tag($element),
                if (map:size($atts) = 0) then () else $atts,
                μ:content($element)
            }
    }
};

(:~
 : Remove attributes from each element in `$nodes`.
 :)
declare function μ:remove-attr($element as array(*), $names as item()*)
as item()*
{
    μ:remove-attr($names)($element)
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function μ:add-class($names as xs:string*)
as function(item()*) as item()*
{
    function($element as array(*)) {
        let $atts := μ:attrs($element)
        return
            array {
                μ:tag($element),
                map:merge((
                    $atts,
                    map:entry('class',
                        string-join(
                            distinct-values(
                                tokenize(
                                    string-join(($atts?class,$names),' '), '\s+')), ' ')
                    )
                )),
                μ:content($element)
            }
    }
};

(:~
 : Add one or more `$names` to the class attribute of `$element`.
 : If it doesn't exist it is added.
 :)
declare function μ:add-class($element as array(*), $names as xs:string*)
as item()*
{
    μ:add-class($names)($element)
};

(:~
 : Create a node transformer that removes one or more `$names` from the
 : class attribute. If the class attribute is empty after removing names it will
 : be removed from the element.
 :)

declare function μ:remove-class($names as xs:string*)
as function(item()*) as item()*
{
   function($element as array(*)) {
        let $atts := μ:attrs($element)
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
                μ:tag($element),
                if (map:size($new-atts) = 0) then () else $new-atts,
                μ:content($element)
            }
    }
};

(:~
 : Remove one or more `$names` from the class attribute of `$element`.
 : If the class attribute is empty after removing names it will be removed
 : from the element.
 :)
declare function μ:remove-class($element as array(*), $names as xs:string*)
as item()*
{
    μ:remove-class($names)($element)
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