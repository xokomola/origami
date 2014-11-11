xquery version "3.0";

(:~
 : Origami xform example: the identity transform
 :
 : The default behaviour of the transformer is to copy output unmodified.
 : Therefore, identity transform is a transform without any templates.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

let $xform := xf:xform()

let $input := 
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p></p>
    </a>

return $xform($input)
