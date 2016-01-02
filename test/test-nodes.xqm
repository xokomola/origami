xquery version "3.1";

(:~
 : Tests for mu node functions
 :)
 module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:head() 
{
    unit:assert-equals(
        o:head(()),
        (),
        "No document"
    ),
    
    unit:assert-equals(
        o:head(['x']),
        'x',
        "Head of empty element"
    ),

    unit:assert-equals(
        o:head(['x',1,2,3]),
        'x',
        "Head of element"
    ),
    
    unit:assert-equals(
        o:head([['x']]),
        ['x'],
        "Head of unwellformed element"
    )
};

declare %unit:test function test:tail() 
{
    unit:assert-equals(
        o:tail(()),
        (),
        "No document"
    ),
    
    unit:assert-equals(
        o:tail(['x']),
        (),
        "Tail of empty element"
    ),

    unit:assert-equals(
        o:tail(['x',1,2,3]),
        (1,2,3),
        "Tail of element"
    ),
    
    unit:assert-equals(
        o:tail([['x']]),
        (),
        "Tail of unwellfored element"
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

    unit:assert-equals(
        o:tag([['x']]),
        ['x'],
        "Tag isnt picky about elements"
    ),

    unit:assert(
        o:tag([function($n){'foo'},2]) instance of function(*),
        "A handler looks like an element"
    )
};

declare %unit:test function test:children() 
{
    unit:assert-equals(
        o:children(()),
        (),
        "No children"
    ),

    unit:assert-equals(
        o:children([(1,2,3), 4,5,6]),
        (2,3,4,5,6),
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
    )
    
};

declare %unit:test function test:attributes() 
{
    unit:assert-equals(
        o:attributes([]),
        (),
        "Emtpy array is not a valid element"
    ),

    unit:assert-equals(
        o:attributes(()),
        (),
        "Emtpy sequence is not a valid element"
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
        o:attributes(['x', map { 'y': 10 }]),
        map { 'y': 10 },
        "Attribute map"
    )
    
};

declare %unit:test function test:attrs()
{
    unit:assert-equals(
        o:attrs(['x',map {}, 1,2,3]),
        map {},
        "Empty attributes map"
    ),

    unit:assert-equals(
        o:attrs(['x',1,2,3]),
        map {},
        "No attributes map"
    ),

    unit:assert-equals(
        o:attrs(['x', map { 'y': 10 }]),
        map { 'y': 10 },
        "Attribute map"
    )
};

declare %unit:test function test:text() 
{
    unit:assert-equals(
        o:text(()),
        '',
        "No document"
    ),

    unit:assert-equals(
        o:text(['b',1,2,3]),
        '123',
        "Child nodes integers"
    ),
    
    unit:assert-equals(
        o:text(['a',1,['b',2,3],4]),
        '1234',
        "Child nodes integer and element"
    ),
    
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo', ['b', 'bar']] => o:text(),
        'foobar'
    )    
};

declare %unit:test function test:ntext() 
{
    unit:assert-equals(
        o:ntext(()),
        '',
        "No document"
    ),

    unit:assert-equals(
        o:ntext(['b','    a       ','     b  ','    c  ']),
        'a b c',
        "Child nodes with extra whitespace"
    ),
    
    unit:assert-equals(
        o:ntext(['a',1,['b',2,3],4]),
        '1234',
        "Child nodes integer and element"
    )
};

declare %unit:test function test:size() 
{
    unit:assert-equals(
        o:size(()),
        0,
        "No children"
    ),

    unit:assert-equals(
        o:size([(1,2,3), 4,5,6]),
        5,
        "Unwellformed element (is fine)"
    ),

    unit:assert-equals(
        o:size(['a']),
        0,
        "No children"
    ),
    
    unit:assert-equals(
        o:size(['a',()]),
        0,
        "No children (empty sequence)"
    ),

    unit:assert-equals(
        o:size(['a',1]),
        1,
        "Single child element"
    ),

    unit:assert-equals(
        o:size(['a', map {},1]),
        1,
        "Single child element with attribute"
    ),

    unit:assert-equals(
        o:size(['a',1,(2,3)]),
        3,
        "Multiple children (sequence)"
    ),

    unit:assert-equals(
        o:size(['a',1,['b'],3]),
        3,
        "Multiple children with element node"
    )    
};

declare %unit:test function test:is-element() 
{
    unit:assert-equals(
        o:is-element(['x']),
        true(),
        "Empty element"
    ),

    unit:assert-equals(
        o:is-element(['x', map { 'y': 10 }]),
        true(),
        "Empty element with attributes"
    ),

    unit:assert-equals(
        o:is-element(['x', map { 'y': 10 }, 1,2,3]),
        true(),
        "Empty element with attributes and children"
    ),

    unit:assert-equals(
        o:is-element([function($n) { 1 }]),
        false(),
        "Handler"
    ),

    unit:assert-equals(
        o:is-element([(1,2,3),'x']),
        false(),
        "Looks like an element but is not"
    ),

    unit:assert-equals(
        o:is-element([1,'x']),
        false(),
        "Looks like an element but is not"
    ),

    unit:assert-equals(
        o:is-element(()),
        false(),
        "Nothing"
    )
};

declare %unit:test function test:is-handler() 
{
    unit:assert-equals(
        o:is-handler(['x']),
        false(),
        "Empty element"
    ),

    unit:assert-equals(
        o:is-handler(function($n) { 1 }),
        true(),
        "Simple handler function"
    ),

    unit:assert-equals(
        o:is-handler([function($n) { 1 }]),
        true(),
        "Handler function"
    ),

    unit:assert-equals(
        o:is-handler([function($n) { 1 }, 1,2,3]),
        true(),
        "Handler function with args"
    ),

    unit:assert-equals(
        o:is-handler(()),
        false(),
        "Nothing"
    )
};

declare %unit:test function test:has-attrs() 
{
    unit:assert-equals(
        o:has-attrs(['x']),
        false(),
        "Empty element"
    ),

    unit:assert-equals(
        o:has-attrs(['x', map {}]),
        false(),
        "Empty element with empty attrs map"
    ),

    unit:assert-equals(
        o:has-attrs(['x', 1,2,3]),
        false(),
        "Element without attributes"
    ),
    
    unit:assert-equals(
        o:has-attrs(['x', map { 'x': 1 }, 1,2,3]),
        true(),
        "Empty element with attrs map"
    )
};

declare %unit:test function test:has-handler() 
{
    unit:assert-equals(
        o:has-handler(['x', map { '@': 'fn' }]),
        true(),
        "Empty element with handler"
    ),
    
    unit:assert-equals(
        o:has-handler(['x', map { '_': 'fn' }]),
        false(),
        "Empty element with handler"
    )
};

