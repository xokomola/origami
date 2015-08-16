xquery version "3.0";

module namespace λ = 'http://xokomola.com/xquery/origami/xf';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at 'mu.xqm'; 

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function λ:content($content as item()*)
as function(*) 
{
    function($mu as array(*)) {
        array:append(μ:tag($mu), $content)
    }
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function λ:content($context as item()*, $content as item()*) 
as item()*
{
    λ:content($content)($context)
};

declare function λ:replace($content as item()*)
as function(*) {
    function($context as item()*) {
        $content
    }
};

declare function λ:replace($context as item()*, $content as item()*) 
as item()*
{
    λ:replace($content)($context)
};

declare function λ:wrap($mu as array(*)?)
as function(*)
{
    function($context as item()*) {
        array:append(μ:tag($mu), $context)
    }
};

declare function λ:wrap($context as item()*, $mu as array(*)?)
as item()*
{
    λ:wrap($mu)($context)
};

(: ========= :)

(:~
 : Create a node transformer that applies a node transformation rule to a
 : sequence of input nodes.
 :)
declare function λ:do(
$rule as array(*)) 
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        λ:do-nodes($nodes, $rule)
    }
};

(:~
 : Apply a node transformation rule to a sequence of nodes.
 :)
declare function λ:do(
$nodes as item()*, 
$rule as array(*)) 
as item()*
{
    λ:do-nodes($nodes, $rule)
};

(:~
 : Create a node transformer that applies a node transformation rule to each 
 : individual input node.
 :)
declare function λ:each(
$rule as array(*)) 
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        for $node in $nodes
            return λ:do-nodes($node, $rule)
    }
};

(:~
 : Apply a node transformation rule to each individual input node.
 :)
declare function λ:each(
$nodes as item()*, 
$rule as array(*)) 
as item()*
{
    for $node in $nodes
        return λ:do-nodes($node, $rule)
};

declare %private function λ:do-nodes(
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

(: TODO: could be a bit clearer ($context is always ()) :)
declare %private function λ:unwrap-nodes($nodes as item()*, $content as item()*, $context as array(*))
as item()* 
{
    for $node in $nodes
    return
        typeswitch ($node)
        case element()
        return 
            for $cnode in $node/node()
            return λ:apply-nodes($node, $cnode, $context)
        case node()
        return $node
        default
        return text { $node }
};

declare %private function λ:apply-nodes($node as item()*, $content as item(), $context as array(*))
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

declare %private function λ:invoke-transformer($fn as function(*), $content as item()*, $context as item()*)
{
    if ($context instance of array(*) and array:size($context) gt 0) then
        $fn(array:head($context), $content, array:tail($context))
    else 
        $fn($context, $content, [])    
};

declare %private function λ:context($context)
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
declare function λ:unwrap()
as function(item()*) as item()*
{
    function($context as item()*) {
        λ:invoke-transformer(λ:unwrap-nodes#3, (), $context)
    }    
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function λ:unwrap($context as item()*)
as item()*
{
    λ:unwrap()($context)
};

(:~
 : Copy nodes without any transformation.
 :)
declare function λ:copy()
as function(*)
{
    function($context as item()*) {
        for $node in λ:context($context)[1]
        return
            typeswitch ($node)
            case node()
            return $node
            default
            return text { $node }
    }
};

(:~
 : Create a node transformer that inserts `$before` before
 : the nodes passed in.
 :)
declare function λ:before($before as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($before, $nodes)
    }
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function λ:before($nodes as item()*, $before as item()*)
as item()*
{
    λ:before($before)($nodes)
};

(:~
 : Create a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function λ:after($after as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($nodes, $after)
    }
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function λ:after($nodes as item()*, $after as item()*) 
as item()*
{
    λ:after($after)($nodes)
};

(:~
 : Create a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function λ:append($append as item()*)
as function(item()*) as item()*
{
    λ:element-transformer(
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
declare function λ:append($nodes as item()*, $append as item()*) 
as item()*
{
    λ:append($append)($nodes)
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function λ:prepend($prepend as item()*)
as function(item()*) as item()*
{
    λ:element-transformer(
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
declare function λ:prepend($nodes as item()*, $prepend as item()*) 
as item()*
{
    λ:prepend($prepend)($nodes)
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function λ:text()
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
declare function λ:text($nodes as item()*)
as item()*
{
    λ:text()($nodes)
};

(:~
 : Create a node transformer that sets attributes using a map
 : on each element in the nodes passed.
 :
 : Map keys must be valid as QNames or they will be ignored.
 :)
declare function λ:set-attr($attributes as item())
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
        λ:element-transformer(
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
declare function λ:set-attr($nodes as item()*, $attributes as item()) 
as item()*
{
    λ:set-attr($attributes)($nodes)
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function λ:add-class($names as xs:string*)
as function(item()*) as item()*
{
    λ:element-transformer(
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
declare function λ:add-class($nodes as item()*, $names as xs:string*) 
as item()*
{
    λ:add-class($names)($nodes)
};

(:~
 : Create a node transformer that removes one or more `$names` from the 
 : class attribute. If the class attribute is empty after removing names it will 
 : be removed from the element.
 :)
declare function λ:remove-class($names as xs:string*)
as function(item()*) as item()*
{
    λ:element-transformer(
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
declare function λ:remove-class($nodes as item()*, $names as xs:string*) 
as item()*
{
    λ:remove-class($names)($nodes)
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :
 : TODO: better testing and clean up code.
 :)
declare function λ:remove-attr($attributes as item()*)
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
        λ:element-transformer(
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
declare function λ:remove-attr($nodes as item()*, $names as item()*) 
as item()*
{
    λ:remove-attr($names)($nodes)
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
declare function λ:rename($map as item()) 
as function(item()*) as item()*
{
    λ:element-transformer(
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
declare function λ:rename($nodes as item()*, $map as item())
as item()*
{
    λ:rename($map)($nodes)
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 :)
declare function λ:xslt($stylesheet as item()) 
as function(node()*) as node()*
{
    λ:xslt($stylesheet, map {})
};

(:~
 : Create a node transformer that transforms nodes using
 : an XSLT stylesheet with parameters.
 :)
declare function λ:xslt($stylesheet as item(), $params as item()) 
as function(item()*) as item()*
{
    λ:element-transformer(
        function($node as element()) as element() {
            xslt:transform($node, $stylesheet, $params)/*
        }
    )($params)
};

(:~
 : Transform `$nodes` using XSLT stylesheet.
 :)
declare function λ:xslt($nodes as item()*, $stylesheet as item(), $params as item())
as item()*
{
    λ:xslt($stylesheet, $params)($nodes)
};

declare %private function λ:element-spec($spec as item())
{
    typeswitch ($spec)
    case node() | array(*) | map(*) | function(*)
    return $spec
    default
    return ()
};

declare %private function λ:element-transformer(
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
