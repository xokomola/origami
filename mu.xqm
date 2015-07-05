xquery version "3.1";

(:~ Origami μ-templates :)

(: TODO: add XML serialization options :)
(: TODO: add option to move all ns declarations at document element (sane namespaces) !? :)
(: TODO: better json serialization :)
(: TODO: remove args from :xml :)
(: TODO: can we scan $items for function items and if so return a function automatically? :)

(: DONE: add ways to configure how names are mapped to qnames (e.g. define a mapping a la JSON-LD) :)
(: DONE: add default element namespace :)

module namespace μ = 'http://xokomola.com/xquery/origami/μ';

declare function μ:xml($items as item()*)
{
    μ:xml($items, [], μ:qname-resolver())
};

declare function μ:xml($items as item()*, $resolver-or-args as function(*)) 
as node()*
{
    if ($resolver-or-args instance of array(*)) then
        μ:xml($items, $resolver-or-args, μ:qname-resolver())
    else
        μ:xml($items, [], $resolver-or-args)
};

declare function μ:xml($items as item()*, $args as array(*), $name-resolver as function(*)) 
as node()*
{
    μ:to-xml($items, $args, $name-resolver)
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
as item()*
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

declare %private function μ:to-xml($items as item()*, $args as array(*), $name-resolver as function(*))
as node()*
{
    for $item in $items
    return
        typeswitch ($item)
        case array(*) return μ:to-element($item, $args, $name-resolver)   
        case map(*) return  μ:to-attributes($item, $args, $name-resolver)
        case function(*) return μ:to-xml(apply($item, $args), $args, $name-resolver)
        case empty-sequence() return ()
        case node() return $item
        default return text { $item }
};

declare %private function μ:to-element($item as array(*), $args as array(*), $name-resolver as function(*))
as element()?
{
    if (array:size($item) gt 0) then
        element { $name-resolver(array:head($item)) } {
            array:fold-left(
                array:tail($item),
                (),
                function($n, $i) {
                    ($n, μ:to-xml($i, $args, $name-resolver))
                }
            )
        }
    else
        ()
};

declare %private function μ:to-attributes($item as map(*), $args as array(*), $name-resolver as function(*))
as attribute()*
{
    map:for-each($item, 
        function($k,$v) {
            if (not(starts-with($k,'μ:'))) then
                attribute { $name-resolver($k) } { 
                    data(
                        typeswitch ($v)
                        case function(*)
                        return apply($v, $args)
                        default
                        return $v
                    ) }
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
{
    μ:ns(map {})
};

declare function μ:ns($ns-map as map(*))
{
    map:merge((
        $ns-map,
        for $ns in doc(concat(file:base-dir(),'/nsmap.xml'))/nsmap/*
        return
            map:entry(string($ns/@prefix), string($ns/@uri))
    ))
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
as item()*
{
    typeswitch ($mu)
        case array(*)
            return array:fold-left($mu, (), μ:cons#2)
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
