xquery version "3.1";

(:~ 
 : Origami μ-templates 
 :)

module namespace μ = 'http://xokomola.com/xquery/origami/μ';

declare function μ:xml($items as item()*)
as node()*
{
    μ:to-xml($items, μ:qname-resolver())
};

declare function μ:xml($items as item()*, $name-resolver as function(*)) 
as node()*
{
    μ:to-xml($items, $name-resolver)
};

declare function μ:json($items as item()*)
as xs:string
{
    μ:json($items, function($name) { $name })
};

declare function μ:json($items as item()*, $name-resolver as function(*)) 
as xs:string
{
    serialize(
        μ:to-json(if (count($items) gt 1) then array { $items } else $items, $name-resolver), 
        map { 'method': 'json' }
    )
};

declare function μ:apply($items as item()*)
as item()*
{
    μ:apply($items, [])
};

declare function μ:apply($items as item()*, $args as item()*) 
as item()*
{
    let $args := if ($args instance of array(*)) then $args else [ $args ]
    for $item in $items
    return
        μ:to-apply($item, $args)
};

declare %private function μ:to-apply($item as item(), $args as array(*)) 
as item()*
{
    typeswitch ($item)
    case array(*) 
    return
        let $name := array:head($item)
        return
            if (empty($name)) then
                for $item in μ:seq(array:tail($item)) return μ:to-apply($item, $args)    
            else
                array:fold-left($item, [], 
                    function($a,$b) {
                        if (empty($b)) then
                            $a
                        else
                            array:append($a, for $item in $b return μ:to-apply($item, $args))
                    }
                )
    case map(*) 
    return
        map:for-each($item, 
            function($k,$v) {
                typeswitch ($v)
                case function(*)
                return map:entry($k, apply($v, $args))
                default
                return $v
            }
        )
    case function(*) 
    return for $item in apply($item, $args) return μ:to-apply($item, $args)
    default return $item
};

declare function μ:mu($xml)
as item()*
{
    μ:from-xml($xml)
};

declare %private function μ:to-json($items as item()*, $name-resolver as function(*))
as item()*
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
                                    array:append($c, μ:to-json($d, $name-resolver))
                                })
                        ))
                    else
                        array:append($a, μ:to-json($b, $name-resolver))
                }
            )
        case map(*)
        return 
            map:merge(
                map:for-each($item, 
                    function($a,$b) { 
                        map:entry($a, μ:to-json($b, $name-resolver)) }))
        case function(*) return ()
        case node() return μ:from-xml($item)
        default return $item
};

declare %private function μ:from-xml($xml)
as item()*
{
    for $node in $xml
    return
        typeswitch($node)
        case array(*)
        return
            array:fold-left($node, [],
                function($a,$b) { array:append($a, μ:from-xml($b)) }
            )
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
        case text() return string($node)
        default return $node
};

declare %private function μ:to-xml($items as item()*, $name-resolver as function(*))
as node()*
{
    for $item in $items
    return
        typeswitch ($item)
        case array(*) return μ:to-element($item, $name-resolver)   
        case map(*) return  μ:to-attributes($item, $name-resolver)
        case function(*) return ()
        case empty-sequence() return ()
        case node() return $item
        default return text { $item }
};

declare %private function μ:to-element($item as array(*), $name-resolver as function(*))
as item()*
{
    if (array:size($item) gt 0) then
        let $name := array:head($item)
        return
            if (empty($name)) then
                array:fold-left(
                    array:tail($item),
                    (),
                    function($n, $i) {
                        ($n, μ:to-xml($i, $name-resolver))
                    }
                )
            else
                element { $name-resolver($name) } {
                    array:fold-left(
                        array:tail($item),
                        (),
                        function($n, $i) {
                            ($n, μ:to-xml($i, $name-resolver))
                        }
                    )
                }
    else
        ()
};

declare %private function μ:to-attributes($item as map(*), $name-resolver as function(*))
as attribute()*
{
    map:for-each($item, 
        function($k,$v) {
            if (not(starts-with($k,'μ:'))) then
                attribute { $name-resolver($k) } { 
                    data(
                        typeswitch ($v)
                        case array(*) return $v
                        case map(*) return $v
                        case function(*) return ()
                        default return $v
                    )
                }
            else
                ()
        })
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
declare function μ:qname($name as xs:string, $ns-map as map(*))
as xs:QName
{
    μ:qname($name, $ns-map, ())
};

declare function μ:qname($name as xs:string, $ns-map as map(*), $default-ns as xs:string?)
as xs:QName
{
    if (contains($name, ':')) then
        let $prefix := substring-before($name,':')
        let $local := substring-after($name, ':')
        let $ns := $ns-map($prefix)
        return
            if ($ns = $default-ns) then
                QName($ns, $local)
            else
                QName($ns, concat($prefix,':',$local))
    else
        if ($default-ns) then
            QName($default-ns, $name)
        else
            QName((), $name)
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

declare function μ:mixed($nodes) 
as array(*)
{
    [(), $nodes]
};

declare function μ:head($mu as array(*)?)
as item()*
{
    if (empty($mu)) then
        ()
    else
        array:head($mu)
};

declare function μ:tail($mu as array(*)?)
as item()*
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
as item()*
{
    typeswitch ($mu)
        case array(*)
            return array:fold-left($mu, (), function($a,$b) { ($a,$b) })
        default
            return $mu
};

declare function μ:content($mu)
as item()*
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
