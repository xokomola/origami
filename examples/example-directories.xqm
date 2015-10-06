xquery version "3.1";

(:~
 : Examples for μ-documents
 :)

module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare function ex:files($dir as xs:string)
{
    o:select(
        o:tree-seq(
            file:children($dir),
            function($n) { ends-with($n,'/') },
            file:children#1
        ),
        function($n) { not(ends-with($n,'/')) }
    ) => o:map(function($f) { ['file', map {'path': $f }]})
};

declare function ex:fileset()
{
    ex:files(file:resolve-path('..', file:base-dir()))
};

declare function ex:fileset($pattern)
{
    o:xml(o:select(
        ex:fileset(),
        function($n) { matches(o:attrs($n)?path, $pattern) }
    ))
};
