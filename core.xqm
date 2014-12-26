xquery version "3.0";

(:~
 : Origami templating.
 :
 : Requires Basex 8.0 20141221 or later.
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
 : Load a plain text resource.
 :)
declare function xf:text-resource($url-or-path) {
    unparsed-text($url-or-path)
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
 : Returns a template function.
 :)
declare function xf:template($template as node(), $selector as array(*)?, $model as item()*)
    as function(*) {
    let $at := if ($selector instance of array(*)) then xf:at($selector) else function($nodes) { $nodes }
    return
        typeswitch ($model)
        (: test array first because it is also a function :)
        case array(*)*
        return
            function() as node()* {
                $template => $at() => xf:transform($model)
            }
        case function(*)
        return
            switch (function-arity($model))
            case 0
            return
                function() as node()* {
                    $template => $at() => xf:transform($model)
                }
            case 1
            return
                function($arg1 as item()?) as node()* {
                    $template => $at() => xf:transform(apply($model, [$arg1]))
                }
            case 2
            return
                function($arg1 as item()?, $arg2 as item()?) as node()* {
                    $template => $at() => xf:transform(apply($model, [$arg1, $arg2]))
                }
            case 3
            return
                function($arg1 as item()?, $arg2 as item()?, $arg3 as item()?) as node()* {
                    $template => $at() => xf:transform(apply($model, [$arg1, $arg2, $arg3]))
                }
            (: max arity-4 supported :)
            case 4
            return
                function($arg1 as item()?, $arg2 as item()?, $arg3 as item()?, $arg4 as item()?) as node()* {
                    $template => $at() => xf:transform(apply($model, [$arg1, $arg2, $arg3, $arg4]))
                }
            default
            return 
                error(xf:ArityNotSupportedError, 'A model function cannot have more than 4 arguments')
            
        case empty-sequence()
        return
            function() as node()* {
                $template => $at()
            }
        default
        return
            error(xf:InvalidModelError, 'This model cannot be used')
};

(:~
 : Apply `$template` to template function.
 :)
declare function xf:template($template as node(), $model as item()*)
    as function(*) {
    xf:template($template, (), $model)
};

(:~
 : Template identity transform.
 :)
declare function xf:template($template as node())
    as function(*) {
    xf:template($template, (), ())
};

(:~
 : Returns a Transformer function.
 :)
declare function xf:transform($rules as array(*)*) 
    as function(node()*) as node()* {
    let $rules :=
        for $rule in $rules
            return xf:match($rule)
    return
        function($nodes as node()*) as node()* {
            xf:apply-nodes(
                $nodes,
                (), 
                $rules)
        }
};

(:~
 : Transform input, using the specified rules.
 :)
declare function xf:transform($nodes as node()*, $rules as array(*)*)
    as node()* {
    xf:transform($rules)($nodes)
};

(:~
 : Identity transformer.
 :)
declare function xf:transform() { xf:transform(()) };

(:~
 : Returns an extractor function that only returns selected nodes 
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract($rules as array(*)*) 
    as function(node()*) as node()* {
    xf:extract-outer($rules)
};

(:~
 : Extracts nodes from input, using the specified rules.
 :)
declare function xf:extract($nodes as node()*, $rules as array(*)*) 
    as node()* {
    xf:extract($rules)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only innermost, in document order and duplicates eliminitated.
 :)
declare function xf:extract-inner($rules as array(*)*) 
    as function(node()*) as node()* {
    let $rules :=
        for $rule in $rules
            return
                xf:at($rule)
    return
        function($nodes as node()*) as node()* {
            innermost(
                for $rule in $rules
                    return $rule($nodes)
            )
        }
};

(:~
 : Apply extractor rules to `$nodes` and return the innermost nodes.
 :)
declare function xf:extract-inner($nodes as node()*, $rules as array(*)*) 
    as node()* {
    xf:extract-inner($rules)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract-outer($rules as array(*)*) 
    as function(node()*) as node()* {
    let $rules :=
        for $rule in $rules
            return xf:at($rule)
    return
        function($nodes as node()*) as node()* {
            outermost(
                for $rule in $rules
                    return $rule($nodes)
            )
        }
};

(:~
 : Apply extractor rules to `$nodes` and return the outermost nodes.
 :)
declare function xf:extract-outer($nodes as node()*, $rules as array(*)*) 
    as node()* {
    xf:extract-outer($rules)($nodes)
};

(:~
 : Create a match template.
 :)
declare function xf:match($rule as array(*)) 
    as map(*)? {
    let $select := xf:selector([array:head($rule)], xf:select#1)
    let $body := xf:do(array:tail($rule))
    where array:size($rule) gt 0
    return
        map {
            'select': $select,
            'fn': $body
        }
};

(:~
 : Create an transformation rule function.
 :)
declare function xf:at($rule as array(*))
    as function(node()*) as node()* {
    xf:selector($rule, xf:select-all#1)
};

(:~
 : Apply a transformation rule to `$nodes`. 
 :)
declare function xf:at($nodes as node()*, $rule as array(*))
    as node()* {
    xf:at($rule)($nodes)
};

(:~
 : Only nodes for which the chain of expressions evaluates to `true()`
 : are passed through.
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
 : Build a node transformation function from a rule.
 :)
declare function xf:do($rule as array(*)) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        array:fold-left(
            $rule, 
            $nodes,
            function($nodes, $step) {
                if ($step instance of function(*)) then
                    $step($nodes)
                else if ($step instance of node()*) then
                    $step
                else
                    ()
            }
        ) 
    }
};

(:~
 : Apply a node transformation rule.
 :)
declare function xf:do($nodes as node()*, $rule as array(*)) 
    as node()* {
    xf:do($rule)($nodes)
};

(:~
 : Return a node transformer that replaces the child nodes of an
 : element with `$content`.
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

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function xf:content($element as element()?, $content as node()*) 
    as element()? {
    xf:content($content)($element)
};

(:~
 : Return a node transformer that replaces the nodes passed with
 : `$replacement`.
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

(:~
 : Replace `$nodes` with `$replacement`.
 :)
declare function xf:replace($nodes as node()*, $replacement as node()*) 
    as node()* {
    xf:replace($replacement)($nodes)
};

(:~
 : Returns a node transformer that inserts `$before` before
 : the nodes passed in.
 :)
declare function xf:before($before as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        ($before, $nodes)
    }
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function xf:before($nodes as node()*, $before as node()*)
    as node()* {
    xf:before($before)($nodes)
};

(:~
 : Returns a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function xf:after($after as node()*)
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        ($nodes, $after)
    }
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function xf:after($nodes as node()*, $after as node()*) 
    as node()* {
    xf:after($after)($nodes)
};

(:~
 : Returns a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
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
 : Inserts `$append` nodes to the child nodes of each element in
 : `$nodes`.
 :)
declare function xf:append($nodes as node()*, $append as node()*) 
    as node()* {
    xf:append($append)($nodes)
};

(:~
 : Returns a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
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
 : Inserts `$prepend` nodes before the first child node of each element
 : in `$nodes`.
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
    function($nodes as item()*) as text()? {
        if (exists($nodes)) then
            text { normalize-space(string-join($nodes,'')) }
        else
            ()
    }
};

(:~
 : Outputs the text value of `$nodes`.
 :)
declare function xf:text($nodes as item()*)
    as text()? {
    xf:text()($nodes)
};

(:~
 : Returns a node transformer that sets attributes using a map
 : on each element in the nodes passed.
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
            return ()
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

(:~
 : Set attributes using a map on each element in `$nodes`.
 :)
declare function xf:set-attr($nodes as node()*, $attributes as item()) 
    as node()* {
    xf:set-attr($attributes)($nodes)
};

(:~
 : Returns a node transformer that adds one or more class names to
 : each element in the nodes passed.
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
 : Returns a node transformer that remove attributes.
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

(:~
 : Remove attributes from each element in `$nodes`.
 :)
declare function xf:remove-attr($nodes as node()*, $names as item()*) 
    as node()* {
    xf:remove-attr($names)($nodes)
};

(:~ 
 : Rename element nodes, passing non-element nodes and element
 : child nodes through unmodified.
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
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as node()* {
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
declare function xf:rename($nodes as node()*, $map as item())
    as node()* {
    xf:rename($map)($nodes)
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

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet.
 :)
declare function xf:xslt($stylesheet as item()) 
    as function(node()*) as node()* {
    xf:xslt($stylesheet, map {})
};

(:~
 : Returns a node transformer that transforms nodes using
 : an XSLT stylesheet with parameters.
 :)
declare function xf:xslt($stylesheet as item(), $params as item()) 
    as function(node()*) as node()* {
    xf:element-transformer(
        function($node as element()) as node()* {
            xslt:transform($node, $stylesheet, $params)/*
        }
    )($params)
};

(:~
 : Transform `$nodes` using XSLT stylesheet.
 :)
declare function xf:xslt($nodes as node()*, $stylesheet as item(), $params as item())
    as node()* {
    xf:xslt($stylesheet, $params)($nodes)
};

(:
 : Creates a generic element node transformer function. It applies
 : `$transform` to each element passed.
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
 : Find matches for XPath expression string applied to passed in nodes
 : including all descendents.
 :)
declare function xf:select-all($selector as xs:string) 
    as function(node()*) as node()* {
    xf:select-with-env($selector, xf:environment())
};

(:~
 : Find matches for XPath expression string applied to passed in nodes
 : including all descendents.
 :)
declare function xf:select-all($nodes as node()*, $selector as xs:string) 
    as function(node()*) as node()* {
    xf:select-all($selector)($nodes)
};

(:~
 : Find matches for XPath expression string applied to passed in nodes.
 :)
declare function xf:select($selector as xs:string) 
    as function(node()*) as node()* {
    xf:select-with-env($selector, xf:expr-environment())
};

(:~
 : Find matches for XPath expression string applied to passed in nodes.
 :)
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

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy-nodes($nodes as node()*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
        return 
            if ($node/self::xf:apply) then
                xf:apply-nodes($node, (), $xform)
            else if ($node instance of element()) then
                element { node-name($node) } {
                    $node/@*,
                    xf:copy-nodes($node/node(), $xform)   
                }
            else if ($node instance of document-node()) then
                document {
                    xf:copy-nodes($node/node(), $xform)
                }
            else $node
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
            if ($node/self::xf:apply) then
                xf:apply-nodes($node/node(), $context, $xform)
            else if ($match instance of map(*)) then
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
 :)
declare function xf:apply($nodes as node()*) 
    as element() { 
    xf:apply()($nodes) 
};

(:~
 : Returns an apply node transfomrer. When used in `xf:transform` it will
 : pass the nodes through all tansformation rules similar to 
 : `<xsl:apply-templates/>` in XSLT.
 :)
declare function xf:apply()
    as function(node()*) as element() {
    function ($nodes as node()*) as element() {
        typeswitch ($nodes)
        case element()
            return
                element { node-name($nodes) } {
                    $nodes/@*,
                    <xf:apply>{ $nodes/node() }</xf:apply>
                }
        default
            return
                <xf:apply>{ $nodes }</xf:apply>
    }
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
                else if ($step instance of node()+) then
                    ($result,
                        function($node as node()+) as node()* {
                            for $node in $step return xf:copy($node) 
                        })
                else if ($step instance of empty-sequence()) then
                    ($result, 
                        function($node as node()*) as node()* {
                            () 
                        })
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
            else $expression
};
 
(:~
 : Returns `true()` if the node `$node` is also in sequence `$seq`. 
 :
 : @see http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence.html
 :)
declare %private function xf:is-node-in-sequence($node as node()?, $seq as node()*)
    as xs:boolean {
    some $nodeInSeq in $seq satisfies $nodeInSeq is $node
};

declare %private function xf:copy($node as node()) 
    as node() {
    typeswitch($node)
    case element()
        return
            element { node-name($node) } {
                $node/@*,
                for $child in $node/node()
                     return xf:copy($child) }         
    default return $node
};