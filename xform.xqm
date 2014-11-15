xquery version "3.0";

(:~
 : Origami transformers.
 :
 : @version 0.3
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami/xform';

(:~
 : Transforms input, using the specified templates.
 :)
declare function xf:transform($templates as map(*)*, $input as item()*) as item()* {
    xf:transform($templates)($input)
};

(:~
 : Returns a node transformation function.
 :)
declare function xf:transform($templates as map(*)*) as function(*) {
    function ($nodes as item()*) as item()* {
        xf:apply($nodes, $templates)
    }
};

(:~
 : Identity transformer.
 :)
declare function xf:transform() { xf:transform(()) };

(:~
 : Extracts nodes from input, using the specified selectors.
 :)
declare function xf:extract($selectors as function(*)*, $input as item()*) 
    as item()* {
    xf:extract($selectors)($input)
};

(:~
 : Returns an extractor function that only returns selected nodes.
 :)
declare function xf:extract($selectors as function(*)*) 
    as function(*) {
    function ($nodes as item()*) as item()* {
        xf:distinct-nodes(xf:select($nodes, $selectors))
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
        case xs:string return xf:matches(?, $selector)
        case function(item()) as xs:boolean return $selector
        default return ()
    let $body :=
        typeswitch ($body)
        case empty-sequence() return function($node) { () }
        case function(item()) as item()* return $body
        case function(*)* return ()
        default return function($node) { $body }
    where $selector instance of function(*) and $body instance of function(*)
    return
        map {
            'selector': $selector,
            'fn': $body
        }
};

declare function xf:select($selector) as function(item()) 
    as item()* {
    xf:xpath-matches($selector)
};

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy($nodes as item()*, $xform as map(*)*)
    as item()* {
    for $node in $nodes
    return 
        if ($node/self::xf:apply) then
            xf:apply(($node/@*,$node/node()), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                $node/@*,
                xf:copy($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:copy($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Applies node transformations to nodes.
 :)
declare %private function xf:apply($nodes as item()*, $xform as map(*)*)
    as item()* {
    for $node in $nodes
    let $match := xf:match($node, $xform)
    return
        if ($match instance of function(*)) then
            xf:copy($match($node), $xform)
        else if ($node instance of element()) then
            element { node-name($node) } {
                xf:apply($node/@*, $xform),
                xf:apply($node/node(), $xform)   
            }
        else if ($node instance of document-node()) then
            document {
                xf:apply($node/node(), $xform)
            }
        else
            $node
};

(:~
 : Apply to be used from within templates.
 :)
declare function xf:apply($nodes as item()*) 
    as element(xf:apply) { 
    <xf:apply>{ $nodes }</xf:apply> 
};

(:~
 : Return matching nodes.
 :
 : This returns nodes in breadth-first order not in conventional document order.
 :)
declare %private function xf:select($nodes as item()*, $selectors as function(*)*)
    as item()* {
    for $node in $nodes
    return (
        for $selector in $selectors
        return
            $selector($node),
            (: descend :)
            typeswitch($node)
            case element()
            return
                xf:select($node/node(), $selectors)
            case document-node()
            return
                xf:select($node/node(), $selectors)
            default
            return
                ()
    )
};

(:~
 : Find the first matching template for a node and return
 : it's node transformation function.
 :)
declare %private function xf:match($node as item(), $xform as map(*)*) 
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
 : Returns true if the string expression matches the $node.
 :)
declare function xf:matches($node as item(), $selector as xs:string) 
    as xs:boolean {
    typeswitch ($node)
    case element() return not($node/self::xf:*) and $selector = (name($node),'*')
    case attribute() return substring-after($selector, '@') = (name($node), '*')
    default return false()
};

(:~
 : Match using XPath (only works in xf:select)
 :)
declare function xf:xpath-matches($selector as xs:string) 
    as function(item()) as item()* {
    function($node as item()*) as item()* {
        xquery:eval($selector, map { '': $node })
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
 