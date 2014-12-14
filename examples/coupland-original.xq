xquery version "3.0";

import module namespace cl = 'http://www.cems.uwe.ac.uk/xmlwiki/coupland'
    at 'coupland-typeswitch.xqm';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input :=
    xf:xml-resource(file:base-dir() || 'coupland.xml')/*

return
    cl:websites($input)
    
(: 

    > basex -V -r10 examples/coupland-original.xq
    Parsing: 77.18 ms (avg)
    Compiling: 18.48 ms (avg)
    Evaluating: 16.51 ms (avg)
    Printing: 3.12 ms (avg)
    Total Time: 115.29 ms (avg)

 :)
