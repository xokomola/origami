xquery version "3.1";

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm';

declare %unit:test function test:node-extractors()
{
    unit:assert-equals(
        o:xml(o:transform(
            <p><x y="10"/><div><x y="20"/></div></p>, 
            ['x[@y]']
        )),
        (<x y="10"/>,<x y="20"/>),
        "Using simple XPath expression"
    ),
    
    unit:assert-equals(
        o:xml(o:transform(
            <p><x y="10"/><div><x y="20"/></div></p>, 
            ['//x[@y]']
        )),
        (<x y="10"/>,<x y="20"/>),
        "Using descendant axis"
    )
};

declare %unit:test function test:node-annotation()
{
    unit:assert-equals(
        o:xml(o:apply(o:transform(
            <p><x y="10"/><div><x y="20"/></div></p>,
            ['/*',
                ['x[@y]', 
                    function($n) { 
                        $n => 
                        o:advise-attr('z', 
                            if (o:attrs($n)?y < 20) then 
                                'A' 
                            else 'B')
                    }
                ]
            ]
        ))),
        <p><x y="10" z="A"/><div><x y="20" z="B"/></div></p>,
        "Add attributes using a handler (using apply)"
    )
    
    (: TODO: this doesn't work (by-design?) :)
    (:,
    
    unit:assert-equals(
        o:xml(o:apply(o:transform(
            <p><x y="10"/><div><x y="20"/></div></p>,
            (
                ['/*']
                ['//x[@y]', 
                    function($n) { 
                        $n => 
                        o:advise-attr('z', 
                            if (o:attrs($n)?y < 20) then 
                                'A' 
                            else 'B')
                    }
                ]
            )
        ))),
        <p><x y="10" z="A"/><div><x y="20" z="B"/></div></p>,
        "Add attributes using a handler (using apply)"
    )
    :)
};
