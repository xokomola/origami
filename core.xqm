xquery version "3.0";

(:~
 : Origami templating.
 :
 : @version 0.3
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami';

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
 : Transform input, using the specified templates.
 :)
declare function xf:transform($templates as map(*)*, $input as node()*)
    as node()* {
    xf:transform($templates)($input)
};

(:~
 : Returns a Transformer function.
 :)
declare function xf:transform($templates as map(*)*) 
    as function(node()*) as node()* {
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
 : only outermost, in document order and duplicates eliminated.
 :)
declare function xf:extract($selectors as function(*)*) 
    as function(node()*) as node()* {
    xf:extract-outer($selectors)
};

(:~
 : Returns an extractor function that returns selected nodes,
 : only innermost, in document order and duplicates eliminitated.
 :)
declare function xf:extract-inner($selectors as function(*)*) 
    as function(node()*) as node()* {
    function ($nodes as node()*) as node()* {
        xf:distinct-nodes(innermost(xf:select-nodes($nodes, $selectors)))
    }
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
declare function xf:extract-outer($selectors as function(*)*) 
    as function(node()*) as node()* {
    function ($nodes as node()*) as node()* {
        xf:distinct-nodes(outermost(xf:select-nodes($nodes, $selectors)))
    }
};

(:~
 : Returns a selector step function that returns a text node with
 : the space normalized string value of a node.
 :)
declare function xf:text()
    as function(node()*) as node()* {
    function ($nodes as node()*) as node() {
        text { normalize-space($nodes) }
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
declare function xf:template($selector, $body) 
    as map(*)? {
    let $selector :=
        typeswitch ($selector)
        case xs:string return xf:matches($selector)
        case function(*) return $selector
        default return ()
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
 : Compose a selector function from a sequence of selector functions or Xpath 
 : expressions.
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
 : Returns a selector step function that wraps nodes in
 : an element `$node`.
 :)
declare function xf:wrap($node as element())
    as function(*) {
    function($nodes as node()*) as element() {
        element { node-name($node) } {
            $node/@*,
            $nodes
        }
    }
};

(:~
 : Wraps `$nodes` in element `$node`.
 :)
declare function xf:wrap($node as element(), $nodes as node()*)
    as node()* {
    xf:wrap($node)($nodes)
};

(:~
 : Returns a selector step function that removes the outer
 : element and returns only the child nodes.
 :)
declare function xf:unwrap()
    as function(*) {
    function($nodes as node()*) {
        $nodes/node()
    }
};

(:~
 : Removes the outer
 : element and returns only the child nodes.
 :)
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
            xf:apply-nodes($node/(@*, node()), $xform)
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
 : Applies node transformations to nodes.
 :)
declare %private function xf:apply-nodes($nodes as node()*, $xform as map(*)*)
    as node()* {
    for $node in $nodes
    let $match := xf:match-node($node, $xform)
    return
        if ($match instance of function(node()) as item()*) then
            xf:copy-nodes($match($node), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                xf:apply-nodes($node/(@*,node()), $xform)   
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
        for $node in $nodes
        return
            $selector($node)
};

(:~
 : Find the first matching template for a node and return
 : it's node transformation function.
 :)
declare %private function xf:match-node($node as node(), $xform as map(*)*) 
    as function(*)? {
    hof:until(
        function($templates as map(*)*) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                not($is-match instance of map(*))
        },
        function($templates as map(*)*) {
            let $template := head($templates)
            return
                (
                    if ($template('selector')($node)) then
                        $template('fn')
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
 : Find matches for XPath expression string applied to passed in nodes and
 : all descendants.
 : It also sets up a helper function to enable proper checks on tokenized
 : (space-delimited) attribute values such as @class.
 :)
declare %private function xf:xpath-matches($selector as xs:string) 
    as function(node()*) as node()* {
    function($nodes as node()*) as node()* {
        xquery:eval(
            'declare variable $in external; ' || $selector, 
            map { 
                '': $nodes/descendant-or-self::element(),
                xs:QName('in'): function($att, $token) as xs:boolean {
                    $token = tokenize(string($att),'\s+')
                }
            })
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
 