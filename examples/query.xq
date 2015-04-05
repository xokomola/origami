xquery version "3.0";

(:~
 : Simple query that uses xquery:eval.
 :
 : Example: basex -V -r 100 examples/query.xq
 :
 : Parsing: 27.14 ms (avg)
 : Compiling: 5.12 ms (avg)
 : Evaluating: 27.78 ms (avg)
 : Printing: 0.03 ms (avg)
 : Total Time: 60.06 ms (avg)
 : 
 :)

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare variable $env := xf:context(<p name="foo" xmlns="http://www.w3.org/1999/xhtml"/>);
declare variable $q := xf:query($env);

$q('self::html:p/@name')

