xquery version "3.0";

(:~
 : Simple query that uses xquery:eval.
 :
 : Example: basex -v -r 100 examples/query.xq
 :)

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare variable $env := xf:context(<p name="foo" xmlns="http://www.w3.org/1999/xhtml"/>);
declare variable $q := xf:query($env);

$q('self::html:p/@name')

