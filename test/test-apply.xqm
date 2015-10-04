xquery version "3.1";

(:~
 : Tests for o:apply.
 :
 : In most tests o:xml is used to convert the mu-document to XML. This makes
 : it much easier to read. So, strictly, this is not a unit-test any more.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare %unit:test function test:attribute-handler-default() 
{
    unit:assert-equals(
        o:xml(o:apply(
            ['x', map { 
                'a': function($e, $x, $y) { 
                    $x + $y 
                } 
            }],
            [2,4]
        )),
        <x a="6"/>,
        'Attribute handler'
    )    
};

declare %unit:test function test:attribute-handler-custom() 
{
    unit:assert-equals(
        o:xml(o:apply(
            ['x', map { 
                'a': [ function($e, $x, $y) { 
                    $x + $y 
                }, 2,4 ]
            }]
        )),
        <x a="6"/>,
        'Attribute handler with arguments'
    )
};

declare %unit:test function test:content-handler-default()
{  
    unit:assert-equals(
        o:xml(
            o:apply(
                ['ul', 
                    function($e, $n) { 
                        for $i in 1 to $n
                        return ['li', concat('item ', $i)] 
                    }
                ],
                [3]
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        'Default content handler: build a list'
    )
};

declare %unit:test function test:content-handler-custom()
{  
    (: 
     : The custom handler provides the number of items to the handler
     : function.
     :)
    unit:assert-equals(
        o:xml(
            o:apply(
                ['ul', 
                    [ function($e,$x) { 
                        for $i in 1 to $x 
                        return ['li', concat('item ', $i)] 
                    }, 3 ]
                ]
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        'Custom content handler: build a list'
    ),
    
    (: 
     : Identical result but produced with literal element constructors 
     :)
    unit:assert-equals(
        o:xml(
            o:apply(
                ['ul', 
                    [ function($e,$x) { 
                        for $i in 1 to $x 
                        return element li { concat('item ', $i) } 
                    }, 3 ]
                ]
            )
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        'Default content handler: build a list with literal result node
         constructors.'
    )
    
};

(:
 : The following few tests should all produce this table.
 :)
declare variable $test:table :=
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
    </table>;

(:
 : Shows how a nested apply is used to push processing forward into
 : the content produced by a handler.
 :)
declare %unit:test function test:nested-apply-table()
{    
    unit:assert-equals(
        o:xml(
            o:apply(
                ['table',
                    function($e, $rows, $cols) {
                        for $i in 1 to $rows
                        return
                            o:apply(
                                ['tr', 
                                    function($e, $cols) {
                                        for $j in 1 to $cols
                                        return
                                            ['td', concat('item ',$i,',',$j)]
                                    }
                                ],
                                [$cols]
                            )
                    }
                ], 
                [3,2]
            )
        ),
        $test:table,
        'Use nested handlers to produce a table'
    )
    (: TODO: other idiom, can't get it work yet :)
    (:,
            o:apply(
                ['table',
                    function($e, $rows, $cols) {
                        let $rows := trace($rows,'ROWS: ')
                        let $cols := trace($cols, 'COLS: ')
                        return
                        1 to $rows ! o:apply(
                                ['tr', 
                                    function($e, $row, $cols) {
                                      let $row := trace($row, 'CROW: ')
                                      let $cols := trace($cols, 'CCOLS: ')
                                      return
                                       1 to $cols ! o:copy(
                                         ['td', trace(concat('item ',$row,',',.),'I: ')]
                                       )
                                    }
                                ],
                                [.,$cols]
                        )
                    }
                ], 
                [3,2]
            )    
    :)
};
