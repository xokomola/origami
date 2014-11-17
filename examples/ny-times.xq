xquery version "3.0";

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:
let $url := 'http://www.nytimes.com'
let $input := xf:fetch-html($url)
:)

let $path := file:base-dir() || 'ny-times.html'
let $input := xf:parse-html($path)

let $select-stories := xf:extract(
    xf:select('article[contains(@class,"story")]'))

let $select-headline := xf:extract(
    xf:select(('((h2|h3|h5)//a)[1]', xf:text(), xf:wrap(<headline/>))))

let $select-byline := xf:extract(
    xf:select(('*[$in(@class,"byline")][1]/text()', xf:wrap(<byline/>))))

let $select-summary := xf:extract(
    xf:select(('*[$in(@class,"summary")][1]', xf:text(), xf:wrap(<summary/>))))

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
