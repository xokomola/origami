xquery version "3.0";

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare variable $url external := file:base-dir() || 'ny-times.html';
(: declare variable $url external := 'http://www.nytimes.com'; :)

let $input := xf:html-resource($url)

let $text := function($nodes) { xf:text($nodes[1]) }
let $select-stories := xf:extractor(['article[$in(@class,"story")]'])
let $select-headline := xf:at(['(h2|h3|h5)//a', $text])
let $select-byline := xf:at(['*[$in(@class,"byline")]', $text])
let $select-summary := xf:at(['*[$in(@class,"summary")]', $text])

for $story in $select-stories($input)

    let $headline := $select-headline($story)
    let $byline :=  $select-byline($story)
    let $summary := $select-summary($story)
    
    where $headline and $byline and $summary
    return
      <story>{
        $headline =>  xf:wrap(<headline/>),
        $byline => xf:wrap(<byline/>),
        $summary => xf:wrap(<summary/>)
      }</story>
