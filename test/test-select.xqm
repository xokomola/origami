xquery version "3.0";

(:~
 : Origami tests: xf:select, xf:select-all
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:select() {

    unit:assert-equals(
        xf:select('@x')(<foo x="10"/>),
        attribute x { '10' },
        'Attributes can be selected'),
        
    unit:assert-equals(
        xf:select('@x')(<foo x="10"><bar x="20"/></foo>),
        attribute x { '10' },
        'xf:select does not descend into the nodes'),
        
    unit:assert-equals(
        xf:select('.')(<foo x="10"><bar x="20"/></foo>),
        <foo x="10"><bar x="20"/></foo>,
        'Return top-level node (context node)'),
        
    unit:assert-equals(
        xf:select('/*')(document { <foo x="10"><bar x="20"/></foo> }),
        <foo x="10"><bar x="20"/></foo>,
        'Only when the input is a document-node() can "/" be used')
        
};

declare %unit:test function test:select-all() {
    unit:assert-equals(
        xf:select-all('@x')(<foo x="10"/>),
        attribute x { '10' },
        'Attributes can be selected'),
        
    unit:assert-equals(
        xf:select-all('@x')(<foo x="10"><bar x="20"/></foo>),
        (attribute x { '10' }, attribute x { '20' }),
        'xf:select-all descends into nodes'),
        
    unit:assert-equals(
        xf:select-all('.')(<foo x="10"><bar x="20"/></foo>),
        (<foo x="10"><bar x="20"/></foo>,<bar x="20"/>),
        'context nodes includes descendants'),
        
    unit:assert-equals(
        xf:select-all('/*')(document { <foo x="10"><bar x="20"/></foo> }),
        <foo x="10"><bar x="20"/></foo>,
        'return document element')
};
