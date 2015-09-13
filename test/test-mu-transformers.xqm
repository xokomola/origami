xquery version "3.1";

(:~
 : Origami tests: node transformers
 :)
 
(: TODO: mix with xml nodes :)
(: TODO: node sequences :)

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' 
    at '../mu.xqm'; 

declare %unit:test function test:insert()
{
    unit:assert-equals(
        ['p'] => μ:insert(['x']),
        ['p', ['x']]
    ),    
    unit:assert-equals(
        ['p', 'foo'] => μ:insert(['x']),
        ['p', ['x']]
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => μ:insert(['x']),
        ['p', map { 'a': 1 },['x']]
    )        
};

declare %unit:test function test:replace()
{
    unit:assert-equals(
        ['p'] => μ:replace(['x']),
        ['x']
    ),    
    unit:assert-equals(
        ['p', 'foo'] => μ:replace(['x']),
        ['x']
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => μ:replace(['x']),
        ['x']
    )        
};

declare %unit:test function test:wrap()
{
    unit:assert-equals(
        ['p'] => μ:wrap(['x']),
        ['x', ['p']]
    ),    
    unit:assert-equals(
        ['p'] => μ:wrap(['x', map { 'a': 1 }]),
        ['x', map { 'a': 1 }, ['p']]
    ),
    unit:assert-equals(
        ['p'] => μ:wrap(['x', map { 'a': 1 }, 'foo']),
        ['x', map { 'a': 1 }, ['p']]
    ),        
    unit:assert-equals(
        ['p'] => μ:wrap(['x', 'foo']),
        ['x', ['p']]
    ),
    unit:assert-equals(
        ['p'] => μ:wrap(()),
        ['p']
    )
};

declare %unit:test function test:unwrap()
{
    unit:assert-equals(
        ['p',['x']] => μ:unwrap(),
        ['x']
    ),    
    unit:assert-equals(
        ['p', map { 'a': 1 }, ['x']] => μ:unwrap(),
        ['x']
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => μ:unwrap(),
        'foo'
    ),        
    unit:assert-equals(
        ['p', 'foo', ['x']] => μ:unwrap(),
        ('foo', ['x'])
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo', ['x']] => μ:unwrap(),
        ('foo', ['x'])
    ),
    unit:assert-equals(
        ['p'] => μ:unwrap(),
        ()
    ),
    unit:assert-equals(
        (['p', ['x']],['p', ['y']]) => μ:unwrap(),
        (['x'],['y'])
    )
};

declare %unit:test function test:copy()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => μ:copy(),
        ['p', map { 'a': 10 }, 'foo']
    )
};

declare %unit:test function test:before()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => μ:before(['x']),
        (['x'],['p', map { 'a': 10 }, 'foo'])
    )
};

declare %unit:test function test:after()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => μ:after(['x']),
        (['p', map { 'a': 10 }, 'foo'],['x'])
    )
};

declare %unit:test function test:insert-before()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => μ:insert-before(['x']),
        ['p', map { 'a': 10 }, ['x'], 'foo']
    )
};

declare %unit:test function test:insert-after()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => μ:insert-after(['x']),
        ['p', map { 'a': 10 }, 'foo', ['x']]
    )
};

declare %unit:test function test:text()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo', ['b', 'bar']] => μ:text(),
        ('foo','bar')
    )
};

declare %unit:test function test:set-attr()
{
    unit:assert-equals(
        ['p', map { 'a': 0 }] => μ:set-attr(map { 'a': 10, 'b': 20 }),
        ['p', map { 'a': 10, 'b': 20 }]
    )
};

declare %unit:test function test:remove-attr()
{
    unit:assert-equals(
        ['p', map { 'a': 0, 'x': 10 }] => μ:remove-attr(('a','b')),
        ['p', map { 'x': 10 }]
    ),
    unit:assert-equals(
        ['p', map { 'a': 0, 'x': 10 }] => μ:remove-attr(('a','x')),
        ['p']
    )
};

declare %unit:test function test:add-class()
{
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => μ:add-class(('a','b')),
        ['p', map { 'class': 'a x b' }]
    ),
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => μ:add-class(('a','b','a')),
        ['p', map { 'class': 'a x b' }]
    ),
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => μ:add-class(('a','x')),
        ['p', map { 'class': 'a x' }]
    ),
    unit:assert-equals(
        ['p'] => μ:add-class(('a','x')),
        ['p', map { 'class': 'a x' }]
    )
};

declare %unit:test function test:remove-class()
{
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => μ:remove-class(('a','b','a')),
        ['p', map { 'class': 'x' }]
    ),
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => μ:remove-class(('a','x')),
        ['p']
    ),
    unit:assert-equals(
        ['p'] => μ:remove-class(('a','x')),
        ['p']
    )
};

declare %unit:test function test:rename()
{
    unit:assert-equals(
        (['p']) => μ:rename('x'),
        ['x']
    ),
    unit:assert-equals(
        (['p', map { 'a': 10 }]) => μ:rename('x'),
        ['x', map { 'a': 10 }]
    ),
    unit:assert-equals(
        (['p', map { 'a': 10 }, 'foo']) => μ:rename('x'),
        ['x', map { 'a': 10 }, 'foo']
    ),
    unit:assert-equals(
        ['p'] => μ:rename(map { 'p': 'x' }),
        ['x']
    ),
    unit:assert-equals(
        ['p'] => μ:rename(map { 'y': 'x' }),
        ['p']
    )
};