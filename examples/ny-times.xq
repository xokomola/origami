xquery version "3.0";

(: A faster version of ny-times example :)

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input := xf:html-resource(file:base-dir() || 'ny-times.html')

(:
let $input := xf:html-resource('http://www.nytimes.com')
:)

let $select-stories := xf:extract(xf:at('article[$in(@class,"story")]'))
let $select-headline := xf:at('((h2|h3|h5)//a)[1]', xf:text())
let $select-byline := xf:at('*[$in(@class,"byline")][1]', xf:text())
let $select-summary := xf:at('*[$in(@class,"summary")][1]', xf:text())

for $story in $select-stories($input)

    let $headline := $story => $select-headline()
    let $byline := $story => $select-byline()
    let $summary := $story => $select-summary()
    
    where $headline and $byline and $summary
    return
      <story>{
        $headline =>  xf:wrap(<headline/>),
        $byline => xf:wrap(<byline/>),
        $summary => xf:wrap(<summary/>)
      }</story>

(:
    Parsing: 506.85 ms
    Compiling: 31.99 ms
    Evaluating: 1.16 ms
    Printing: 826.16 ms
    Total Time: 1366.15 ms
:)