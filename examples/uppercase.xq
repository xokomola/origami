xquery version "3.0";

(:~
 : Origami transformer example: uppercase element and attribute names
 :
 : This requires two templates, one to transform elements and the
 : other to transform attributes. Note that by default the transformer
 : will not modify attributes, you must explicitly apply the templates.  
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $transform := xf:transform((

    ['*', function($node) {
            element { QName(namespace-uri($node), upper-case(name($node))) } {
                xf:apply($node/(@*, node()))
            }
        }
    ],

    ['@*', function($node) {
            attribute { QName(namespace-uri($node), upper-case(name($node))) } {
                string($node)
            }
        }
    ]
))

let $input :=
  document {
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p/>
    </a>    
  } 

return $transform($input)
