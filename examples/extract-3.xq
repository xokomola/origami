xquery version "3.0";

(:~
 : Origami extract example
 :
 : Extract returns only outermost nodes. This seems more appropriate
 : for a templating library. Use separate extracts to select lists
 : and list items.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';


let $input :=
    document {
        <ul>
          <li id="first">item 1</li>
          <li>item 2</li>
          <li id="last">item 3</li>
        </ul>    
    }
 
let $extract :=
    xf:extract((
        ['li[@id="last"]'],
        ['ul']
    ))

return $extract($input)