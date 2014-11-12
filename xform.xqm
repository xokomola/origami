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
declare function xf:transform($templates as map(*)*, $input as node()) as node() {
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
declare function xf:extract($selectors as map(*)*, $input as node()) as node() {
    xf:extract($selectors)($input)
};

(:~
 : Returns an extractor function that only returns selected nodes.
 :)
declare function xf:extract($selectors as map(*)*) as function(*) {
    function ($nodes as item()*) as item()* {
        xf:select($nodes, $selectors)
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
declare function xf:template($match, $body) as map(*)? {
    let $match :=
        typeswitch ($match)
        case xs:string return xf:css-matches(?, xf:css-matcher($match))
        case function(item()) as xs:boolean return $match
        default return ()
    let $body :=
        typeswitch ($body)
        case empty-sequence() return function($node) { () }
        case function(item()) as item()* return $body
        case function(*)* return ()
        default return function($node) { $body }
    where $match instance of function(*) and $body instance of function(*)
    return
        map {
            'match': $match,
            'fn': $body
        }
};

declare function xf:select($match) as map(*)? {
    let $match :=
        typeswitch ($match)
        case xs:string return xf:css-matches(?, $match)
        case function(item()) as xs:boolean return $match
        default return ()
    where $match instance of function(*)
    return
        map {
            'match': $match,
            'fn': function($node) { $node }
        }
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
    let $fn := xf:match($node, $xform)
    return
        if ($fn instance of function(*)) then
            xf:copy($fn($node), $xform)
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
 : Look for nodes that match
 :)
declare %private function xf:select($nodes as item()*, $selectors as map(*)*)
    as item()* {
    for $node in $nodes
    let $fn := xf:match($node, $selectors)
    return
        if ($fn instance of function(*)) then
            xf:copy($fn($node), $selectors)
        else if ($node instance of element()) then
            xf:select($node/node(), $selectors)   
        else if ($node instance of document-node()) then
            document {
                xf:select($node/node(), $selectors)
            }
        else
            ()
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
                    if ($template('match')($node)) then
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
declare function xf:matches($node as item(), $expr as xs:string) as xs:boolean {
    typeswitch ($node)
    case element() return not($node/self::xf:*) and $expr = (name($node),'*')
    case attribute() return substring-after($expr, '@') = (name($node), '*')
    default return false()
};

(:~
 : Returns true if the css matcher matches the $node.
 : TODO: add class matching
 :)
declare function xf:css-matches($node as item(), $css-matcher as map(*)) as xs:boolean {
    typeswitch ($node)
    case element() 
    return
        not($node/self::xf:*) and 
        $css-matcher('el') = (local-name($node),'*') and
        ( not($css-matcher('id')) or $css-matcher('id') = trace($node/@id,'ID: ') ) and
        ( not($css-matcher('att')) or $css-matcher('att') = $node/@*/local-name() ) and
        ( not($css-matcher('class') or $node/@class) or 
            ( every $cls in trace($css-matcher('class'),'CLS: ')
            satisfies contains(concat(' ',$node/@class,' '), concat(' ',$cls,' ')) ))
    case attribute() 
    return
        not($css-matcher('att')) or $css-matcher('att') = local-name($node)
    default return false()
};

(:~
 : Build a CSS style matcher map.
 : TODO: fine-tune regexp
 : TODO: make it work for multiple expressions
 :)
declare function xf:css-matcher($expr) as map(*)* {
    for $expr in tokenize($expr,'\s+')[1]
    let $parsed := 
        for $token in analyze-string($expr, '[@#.]?[^@#.]+')/fn:match
        return
            string($token)
    return
         map {
            'att': for $att in $parsed[starts-with(.,'@')][1] return substring-after($att,'@'),
            'el': $parsed[not(starts-with(.,'.') or starts-with(.,'#') or starts-with(.,'@'))],
            'class': for $cls in $parsed[starts-with(.,'.')] return substring-after($cls,'.'),
            'id': for $id in $parsed[starts-with(.,'#')][1] return substring-after($id,'#')
        }
};
