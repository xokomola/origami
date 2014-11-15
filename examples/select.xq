xquery version "3.0";

import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

declare variable $input :=
  document {
    <ul>
      <li>item 1</li>
      <li>item 2</li>
      <li id="last">item 3</li>
    </ul>    
  };

declare variable $extract :=
  xf:extract((xf:select('li[@id="last"]'), xf:select('ul')));
  
$extract($input)