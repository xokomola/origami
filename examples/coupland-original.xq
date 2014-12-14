xquery version "3.0";

import module namespace cl = 'http://www.cems.uwe.ac.uk/xmlwiki/coupland'
    at 'coupland-typeswitch.xq';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input :=
    xf:xml-resource(file:base-dir() || 'coupland.xml')/*

return
    cl:websites($input)
    
(: 
    Parsing: 518.2 ms
    Compiling: 69.4 ms
    Evaluating: 30.69 ms
    Printing: 11.49 ms
    Total Time: 629.79 ms
:)
