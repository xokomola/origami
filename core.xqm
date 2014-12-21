xquery version "3.0";

(:~
 : Origami templating.
 :
 : Requires Basex 8.0 20141219 or later.
 :
 : @version 0.4 
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami';

(:~
 : Load an HTML resource.
 :)
declare function xf:html-resource($url-or-path) {
    if (starts-with($url-or-path,'http:/')) then
        xf:fetch-html($url-or-path)
    else
        xf:parse-html($url-or-path)
};

(:~
 : Load an XML resource.
 :)
declare function xf:xml-resource($url-or-path) {
    doc($url-or-path)
};

(:~
 : Fetch and parse HTML given a URL.
 :)
declare function xf:fetch-html($url) {
    html:parse(fetch:binary($url))
};

(:~
 : Parse HTML from a filesystem path.
 :)
declare function xf:parse-html($path) {
    html:parse(file:read-binary($path))
};

(:~
 : Returns a Transformer function.
 :)
declare function xf:transform($templates as array(*)*) 
    as function(node()*) as node()* {
    let $templates :=
        for $template in $templates
        return xf:match($template)
    return
        function($nodes as node()*) as node()* {
            xf:apply-nodes($nodes, (), $templates)
        }
};

(:~
 : Transform input, using the specified templates.
 :)
declare function xf:transform($nodes as node()*, $templates as array(*)*)
    as node()* {
    xf:transform($templates)($nodes)
};

(:~
 : Identity transformer.
 :)
declare function xf:transform() { xf:transform(()) };

(:~
 : Returns an extractor function that only returns selected nodes 
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract($selectors as array(*)*) 
    as function(node()*) as node()* {
    xf:extract-outer($selectors)
};

(:~
 : Extracts nodes from input, using the specified selectors.
 :)
declare function xf:extract($nodes as node()*, $selectors as array(*)*) 
    as node()* {
    xf:extract($selectors)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only innermost, in document order and duplicates eliminitated.
 :
 : TODO: when using ['*',()] this should delete the element
 :
 : TODO: this version still suffers from the problem with transforms
 :       being done before the inner/outermost which means that 
 :       they still frustrate the distinct/duplicate nodes stuff
 :)
declare function xf:extract-inner($selectors as array(*)*) 
    as function(node()*) as node()* {
    let $selectors :=
        for $selector in $selectors
        return
            xf:at($selector)
    return
        function($nodes as node()*) as node()* {
            innermost(
                for $selector in $selectors
                return $selector($nodes)
            )
        }
};

declare function xf:extract-inner($nodes as node()*, $selectors as array(*)*) 
    as node()* {
    xf:extract-inner($selectors)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract-outer($selectors as array(*)*) 
    as function(node()*) as node()* {
    let $selectors :=
        for $selector in $selectors
        return xf:at($selector)
    return
        function($nodes as node()*) as node()* {
            outermost(
                for $selector in $selectors
                return $selector($nodes)
            )
        }
};

declare function xf:extract-outer($nodes as node()*, $selectors as array(*)*) 
    as node()* {
    xf:extract-outer($selectors)($nodes)
};

(:~
 : Defines a match template.
 :
 : A template takes a selector string or function and
 : a node transformation function or the items to return as 
 : the template body.
 : Providing invalid matcher returns empty sequence.
 :)
declare function xf:match($template as array(*)) 
    as map(*)? {
    let $selector := xf:selector([array:head($template)])
    (: HACK: to work around an array:fold-left bug in 20141219 :)
    let $body := xf:do(array:filter($template,function($i) { not($i instance of xs:string) }))
    where array:size($template) gt 0
    return
        map {
            'select': $selector,
            'fn': $body
        }
};

declare function xf:at($steps as array(*))
    as function(node()*) as node()* {
    xf:selector($steps, xf:select-all#1)
};
(:~
 : Execute a chain of node selectors. 
 :)
declare function xf:at($nodes as node()*, $selector as item()*) {
    xf:at($selector)($nodes)
};

declare %private function xf:selector($steps as array(*))
    as function(node()*) as node()* {
    xf:selector($steps, xf:select-all#1)
};
(:~
 : Only nodes for which the chain of expressions evaluates to `true()`
 : are passed through.
 :
 : TODO: need to do proper xpath expression evaluation (not used descendent)
 :)
declare function xf:if($conditions as item()*) 
    as function(node()*) as node()* {
    let $conditions := xf:comp-expression($conditions)
    return
        function($nodes as node()*) as node()* {
            fold-left(
                $conditions,
                $nodes,
                function($result, $step) {
                    if ($step($result)) then
                       $result
                    else
                        ()
                }
            )
        }
};

(:~
 : Filter nodes based on evaluating a chain of expressions, letting only
 : those nodes through for which it returns `true()`.
 :) 
declare function xf:if($nodes as node()*, $conditions as item()*) 
    as node()* {
    xf:if($conditions)($nodes)
};

(:~
 : Compose a chain of node transformers.
 :)
declare function xf:do($fns as array(*)) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        array:fold-left(
            $fns, 
            $nodes,
            function($nodes, $fn) {
                if (exists($fn)) then
                    $fn($nodes)
                else
                    ()
            }
        ) 
    }
};

(:~
 : Execute a chain of node transformers.
 :)
declare function xf:do($nodes as node()*, $fns as array(*)) 
    as node()* {
    xf:do($fns)($nodes)
};

(:~
 : Compose a chain of node transformers.
 :)
declare function xf:do-each($fns as array(*)) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        for $node in $nodes
        return
            array:fold-left(
                $fns, 
                $node,
                function($node, $fn) {
                if (exists($fn)) then
                    $fn($node)
                else
                    ()
                }
            ) 
    }
};

(:~
 : Execute a chain of node transformers.
 :)
declare function xf:do-each($nodes as node()*, $fns as array(*)) 
    as node()* {
    xf:do-each($fns)($nodes)
};

(: ================ node transformers ================ :)

(:~
 : Replace the content (child nodes) of the input node
 :)
declare function xf:content($content as node()*)
    as function(element()?) as element()? {
    function($element as element()?) as element()? {
        if (exists($element)) then
            element { node-name($element) } {
                $element/@*,
                $content
            }
        else
            $element
    }
};

declare function xf:content($element as element()?, $content as node()*) 
    as element()? {
    xf:content($content)($element)
};

(:~
 : Only replace the content of the input element when
 : the content is not empty.
 :)
declare function xf:content-if($content as node()*)
    as function(element()?) as element()? {
    function($element as element()?) as element()? {
        if (exists($content) and exists($element)) then
            element { node-name($element) } {
                $element/@*,
                $content
            }
        else
            $element
    }
};

declare function xf:content-if($element as element()?, $content as node()*)
    as element()? {
    xf:content-if($content)($element)
};

(:~
 : Replace the current node.
 :)
declare function xf:replace($replacement as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        if (exists($nodes)) then
            $replacement
        else
            $nodes
    }
};

declare function xf:replace($nodes as node()*, $replacement as node()*) 
    as node()* {
    xf:replace($replacement)($nodes)
};

(:~
 : Only replace the input nodes when the replacement
 : is not empty.
 :)
declare function xf:replace-if($replacement as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        if (exists($replacement) and exists($nodes)) then
            $replacement
        else
            $nodes
    }
};

declare function xf:replace-if($nodes as node()*, $replacement as node()*)
    as node()* {
    xf:replace-if($replacement)($nodes)
};

(:~
 : Inserts nodes before the current node.
 :)
declare function xf:before($before as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        ($before, $nodes)
    }
};

declare function xf:before($nodes as node()*, $before as node()*)
    as node()* {
    xf:before($before)($nodes)
};

(:~
 : Inserts nodes after the current node.
 :)
declare function xf:after($after as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        ($nodes, $after)
    }
};

declare function xf:after($nodes as node()*, $after as node()*) 
    as node()* {
    xf:after($after)($nodes)
};

(:~
 : Inserts nodes as first child, before the current content.
 :)
declare function xf:append($append as node()*)
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as element() {
            element { node-name($node) } {
                ($node/(@*,node()), $append)
            }
        }
     (: HACK :)
    )(true())
};

(:~
 : Inserts nodes as last child, after the current content.
 :)
declare function xf:append($nodes as node()*, $append as node()*) 
    as node()* {
    xf:append($append)($nodes)
};

(:~
 : Inserts nodes as last child, after the current content.
 :)
declare function xf:prepend($prepend as node()*)
    as function(node()*) as node()* {
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
 : Inserts nodes as last child, after the current content.
 :)
declare function xf:prepend($nodes as node()*, $prepend as node()*) 
    as node()* {
    xf:prepend($prepend)($nodes)
};

(:~
 : Returns a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function xf:text()
    as function(node()*) as node()* {
    function($nodes as node()*) as text()? {
        if (exists($nodes)) then
            text { normalize-space(string-join($nodes,'')) }
        else
            ()
    }
};

declare function xf:text($nodes as node()*)
    as text()? {
    xf:text()($nodes)
};

(:~
 : Set attributes using a map.
 :)
declare function xf:set-attr($attributes as item())
    as function(node()*) as node()* {
    let $attributes := 
        typeswitch ($attributes)
        case map(*)
        return 
            map:for-each(
                $attributes, 
                function($name,$value) { 
                    attribute { $name } { $value } 
                })
        case element()
        return $attributes/@*
        default
        return
            ()
    return
        xf:element-transformer(
            function($node as element()) as node()* {
                element { node-name($node) } {
                    $attributes,
                    for $att in $node/@*
                    where node-name($att) != $attributes/node-name()
                    return $att,
                    $node/node()
                }
            }
        )($attributes)
};

declare function xf:set-attr($nodes as node()*, $attributes as item()) 
    as node()* {
    xf:set-attr($attributes)($nodes)
};

(:~
 : Add one or more `$names` to a class attribute.
 :)
declare function xf:add-class($names as xs:string*)
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as node()* {
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
declare function xf:add-class($nodes as node()*, $names as xs:string*) 
    as node()* {
    xf:add-class($names)($nodes)
};

(:~
 : Remove one or more `$names` from the class attribute.
 : If the class attribute is empty after removing names it will be removed
 : from the element.
 :)
declare function xf:remove-class($names as xs:string*)
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as node()* {
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
declare function xf:remove-class($nodes as node()*, $names as xs:string*) 
    as node()* {
    xf:remove-class($names)($nodes)
};

(:~
 : Remove attributes.
 :)
declare function xf:remove-attr($attributes as item()*)
    as function(node()*) as node()* {
    let $attributes := 
        typeswitch ($attributes) 
        case xs:string*
        return for $name in $attributes return attribute { $name } { '' }
        case element()
        return $attributes/@*
        case map(*)
        return             
            map:for-each(
                $attributes, 
                function($name,$value) { 
                    attribute { $name } { '' } 
            })
        default
        return ()
    return
        xf:element-transformer(
            function($node as element()) as node()* {
                element { node-name($node) } {
                    for $att in $node/@*
                    where not(node-name($att) = $attributes/node-name())
                    return $att
                }
            }
        )($attributes)
};


declare function xf:remove-attr($nodes as node()*, $names as item()*) 
    as node()* {
    xf:remove-attr($names)($nodes)
};

(:~
 : Returns a selector step function that wraps nodes in
 : an element `$element`. An empty sequence will not be
 : wrapped.
 :)
declare function xf:wrap($element as element())
    as function(node()*) as element()? {
    function($nodes as node()*) as element()? {
        if (exists($nodes)) then
            element { node-name($element) } {
                $element/@*,
                $nodes
            }
        else
            ()
    }
};

(:~
 : Wraps `$nodes` in element `$node`. An empty sequence will
 : not be wrapped.
 :)
declare function xf:wrap($nodes as node()*, $element as element())
    as element()? {
    xf:wrap($element)($nodes)
};

(:~
 : Returns a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :
 : This function is safe for use as a node selector.
 :)
declare function xf:unwrap()
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as node()* {
            $node/node()
          (: FIXME: passing true() is a bit of a hack, because 
             element-transformers check for empty arg even if they 
             don't need one :)
        }
    )(true())
};

(:~
 : Unwraps all nodes that are elements.
 :)
declare function xf:unwrap($nodes as node()*)
    as node()* {
    xf:unwrap()($nodes)
};

declare function xf:xslt($stylesheet as item()) 
    as function(node()*) as node()* {
    xf:xslt($stylesheet, map {})
};

declare function xf:xslt($stylesheet as item(), $params as item()) 
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as node()* {
            xslt:transform($node, $stylesheet, $params)/*
        }
    )($params)
};

declare function xf:xslt($nodes as node()*, $stylesheet as item(), $params as item())
    as node()* {
    xf:xslt($stylesheet, $params)($nodes)
};

(:
 : Creates a generic element node transformer function.
 :)
declare function xf:element-transformer($transform as function(element()) as node()*) 
    as function(*) {
    function($args as item()*) as function(*) {
        function($nodes as node()*) as node()* {
            if (exists($args)) then
                for $node in $nodes
                return
                    if ($node instance of element()) then
                        $transform($node)
                    else
                        $node
            else
                $nodes
        }
    }
};

(: ================ environment ================ :)

(:~
 : Sets up a default environment which can be customized.
 : Represents the default bindings for selecting nodes.
 : The context is set to $nodes and all it's descendant elements.
 : It also sets up a helper function $in to enable proper checks on tokenized
 : (space-delimited) attribute values such as @class.
 :)
declare function xf:environment() {
    map {
        'bindings': function($nodes as node()*) as map(*) {
            map { 
                '': $nodes/descendant-or-self::node(),
                xs:QName('in'): function($att, $token) as xs:boolean {
                    $token = tokenize(string($att),'\s+')
                }
            }
        },
        'query': function($selector as xs:string) {
            'declare variable $in external; ' || $selector
        }
    }
};

declare function xf:expr-environment() {
    map {
        'bindings': function($nodes as node()*) as map(*) {
            map { 
                '': $nodes,
                xs:QName('in'): function($att, $token) as xs:boolean {
                    $token = tokenize(string($att),'\s+')
                }
            }
        },
        'query': function($selector as xs:string) {
            'declare variable $in external; ' || $selector
        }
    }
};

(:~
 : Find matches for XPath expression string applied to passed in nodes.
 :)
declare function xf:select-all($selector as xs:string) 
    as function(node()*) as node()* {
    xf:select-with-env($selector, xf:environment())
};

declare function xf:select-all($nodes as node()*, $selector as xs:string) 
    as function(node()*) as node()* {
    xf:select-all($selector)($nodes)
};

declare function xf:select($selector as xs:string) 
    as function(node()*) as node()* {
    xf:select-with-env($selector, xf:expr-environment())
};

declare function xf:select($nodes as node()*, $selector as xs:string) 
    as function(node()*) as node()* {
    xf:select($selector)($nodes)
};

declare %private function xf:select-with-env($selector as xs:string, $env as map(*)) 
    as function(node()*) as node()* {
    let $query := $env('query')($selector)
    let $bindings := $env('bindings')
    return
        function($nodes as node()*) as node()* {
            xquery:eval($query, $bindings($nodes))
        }
};

(: ================ internal functions ================ :)

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy-nodes($nodes as node()*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
    return 
        if ($node/self::xf:apply) then
            xf:apply-nodes($node/(@*, node()), (), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                $node/@*,
                xf:copy-nodes($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:copy-nodes($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Applies nodes to output, but runs the template node transformer when it
 : encounters a node that was matched.
 :)
declare %private function xf:apply-nodes($nodes as node()*, $context as map(*)*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
    let $context := (xf:match-templates($node, $xform), $context)
    let $match := xf:matched-template($node, $context)
    return
        if ($match instance of map(*)) then
            xf:copy-nodes($match('fn')($node), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                xf:apply-nodes($node/(@*, node()), $context, $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:apply-nodes($node/node(), $context, $xform)
            }
        else
            $node
};

(:~
 : Apply to be used from within templates.
 : TODO: maybe rename to xf:apply-rules
 :)
declare function xf:apply($nodes as node()*) 
    as element(xf:apply) { 
    <xf:apply>{ $nodes }</xf:apply> 
};

(:~
 : Find all templates matched by this node and adds the matched nodes
 : to the templates.
 :)
declare %private function xf:match-templates($node as node(), $xform as map(*)*) 
    as map(*)* {
    fold-left(
        $xform, 
        (),
        function($matched-templates as map(*)*, $template as map(*)) {
            let $matched-nodes := $template('select')($node)
            return
                if (exists($matched-nodes)) then
                    ($matched-templates, map:new(($template, map { 'nodes': $matched-nodes })))
                else
                    $matched-templates
        }
    )
};

(:~
 : Looks in the $context to find a template that was matched by this
 : node. First one found (most-specific) wins.
 :)
declare %private function xf:matched-template($node as node(), $context as map(*)*) 
    as map(*)? {
    if (count($context) gt 0) then
        hof:until(
            function($context as map(*)*) { 
                empty($context) or 
                xf:is-node-in-sequence($node, head($context)('nodes')) },
            function($context as map(*)*) { 
                tail($context) },
            $context
        )[1]
    else
        ()
};

(:~
 : Define a transformation that starts with selecting nodes with an
 : XPath expression.
 :)
declare %private function xf:selector($steps as array(*), $selector-fn as function(*)) 
    as function(node()*) as node()* {
    (: compile the steps :)
    let $steps :=
        array:fold-left(
            $steps,
            (),
            function($result, $step) {
                if ($step instance of xs:string) then
                    ($result, $selector-fn($step))
                else if ($step instance of function(*)) then
                    ($result, $step)
                else if ($step instance of node()*) then
                    ($result, function($node as node()*) as node()* { $step })
                else if ($step instance of empty-sequence()) then
                    function($node as node()*) as node()* { () }
                else
                    ($result, text { $step })
            }
        )
    return
        function($nodes as node()*) as node()* {
            for $selected in head($steps)($nodes)
            return
                fold-left(
                    tail($steps),
                    $selected,
                    function($result, $step) {
                        $step($result)
                    }
                )
        }
};

declare %private function xf:comp-expression($expressions as item()*)
    as (function(node()*) as node()*)* {
    for $expression in $expressions
    return
        if ($expression instance of xs:string) then
            xf:select($expression)
        else
            $expression
};
 
(:~
 : Is node defined in seq?
 : @see http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence.html
 :)
declare %private function xf:is-node-in-sequence($node as node()?, $seq as node()*)
    as xs:boolean {
    some $nodeInSeq in $seq satisfies $nodeInSeq is $node
};
