xquery version "3.0";

(:~
 : Origami xform example: the identity transform
 :
 : The default behaviour of the transformer is to copy output unmodified.
 : Therefore, identity transform is a transform without any templates.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

let $paras := xf:xtract(xf:select('code'))

let $input := 
    html:parse(fetch:binary("http://xokomola.com/2014/11/10/xquery-origami-1.html"))/*
    
return $paras($input)
