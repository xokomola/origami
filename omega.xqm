xquery version "3.1";

module namespace ω = 'http://xokomola.com/xquery/origami/ω';

declare namespace xsl = 'http://www.w3.org/1999/XSL/Transform';
declare namespace xs = 'http://www.w3.org/2001/XMLSchema';
declare %private variable $ω:ns := 'http://xokomola.com/xquery/origami/ω';

(: FIXME: when giving html without namespace somehow Saxon or BaseX is not dealing with link elements properly :)

(: TODO: maybe use ω as prefix :)
(: TODO: maybe generalize ω:template even further and allow more control
 :       over the transformation so their's a tighther integration with
 :       XSLT.
 :)

(:~
 : Load an HTML resource.
 :)
declare function ω:html-resource($url-or-path)
as document-node()
{
    if (starts-with($url-or-path, 'http://')) then
        ω:fetch-html($url-or-path)
    else
        ω:parse-html($url-or-path)
};

(:~
 : Load an XML resource.
 :)
declare function ω:xml-resource($url-or-path)
as document-node()
{
    doc($url-or-path)
};

(:~
 : Fetch and parse HTML given a URL.
 :)
declare function ω:fetch-html($url)
as document-node()
{
    html:parse(fetch:binary($url))
};

(:~
 : Parse HTML from a filesystem path.
 :)
declare function ω:parse-html($path)
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
declare function ω:template($template as node()*)
as function(*)
{
    ω:template($template, ())
};

(:~
 : Create a template using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function ω:template($template as node()*, $rules as array(*)*)
as function(*)
{
    ω:template($template, $rules, function() { () })
};

(:~
 : Create a template using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
declare function ω:template(
$template as node()*, $rules as array(*)*, $context as function(*))
as function(*)
{
    ω:template($template, $rules, $context, ω:compile-transformer#2)
};

declare %private function ω:template(
$template as node()*, $rules as array(*)*, $context as function(*), $transform as function(*))
as function(*)
{
    let $template := 
        if (count($template) gt 1) then
            element ω:seq { $template }
        else
            $template
            
    let $compiled-template :=
        if (empty($rules)) then
            $template
        else
            xslt:transform($template, $transform($rules, ω:namespaces-map($template)))/*
            
    return
        if (empty($rules)) then
            function() {
                if ($compiled-template/self::ω:seq) then
                    $compiled-template/node()
                else
                    $compiled-template
            }
        else
            let $transform := ω:transform($compiled-template, ?, ω:compile-rules($rules))
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
                    error(ω:ContextArityError, 
                        'ω:template does not support context function arity &gt; 6')
};

(:~
 : Create a template snippet using a node sequence. This template
 : does not have template rules and does not accept any 
 : context arguments. Effectively this will return the
 : template node sequence unmodified.
 :) 
declare function ω:snippet($template as node()*)
as function(*)
{
    ω:snippet($template, ())
};

(:~
 : Create a template snippet using a node sequence and a sequence of
 : template rules. If there are template rules then the
 : template accepts a single map item as context data. If there
 : are no template rules the template will not accept context
 : data.
 :)
declare function ω:snippet($template as node()*, $rules as array(*)*)
as function(*)
{
    ω:snippet($template, $rules, function() { () })
};

(:~
 : Create a template snippet using a node sequence, a sequence of template
 : rules and a context function. The context function determines the
 : signature of the arguments accepted by the template. The context
 : function takes the arguments and prepares the context map for the
 : use by the template rules.
 :)
declare function ω:snippet(
$template as node()*, $rules as array(*)*, $context as function(*))
as function(*)
{
    ω:template($template, $rules, $context, ω:compile-extractor#2)
};

(:~
 : Select nodes from a template using XPath rules.
 :
 : TODO: Note that this goes for a simple functional approach instead of via XSLT.
 : I think we can switch between both using typeswitch.
 :)
declare function ω:select($template as node()*, $selector as function(*))
{
    $selector($template)
};

(: TODO: smarter treatment of rule. :)
(: ['p', ()]   delete p elements :)
(: ['p', <foobar/>] replace p with foobar :)
(: ['p', fn1#2, fn2#2, fn3#2] compose a node transformer/pipeline :)
declare %private function ω:compile-rules($rules as item()*)
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
declare function ω:ctx()
as function(*)
{
    function($ctx) {
        $ctx
    }
};

(: May even make lookup easier by accessing keys in submaps :)
declare function ω:ctx($key as xs:string)
as function(*)
{
    function($ctx) {
        $ctx($key)
    }
};

(: TODO: remove code duplication between this and the next function :)
declare %private function ω:compile-extractor($rules as array(*)*, $namespaces as map(*))
as element(xsl:stylesheet)
{
    element xsl:stylesheet {
        namespace ω { $ω:ns },
        map:for-each(
            $namespaces,
            function($k,$v) {
                namespace { $k } { $v }
            }
        ),
        attribute version { '1.0' },
        element xsl:template {
            attribute match { '/' },
            element ω:seq {
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
                        attribute name { 'ω:node' },
                        $rule(1)
                    },
                    element xsl:copy-of { attribute select { 'node()' } }
                }
            }
    }
};

declare %private function ω:compile-transformer($rules as array(*)*, $namespaces as map(*))
as element(xsl:stylesheet)
{
    element xsl:stylesheet {
        namespace ω { $ω:ns },
        map:for-each(
            $namespaces,
            function($k,$v) {
                namespace { $k } { $v }
            }
        ),
        (: TODO: maybe use 2.0 when present? :)
        attribute version { '1.0' },
        ω:identity-transform(),
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
                        attribute name { 'ω:node' },
                        $rule(1)
                    },
                    element xsl:apply-templates {}
                }
            }
    }
};

declare %private function ω:identity-transform()
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

declare function ω:identity($nodes as item()*)
as item()*
{
    ω:identity($nodes, map {})
};

declare function ω:identity($nodes as item()*, $ctx)
as item()*
{
    for $node in $nodes
    return 
        typeswitch($node)
        case element(ω:seq)
        return
            ω:identity($node/node(), $ctx)
        case element()
        return
            element { node-name($node) } {
                for $att in $node/@*
                where namespace-uri($att) != $ω:ns
                return 
                    attribute {name($att)} {$att},
                ω:identity($node/node(), $ctx)
            }
        default 
        return $node  
};

declare %private function ω:transform(
$nodes as item()*, $ctx, $rules as item()*)
as item()*
{
    for $node in $nodes
    return 
        typeswitch($node)
        case element(ω:seq)
        return
            ω:transform($node/node(), $ctx, $rules)
        case element()
        return
            if ($node/@ω:node) then
                let $xf := $rules(string($node/@ω:node))
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
                            (: ω:copy-namespaces($result), :)
                            for $att in $result/@*
                            where namespace-uri($att) != $ω:ns
                            return 
                                attribute {name($att)} {$att},
                            for $child in $result/node()
                            return 
                                ω:transform($child, $ctx, $rules)
                        }
                    default
                    return $result
            else if ($node/self::ω:seq) then
                ω:transform($node/node(), $ctx, $rules)
            else
                element { node-name($node) } {
                    (: ω:copy-namespaces($node), :)
                    for $att in $node/@*
                    where namespace-uri($att) != $ω:ns
                    return
                        attribute {name($att)} {$att},
                    ω:transform($node/node(), $ctx, $rules)
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
declare %private function ω:namespaces-map($nodes as node()*)
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
declare %private function ω:copy-namespaces($node as element())
as namespace-node()* 
{
    for $ns in in-scope-prefixes($node)
    where not($ns = ('xml','xf',''))
    return
        namespace { $ns } { namespace-uri-for-prefix($ns, $node) }
};
