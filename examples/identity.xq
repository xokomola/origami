xquery version "3.0";

(:~
 : Origami transformer example: the identity transform
 :
 : The default behaviour of the transform is to copy output unmodified.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $transform := xf:transform()

let $input := 
    <a x="10">
        <b y="20">
            <c/>
        </b>
        <p></p>
    </a>

return $transform($input)

(:
    Parsing: 506.69 ms
    Compiling: 8.84 ms
    Evaluating: 0.55 ms
    Printing: 10.05 ms
    Total Time: 526.13 ms
 :)
