xquery version "3.0";

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $tr := xf:transform((
  xf:template('p', function($node) { <foo/> } ),
  xf:template('p[@x]', function($node) { element bar { $node/@* }})
))
let $input :=
  <div><p x="1">hello</p><p/><p x="2"/><p/></div>
return
  $tr($input)