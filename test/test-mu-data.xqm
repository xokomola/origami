xquery version "3.1";

(:~
 : Origami tests: μ:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami/mu'
    at '../mu.xqm';

declare %unit:test function test:attribute-handlers() 
{
    unit:assert-equals(
        o:apply(['foo', map { 'bar': function($d) { if ($d) then $d * 10 else 0 } }]),
        ['foo', map { 'bar': 0 }],
        "Apply attribute handler without data."
    ),
    
    unit:assert-equals(
        o:apply(['foo', map { 'bar': function($d) { if ($d) then $d * 10 else 0 } }], 3),
        ['foo', map { 'bar': 30 }],
        "Apply data to an attribute handler."
    )
};

declare %unit:test function test:to-xml() 
{
    unit:assert-equals(
        o:xml(['ul', map { 'μ:data': [10,20,30] },
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
        o:xml(o:apply(['ul', map { 'μ:data': [10,20,30] },
            ['li', function($d) { sum($d?*) }]
        ])),
        <ul>
            <li>60</li>
        </ul>,
        "The data is used in the li function."
    )
};

declare %unit:test function test:pass-data()
{    
    unit:assert-equals(
        o:apply(
            ['foo', map { 'μ:data': 3 },
                ['bar', map { 'μ:data': function($d) { $d * $d } },
                    ['baz', function($d) { $d * $d }]
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
                ['bar', map { 'μ:data': function($d) { $d * $d } },
                    ['baz', function($d) { $d * $d }]
                ]
            ],
            3
        ),
        ['foo',
            ['bar',
                ['baz', 81]
            ]
        ],
        "Data will be passed down."
    )

};