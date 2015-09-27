xquery version "3.1";

(:~
 : Tests for μ:apply.
 :
 : In most tests μ:xml is used to convert the mu-document to XML. This makes
 : it much easier to read. So, strictly, this is not a unit-test any more.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' 
    at '../mu.xqm'; 
import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare variable $test:html :=
    <html>
        <head>
            <title>title</title>
        </head>
        <body>
            <div id="content">
                <table id="table-1">
                    <tr>
                        <th>A</th><th>B</th><th>C</th>
                    </tr>
                    <tr>
                        <td><a href="a-link">10</a></td><td>20</td><td>30</td>
                    </tr>
                </table>
                <ol id="list-1">
                    <li>item 1</li>
                    <li>item 2</li>
                    <li>item 3</li>
                </ol>
                <div id="sub-content">
                    <ol id="list-2">
                        <li>item 3</li>
                        <li>item 4</li>
                        <li>item 5</li>
                    </ol> 
                </div>
            </div>
            <ol id="list-3">
                <li>item 6</li>
                <li>item 7</li>
                <li>item 8</li>
            </ol> 
        </body>
    </html>;

declare variable $test:html-no-lists :=
    <html>
        <head>
            <title>title</title>
        </head>
        <body>
            <div id="content">
                <table id="table-1">
                    <tr>
                        <th>A</th><th>B</th><th>C</th>
                    </tr>
                    <tr>
                        <td><a href="a-link">10</a></td><td>20</td><td>30</td>
                    </tr>
                </table>
                <div id="sub-content">
                </div>
            </div>
        </body>
    </html>;

declare function test:xf($rules)
{
    μ:xml(o:transformer($rules)($test:html))
};

declare %unit:test function test:empty() 
{
    unit:assert-equals(
        test:xf([]),
        (),
        'No transform rules, no result'
    )    
};

declare %unit:test function test:copy-whole-page() 
{
    unit:assert-equals(
        test:xf(['html']),
        $test:html,
        'Take the whole html document'
    )    
};


declare %unit:test function test:extract-lists() 
{
    unit:assert-equals(
        test:xf(
            ['ol']
        ),
        ($test:html//ol[@id='list-1'], $test:html//ol[@id='list-2'], $test:html//ol[@id='list-3']),
        'Take all lists in order'
    ),
    unit:assert-equals(
        test:xf(
            ['div', ['ol']]
        ),
        ($test:html//ol[@id='list-1'], $test:html//ol[@id='list-2']),
        'Take some lists using nested rule'
    )
};

declare %unit:test function test:remove-lists() 
{
    unit:assert-equals(
        test:xf(
            ['ol', ()]
        ),
        $test:html-no-lists,
        'Remove all lists'
    ),
    unit:assert-equals(
        test:xf(
            ['div', ['ol', ()]]
        ),
        $test:html-no-lists,
        'Remove some lists using nested rule'
    )
};

(: remove all but first item from a list :)
(: ['ol', ['li[1]'], ['li', ()]] :)
(: return only first item from a list :)
(: ['ol', (), ['li[1]']] :)

 