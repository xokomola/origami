xquery version "3.0";

(: A faster version of ny-times example :)

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input := xf:html-resource(file:base-dir() || 'ny-times.html')

(:
let $input := xf:html-resource('http://www.nytimes.com')
:)

let $select-stories := xf:extract(
    xf:at('article[contains(@class,"story")]'))
    
for $story in $select-stories($input)

let $headline :=
    $story => xf:at('((h2|h3|h5)//a)[1]/text()')

let $byline := 
    $story => xf:at('*[$in(@class,"byline")][1]/text()')

let $summary :=
    $story => xf:at('*[$in(@class,"summary")][1]/text()')

where $headline and $byline and $summary
return
  <story>
    <headline>{ $headline }</headline>
    <byline>{ $byline }</byline>
    <summary>{ $summary }</summary>
  </story>
