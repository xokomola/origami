xquery version "3.1";

(:~
 : Examples for μ-documents
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace o = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

(: Example 1 :)

declare function ex:list-template-traditional() 
{
    let $groceries := ('Apples', 'Bananas', 'Pears')
    let $template :=   
        function($items) {
            <ul class="groceries">{ 
                for $item in $items
                return 
                    <li>{ $item }</li>
            }</ul>
        }
    return $template($groceries)
};

declare %unit:test function ex:test-list-template-traditional()
{
    unit:assert-equals(
        ex:list-template-traditional(),
        <ul class="groceries">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>
    )
};

(: Example 2 :)

declare function ex:list-template-pure() 
{
    let $groceries := ('Apples', 'Bananas', 'Pears')
    let $template :=   
        function($items) {
            ['ul', map { 'class': 'groceries' }, 
                for $item in $items
                return 
                    ['li', $item]
            ]
        }
    return o:xml($template($groceries))
};

declare %unit:test function ex:test-list-template-pure()
{
    unit:assert-equals(
        ex:list-template-pure(),
        <ul class="groceries">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>
    )
};

(: Example 3 :)

declare function ex:list-template-apply() 
{
    let $groceries := ('Apples', 'Bananas', 'Pears')
    let $template :=   
        ['ul', map { 'class': 'groceries' },  
            function($items) {
                for $item in $items
                return 
                    ['li', $item]
            }
        ]
    return o:xml(o:apply($template, $groceries))
};

declare %unit:test function ex:test-list-template-apply()
{
    unit:assert-equals(
        ex:list-template-apply(),
        <ul class="groceries">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>
    )
};

(: Example 4 :)

declare function ex:list-template-dsl()
{
    let $groceries := ('Apples', 'Bananas', 'Pears')
    let $list := 
        ex:template(
            <ul>
            <li ex:for-each=".">item 1</li>
            <li ex:remove=".">item 2</li>
            <li ex:remove=".">item 3</li>
            </ul>
        )
    return o:apply($list, $groceries)
};

declare function ex:for-each($nodes, $items) {
    for $item in $items
    return
        (: currently o:replace isn't working :)
        (: o:replace($nodes, $item) :)
        ['li', $item]
};

declare function ex:template($xml) {
    o:template(
        $xml,
        (
            ['li[@ex:for-each]', ex:for-each#2],
            ['li[@ex:remove]', ()]
        )
    )
};

(: TODO: mu namespace shouldn't be here, see comment in code :)
declare %unit:test function ex:test-list-template-dsl()
{
    unit:assert-equals(
        o:xml(ex:list-template-dsl()),
        <ul xmlns:μ="http://xokomola.com/xquery/origami/mu">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>
    )  
};

(:
 : Composing templates.
 :
 : Free functions do not receive the node as automatic first arg.
 :)
declare variable $ex:list-item :=
  ['li', map {'class': 'calc'}, function($pair) { sum($pair) }];
  
declare variable $ex:ol-list :=
  ['ol', function($seq) {
    for $pair in $seq
    return o:apply($ex:list-item, $pair)      
  }];

(:
 : The top level takes 1 argument, the list item
 : takes 2 arguments. 
 :)
declare function ex:list-template3() 
{
    o:apply($ex:ol-list, ([1,2],[3,4],[5,6]))
};

declare %unit:test function ex:test-list-template3()
{
    unit:assert-equals(
        o:xml(ex:list-template3()),
        <ol xmlns:μ="http://xokomola.com/xquery/origami/mu">
            <li class="calc">3</li>
            <li class="calc">7</li>
            <li class="calc">11</li>
        </ol>
    )
};
