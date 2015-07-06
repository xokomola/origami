xquery version "3.0";

module namespace xf = 'http://xokomola.com/xquery/origami';

declare namespace xsl = 'http://www.w3.org/1999/XSL/Transform';
declare namespace xs = 'http://www.w3.org/2001/XMLSchema';
declare %private variable $xf:ns := 'http://xokomola.com/xquery/origami';

(: FIXME: when giving html without namespace somehow Saxon or BaseX is not dealing with link elements properly :)

(: TODO: maybe use ω as prefix :)
(: TODO: maybe generalize xf:template even further and allow more control
 :       over the transformation so their's a tighther integration with
 :       XSLT.
 :)

(:~
 : Load an HTML resource.
 :)
declare function xf:html-resource($url-or-path)
as document-node()
{
    if (starts-with($url-or-path, 'http://')) then
        xf:fetch-html($url-or-path)
    else
        xf:parse-html($url-or-path)
};

(:~
 : Load an XML resource.
 :)
declare function xf:xml-resource($url-or-path)
as document-node()
{
    doc($url-or-path)
};

(:~
 : Fetch and parse HTML given a URL.
 :)
declare function xf:fetch-html($url)
as document-node()
{
    html:parse(fetch:binary($url))
};

(:~
 : Parse HTML from a filesystem path.
 :)
declare function xf:parse-html($path)
as document-node()
{
    html:parse(file:read-binary($path))
};

(:~
 : Create a template using a node sequence. This template
 : does not have template rules and does not accept any 
 : context arguments. Effectively this will return the
 : template node sequence unmodified.
 :) 
declare function xf:template($template as node()*)
as function(*)
{
    xf:template($template, ())
};

(:~
 : Create a template using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function xf:template($template as node()*, $rules as array(*)*)
as function(*)
{
    xf:template($template, $rules, function() { () })
};

(:~
 : Create a template using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
declare function xf:template(
$template as node()*, $rules as array(*)*, $context as function(*))
as function(*)
{
    xf:template($template, $rules, $context, xf:compile-transformer#2)
};

declare %private function xf:template(
$template as node()*, $rules as array(*)*, $context as function(*), $transform as function(*))
as function(*)
{
    let $template := 
        if (count($template) gt 1) then
            element xf:seq { $template }
        else
            $template
            
    let $compiled-template :=
        if (empty($rules)) then
            $template
        else
            xslt:transform($template, $transform($rules, xf:namespaces-map($template)))/*
            
    return
        if (empty($rules)) then
            function() {
                if ($compiled-template/self::xf:seq) then
                    $compiled-template/node()
                else
                    $compiled-template
            }
        else
            let $transform := xf:transform($compiled-template, ?, xf:compile-rules($rules))
            return
                switch (function-arity($context))                
                case 0 return function() { $transform(()) }
                case 1 return function($a) { $transform($context($a)) }
                case 2 return function($a,$b) { $transform($context($a,$b)) }
                case 3 return function($a,$b,$c) { $transform($context($a,$b,$c)) }
                case 4 return function($a,$b,$c,$d) { $transform($context($a,$b,$c,$d)) }
                case 5 return function($a,$b,$c,$d,$e) { $transform($context($a,$b,$c,$d,$e)) }
                case 6 return function($a,$b,$c,$d,$e,$f) { $transform($context($a,$b,$c,$d,$e,$f)) }
                default return 
                    error(xf:ContextArityError, 
                        'xf:template does not support context function arity &gt; 6')
};

(:~
 : Create a template snippet using a node sequence. This template
 : does not have template rules and does not accept any 
 : context arguments. Effectively this will return the
 : template node sequence unmodified.
 :) 
declare function xf:snippet($template as node()*)
as function(*)
{
    xf:snippet($template, ())
};

(:~
 : Create a template snippet using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function xf:snippet($template as node()*, $rules as array(*)*)
as function(*)
{
    xf:snippet($template, $rules, function() { () })
};

(:~
 : Create a template snippet using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
declare function xf:snippet(
$template as node()*, $rules as array(*)*, $context as function(*))
as function(*)
{
    xf:template($template, $rules, $context, xf:compile-extractor#2)
};

(:~
 : Select nodes from a template using XPath rules.
 :
 : TODO: Note that this goes for a simple functional approach instead of via XSLT.
 : I think we can switch between both using typeswitch.
 :)
declare function xf:select($template as node()*, $selector as function(*))
{
    $selector($template)
};

(: TODO: smarter treatment of rule. :)
(: ['p', ()]   delete p elements :)
(: ['p', <foobar/>] replace p with foobar :)
(: ['p', fn1#2, fn2#2, fn3#2] compose a node transformer/pipeline :)
declare %private function xf:compile-rules($rules as item()*)
as map(*)
{
    map:merge((
        for $rule in $rules
        return
            map:entry($rule(1), $rule(2))
    ))
};

(: ctx could be made to work with arrays, maps and nodes :)
(: TODO: verify if needed :)
declare function xf:ctx()
as function(*)
{
    function($ctx) {
        $ctx
    }
};

(: May even make lookup easier by accessing keys in submaps :)
declare function xf:ctx($key as xs:string)
as function(*)
{
    function($ctx) {
        $ctx($key)
    }
};

(: TODO: remove code duplication between this and the next function :)
declare %private function xf:compile-extractor($rules as array(*)*, $namespaces as map(*))
as element(xsl:stylesheet)
{
    element xsl:stylesheet {
        namespace xf { $xf:ns },
        map:for-each(
            $namespaces,
            function($k,$v) {
                namespace { $k } { $v }
            }
        ),
        attribute version { '1.0' },
        element xsl:template {
            attribute match { '/' },
            element xf:seq {
                element xsl:apply-templates {}    
            }
        },
        element xsl:template {
            attribute match { 'text()' }
        },
        for $rule in $rules
        return
            element xsl:template {
                attribute match { $rule(1) },
                attribute priority { '10' },
                element xsl:copy { 
                    element xsl:copy-of {
                        attribute select { '@*' }
                    },
                    element xsl:attribute {
                        attribute name { 'xf:node' },
                        $rule(1)
                    },
                    element xsl:copy-of { attribute select { 'node()' } }
                }
            }
    }
};

declare %private function xf:compile-transformer($rules as array(*)*, $namespaces as map(*))
as element(xsl:stylesheet)
{
    element xsl:stylesheet {
        namespace xf { $xf:ns },
        map:for-each(
            $namespaces,
            function($k,$v) {
                namespace { $k } { $v }
            }
        ),
        (: TODO: maybe use 2.0 when present? :)
        attribute version { '1.0' },
        xf:identity-transform(),
        for $rule in $rules
        return
            element xsl:template {
                attribute match { $rule(1) },
                attribute priority { '10' },
                element xsl:copy { 
                    element xsl:copy-of {
                        attribute select { '@*' }
                    },
                    element xsl:attribute {
                        attribute name { 'xf:node' },
                        $rule(1)
                    },
                    element xsl:apply-templates {}
                }
            }
    }
};

declare %private function xf:identity-transform()
as element(xsl:template)
{
    element xsl:template {
        attribute match { '@*|*|processing-instruction()|comment()' },
        element xsl:copy {
            element xsl:apply-templates { 
                attribute select { 
                    '*|@*|text()|processing-instruction()|comment()' 
                } 
            }
        }
    }
};

declare function xf:identity($nodes as item()*)
as item()*
{
    xf:identity($nodes, map {})
};

declare function xf:identity($nodes as item()*, $ctx)
as item()*
{
    for $node in $nodes
    return 
        typeswitch($node)
        case element(xf:seq)
        return
            xf:identity($node/node(), $ctx)
        case element()
        return
            element { node-name($node) } {
                for $att in $node/@*
                where namespace-uri($att) != $xf:ns
                return 
                    attribute {name($att)} {$att},
                xf:identity($node/node(), $ctx)
            }
        default 
        return $node  
};

declare %private function xf:transform(
$nodes as item()*, $ctx, $rules as item()*)
as item()*
{
    for $node in $nodes
    return 
        typeswitch($node)
        case element(xf:seq)
        return
            xf:transform($node/node(), $ctx, $rules)
        case element()
        return
            if ($node/@xf:node) then
                let $xf := $rules(string($node/@xf:node))
                let $result := 
                    typeswitch($xf)
                    (: TODO: maybe do arity checking here? :)
                    case function(*)
                    return
                        (: TODO: review :)
                       switch (function-arity($xf))
                       case 0 return $xf()
                       case 1 return $xf([$node,$ctx])
                       default return $xf($node, $ctx)
                    default
                    return $xf
                return
                    typeswitch($result)
                    case element()
                    return
                        element { node-name($result) } {
                            (: xf:copy-namespaces($result), :)
                            for $att in $result/@*
                            where namespace-uri($att) != $xf:ns
                            return 
                                attribute {name($att)} {$att},
                            for $child in $result/node()
                            return 
                                xf:transform($child, $ctx, $rules)
                        }
                    default
                    return $result
            else if ($node/self::xf:seq) then
                xf:transform($node/node(), $ctx, $rules)
            else
                element { node-name($node) } {
                    (: xf:copy-namespaces($node), :)
                    for $att in $node/@*
                    where namespace-uri($att) != $xf:ns
                    return
                        attribute {name($att)} {$att},
                    xf:transform($node/node(), $ctx, $rules)
                }
        default 
        return $node  
};

(:~
 : Returns a map with namespaces taken from the input nodes.
 : Note that it doesn't return all the possible namespaces
 : but rather looks at all top-level element nodes and only
 : returns the namespaces in scope for these nodes.
 :)
declare %private function xf:namespaces-map($nodes as node()*)
as map(*) {
    map:merge((
        let $node :=
            typeswitch ($nodes)
            case document-node()
            return
                $nodes/*
            default
            return $nodes
        let $ns-map :=
            for $ns-prefix in in-scope-prefixes($node)
            let $ns-uri := namespace-uri-for-prefix($ns-prefix, $node)
            where $ns-uri != 'http://www.w3.org/XML/1998/namespace'
            return 
                map:entry($ns-prefix, $ns-uri)
        let $predefined-ns :=
            map {
                '': 'http://www.w3.org/1999/xhtml',
                'html': 'http://www.w3.org/1999/xhtml'
            }
        return
            map:merge(($predefined-ns, $ns-map))
    ))    
};

(:~
 : Returns all in-scope namespaces as namespace nodes (except xml and xf namespaces)
 :) 
(: TODO: this probably doesn't work as expected :)
declare %private function xf:copy-namespaces($node as element())
as namespace-node()* 
{
    for $ns in in-scope-prefixes($node)
    where not($ns = ('xml','xf',''))
    return
        namespace { $ns } { namespace-uri-for-prefix($ns, $node) }
};

(: ========= node transformers ============== :)

(:~
 : Create a node transformer that applies a node transformation rule to a
 : sequence of input nodes.
 :)
declare function xf:do(
$rule as array(*)) 
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        xf:do-nodes($nodes, $rule)
    }
};

(:~
 : Apply a node transformation rule to a sequence of nodes.
 :)
declare function xf:do(
$nodes as item()*, 
$rule as array(*)) 
as item()*
{
    xf:do-nodes($nodes, $rule)
};

(:~
 : Create a node transformer that applies a node transformation rule to each 
 : individual input node.
 :)
declare function xf:each(
$rule as array(*)) 
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        for $node in $nodes
            return xf:do-nodes($node, $rule)
    }
};

(:~
 : Apply a node transformation rule to each individual input node.
 :)
declare function xf:each(
$nodes as item()*, 
$rule as array(*)) 
as item()*
{
    for $node in $nodes
        return xf:do-nodes($node, $rule)
};

declare %private function xf:do-nodes(
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

(:~ TODO: how to do xf:if, xf:choose without using eval() :)

declare %private function xf:content-nodes($nodes as item()*, $content as item()*, $context as array(*))
as item()* 
{
    for $node in $nodes
    return
        typeswitch ($node)
        case element()
        return 
            element { node-name($node) } { 
                $node/@* except $node/@xf:*, 
                for $cnode in $content 
                return xf:apply-nodes($node, $cnode, $context) 
            }
        default
        return $node
};

declare %private function xf:replace-nodes($nodes as item()*, $content as item()*, $context as array(*))
as item()* 
{
    for $node in $nodes
    return
        typeswitch ($node)
        case element()
        return 
            for $cnode in $content 
            return xf:apply-nodes($node, $cnode, $context)
        default
        return $node   
};

declare %private function xf:wrap-nodes($nodes as item()*, $element as item()*, $context as array(*))
as item()* 
{
    if (empty($nodes)) then
        (: empty nodes should not be wrapped :)
        $nodes
    else
        let $element := xf:apply-nodes($nodes, $element, $context)
        return
            element { node-name($element) } { $element/@*, $nodes }
};

(: TODO: could be a bit clearer ($context is always ()) :)
declare %private function xf:unwrap-nodes($nodes as item()*, $content as item()*, $context as array(*))
as item()* 
{
    for $node in $nodes
    return
        typeswitch ($node)
        case element()
        return 
            for $cnode in $node/node()
            return xf:apply-nodes($node, $cnode, $context)
        case node()
        return $node
        default
        return text { $node }
};

declare %private function xf:apply-nodes($node as item()*, $content as item(), $context as array(*))
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

declare %private function xf:invoke-transformer($fn as function(*), $content as item()*, $context as item()*)
{
    if ($context instance of array(*) and array:size($context) gt 0) then
        $fn(array:head($context), $content, array:tail($context))
    else 
        $fn($context, $content, [])    
};

declare %private function xf:context($context)
{
    if ($context instance of array(*) and array:size($context) gt 0) then
        (array:head($context), array:tail($context))
    else 
        ($context, [])        
};

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function xf:content($content as item()*)
as function(*) 
{
    function($context as item()*) {
        xf:invoke-transformer(xf:content-nodes#3, $content, $context)
    }
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function xf:content($context as item()*, $content as item()*) 
as item()*
{
    xf:content($content)($context)
};

declare function xf:replace($content as item()*)
as function(*) {
    function($context as item()*) {
        xf:invoke-transformer(xf:replace-nodes#3, $content, $context)
    }
};

declare function xf:replace($context as item()*, $content as item()*) 
as item()*
{
    xf:replace($content)($context)
};

declare function xf:wrap($spec as item())
as function(*)
{
    let $element := xf:element-spec($spec)
    return
        function($context as item()*) {
            xf:invoke-transformer(xf:wrap-nodes#3, $element, $context)
        }
};

declare function xf:wrap($context as item()*, $element-spec as item())
as element()?
{
    xf:wrap($element-spec)($context)
};

(:~
 : Create a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :
 : This function is safe for use as a node selector.
 :)
declare function xf:unwrap()
as function(item()*) as item()*
{
    function($context as item()*) {
        xf:invoke-transformer(xf:unwrap-nodes#3, (), $context)
    }    
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function xf:unwrap($context as item()*)
as item()*
{
    xf:unwrap()($context)
};

(:~
 : Copy nodes without any transformation.
 :)
declare function xf:copy()
as function(*)
{
    function($context as item()*) {
        for $node in xf:context($context)[1]
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
declare function xf:before($before as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($before, $nodes)
    }
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function xf:before($nodes as item()*, $before as item()*)
as item()*
{
    xf:before($before)($nodes)
};

(:~
 : Create a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function xf:after($after as item()*)
as function(item()*) as item()*
{
    function($nodes as item()*) as item()* {
        ($nodes, $after)
    }
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function xf:after($nodes as item()*, $after as item()*) 
as item()*
{
    xf:after($after)($nodes)
};

(:~
 : Create a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function xf:append($append as item()*)
as function(item()*) as item()*
{
    xf:element-transformer(
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
declare function xf:append($nodes as item()*, $append as item()*) 
as item()*
{
    xf:append($append)($nodes)
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function xf:prepend($prepend as item()*)
as function(item()*) as item()*
{
    xf:element-transformer(
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
declare function xf:prepend($nodes as item()*, $prepend as item()*) 
as item()*
{
    xf:prepend($prepend)($nodes)
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function xf:text()
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
declare function xf:text($nodes as item()*)
as item()*
{
    xf:text()($nodes)
};

(:~
 : Create a node transformer that sets attributes using a map
 : on each element in the nodes passed.
 :
 : Map keys must be valid as QNames or they will be ignored.
 :)
declare function xf:set-attr($attributes as item())
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
        xf:element-transformer(
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
declare function xf:set-attr($nodes as item()*, $attributes as item()) 
as item()*
{
    xf:set-attr($attributes)($nodes)
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function xf:add-class($names as xs:string*)
as function(item()*) as item()*
{
    xf:element-transformer(
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
declare function xf:add-class($nodes as item()*, $names as xs:string*) 
as item()*
{
    xf:add-class($names)($nodes)
};

(:~
 : Create a node transformer that removes one or more `$names` from the 
 : class attribute. If the class attribute is empty after removing names it will 
 : be removed from the element.
 :)
declare function xf:remove-class($names as xs:string*)
as function(item()*) as item()*
{
    xf:element-transformer(
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
declare function xf:remove-class($nodes as item()*, $names as xs:string*) 
as item()*
{
    xf:remove-class($names)($nodes)
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :
 : TODO: better testing and clean up code.
 :)
declare function xf:remove-attr($attributes as item()*)
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
        xf:element-transformer(
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
declare function xf:remove-attr($nodes as item()*, $names as item()*) 
as item()*
{
    xf:remove-attr($names)($nodes)
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
declare function xf:rename($map as item()) 
as function(item()*) as item()*
{
    xf:element-transformer(
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
declare function xf:rename($nodes as item()*, $map as item())
as item()*
{
    xf:rename($map)($nodes)
};

declare %private function xf:element-spec($spec as item())
{
    typeswitch ($spec)
    case node() | array(*) | map(*) | function(*)
    return $spec
    default
    return ()
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 :)
declare function xf:xslt($stylesheet as item()) 
as function(node()*) as node()*
{
    xf:xslt($stylesheet, map {})
};

(:~
 : Create a node transformer that transforms nodes using
 : an XSLT stylesheet with parameters.
 :)
declare function xf:xslt($stylesheet as item(), $params as item()) 
as function(item()*) as item()*
{
    xf:element-transformer(
        function($node as element()) as element() {
            xslt:transform($node, $stylesheet, $params)/*
        }
    )($params)
};

(:~
 : Transform `$nodes` using XSLT stylesheet.
 :)
declare function xf:xslt($nodes as item()*, $stylesheet as item(), $params as item())
as item()*
{
    xf:xslt($stylesheet, $params)($nodes)
};

declare %private function xf:element-transformer(
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
