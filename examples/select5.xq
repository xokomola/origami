xquery version "3.0";

(:~
 : Origami extract example
 :
 : Demonstrates how chain of selectors can modify the result. The first
 : selector returns all code elements and the second selector function
 : wraps all code elements in an extra foo element.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $extract := xf:extract(xf:select(('code', xf:wrap(<foo/>))))

let $input := 
    html:parse(fetch:binary("http://xokomola.com/2014/11/10/xquery-origami-1.html"))
    
return prof:time($extract($input))
