xquery version "3.1";

module namespace ld = 'http://xokomola.com/xquery/origami/ld';

import module namespace u = 'http://xokomola.com/xquery/origami/utils' at 'utils.xqm'; 

(:~
 : Get the nested objects inside the datastructure.
 :)
declare function ld:objects($mu as item()?)
{
    let $inner := function($el) {
        if (ld:tag($el) = 'ld:object')
        then $el
        else
            for $item in ld:content($el)
            where $item instance of array(*)
            return ld:objects($item)
    }
    let $outer := function($seq) { $seq }
    return
        u:walk($inner, $outer, $mu)
};

declare %private function ld:typed-object($type as xs:string, $content as item()*, $attributes as map(xs:string, item()))
as array(*)?
{
    let $attributes := map:merge(($attributes, map:entry('ld:type', $type)))
    where count($content) gt 0
    return
        ['ld:object', $attributes, $content]
};

declare function ld:json-object($json-xdm as item()?)
as array(*)?
{
    ld:json-object($json-xdm, map {})
};

declare function ld:json-object($json-xdm as item()?, $attributes as map(xs:string, item()))
as array(*)?
{
    ld:typed-object('json', $json-xdm, $attributes)
};

declare function ld:csv-object($csv-xdm as array(*)*)
as array(*)?
{
    ld:csv-object($csv-xdm, map {})
};

declare function ld:csv-object($csv-xdm as array(*)*, $attributes as map(xs:string, item()))
as array(*)?
{
    ld:typed-object('csv', $csv-xdm, $attributes)
};

declare function ld:text-object($text as xs:string*)
as array(*)?
{
    ld:text-object($text, map {})
};

declare function ld:text-object($text as xs:string*, $attributes as map(xs:string, item()))
as array(*)?
{
    
    ld:typed-object('text', $text, $attributes)
};

(: Object to XML transformers: provides default rendering of basic objects. :)
(: TODO: merge this with ld:doc :) 
declare function ld:object-doc($object as array(*))
{
    switch (ld:attributes($object)?('ld:type'))
    
    case 'text'
    return
        for $line in ld:content($object)
        return
            ['p', $line]
            
    case 'csv'
    return
        ['table',
            for $row in ld:content($object)
            return
                ['tr',
                    for $cell in $row?*
                    return
                        ['td', $cell]
                ]
        ]
        
    case 'json'
    return 'JSON'
    
    default
    return $object
};
