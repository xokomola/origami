xquery version "3.0";

(:~
 : Origami transformers.
 :
 : @version 0.2
 : @author Marc van Grootel
 : @see https://github.com/xokomola/origami
 :)

module namespace xf = 'http://xokomola.com/xquery/origami/xform';

(:~
 : Returns a node transformation function.
 :)
declare function xf:xform($templates as map(*)*) as function(*) {
    function ($nodes as item()*) as item()* {
        xf:apply($nodes, $templates)
    }
};

(:~
 : Identity transformer.
 :)
declare function xf:xform() { xf:xform(()) };

(:~
 : Defines a template.
 :)
declare function xf:template($expr, $fn) as map(*) {
    map {
        'match': xf:matches($expr,?),
        'fn': if (empty($fn)) then function ($node) { () }  else $fn
    }
};

(:~
 : Copies nodes to output, and calls apply for
 : nodes that are wrapped inside <xf:apply>.
 :)
declare %private function xf:copy($nodes, $xform) {
    for $node in $nodes
    return 
        if ($node/self::xf:apply) then
            xf:apply(($node/@*,$node/node()), $xform)
        else if ($node instance of element()) then
            element { name($node) } {
                $node/@*,
                xf:copy($node/node(), $xform)   
            }
        else
            $node
};

(:~
 : Applies node transformations to nodes.
 :)
declare %private function xf:apply($nodes, $xform) {
    for $node in $nodes
    let $fn := xf:match($node, $xform)
    return
        if ($fn instance of function(*)) then
            xf:copy($fn($node), $xform)
        else if ($node instance of element()) then
            element { name($node) } {
                xf:apply($node/@*, $xform),
                xf:apply($node/node(), $xform)   
            }
        else
            $node
};

(:~
 : Apply to be used from within templates.
 :)
declare function xf:apply($nodes) { <xf:apply>{ $nodes }</xf:apply> };

(:~
 : Find the first matching template for a node and return
 : it's node transformation function.
 :)
declare %private function xf:match($node, $xform) as function(*)? {
    hof:until(
        function($templates) {
            let $is-match := head($templates)
            return
                empty($is-match) or
                not($is-match instance of map(*))
        },
        function($templates) {
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
declare function xf:matches($expr, $node) as xs:boolean {
    typeswitch ($node)
    case element() return not($node/self::xf:*) and $expr = (name($node),'*')
    case attribute() return substring-after($expr, '@') = (name($node), '*')
    default return false()
};
