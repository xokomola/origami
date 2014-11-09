xquery version "3.0";

(:~
 : Origami xform example: uppercase element and attribute names
 :
 : This requires two templates, one to transform elements and the
 : other to transform attributes. Note that by default the transformer
 : will not modify attributes, you must explicitly apply the templates.  
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/xform/examples';

import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

declare variable $ex:xform :=
    xf:xform((
    
        xf:template(
            '*', function ($node) {
                element { upper-case(name($node)) } {
                    xf:apply(($node/@*, $node/node()))
                }
            }
        ),

        xf:template(
            '@*', function ($node) {
                attribute { upper-case(name($node)) } {
                    string($node)
                }
            }
        )
    ));
    
declare variable $ex:input := 
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p/>
    </a>;

declare variable $ex:output :=
    <A X="10">
        <B Y="20">
            <C/>
        </B>
        <P/>
    </A>;

declare %unit:test function ex:upper-case-elements-and-attributes() {
    unit:assert-equals($ex:xform($ex:input), $ex:output)
};
