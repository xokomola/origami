xquery version "3.1";

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare %unit:test function test:select-keys() 
{
    unit:assert-equals(
        o:select-keys((),()),
        map {},
        "Empty $map and $keys arguments produces an empty map"
    ),
    unit:assert-equals(
        o:select-keys(map {},('a')),
        map {},
        "Empty $map argument produces an empty map"
    ),
    unit:assert-equals(
        o:select-keys(map {'a': 1},('a')),
        map {'a': 1},
        "Single $key produces a new map with that key"
    ),
    unit:assert-equals(
        o:select-keys(map {'b': 2},('a')),
        map {},
        "Single $key that is not in map produces an empty map"
    ),
    unit:assert-equals(
        o:select-keys(map {'a': 1, 'b': 2, 'c': 3},('a','b')),
        map {'a': 1, 'b': 2},
        "Multiple keys produce a new map with only these keys"
    )    
};

