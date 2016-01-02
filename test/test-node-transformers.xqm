xquery version "3.1";

(:~
 : Origami tests: node transformers
 :)

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

(: TODO: o:remove-attr-handlers :)
(: TODO: o:set-attr-handlers :)
(: TODO: o:remove-handler :)
(: TODO: o:set-handler :)
    
declare %unit:test function test:insert()
{
    unit:assert-equals(
        ['p'] => o:insert(['x']),
        ['p', ['x']],
        "Insert element into empty element"
    ),
    
    unit:assert-equals(
        ['p', 'foo'] => o:insert(['x']),
        ['p', ['x']],
        "Insert element into non-empty element (overwrite)"
    ),
    
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => o:insert(['x']),
        ['p', map { 'a': 1 },['x']],
        "Insert does not modify attributes"
    )        
};

declare %unit:test function test:replace()
{
    unit:assert-equals(
        ['p'] => o:replace(['x']),
        ['x']
    ),    
    unit:assert-equals(
        ['p', 'foo'] => o:replace(['x']),
        ['x']
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => o:replace(['x']),
        ['x']
    )        
};

declare %unit:test function test:wrap()
{
    unit:assert-equals(
        ['p'] => o:wrap(['x']),
        ['x', ['p']]
    ),    
    unit:assert-equals(
        ['p'] => o:wrap(['x', map { 'a': 1 }]),
        ['x', map { 'a': 1 }, ['p']]
    ),
    unit:assert-equals(
        ['p'] => o:wrap(['x', map { 'a': 1 }, 'foo']),
        ['x', map { 'a': 1 }, ['p']]
    ),        
    unit:assert-equals(
        ['p'] => o:wrap(['x', 'foo']),
        ['x', ['p']]
    ),
    unit:assert-equals(
        ['p'] => o:wrap(()),
        ['p']
    )
};

declare %unit:test function test:unwrap()
{
    unit:assert-equals(
        ['p',['x']] => o:unwrap(),
        ['x']
    ),    
    unit:assert-equals(
        ['p', map { 'a': 1 }, ['x']] => o:unwrap(),
        ['x']
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => o:unwrap(),
        'foo'
    ),        
    unit:assert-equals(
        ['p', 'foo', ['x']] => o:unwrap(),
        ('foo', ['x'])
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo', ['x']] => o:unwrap(),
        ('foo', ['x'])
    ),
    unit:assert-equals(
        ['p'] => o:unwrap(),
        ()
    )
};

declare %unit:test function test:copy()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => o:copy(),
        ['p', map { 'a': 10 }, 'foo']
    )
};

declare %unit:test function test:before()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => o:before(['x']),
        (['x'],['p', map { 'a': 10 }, 'foo'])
    )
};

declare %unit:test function test:after()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => o:after(['x']),
        (['p', map { 'a': 10 }, 'foo'],['x'])
    )
};

declare %unit:test function test:insert-before()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => o:insert-before(['x']),
        ['p', map { 'a': 10 }, ['x'], 'foo']
    )
};

declare %unit:test function test:insert-after()
{
    unit:assert-equals(
        ['p', map { 'a': 10 }, 'foo'] => o:insert-after(['x']),
        ['p', map { 'a': 10 }, 'foo', ['x']]
    )
};

declare %unit:test function test:set-attr()
{
    unit:assert-equals(
        ['p', map { 'a': 0 }] => o:set-attrs(map { 'a': 10, 'b': 20 }),
        ['p', map { 'a': 10, 'b': 20 }]
    )
};

declare %unit:test function test:remove-attr()
{
    unit:assert-equals(
        ['p', map { 'a': 0, 'x': 10 }] => o:remove-attr(('a','b')),
        ['p', map { 'x': 10 }]
    ),
    unit:assert-equals(
        ['p', map { 'a': 0, 'x': 10 }] => o:remove-attr(('a','x')),
        ['p']
    )
};

declare %unit:test function test:add-class()
{
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => o:add-class(('a','b')),
        ['p', map { 'class': 'a x b' }]
    ),
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => o:add-class(('a','b','a')),
        ['p', map { 'class': 'a x b' }]
    ),
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => o:add-class(('a','x')),
        ['p', map { 'class': 'a x' }]
    ),
    unit:assert-equals(
        ['p'] => o:add-class(('a','x')),
        ['p', map { 'class': 'a x' }]
    )
};

declare %unit:test function test:remove-class()
{
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => o:remove-class(('a','b','a')),
        ['p', map { 'class': 'x' }]
    ),
    unit:assert-equals(
        ['p', map { 'class': 'a x' }] => o:remove-class(('a','x')),
        ['p']
    ),
    unit:assert-equals(
        ['p'] => o:remove-class(('a','x')),
        ['p']
    )
};

declare %unit:test function test:rename()
{
    unit:assert-equals(
        (['p']) => o:rename('x'),
        ['x']
    ),
    unit:assert-equals(
        (['p', map { 'a': 10 }]) => o:rename('x'),
        ['x', map { 'a': 10 }]
    ),
    unit:assert-equals(
        (['p', map { 'a': 10 }, 'foo']) => o:rename('x'),
        ['x', map { 'a': 10 }, 'foo']
    ),
    unit:assert-equals(
        ['p'] => o:rename(map { 'p': 'x' }),
        ['x']
    ),
    unit:assert-equals(
        ['p'] => o:rename(map { 'y': 'x' }),
        ['p']
    )
};

declare variable $test:xslt :=
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">
        <xsl:param name="x"/>
        <xsl:template match="/">
            <result>
                <xsl:apply-templates/>
            </result>
        </xsl:template>
        <xsl:template match="p">
            <para x="{{$x}}"><xsl:value-of select="."/></para>
        </xsl:template>
    </xsl:stylesheet>;

declare variable $test:xslt-params :=
    map { 'x': 10 };

declare %unit:test function test:xslt()
{
    unit:assert-equals(
        ['p',  'foobar'] => o:xslt($test:xslt, $test:xslt-params),
        ['result', ['para', map { 'x': '10' }, 'foobar' ]]
    )
};
