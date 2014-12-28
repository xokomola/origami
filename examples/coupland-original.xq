xquery version "3.0";

import module namespace cl = 'http://www.cems.uwe.ac.uk/xmlwiki/coupland'
    at 'coupland-typeswitch.xq';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $input :=
    xf:xml-resource(file:base-dir() || 'coupland.xml')/*

return
  cl:websites($input)
  
