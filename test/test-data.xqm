xquery version "3.1";

(:~
 : Origami tests: μ:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm';

declare %unit:test function test:attribute-handlers() 
{
    unit:assert-equals(
        o:apply(['foo', map { 'bar': function($e) { 100 } }]),
        ['foo', map { 'bar': 100 }],
        "Apply attribute handler without data."
    ),
    
    unit:assert-equals(
        o:apply(['foo', map { 'bar': function($e, $d) { if ($d) then $d * 10 else 0 } }], [3]),
        ['foo', map { 'bar': 30 }],
        "Apply data to an attribute handler."
    )
};

declare %unit:test function test:to-xml() 
{
    unit:assert-equals(
        o:xml(['ul', map { '!': [10,20,30] },
            ['li', 'list item']
        ]),
        <ul>
            <li>list item</li>
        </ul>,
        "The data attribute is removed."
    )
};

declare %unit:test function test:to-xml-with-data() 
{
    unit:assert-equals(
        o:xml(o:apply(['ul', map { '!': [10,20,30] },
            ['li', function($e,$a,$b,$c) { sum(($a,$b,$c)) }]
        ])),
        <ul>
            <li>60</li>
        </ul>,
        "The data handler modifies the context arguments"
    ),

    unit:assert-equals(
        o:xml(o:apply(['ul', map { '!': (10,20,30) },
            ['li', function($e,$x) { sum($x) }]
        ])),
        <ul>
            <li>60</li>
        </ul>,
        "The data handler modifies the context arguments"
    )
};

declare %unit:test function test:pass-data()
{    
    unit:assert-equals(
        o:apply(
            ['foo', map { '!': 3 },
                ['bar', map { '!': function($e, $d) { $d * $d } },
                    ['baz', function($e, $d) { $d * $d }]
                ]
            ]
        ),
        ['foo',
            ['bar',
                ['baz', 81]
            ]
        ],
        "Data will be passed down."
    ),
    
    unit:assert-equals(
        o:apply(
            ['foo',
                ['bar', map { '!': function($e, $d) { $d * $d } },
                    ['baz', function($e, $d) { $d * $d }]
                ]
            ],
            [3]
        ),
        ['foo',
            ['bar',
                ['baz', 81]
            ]
        ],
        "Data will be passed down."
    )

};