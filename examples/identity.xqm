xquery version "3.0";

(:~
 : Origami xform example: the identity transform
 :
 : The default behaviour of the transformer is to copy output unmodified.
 : Therefore, identity transform is a transform without any templates.
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/xform/examples';

import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

declare variable $ex:xform := xf:xform();

declare variable $ex:input := 
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p></p>
    </a>;

declare %unit:test function ex:identity-transform() {
    unit:assert-equals($ex:xform($ex:input), $ex:input)
};
