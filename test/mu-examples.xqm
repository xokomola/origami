xquery version "3.1";

(:~
 : Examples for μ-documents
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

(:
 : A datastructure with functions can be used
 : as a template with the μ:apply function.
 :)
declare variable $ex:list :=
  ['ul', function($seq) {
    for $item in $seq
    return array:append(['li'], $item)
  }];

(: 
 : In mixed content an attributes map is not allowed.
 : Only values will be used as text nodes.
 :)
declare function ex:list-template() 
{
  μ:apply($ex:list, (
     'item 1', 
     [(), map {'class': 'foo'}, 'item ', ['b', '2']], 
     'item 3'
  ))
};

(:
 : Mixed content function. 
 :)
declare function ex:list-template2() 
{
  μ:apply($ex:list, (
    'item 1', 
    μ:mix(('item ', ['b', '2'])),
    'item 3'
  ))
};

(:
 : Composing templates.
 :)
declare variable $ex:list-item :=
  ['li', map {'class': 'calc'}, function($a,$b) { $a * $b }];
  
declare variable $ex:ol-list :=
  ['ol', function($seq) {
    for $pair in $seq
    return μ:apply($ex:list-item, $pair)      
  }];

(:
 : The top level takes 1 argument, the list item
 : takes 2 arguments. 
 :)
declare function ex:list-template3() 
{
  μ:apply($ex:ol-list, ([1,2],[3,4],[5,6]))
};

(:
 : Slightly different, pass variable arguments for sum. 
 :)
declare variable $ex:list-item2 :=
  ['li', map {'class': 'calc'}, sum(?)];

declare variable $ex:ol-list2 :=
  ['ol', function($seq) {
    for $numbers in $seq
    return μ:apply($ex:list-item2, $numbers)      
  }];

(:
 : Slightly more awkward. Fix this!
 :)
declare function ex:list-template4() 
{
  μ:apply($ex:ol-list, ([(1,2,10,100)],[(3)],[(5,6)]))
};

(:
 : Load a CSV and display it as a table. 
 :)
declare function ex:table-from-csv($name)
{
  μ:parse-csv(μ:read-csv(concat(file:base-dir(), 'csv/', $name)))
};

declare function ex:xml-table-from-csv()
{
  μ:xml(ex:table-from-csv('countries.csv'))
};