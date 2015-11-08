xquery version "3.1";

(:~
 : Tests for mu node functions
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:children() 
{
    unit:assert-equals(
        o:children(()),
        (),
        "No children"
    ),

    unit:assert-equals(
        o:children((1,2,3)),
        (),
        "Not an element"
    ),

    unit:assert-equals(
        o:children([(1,2,3), 4,5,6]),
        (4,5,6),
        "Unwellformed element (is fine)"
    ),

    unit:assert-equals(
        o:children(['a']),
        (),
        "No children"
    ),
    
    unit:assert-equals(
        o:children(['a',()]),
        (),
        "No children (empty sequence)"
    ),

    unit:assert-equals(
        o:children(['a',1]),
        1,
        "Single child element"
    ),

    unit:assert-equals(
        o:children(['a', map {},1]),
        1,
        "Single child element with attribute"
    ),

    unit:assert-equals(
        o:children(['a',1,(2,3)]),
        (1,2,3),
        "Multiple children (sequence)"
    ),

    unit:assert-equals(
        o:children(['a',1,['b'],3]),
        (1,['b'],3),
        "Multiple children with element node"
    ),
    
    unit:assert-equals(
        o:children((['x',1,2,3],['y',4,5,6])),
        (1,2,3,4,5,6),
        "Multiple elements"
    ),

    unit:assert-equals(
        o:children((['x',1,2,3],0,['y',4,5,6])),
        (1,2,3,4,5,6),
        "Multiple elements mixed content"
    )

};

declare %unit:test function test:tag() 
{
    unit:assert-equals(
        o:tag(['x']),
        'x',
        "Simple element"
    ),

    unit:assert-equals(
        o:tag([1,2]),
        1,
        "Tag isnt picky about elements"
    ),
    
    unit:assert(
        o:tag([function($n){'foo'},2]) instance of function(*),
        "A handler looks like an element"
    )
};

declare %unit:test function test:attributes() 
{

    unit:assert-equals(
        o:attributes(1),
        (),
        "No attributes"
    ),

    unit:assert-equals(
        o:attributes((1,2,3)),
        (),
        "No attributes"
    ),

    unit:assert-equals(
        o:attributes(['x']),
        (),
        "No attributes"
    ),

    unit:assert-equals(
        o:attributes(['x',1,2,3]),
        (),
        "No attributes"
    ),

    unit:assert-equals(
        o:attributes(['x',map {}, 1,2,3]),
        map {},
        "No attributes"
    ),

    unit:assert-equals(
        o:attrs(['x',map {}, 1,2,3]),
        map {},
        "No attributes"
    ),

    unit:assert-equals(
        o:attributes(['x', map { 'y': 10 }]),
        map { 'y': 10 },
        "No attributes"
    ),
    
    unit:assert-equals(
        o:attrs(['x', map { 'y': 10 }]),
        map { 'y': 10 },
        "No attributes"
    )
};

declare %unit:test function test:is-element() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    )
};

declare %unit:test function test:is-element-or-handler() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    )
};

declare %unit:test function test:head() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    )
};

declare %unit:test function test:tail() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    )
};

declare %unit:test function test:text() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    )
};

declare %unit:test function test:ntext() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    )
};
