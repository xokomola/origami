xquery version "3.1";

(:~ Origami μ-templates :)

(: TODO: add XML serialization options :)
(: TODO: add default element namespace :)
(: TODO: add option to move all ns declarations at document element (sane namespaces) !? :)
(: TODO: add ways to configure how names are mapped to qnames (e.g. define a mapping a la JSON-LD) :)
(: TODO: better json serialization :)
(: TODO: remove args from :xml :)
(: TODO: can we scan $items for function items and if so return a function automatically? :)

module namespace μ = 'http://xokomola.com/xquery/origami/μ';

declare function μ:xml-template($items as item()*)
{
    function($ctx) {
        μ:xml(
            $items,
            if ($ctx instance of array(*)) then $ctx 
            else array { $ctx })
    }
};

declare function μ:json-template($items as item()*)
{
    function($ctx) {
        μ:json(
            $items,
            if ($ctx instance of array(*)) then $ctx 
            else array { $ctx })
    }
};

declare function μ:xml($items as item()*)
{
    μ:xml($items, μ:ns(), [])
};

declare function μ:xml($items as item()*, $ctx as item()) 
as node()*
{
    let $args :=
        typeswitch ($ctx)
        case array(*)
        return $ctx
        case map(*)
        return if (map:contains($ctx, 'args')) then $ctx('args') else []
        default
        return array { $ctx }
    let $ns-map :=
        typeswitch ($ctx)
        case array(*)
        return μ:ns()
        case map(*)
        return  if (map:contains($ctx, 'ns')) then μ:ns($ctx('ns')) else μ:ns($ctx)
        default
        return μ:ns()
    return
        μ:xml($items, $ns-map, $args)
};

declare function μ:xml($items as item()*, $ns-map as map(*), $args as array(*)) 
as node()*
{
    μ:to-xml($items, map { 'ns': $ns-map, 'args': $args, 'xmlns': 'http://www.w3.org/1999/xhtml' })
};

declare function μ:json($items as item()*)
{
    μ:json($items, [])
};

declare function μ:json($items as item()*, $ctx as array(*)) 
{
    serialize(μ:to-json(if (count($items) gt 1) then array { $items } else $items, $ctx), map { 'method': 'json' })
};

declare function μ:mu($xml)
{
    μ:from-xml($xml)
};

(: Utility functions :)

declare function μ:ns()
{
    μ:ns(map {})
};

declare function μ:ns($ns-map as map(*))
{
    let $default-ns-map :=
        map {
            'μ': 'http://xokomola.com/xquery/origami/μ',
            'h': 'http://www.w3.org/1999/xhtml',
            'atom': 'http://www.w3.org/2005/Atom',
            'app': 'http://www.w3.org/2007/app',
            'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'rdfs': 'http://www.w3.org/2000/01/rdf-schema#',
            'svg': 'http://www.w3.org/2000/svg',
            'fo': 'http://www.w3.org/1999/XSL/Format',
            'xsl': 'http://www.w3.org/1999/XSL/Transform',
            'xsd': 'http://www.w3.org/2001/XMLSchema',
            'xsi': 'http://www.w3.org/2001/XMLSchema-instance',
            'xlink': 'http://www.w3.org/1999/xlink'
        }
    return
        if (empty($ns-map)) then
            $default-ns-map
        else
            map:merge(($default-ns-map, $ns-map))
};

declare function μ:cons($a,$b) {
    ($a,$b)
};

declare function μ:head($mu as array(*)?)
{
    if (empty($mu)) then
        ()
    else
        array:head($mu)
};

declare function μ:tail($mu as array(*)?)
as array(*)*
{
    if (not(empty($mu))) then
        tail(μ:seq($mu))
    else
        ()
};

(:~ 
 : Remove level of array and change it into a normal sequence.
 :)
declare function μ:seq($mu as array(*))
{
    typeswitch ($mu)
        case array(*)
            return array:fold-left($mu, (), μ:cons#2)
        default
            return $mu
};

declare function μ:content($mu)
{
    typeswitch($mu)
    case array(*)
    return
        let $c := array:tail($mu)
        return
            if (array:head($c) instance of map(*)) then
                array:tail($c)
            else
                $c
    default 
    return $mu/node()
};

declare %private function μ:to-json($items as item()*, $ctx as array(*)) 
{
    for $item in $items
    return
        typeswitch ($item)
        case array(*)
        return 
            array:fold-left($item, [], 
                function($a,$b) {
                    if (count($b) gt 1) then
                        (: splice the sequence into the array to avoid JSON 
                         : serialization error :)
                        array:join((
                            $a, 
                            fold-left($b, [], 
                                function($c,$d) { 
                                    array:append($c, μ:to-json($d, $ctx))
                                })
                        ))
                    else
                        array:append($a, μ:to-json($b, $ctx))
                }
            )
        case map(*)
        return 
            map:merge(
                map:for-each($item, 
                    function($a,$b) { 
                        map:entry($a, μ:to-json($b, $ctx)) }))
        case function(*) return μ:to-json(apply($item, $ctx), $ctx)
        case node() return μ:from-xml($item)
        default return $item
};

declare %private function μ:from-xml($xml)
{
    for $node in $xml
    return
        typeswitch($node)
        case element()
        return
            array { 
                name($node), 
                if ($node/@*) then 
                    map:merge((
                        for $a in $node/@* 
                        return map:entry(name($a), data($a))))
                else
                    (),
                μ:from-xml($node/node())
            }
        case comment() | processing-instruction() return ()
        default return string($node)
};

declare %private function μ:to-xml($items as item()*, $ctx as map(*))
{
    for $item in $items
    return
        typeswitch ($item)
        case array(*) return μ:to-element($item, $ctx)   
        case map(*) return  μ:to-attributes($item, $ctx)
        case function(*) return μ:to-xml(apply($item, $ctx('args')), $ctx)
        case empty-sequence() return ()
        case node() return $item
        default return text { $item }
};

declare %private function μ:to-element($item as array(*), $ctx as map(*))
as element()?
{
    if (array:size($item) gt 0) then
        element { μ:qname(array:head($item), $ctx('ns'),
                    if (map:contains($ctx,'xmlns')) then $ctx('xmlns') else () 
                  ) } {
            array:fold-left(
                array:tail($item),
                (),
                function($n, $i) {
                    ($n, μ:to-xml($i, $ctx))
                }
            )
        }
    else
        ()
};

declare %private function μ:to-attributes($item as map(*), $ctx as map(*))
as attribute()*
{
    map:for-each($item, 
        function($k,$v) {
            if (not(starts-with($k,'μ:'))) then
                attribute { μ:qname($k, $ctx('ns')) } { 
                    data(
                        typeswitch ($v)
                        case function(*)
                        return apply($v, $ctx('args'))
                        default
                        return $v
                    ) }
            else
                ()
        })
};

(:~
 : As XQuery doesn't allow access to namespace nodes (as XSLT does)
 : construct them indirectly via QName#2.
 :)
declare %private function μ:qname($name, $ns-map)
{
    μ:qname($name, $ns-map, ())
};

declare %private function μ:qname($name, $ns-map, $default-ns as xs:string*)
{
    if (contains($name, ':')) then
        let $prefix := substring-before($name,':')
        let $local := substring-after($name, ':')
        let $ns := $ns-map($prefix)
        return
            (: TODO: implement default element namespace in render options :)
            if ($ns = $default-ns) then
                QName($ns, $local)
            else
                QName($ns, concat($prefix,':',$local))
    else
        let $ns := $ns-map('')
        return
            if (not(empty($ns))) then
                QName($ns, $name)
            else
                $name
};
