xquery version "3.0";

(:~
 : Origami templating.
 :
 : @version 0.4
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami';

import module namespace apply = 'http://xokomola.com/xquery/common/apply'
    at 'apply.xqm';

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
 : Template data. This is constructed from a transform on the template
 : and executing the slot handlers (match templates) on each matched
 : node from the template.
 :
 : TODO: $tpl should be looked at to determine if fetch or parse should be
 :       invoked (or even doc()). 
 :)
declare function xf:template($nodes as node()*, $tpl, $slots as map(*)*)
    as node()* {
    xf:template($tpl, $slots)($nodes)
};

declare function xf:template($tpl, $slots as map(*)*) 
    as node()* {
    xf:transform($slots)($tpl)
};

(:~
 : Returns a Transformer function.
 :)
declare function xf:transform($templates as map(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xf:apply-nodes($nodes, (), $templates)
    }
};

(:~
 : Transform input, using the specified templates.
 :)
declare function xf:transform($nodes as node()*, $templates as map(*)*)
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
declare function xf:extract($steps as function(*)*) 
    as function(node()*) as node()* {
    xf:extract-outer($steps)
};

(:~
 : Extracts nodes from input, using the specified selectors.
 :)
declare function xf:extract($nodes as node()*, $steps as function(*)*) 
    as node()* {
    xf:extract($steps)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only innermost, in document order and duplicates eliminitated.
 :)
declare function xf:extract-inner($steps as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xf:distinct-nodes(innermost(xf:select-nodes($nodes, $steps)))
    }
};

declare function xf:extract-inner($nodes as node()*, $steps as function(*)*) 
    as node()* {
    xf:extract-inner($steps)($nodes)
};

(:
 : TODO: when running on 8.0 20141116.135016 or higher then
 :       xf:distinct-nodes() can be removed due to bugfix
 :       remove it after 8.0 is released. 
 :)

(:~
 : Returns an extractor function that returns selected nodes,
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract-outer($steps as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xf:distinct-nodes(outermost(xf:select-nodes($nodes, $steps)))
    }
};

declare function xf:extract-outer($nodes as node()*, $steps as function(*)*) 
    as node()* {
    xf:extract-outer($steps)($nodes)
};


(:~
 : TODO
 :
 : Defines a match template.
 :
 : A template takes a selector string or function and
 : a node transformation function or the items to return as 
 : the template body.
 : Providing invalid matcher returns empty sequence.
 :)
declare function xf:match($selectors, $body) 
    as map(*)? {
    let $select := xf:at($selectors)
    let $body :=
        typeswitch ($body)
        case empty-sequence() return function($node) { () }
        case function(*) return $body
        default return function($node) { $body }
    where $select instance of function(*) and $body instance of function(*)
    return
        map {
            'select': $select,
            'fn': $body
        }
};

(:~
 : Compose a select function from a sequence of selector functions or Xpath 
 : expressions.
 : 
 : A node selector is any function
 : compatible with the signature `function(node()*) as node()*`. For
 : some extractors it is necessary that this function only selects
 : nodes and that it doesn't create new nodes as this would frustrate
 : the functionality that depends on node identity. Extractors usually
 : do not return duplicate nodes and also ensure that nodes are output
 : in document-order. This is not enforced, however, and this allows
 : combining node selection with transformation. But it may also
 : cause unexpected issues.
 :)
declare function xf:at($selectors as item()*) 
    as function(node()*) as node()* {
    let $selectors := xf:comp-selector($selectors)
    return
        function($nodes as node()*) as node()* {
            fold-left(
                $selectors,
                $nodes,
                function($result, $step) {
                    $step($result)
                }
            )
        }
};

(:~
 : Execute a chain of node selectors. 
 :)
declare function xf:at($nodes as node()*, $selectors as item()*) {
    xf:at($selectors)($nodes)
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
declare function xf:do($fns as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        fold-left(
            $fns, 
            $nodes,
            function($nodes, $fn) {
                $fn($nodes) 
            }
        ) 
    }
};

(:~
 : Execute a chain of node transformers.
 :)
declare function xf:do($nodes as node()*, $fns as function(*)*) 
    as node()* {
    xf:do($fns)($nodes)
};

(:~
 : Compose a chain of node transformers.
 :)
declare function xf:do-each($fns as function(*)*) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        for $node in $nodes
        return
            fold-left(
                $fns, 
                $node,
                function($node, $fn) {
                    $fn($node) 
                }
            ) 
    }
};

(:~
 : Execute a chain of node transformers.
 :)
declare function xf:do-each($nodes as node()*, $fns as function(*)*) 
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
 : Return matching nodes.
 :)
declare %private function xf:select-nodes($nodes as node()*, $selectors as function(*)*)
    as node()* {
    for $selector in $selectors
    return
        for $node in $nodes
        return
            $selector($node)
};

(:~
 : Find the first matching template for a node and return
 : it's node transformation function.
 :)
declare %private function xf:match-node($node as node(), $xform as map(*)*) 
    as map(*)? {
    hof:until(
        function($templates as map(*)*) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                ($is-match instance of map(*) and map:contains($is-match,'nodes'))
        },
        function($templates as map(*)*) {
            let $template := head($templates)
            let $matched-nodes := $template('select')($node)
            return
                (
                    if ($matched-nodes) then
                        map:new(($template, map { 'nodes': $matched-nodes }))
                    else
                        ()
                    ,
                    tail($templates)
                )
        },
        $xform
    )[1]
};

(:~
 : Find the first matching template for a node
 : and return a modified template that contains the matched nodes.
 :)
declare %private function xf:match-template($node as node(), $xform as map(*)*) 
    as map(*)? {
    hof:until(
        function($templates as map(*)*) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                ($is-match instance of map(*) and map:contains($is-match,'nodes'))
        },
        function($templates as map(*)*) {
            let $template := head($templates)
            let $matched-nodes := $template('select')($node)
            return
                (
                    if ($matched-nodes) then
                        map:new(($template, map { 'nodes': $matched-nodes }))
                    else
                        ()
                    ,
                    tail($templates)
                )
        },
        $xform
    )[1]
};

(:~
 : Find all templates matched by this node and adds the matched nodes
 : to the templates.
 :)
declare %private function xf:match-templates($node as node(), $xform as map(*)*) 
    as map(*)* {
    fold-left(
        $xform, (),
        function($matched-templates as map(*)*, $template as map(*)) {
            let $matched-nodes := $template('select')($node)
            return
                if ($matched-nodes) then
                    ($matched-templates, map:new(($template, map { 'nodes': $matched-nodes })))
                else
                    $matched-templates
        }
    )
};

declare %private function xf:comp-selector($selectors as item()*)
    as (function(node()*) as node()*)* {
    for $step in $selectors
    return
        if ($step instance of xs:string) then
            xf:xpath-matches($step)
        else
            $step
};

declare %private function xf:comp-expression($expressions as item()*)
    as (function(node()*) as node()*)* {
    for $expression in $expressions
    return
        if ($expression instance of xs:string) then
            xf:xpath-expression($expression)
        else
            $expression
};

(:~
 : Find matches for XPath expression string applied to passed in nodes.
 :)
declare %private function xf:xpath-matches($selector as xs:string) 
    as function(node()*) as node()* {
    xf:xpath-matches($selector, xf:environment())
};

declare %private function xf:xpath-expression($selector as xs:string) 
    as function(node()*) as node()* {
    xf:xpath-matches($selector, xf:expr-environment())
};

declare %private function xf:xpath-matches($selector as xs:string, $env as map(*)) 
    as function(node()*) as node()* {
    let $query := $env('query')($selector)
    let $bindings := $env('bindings')
    return
        function($nodes as node()*) as node()* {
            xquery:eval($query, $bindings($nodes))
        }
};

(:~
 : Returns only distinct nodes.
 : @see http://www.xqueryfunctions.com/xq/functx_distinct-nodes.html
 :)
declare %private function xf:distinct-nodes($nodes as node()*) 
    as node()* {
    for $seq in (1 to count($nodes))
    return $nodes[$seq][
        not(xf:is-node-in-sequence(.,$nodes[position() < $seq]))]
};
 
(:~
 : Is node defined in seq?
 : @see http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence.html
 :)
declare %private function xf:is-node-in-sequence($node as node()?, $seq as node()*)
    as xs:boolean {
    some $nodeInSeq in $seq satisfies $nodeInSeq is $node
};

(:~
 : Partition a sequence into an array of sequences $n long.
 : This is used to build rules that consist of a selector (xf:at) and
 : a body (xf:do).
 :
 : NOTE: currently not used
 :)
declare function xf:partition($n as xs:integer, $seq) as array(*)* {
    if (not(empty($seq))) then
        for $i in 1 to (count($seq) idiv $n) + 1
        where count($seq) > ($i -1) * $n
        return
            array { subsequence($seq, (($i -1) * $n) + 1, $n) }
    else
        ()
};
