xquery version "3.1";

(:~
 : Examples for μ-documents
 :)

module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare function ex:files($dir as xs:string)
{
let $ls := function($dir) { file:children($dir) }
return
    o:xml(
        o:select(
            o:tree-seq(
                $ls($dir),
                function($n) { ends-with($n,'/') },
                function($n) { $ls($n) }
            ),
            function($n) { not(ends-with($n,'/')) }
        ) => o:map(o:wrap(['file']))
    )  
};

declare function ex:fileset()
{
    ex:files(file:resolve-path('..', file:base-dir()))
};

declare function ex:fileset($pattern)
{
    o:select(
        ex:files(file:resolve-path('..', file:base-dir())),
        function($n) { matches(o:text($n), $pattern) }
    )
};
