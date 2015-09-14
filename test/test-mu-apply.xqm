xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

declare %unit:test function test:apply-attributes() 
{
        unit:assert-equals(
            μ:apply(['x', map { 'a': function($x,$y) { $x + $y }}], [2,4]),
            ['x', map { 'a': 6 }]
        )
};


declare %unit:test function test:xml-templating()
{
    (:~
     : This is the simplest way to build a list.
     :)
    unit:assert-equals(
        μ:xml(
            ['ul', 
                for $i in 1 to 3
                return ['li', concat('item ', $i)] 
            ]
        ),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>,
        'Traditional way to build a list'
    ),

    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['ul', 
                    function($x) { 
                        for $i in 1 to $x 
                        return ['li', concat('item ', $i)] 
                    }
                ],
                3
            )
        ),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>,
        'Build a list using apply'
    ),
   
    (:~
     : The function may produce XML nodes. This is identical
     : to the above but uses a literal element constructor
     : to construct the li elements.
     :)
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['ul', 
                    function($x) { 
                        for $i in 1 to $x 
                        return element li { concat('item ', $i) } 
                    }
                ],
                3
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>
    ),
    
    (:~
     : Produce a table. Multiple arguments have to be specified as a sequence
     : or an array (the outer sequence will be changed into an array so it
     : can be used with fn:apply.
     :)
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['table', 
                    function($r,$c) { 
                        for $i in 1 to $r 
                        return 
                            ['tr', 
                                function($r,$c) {
                                    for $j in 1 to $c
                                    return
                                        ['td', concat('item ',$i,',',$j)]
                                }
                            ]
                    }
                ], 
                (3,2)
            )
        ),
        <table>
            <tr>
              <td>item 1,1</td>
              <td>item 1,2</td>
            </tr>
            <tr>
              <td>item 2,1</td>
              <td>item 2,2</td>
            </tr>
            <tr>
              <td>item 3,1</td>
              <td>item 3,2</td>
            </tr>
          </table>
    )
};

declare %unit:test function test:xml-templating-obfuscated()
{
    (: Not very useful but xml-templates can be nested. :)
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['ul', 
                    function($x) { 
                        for $i in 1 to $x 
                        return μ:apply(function($x) { ['li', concat('item ', $x)] }, $i) 
                    }], 3)),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>
    ),

    (: Still not very useful, but demonstrates how the above is simplified a bit :)
    unit:assert-equals(
        μ:xml(
            μ:apply(['ul', 
                function($x) { 
                    for $i in 1 to $x 
                    return function($x) { ['li', concat('item ', $x)] }($i) 
                }], 3)),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>
    )
};

declare %unit:test("expected", "err:FOAP0001") function test:xml-templating-arity-error()
{
    (: 
     : When a template receives the incorrect number of arguments it will raise an
     : arity error.
     :)
    unit:assert-equals(
        μ:xml(
            μ:apply(
                ['table', 
                    function($r,$c) { 
                        for $i in 1 to $r 
                        return 
                            ['tr', 
                                function($r,$c) {
                                    for $j in 1 to $c
                                    return
                                        ['td', concat('item ',$i,',',$j)]
                                }]
                    }], [(3,2,1)])),
        <table>
            <tr>
              <td>item 1,1</td>
              <td>item 1,2</td>
            </tr>
            <tr>
              <td>item 2,1</td>
              <td>item 2,2</td>
            </tr>
            <tr>
              <td>item 3,1</td>
              <td>item 3,2</td>
            </tr>
          </table>
    )
};
