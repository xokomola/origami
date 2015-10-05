xquery version "3.1";

(:~
 : Examples for μ-documents
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare variable $ex:web := 'http://www.nytimes.com';
declare variable $ex:local := file:base-dir() || 'ny-times.html';

declare function ex:html($uri)
{
    o:read-html($uri)
};

(: 
    The following works as expected.
    
    o:xml(o:apply(ex:stories(
       <foo>
         <article class="story">
           <div>
             <h2 class="story-heading"><a>headline</a></h2>
             <p class="byline">byline</p>
             <p class="summary">summary</p>
           </div>
         </article>
       </foo>
   )))
   
 :)
 
(:
declare function ex:scraper($uri)
{
    o:xml(o:apply(ex:stories(ex:html($uri))))
};

declare function ex:stories($html)
{
    o:apply(o:snippets($html, (
        ['article[contains(@class, "story")]', function($e) { 
            ['story',
                $e => o:snippets((
                    (: '(h2|h3|h5)//a' :)
                    ['*[contains(@class,"story-heading")]', function($e) { $e => o:ntext() => o:wrap(['headline']) }],
                    ['*[contains(@class,"byline")]', function($e) { $e => o:ntext() => o:wrap(['byline']) }],
                    ['*[contains(@class,"summary")]', function($e) { $e => o:ntext() => o:wrap(['summary']) }]            
                ))
            ] 
        }]
    ))) 
};
:)