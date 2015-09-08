xquery version "3.1";

declare function μ:apply($mu as item()*)
as item()*
{
    μ:apply($mu, [])
};

declare function μ:apply($mu as item()*, $args as item()*) 
as item()*
{
    (: if there's one argument given wrap it in an array (for fn:apply) :)
    let $args := if ($args instance of array(*)) then $args else [ $args ]
    for $item in $mu
    return
        μ:to-apply($item, $args)
};

(: TODO: bug in attribute map handling, currently creates text nodes not attributes :)
declare %private function μ:to-apply($mu as item(), $args as array(*)) 
as item()*
{
    typeswitch ($mu)
    
    case array(*) 
    return
        let $name := array:head($mu)
        return
            if (empty($name)) 
            then
                for $item in array:tail($mu)?* return μ:to-apply($item, $args)    
            else
                array:fold-left($mu, [], 
                    function($a,$b) {
                        if (empty($b)) 
                        then $a
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
    
    default 
    return $mu
};

(: TODO: could be a bit clearer ($context is always ()) :)

declare %private function μ:unwrap-nodes($nodes as item()*, $content as item()*, $context as array(*))
as item()* 
{
    for $node in $nodes
    return
        typeswitch ($node)
        case element()
        return 
            for $cnode in $node/node()
            return μ:apply-nodes($node, $cnode, $context)
        case node()
        return $node
        default
        return text { $node }
};

declare %private function μ:apply-nodes($node as item()*, $content as item(), $context as array(*))
as item()* 
{
    typeswitch ($content)
    case array(*) | map(*)
    return apply($content, $context)
    case function(*)
    return 
        switch (function-arity($content))
        case 0
        return $content()
        default
        return apply($content, array:join(([$node],$context)))
    case node()
    return $content
    default
    return text { $content }
};

