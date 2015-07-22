xquery version "3.1";

(:~ 
 : Origami μ-templates 
 :)

module namespace μ = 'http://xokomola.com/xquery/origami/μ';

declare function μ:xml($mu as item()*)
as node()*
{
    μ:to-xml($mu, μ:qname-resolver())
};

declare function μ:xml($mu as item()*, $name-resolver as function(*)) 
as node()*
{
    μ:to-xml($mu, $name-resolver)
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

declare function μ:apply($mu as item()*)
as item()*
{
    μ:apply($mu, [])
};

declare function μ:apply($mu as item()*, $args as item()*) 
as item()*
{
    let $args := if ($args instance of array(*)) then $args else [ $args ]
    for $item in $mu
    return
        μ:to-apply($item, $args)
};

declare function μ:to-apply($mu as item(), $args as array(*)) 
as item()*
{
    typeswitch ($mu)
    case array(*) 
    return
        let $name := array:head($mu)
        return
            if (empty($name)) then
                for $item in μ:seq(array:tail($mu)) return μ:to-apply($item, $args)    
            else
                array:fold-left($mu, [], 
                    function($a,$b) {
                        if (empty($b)) then
                            $a
                        else
                            array:append($a, for $item in $b return μ:to-apply($item, $args))
                    }
                )
    case map(*) 
    return
        map:for-each($mu, 
            function($k,$v) {
                typeswitch ($v)
                case function(*)
                return map:entry($k, apply($v, $args))
                default
                return $v
            }
        )
    case function(*) 
    return for $item in apply($mu, $args) return μ:to-apply($item, $args)
    default return $mu
};

declare function μ:mu($xml)
as item()*
{
    μ:from-xml($xml)
};

declare function μ:to-json($mu as item()*, $name-resolver as function(*))
as item()*
{
    for $item in $mu
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
        (: FIXME: I think this should be using to-json as well :)
        case node() return μ:from-xml($item)
        default return $item
};

declare function μ:from-xml($xml)
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

declare function μ:to-xml($mu as item()*, $name-resolver as function(*))
as node()*
{
    for $item in $mu
    return
        typeswitch ($item)
        case array(*) return μ:to-element($item, $name-resolver)   
        case map(*) return  μ:to-attributes($item, $name-resolver)
        case function(*) return ()
        case empty-sequence() return ()
        case node() return $item
        default return text { $item }
};

declare function μ:to-element($mu as array(*), $name-resolver as function(*))
as item()*
{
    if (array:size($mu) gt 0) then
        let $name := array:head($mu)
        return
            if (empty($name)) then
                array:fold-left(
                    array:tail($mu),
                    (),
                    function($n, $i) {
                        ($n, μ:to-xml($i, $name-resolver))
                    }
                )
            else
                element { $name-resolver($name) } {
                    array:fold-left(
                        array:tail($mu),
                        (),
                        function($n, $i) {
                            ($n, μ:to-xml($i, $name-resolver))
                        }
                    )
                }
    else
        ()
};

declare function μ:to-attributes($mu as map(*), $name-resolver as function(*))
as attribute()*
{
    map:for-each($mu, 
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

declare function μ:mix($mu) 
as array(*)
{
    [(), $mu]
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
    if (empty($mu)) then
        ()
    else
        tail(μ:seq($mu))
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

declare function μ:children($mu as array(*))
as item()*
{
    if (array:size($mu) > 0) then
        let $c := array:tail($mu)
        return
            if (array:size($c) > 0 and array:head($c) instance of map(*)) then
                μ:seq(array:tail($c))
            else
                μ:seq($c)
    else
        ()
};

declare function μ:attributes($mu as array(*))
as map(*)
{
    if (array:size($mu) gt 1 and $mu(2) instance of map(*)) then $mu(2) else map {}
};

declare function μ:element($mu as array(*))
as xs:string?
{
    if (array:size($mu) eq 0) then () else $mu(1)
};
