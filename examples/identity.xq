xquery version "3.0";

(:~
 : Origami transformer example: the identity transform
 :
 : The default behaviour of the transform is to copy output unmodified.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input := 
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p></p>
    </a>

let $transform := xf:transformer()

return $transform($input)
