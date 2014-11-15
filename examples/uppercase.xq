xquery version "3.0";

(:~
 : Origami xform example: uppercase element and attribute names
 :
 : This requires two templates, one to transform elements and the
 : other to transform attributes. Note that by default the transformer
 : will not modify attributes, you must explicitly apply the templates.  
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $xform := xf:transform((

    xf:template(
        '*', function($node) {
            element { QName(namespace-uri($node), upper-case(name($node))) } {
                xf:apply($node/(@*, node()))
            }
        }
    ),

    xf:template(
        '@*', function($node) {
            attribute { QName(namespace-uri($node), upper-case(name($node))) } {
                string($node)
            }
        }
    )
))

let $input := 
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p/>
    </a>

return $xform($input)
