xquery version "3.0";

(: A faster version of ny-times example :)
(: This version is comparable to the previous one :)

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input := xf:html-resource(file:base-dir() || 'ny-times.html')

(:
let $input := xf:html-resource('http://www.nytimes.com')
:)

let $text := function($nodes) { xf:text($nodes[1]) }
let $select-stories := xf:extract(['article[$in(@class,"story")]'])
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
