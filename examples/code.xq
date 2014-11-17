xquery version "3.0";

(:~
 : Origami extractor example: select code elements from web page.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $extract := xf:extract(xf:select('code'))

let $input := 
    xf:fetch-html("http://xokomola.com/2014/11/10/xquery-origami-1.html")
    
return prof:time($extract($input))
