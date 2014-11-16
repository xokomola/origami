xquery version "3.0";

(:~
 : Origami templating.
 :
 : @version 0.3
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

(: TODO: attribute tokens selector (for @class) :)

module namespace xf = 'http://xokomola.com/xquery/origami';

(:~
 : Transforms input, using the specified templates.
 : TODO: check if $input and $templates should be switched (like in xf:extract) :)
 :)
declare function xf:transform($templates as map(*)*, $input as node()*)
    as node()* {
    xf:transform($templates)($input)
};

(:~
 : Returns a node transformation function.
 :)
declare function xf:transform($templates as map(*)*) 
    as function(*) {
    function ($nodes as node()*) as node()* {
        xf:apply-nodes($nodes, $templates)
    }
};

(:~
 : Identity transformer.
 :)
declare function xf:transform() { xf:transform(()) };

(:~
 : Extracts nodes from input, using the specified selectors.
 :)
declare function xf:extract($input as node()*, $selectors as function(*)*) 
    as node()* {
    xf:extract($selectors)($input)
};

(:~
 : Returns an extractor function that only returns selected nodes 
 : only outermost in document order and duplicates eleminated.
 :
 : TODO: when running on 8.0 20141116.135016 or higher then
 :       xf:distinct-nodes() can be removed due to bugfix
 :       remove it after 8.0 is released.
 :)
declare function xf:extract($selectors as function(*)*) 
    as function(*) {
    function ($nodes as node()*) as node()* {
        xf:distinct-nodes(outermost(xf:select-nodes($nodes, $selectors)))
    }
};

(:~
 : Defines a template.
 :
 : A template takes a selector string or function and
 : a node transformation function or the items to return as 
 : the template body.
 : Providing invalid matcher returns empty sequence.
 :)
declare function xf:template($selectors, $body) 
    as map(*)? {
    let $selector := xf:select($selectors)
    let $body :=
        typeswitch ($body)
        case empty-sequence() return function($node) { () }
        case function(*) return $body
        default return function($node) { $body }
    where $selector instance of function(*) and $body instance of function(*)
    return
        map {
            'selector': $selector,
            'fn': $body
        }
};

(:~
 : Compose a selector function from a sequence of selectors.
 :)
declare function xf:select($selectors as item()*) 
    as function(node()*) as node()* {
    let $fns :=
        for $selector in $selectors
        return
            if ($selector instance of xs:string) then
                xf:xpath-matches($selector)
            else
                $selector
    return
        function($nodes as node()*) as node()* {
            fold-left($fns, $nodes,
                function($nodes, $fn) {
                    for $node in $nodes
                    return
                        $fn($node)
                }
            )
        }
};

(:~
 : Wrap nodes in an element.
 :)
declare function xf:wrap($node as element())
    as function(*) {
    function($nodes as node()*) as element() {
        element { $node/name() } {
            $node/@*,
            $nodes
        }
    }
};

declare function xf:wrap($node as element(), $nodes as node()*)
    as node()* {
    xf:wrap($node)($nodes)
};

(:~
 : Removes the outer elements from nodes.
 :)
declare function xf:unwrap()
    as function(*) {
    function($nodes as node()*) {
        $nodes/node()
    }
};

declare function xf:unwrap($nodes as node()*)
    as node()* {
    xf:unwrap()($nodes)
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
            xf:apply-nodes(($node/@*,$node/node()), $xform)
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
declare %private function xf:apply-nodes($nodes as node()*, $template as map(*), $xform as map(*)*)
    as node()* {
    for $node in $nodes
    return
        if (xf:is-node-in-sequence($node, $template('nodes')) then
            $template('fn')($node)
        else if ($node instance of element()) then
            element { node-name($node) } {
                $node/@*,
                xf:co-nodes($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:copy-nodes($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Applies node transformations to nodes.
 :)
declare %private function xf:apply-nodes($nodes as node()*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
    (: TODO: rename to match-template :)
    let $match := xf:match-node($node, $xform)
    return
        if ($match instance of function(node()) as item()*) then
            xf:apply-nodes($node, $match, $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                xf:apply-nodes($node/(@*, node()), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:apply-nodes($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Apply to be used from within templates.
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
        for $node in $nodes/descendant-or-self::element()
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
            let $matched-nodes := $template('selector')($node)
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
 : Returns a function that returns true if the passed in node matches
 : the selector string.
 :)
declare function xf:matches($selector as xs:string) 
    as function(*) {
    function($node as node()) as xs:boolean {
        typeswitch ($node)
        case element() return not($node/self::xf:*) and $selector = (name($node), '*')
        case attribute() return substring-after($selector, '@') = (name($node), '*')
        default return false()
    }
};

(:~
 : Match using XPath (only works in xf:select)
 :)
declare %private function xf:xpath-matches($selector as xs:string) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xquery:eval($selector, map { '': $nodes })
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
        not(xf:is-node-in-sequence(
            .,$nodes[position() < $seq]))]
};
 
(:~
 : Is node defined in seq?
 : @see http://www.xqueryfunctions.com/xq/functx_is-node-in-sequence.html
 :)
declare %private function xf:is-node-in-sequence ($node as node()?, $seq as node()*)
    as xs:boolean {
    some $nodeInSeq in $seq satisfies $nodeInSeq is $node
 };
 