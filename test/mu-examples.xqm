xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/μ/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/μ' at '../mu.xqm'; 

declare %unit:test function test:lists() 
{
    let $template := ['ul', function($seq) {
            for $item in $seq
            return
                ['li', $item]
            }]
    return (
        unit:assert-equals(
            μ:xml($template, ('item 1', μ:mixed(('item ', ['b', '2'])), 'item 3')),
            <ul>
              <li>item 1</li>
              <li>item <b>2</b></li>
              <li>item 3</li>
            </ul>
        ),
        (: NOTE: apply leaves extra sequences in, they should have significance for output structure :)
        unit:assert-equals(
            μ:apply($template, ('item 1', μ:mixed(('item ', ['b', '2'])), 'item 3')),
            [
              "ul",
              ([
                "li",
                "item 1"
              ],
              [
                "li",
                ("item ",
                [
                  "b",
                  "2"
                ])
              ],
              [
                "li",
                "item 3"
              ])
            ]
        )
    )   
};

declare %unit:test function test:mixing-namespaces()
{
    let $mu := 
        <workspace xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom">{
            μ:xml(
                (['atom:entry'], ['atom:entry'], ['category']), 
                μ:qname-resolver(μ:ns(), 'http://www.w3.org/2007/app')
            )
        }</workspace>
    return
        <todo/>
};

