xquery version "3.0";

(:~
 : Origami transformer example: Rigging SVG
 :
 : Take parts from an Inkscape SVG and use it to generate new SVG.
 : The objective is to re-use SVG without touching it.
 :)
 
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare option db:chop 'false';
    let $svg := xf:xml-resource(file:base-dir() || 'blocks.svg')
    let $dim := [5,5,200,100]
    let $rig := xf:template(
        $svg,
        ['svg:rect[@id="rect1"]'],
        function($x,$y,$w,$h) {
            ['.',
                xf:remove-attr(('*:label','id')),
                xf:set-attr(
                  map { 
                    'width': $w, 'height': $h,
                    'x': $x, 'y': $y })]})
    return
        $rig(5,5,100,200)