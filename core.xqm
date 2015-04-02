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
declare function xf:template($template as item()*, $selector as array(*)?, $model as item()*)
    as function(*) {
    let $at := if ($selector instance of array(*)) then xf:at($selector) else function($nodes) { $nodes }
    return
        typeswitch ($model)
        (: test array first because it is also a function :)
        case array(*)*
        return
            function() as item()* {
                $template => $at() => xf:transform($model)
            }
        case function(*)
        return
            switch (function-arity($model))
            case 0
            return
                function() as item()* {
                    $template => $at() => xf:transform($model)
                }
            case 1
            return
                function($arg1 as item()?) as item()* {
                    $template => $at() => xf:transform(apply($model, [$arg1]))
                }
            case 2
            return
                function($arg1 as item()?, $arg2 as item()?) as item()* {
                    $template => $at() => xf:transform(apply($model, [$arg1, $arg2]))
                }
            case 3
            return
                function($arg1 as item()?, $arg2 as item()?, $arg3 as item()?) as item()* {
                    $template => $at() => xf:transform(apply($model, [$arg1, $arg2, $arg3]))
                }
            (: max arity-4 supported :)
            case 4
            return
                function($arg1 as item()?, $arg2 as item()?, $arg3 as item()?, $arg4 as item()?) as item()* {
                    $template => $at() => xf:transform(apply($model, [$arg1, $arg2, $arg3, $arg4]))
                }
            default
            return 
                error(xf:ArityNotSupportedError, 'A model function cannot have more than 4 arguments')
            
        case empty-sequence()
        return
            function() as item()* {
                $template => $at()
            }
        default
        return
            error(xf:InvalidModelError, 'This model cannot be used')
};

(:~
 : Apply `$template` to template function.
 :)
declare function xf:template($template as item(), $model as item()*)
    as function(*) {
    xf:template($template, (), $model)
};

(:~
 : Template identity transform.
 :)
declare function xf:template($template as item())
    as function(*) {
    xf:template($template, (), ())
};

(:~
 : Returns a Transformer function.
 :)
declare function xf:transformer($rules as array(*)*) {
    xf:transformer($rules, $xf:environment)
};

declare function xf:transformer($rules as array(*)*, $environment as map(*)) 
    as function(item()*) as item()* {
    let $rules :=
        for $rule in $rules
            return xf:match($rule)
    return
        function($nodes as item()*) as item()* {
            xf:apply-nodes(
                $nodes,
                (), 
                $rules)
        }
};

(:~
 : Identity transformer.
 :)
declare function xf:transformer() { xf:transformer(()) };

(:~
 : Transform input, using the specified rules.
 :)
declare function xf:transform($nodes as item()*, $rules as array(*)*)
    as item()* {
    xf:transformer($rules)($nodes)
};

(:~
 : Returns an extractor function that only returns selected nodes 
 : only outermost, in document order and duplicates eliminated.
 :)

declare function xf:extractor($rules as array(*)*) 
    as function(item()*) as item()* {
    xf:outer-extractor($rules, $xf:environment)
};

declare function xf:extractor($rules as array(*)*, $environment as map(*)) 
    as function(item()*) as item()* {
    xf:outer-extractor($rules, $environment)
};

(:~
 : Extracts nodes from input, using the specified rules.
 :)
declare function xf:extract($nodes as item()*, $rules as array(*)*) 
    as item()* {
    xf:extractor($rules)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only innermost, in document order and duplicates eliminitated.
 :)
declare function xf:inner-extractor($rules as array(*)*) 
    as function(item()*) as item()* {
    xf:inner-extractor($rules, $xf:environment)
};

declare function xf:inner-extractor($rules as array(*)*, $environment as map(*)) 
    as function(item()*) as item()* {
    let $rules :=
        for $rule in $rules
            return
                xf:at($rule, $environment)
    return
        function($nodes as item()*) as item()* {
            innermost(
                for $rule in $rules
                    return $rule($nodes)
            )
        }
};

(:~
 : Apply extractor rules to `$nodes` and return the innermost nodes.
 :)
declare function xf:extract-inner($nodes as item()*, $rules as array(*)*) 
    as item()* {
    xf:inner-extractor($rules)($nodes)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:outer-extractor($rules as array(*)*) 
    as function(item()*) as item()* {
    xf:outer-extractor($rules, $xf:environment)
};

declare function xf:outer-extractor($rules as array(*)*, $environment as map(*)) 
    as function(item()*) as item()* {
    let $rules :=
        for $rule in $rules
            return xf:at($rule, $environment)
    return
        function($nodes as item()*) as item()* {
            outermost(
                for $rule in $rules
                    return $rule($nodes)
            )
        }
};

(:~
 : Apply extractor rules to `$nodes` and return the outermost nodes.
 :)
declare function xf:extract-outer($nodes as item()*, $rules as array(*)*) 
    as item()* {
    xf:outer-extractor($rules)($nodes)
};

(:~
 : Create a match function from a rule.
 :)
declare function xf:match($rule as array(*))
    as map(*)? {
    xf:match($rule, $xf:environment)
};
declare function xf:match($rule as array(*), $environment as map(*)) 
    as map(*)? {
    let $select := xf:selector([array:head($rule)], xf:select(?,$environment))
    let $body := xf:do(array:tail($rule))
    where array:size($rule) gt 0
    return
        map {
            'select': $select,
            'fn': $body
        }
};

(:~
 : Create a selector function from a rule.
 :)
declare function xf:at($rule as array(*))
    as function(item()*) as item()* {
    xf:at($rule, $xf:environment)
};

declare function xf:at($rule as array(*), $environment as map(*))
    as function(item()*) as item()* {
    xf:selector($rule, xf:select-all(?, $environment))
};

(:~
 : Create a node transformer that applies a node transformation rule to a
 : sequence of input nodes.
 :)
declare function xf:do($rule as array(*)) 
    as function(item()*) as item()* {
    function($nodes as item()*) as item()* {
        xf:do-nodes($nodes, $rule)
    }
};

(:~
 : Apply a node transformation rule to a sequence of nodes.
 :)
declare function xf:do($nodes as item()*, $rule as array(*)) 
    as item()* {
    xf:do-nodes($nodes, $rule)
};

(:~
 : Create a node transformer that applies a node transformation rule to each 
 : individual input node.
 :)
declare function xf:each($rule as array(*)) 
    as function(item()*) as item()* {
    function($nodes as item()*) as item()* {
        for $node in $nodes
            return xf:do-nodes($node, $rule)
    }
};

(:~
 : Apply a node transformation rule to each individual input node.
 :)
declare function xf:each($nodes as item()*, $rule as array(*)) 
    as item()* {
    for $node in $nodes
        return xf:do-nodes($node, $rule)
};

declare %private function xf:do-nodes($nodes as item()*, $rule as array(*))
    as item()* {
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

(:~
 : Only nodes for which the chain of expressions evaluates to `true()`
 : are passed through.
 :)
declare function xf:if($conditions as item()*) 
    as function(item()*) as item()* {
    let $conditions := xf:comp-expression($conditions)
    return
        function($nodes as item()*) as item()* {
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
declare function xf:if($nodes as item()*, $conditions as item()*) 
    as item()* {
    xf:if($conditions)($nodes)
};

declare %private function xf:comp-expression($expressions as item()*)
    as (function(item()*) as item()*)* {
    for $expression in $expressions
        return
            if ($expression instance of xs:string) then 
                xf:select($expression)
            else $expression
};

(:~
 : Create a node transformer that replaces the child nodes of an
 : element with `$content`.
 :)
declare function xf:content($content as item()*)
    as function(item()*) as item()* {
    xf:element-transformer(
        function($node as element()) as element() {
            element { node-name($node) } {
                $node/@*,
                $content
            }
        }
     (: HACK :)
    )(true())
};

(:~
 : Replace the child nodes of `$element` with `$content`.
 :)
declare function xf:content($nodes as item()*, $content as item()*) 
    as item()* {
    xf:content($content)($nodes)
};

(:~
 : Create a node transformer that replaces the nodes passed with
 : `$replacement`.
 :)
declare function xf:replace($replacement as item()*)
    as function(item()*) as item()* {
    function($nodes as item()*) as item()* {
        if (exists($nodes)) then
            $replacement
        else
            $nodes
    }
};

(:~
 : Replace `$nodes` with `$replacement`.
 :)
declare function xf:replace($nodes as item()*, $replacement as item()*) 
    as item()* {
    xf:replace($replacement)($nodes)
};

(:~
 : Create a node transformer that inserts `$before` before
 : the nodes passed in.
 :)
declare function xf:before($before as item()*)
    as function(item()*) as item()* {
    function($nodes as item()*) as item()* {
        ($before, $nodes)
    }
};

(:~
 : Inserts the `$before` nodes, before `$nodes`.
 :)
declare function xf:before($nodes as item()*, $before as item()*)
    as item()* {
    xf:before($before)($nodes)
};

(:~
 : Create a node transformer that inserts `$after` after
 : the nodes passed in.
 :)
declare function xf:after($after as item()*)
    as function(item()*) as item()* {
    function($nodes as item()*) as item()* {
        ($nodes, $after)
    }
};

(:~
 : Inserts the `$after` nodes, after `$nodes`.
 :)
declare function xf:after($nodes as item()*, $after as item()*) 
    as item()* {
    xf:after($after)($nodes)
};

(:~
 : Create a node transformer that appends `$append` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function xf:append($append as item()*)
    as function(item()*) as item()* {
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
    as item()* {
    xf:append($append)($nodes)
};

(:~
 : Create a node transformer that prepends `$prepend` nodes
 : to the child nodes of each element of `$nodes`.
 :)
declare function xf:prepend($prepend as item()*)
    as function(item()*) as item()* {
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
    as item()* {
    xf:prepend($prepend)($nodes)
};

(:~
 : Create a node transformer that returns a text node with
 : the space normalized string value of a node.
 :)
declare function xf:text()
    as function(item()*) as item()* {
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
    as item()* {
    xf:text()($nodes)
};

(:~
 : Create a node transformer that sets attributes using a map
 : on each element in the nodes passed.
 :
 : Map keys must be valid as QNames or they will be ignored.
 :)
declare function xf:set-attr($attributes as item())
    as function(item()*) as item()* {
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
declare function xf:set-attr($nodes as item()*, $attributes as item()) 
    as item()* {
    xf:set-attr($attributes)($nodes)
};

(:~
 : Create a node transformer that adds one or more class names to
 : each element in the nodes passed.
 :)
declare function xf:add-class($names as xs:string*)
    as function(item()*) as item()* {
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
    as item()* {
    xf:add-class($names)($nodes)
};

(:~
 : Create a node transformer that removes one or more `$names` from the 
 : class attribute. If the class attribute is empty after removing names it will 
 : be removed from the element.
 :)
declare function xf:remove-class($names as xs:string*)
    as function(item()*) as item()* {
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
    as item()* {
    xf:remove-class($names)($nodes)
};

(:~
 : Create a node transformer that remove attributes.
 :
 : If a name cannot be used as an attribute name (xs:QName) then
 : it will be silently ignored.
 :)
declare function xf:remove-attr($attributes as item()*)
    as function(item()*) as item()* {
    let $names := 
        typeswitch ($attributes)
        case xs:string*
            return 
                for $name in $attributes 
                return
                    if ($name eq '*') then
                        '*'
                    else if ($name castable as xs:QName) then
                        attribute { $name } { '' }
                    else
                        ()
        case element()
            return $attributes/@*
        case map(*)
            return             
                map:for-each(
                    $attributes, 
                    function($name,$value) { 
                    if ($name castable as xs:QName) then
                        attribute { $name } { '' }
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
                        where not($names = '*') and
                              not(node-name($att) = $names/node-name()) 
                        return $att
                }
            }
        )($attributes)
};

(:~
 : Remove attributes from each element in `$nodes`.
 :)
declare function xf:remove-attr($nodes as item()*, $names as item()*) 
    as item()* {
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
    as function(item()*) as item()* {
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
    as item()* {
    xf:rename($map)($nodes)
};

(:~
 : Create a node transformer that wraps nodes in
 : an element `$element` and adding attributes from `$map` if present.
 : Attributes already on `$element` cannot be overwritten.
 : An empty sequence will not be wrapped.
 :)
declare function xf:wrap($element-spec as item())
    as function(item()*) as element()? {
    let $args :=
        if ($element-spec instance of element()) then 
            $element-spec 
        else 
            array:flatten($element-spec)
    let $element as element() := $args[1]
    let $map as map(*)? := $args[2]
    where $element
    return
        function($nodes as item()*) as element()? {
            if (exists($nodes)) then
                element { node-name($element) } {
                    $element/@*,
                    if (exists($map)) then
                        map:for-each(
                            $map,
                            function($k,$v) {
                                if (not($element/@*[node-name(.) eq xs:QName($k)])) then
                                    attribute { $k } { $v }
                                else
                                    ()
                            }
                        )
                    else 
                        (),
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
declare function xf:wrap($nodes as item()*, $element-spec as item())
    as element()? {
    xf:wrap($element-spec)($nodes)
};

(:~
 : Create a node transformer that removes (unwraps) the
 : outer element of all nodes that are elements. Other nodes
 : are passed through unmodified.
 :
 : This function is safe for use as a node selector.
 :)
declare function xf:unwrap()
    as function(item()*) as item()* {
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
declare function xf:unwrap($nodes as item()*)
    as item()* {
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
 : Create a node transformer that transforms nodes using
 : an XSLT stylesheet with parameters.
 :)
declare function xf:xslt($stylesheet as item(), $params as item()) 
    as function(item()*) as item()* {
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
    as item()* {
    xf:xslt($stylesheet, $params)($nodes)
};

(:
 : Creates a generic element node transformer function. It applies
 : `$transform` to each element passed.
 :)
declare function xf:element-transformer($transform as function(element()) as item()*) 
    as function(*) {
    function($args as item()*) as function(*) {
        function($nodes as item()*) as item()* {
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
(:~
 : Builds an eval environment from individual elements.
 :
 : Environments can be composed from smaller parts and
 : when a transformer or extractor is created the environment
 : can be passed as the third argument to provide a customized
 : environment (e.g. namespaces, variables, imports etc.)
 :)
declare function xf:env($list as item()*) as map(*) {
    map {
        'bindings': fold-left(
            $list,
            map {},
            function($bindings, $element) {
                if ($element instance of array(*) and $element(1) eq xs:QName('xf:var'))
                then map:merge(($bindings, map { $element(2): $element(3) }))
                else $bindings
            }
        ),
        'imports': fold-left(
            $list,
            map {},
            function($imports, $element) {
            if ($element instance of array(*) and $element(1) eq xs:QName('xf:import'))
                then map:merge(($imports, 
                    map { 
                        xs:QName(name($element(2))): (data($element(2)),$element(3)) 
                    }))
                else $imports
            }
        ),
        'namespaces': fold-left(
            $list,
            map {},
            function($namespaces, $element) {
                if ($element instance of namespace-node())
                then map:merge(($namespaces, map { xs:QName(name($element)): data($element) }))
                else $namespaces
            }
        ),
        'options': fold-left(
            $list,
            map {},
            function($options, $element) {
                if ($element instance of array(*) and $element(1) eq xs:QName('xf:option'))
                then map:merge(($options, map { $element(2): $element(3) }))
                else $options
            }
        ),
        '': fold-left(
            $list,
            (),
            function($ctx, $element) {
                if ($element instance of array(*) and $element(1) eq xs:QName('xf:ctx'))
                then ($ctx, $element(2))
                else $ctx
            }
        )
    }
};

(:~
 : Namespace declaration.
 :)
declare function xf:var($name, $value) {
    [xs:QName('xf:var'), xs:QName($name), $value]
};

(:~
 : Context declaration.
 :)
declare function xf:ctx($nodes as item()*) {
    [xs:QName('xf:ctx'), $nodes]
};

(:~
 : Namespace node. Get the $prefix using fn:name#1, and the $uri is the value 
 : (or use fn:data#1
 :)
declare function xf:ns($prefix, $uri) {
    namespace {$prefix} {$uri}
};

(:~
 : Import repo module.
 :)
declare function xf:import($prefix, $uri) {
    [xs:QName('xf:import'), namespace {$prefix} {$uri}, ()]
};

(:~
 : Import file system module.
 :)
declare function xf:import($prefix, $uri, $path) {
    [xs:QName('xf:import'), namespace {$prefix} {$uri}, resolve-uri($path)]
};

(:~
 : Permission environment option.
 :)
declare function xf:permission($perms as xs:string) {
    [xs:QName('xf:option'), 'permission', $perms]
};

(:~
 : Timeout environment option.
 :)
declare function xf:timeout($seconds as xs:integer) {
    [xs:QName('xf:option'), 'timeout', $seconds]
};

(:~
 : Memory environment option.
 :)
declare function xf:memory($mb as xs:integer) {
    [xs:QName('xf:option'), 'memory', $mb]
};

(:~
 : Environment map
 :
 : bindings -  a map with the bindings
 : namespaces - a map with namespaces
 : imports - a map with imports (key = ns prefix, value is two item list (ns, location))
 : options / memory
 : options / timeout
 : options / permission
 :)
declare function xf:environment() as map(*) {
    xf:environment(map {})
};

declare function xf:environment($env-map as map(*)) as map(*) {
    let $bindings := ($env-map('bindings'), map {})[1]
    let $options := ($env-map('options'), map {})[1]
    let $prolog := string-join((

            let $imports := $env-map('imports')
            where $imports instance of map(*)
            for $import in map:keys($imports)
            return
                'import module namespace ' || $import || ' = "' || 
                    $imports($import)[1] || '" at "' || 
                    $imports($import)[2] || '";',

            let $nss := $env-map('namespaces')
            where $nss instance of map(*)
            for $ns in map:keys($nss)
            return
                'declare namespace ' || $ns || ' = "' || $nss($ns) || '";',
                
            let $vars := $env-map('bindings')
            where $vars instance of map(*)
            for $var in map:keys($vars)
            where $var ne ''
            return
                'declare variable $' || $var || ' external;'
                
            
        ),'')
    return
        map { 
            'bindings': $bindings,
            'options': $options,
            'prolog': $prolog
        }
        
};

(: TEST function for showing how to build a better env :)
(:
declare function xf:env($node) {
    xf:in-scope-namespace-uris($node)
};

declare %private function xf:in-scope-namespace-uris($node as node()?) 
    as xs:anyURI* {
    fold-left(
        fn:in-scope-prefixes($node),
        (),
        function($ns-list, $prefix) {
            ($ns-list, [ $prefix, namespace-uri-for-prefix($prefix) ])
        }
    )
};
:)

(:~
 : Create a function for querying over a given set of nodes.
 :
 : TODO: review if needed.
 :)
declare function xf:query($nodes as item()*, $env as map(*)) as function(*) {
    let $bindings := map:merge(($env('bindings'), map { '': $nodes }))
    return
        function($query as xs:string) as item()* {
            xquery:eval(trace($env('prolog') || $query, 'Q: '), $bindings, $env('options'))
        }
};

declare variable $xf:environment :=
    xf:environment(
        map { 'bindings': 
            map { 'in': 
                        function($att, $token) as xs:boolean {
                            $token = tokenize(string($att),'\s+')
                        } 
                }
        }
    );

(:~
 : Find matches for XPath expression string applied to passed in nodes
 : including all descendents.
 :)
declare %private function xf:select-all($selector as xs:string) 
    as function(item()*) as item()* {
    xf:select-all($selector, $xf:environment)
};

declare %private function xf:select-all($selector as xs:string, $environment as map(*)) 
    as function(item()*) as item()* {
    let $bindings := $environment('bindings')
    let $options := $environment('options')
    let $prolog := $environment('prolog')
    return  
        function($nodes as item()*) as item()* {
            xquery:eval(
                $prolog || $selector, 
                map:merge(($bindings,map {'': $nodes/descendant-or-self::node() })), 
                $options
            )
        }
};

(:~
 : Find matches for XPath expression string applied to passed in nodes.
 : TODO: remove this in favor of xf:selector($env)
 :)
declare %private function xf:select($selector as xs:string)
    as function(item()*) as item()* {
    xf:select($selector, $xf:environment)
};

declare %private function xf:select($selector as xs:string, $environment as map(*)) 
    as function(item()*) as item()* {
    let $bindings := $environment('bindings')
    let $options := $environment('options')
    let $prolog := $environment('prolog')
    return
        function($nodes as item()*) as item()* {
            xquery:eval(
                $prolog || $selector, 
                map:merge(($bindings, map {'': $nodes })), 
                $options
            )
        }
};

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy-nodes($nodes as item()*, $xform as map(*)*)
    as item()* {
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
declare %private function xf:apply-nodes($nodes as item()*, $context as map(*)*, $xform as map(*)*)
    as item()* {
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
declare function xf:apply($nodes as item()*) 
    as element() { 
    xf:apply()($nodes) 
};

(:~
 : Returns an apply node transfomrer. When used in `xf:transform` it will
 : pass the nodes through all tansformation rules similar to 
 : `<xsl:apply-templates/>` in XSLT.
 :)
declare function xf:apply()
    as function(item()*) as element() {
    function ($nodes as item()*) as element() {
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
declare %private function xf:match-templates($node as item(), $xform as map(*)*) 
    as map(*)* {
    fold-left(
        $xform, 
        (),
        function($matched-templates as map(*)*, $template as map(*)) {
            let $matched-nodes := $template('select')($node)
            return
                if (exists($matched-nodes)) then
                    ($matched-templates, map:merge(($template, map { 'nodes': $matched-nodes })))
                else
                    $matched-templates
        }
    )
};

(:~
 : Looks in the $context to find a template that was matched by this
 : node. First one found (most-specific) wins.
 :)
declare %private function xf:matched-template($node as item(), $context as map(*)*) 
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
    as function(item()*) as item()* {
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
                        function($node as item()*) as item()* {
                            () 
                        })
                else
                    ($result, text { $step })
            }
        )
    return
        function($nodes as item()*) as item()* {
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