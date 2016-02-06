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
                'a': function($owner, $data as array(xs:integer)) { 
                    $data?1 + $data?2
                } 
            }],
            [2,4]
        )),
        <x a="6"/>,
        "Attribute handler"
    )    
};

declare %unit:test function test:attribute-handler-custom() 
{
    unit:assert-equals(
        o:xml(o:apply(o:doc(
            ['x', map { 
                'a': [ function($owner, $data as xs:integer*) { 
                    sum($data)
                }, 2,4]
            }]
        ))),
        <x a="6"/>,
        "Attribute handler with arguments"
    )
};

declare %unit:test function test:content-handler-default()
{  
    unit:assert-equals(
        o:xml(
            o:apply(
                ['ul', 
                    function($owner, $data) { 
                        for $i in 1 to $data?1
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
        "Default content handler: build a list"
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
            o:apply(o:doc(
                ['ul', 
                    [ function($owner, $data) { 
                        for $i in 1 to $data
                        return ['li', concat('item ', $i)] 
                    }, 3 ]
                ]
            ))
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        "Custom content handler: build a list"
    ),
    
    (: 
     : Identical result but produced with literal element constructors 
     :)
    unit:assert-equals(
        o:xml(
            o:apply(o:doc(
                ['ul', 
                    (: NOTE: $data or $data?1 both work!!! :)
                    [ function($node, $data) { 
                        for $i in 1 to $data
                        return element li { concat('item ', $i) } 
                    }, 3 ]
                ]
            ))
        ),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>,
        "Default content handler: build a list with literal result node
         constructors."
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
                    function($node, $data) {
                        for $i in 1 to $data?1
                        return
                            o:apply(
                                ['tr', 
                                    function($node, $data) {
                                        for $j in 1 to $data?1
                                        return
                                            ['td', concat('item ',$i,',',$j)]
                                    }
                                ],
                                [$data?2]
                            )
                    }
                ], 
                [3,2]
            )
        ),
        $test:table,
        "Use nested handlers to produce a table"
    )
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


declare %unit:test function test:component-0-no-data() 
{
    unit:assert-equals(
        o:apply(o:doc(
            ['foo', function(){ 'foo' }]
        ), ()),
        ['foo', 'foo'],
        "Inline handler"
    )
};

declare %unit:test function test:component-0-data-is-ignored() 
{
    unit:assert-equals(
        o:apply(o:doc(
            ['foo', function() { 'hello' }]
        ), ['foobar']),
        ['foo', 'hello'],
        "Data is ignored as the handler does not use it."
    )
};

declare %unit:test function test:component-1-no-data() 
{
    unit:assert-equals(
        o:apply(o:doc(
            ['foo', function($n) { $n => o:insert('hello') }]
        )),
        ['foo', ['foo', 'hello']],
        "One arity component, only passes in the node"
    )
};

declare %unit:test function test:component-1-data-is-ignored() 
{
    unit:assert-equals(
        o:apply(o:doc(
            ['foo', function($n) { $n => o:insert('hello') }]
        ), ['foobar']),
        ['foo', ['foo', 'hello']],
        "One arity component, only passes in the node, data is always ignored"
    )
};
