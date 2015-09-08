xquery version "3.1";

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu'
    at '../mu.xqm';

(:
 : Load a CSV into normal form. 
 :)
declare function test:read-csv($name)
{
  μ:parse-csv(μ:read-csv(concat(file:base-dir(), 'csv/', $name)))
};

declare %unit:test function test:object-doc()
{
    unit:assert-equals(
        μ:doc(μ:object([1,2,3], function($n){ array { 'list', $n?* } })),
        ['list', 1,2,3],
        "μ:doc will invoke doc-fn to get expanded document"
    )
};

(: 
 : NOTE: the extra sequences created do not affect rendering to XML  
 : if you want to avoid this use array {...} constructors instead
 : of the literal syntax [...].
 :)
declare %unit:test function test:object-doc-table()
{
    unit:assert-equals(
        μ:xml(μ:doc(
            μ:object(
                [['A','B','C'],[1,2,3]], 
                function($n){
                    ['table',
                        for $row in $n?*
                        return
                            ['tr',
                                for $cell in $row?* 
                                return
                                    ['td', $cell]
                            ]
                    ]
                }
            )
        )),
        <table>
          <tr>
            <td>A</td>
            <td>B</td>
            <td>C</td>
          </tr>
          <tr>
            <td>1</td>
            <td>2</td>
            <td>3</td>
          </tr>
        </table>,
        "Make a small table"
    )
};

(:
 : To build tables from normal form CSV (array of arrays) we can use μ:csv-object.
 :)
declare %unit:test function test:table-object()
{
    unit:assert-equals(
        μ:doc(
            μ:table-object([['A','B','C'],[1,2,3]])
        ),
        ['table',
            ['tr',
                ['td', 'A'],
                ['td', 'B'],
                ['td', 'C']
            ],
            ['tr',
                ['td', 1],
                ['td', 2],
                ['td', 3]
            ]
        ],
        "Make a small table using from an array of arrays"
    ),

    unit:assert-equals(
        μ:doc(
            μ:table-object((['A','B','C'],[1,2,3]))
        ),
        ['table',
            ['tr',
                ['td', 'A'],
                ['td', 'B'],
                ['td', 'C']
            ],
            ['tr',
                ['td', 1],
                ['td', 2],
                ['td', 3]
            ]
        ],
        "Make a small table using from an sequence of arrays"
    )

};

(: again, extra sequences make comparing result with μ-nodes difficult :)
declare %unit:test function test:embedded-table-object()
{
    unit:assert-equals(
        μ:xml(μ:doc(
            ['html', map { 'lang': 'en' },
                ['body',
                    μ:table-object((['A','B','C'],[1,2,3]))
                ]
            ]
        )),
        <html lang="en">
            <body>
                <table>
                     <tr>
                         <td>A</td>
                         <td>B</td>
                         <td>C</td>
                     </tr>
                     <tr>
                         <td>1</td>
                         <td>2</td>
                         <td>3</td>
                     </tr>
                 </table>
            </body>
        </html>,
        "A small table embedded in a document"
    )
};

declare %unit:test function test:embedded-table-object-using-xml-nodes()
{
    unit:assert-equals(
            <html lang="en">
                <body>{
                    μ:xml(μ:doc(μ:table-object((['A','B','C'],[1,2,3]))))
                }</body>
            </html>,
        <html lang="en">
            <body>
                <table>
                     <tr>
                         <td>A</td>
                         <td>B</td>
                         <td>C</td>
                     </tr>
                     <tr>
                         <td>1</td>
                         <td>2</td>
                         <td>3</td>
                     </tr>
                 </table>
            </body>
        </html>,
        "Array nodes cannot be embedded in XML so convert them first"
    ),
    
    unit:assert-equals(
        <html lang="en">
            <body>{
                μ:xml(
                  (['A','B','C'],[1,2,3]) => μ:table-object-doc()
                )
            }</body>
        </html>,
        <html lang="en">
            <body>
                <table>
                     <tr>
                         <td>A</td>
                         <td>B</td>
                         <td>C</td>
                     </tr>
                     <tr>
                         <td>1</td>
                         <td>2</td>
                         <td>3</td>
                     </tr>
                 </table>
            </body>
        </html>,
        "Using table-doc-fn directly"
    )

};