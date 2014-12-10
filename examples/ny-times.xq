xquery version "3.0";

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';


let $input := xf:html-resource(file:base-dir() || 'ny-times.html')

(:
let $input := xf:html-resource('http://www.nytimes.com')
:)

let $select-stories := xf:extract(
    xf:at('article[contains(@class,"story")]'))

let $select-headline :=
    xf:at(('((h2|h3|h5)//a)[1]', xf:text(), xf:wrap(<headline/>)))

let $select-byline := 
    xf:at(('*[$in(@class,"byline")][1]/text()', xf:wrap(<byline/>)))

let $select-summary :=
    xf:at(('*[$in(@class,"summary")][1]', xf:text(), xf:wrap(<summary/>)))

for $story in $select-stories($input)
let $headline := $select-headline($story)
let $byline := $select-byline($story)
let $summary := $select-summary($story)
where $headline and $byline and $summary
return
  <story>{
    $headline,
    $byline,
    $summary
  }</story>
