xquery version "3.0";

(:~
 : Origami transformer example: XQuery wiki example
 :
 : This is a port of the example.
 : It shows a style of templating that is very similar to
 : XSLT. Later examples will have to improve on this.
 :
 : @see http://en.wikibooks.org/wiki/XQuery/Transformation_idioms
 :
 : TODO: Currently runs at about 1.5 secs which is terrible.
 :       When running from basexgui it also gets increasingly slower.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:
 : Required to avoid whitespace 'chopping' around inline elements
 : This has the consequence that too much whitespace will be inserted
 : into output.
 :)
declare option db:chop 'false';

let $parent := 
    function($node) {
        $node/ancestor::*[not(self::xf:*)][1] }
   
let $input :=
    xf:xml-resource(file:base-dir() || 'coupland.xml')

let $transform := xf:transform((

    ['websites', function($websites as element(websites)) {
        <html>
            <head>
               <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
               <title>Web Sites by Coupland</title>
               <link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/css/blueprint/screen.css" type="text/css" media="screen, projection"/>
               <link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/css/blueprint/print.css" type="text/css" media="print"/>
               <!--[if IE ]><link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/css/blueprint/ie.css" type="text/css" media="screen, projection" /><![endif]-->
               <link rel="stylesheet" href="http://www.cems.uwe.ac.uk/xmlwiki/eXist/transformation/screen.css" type="text/css" media="screen"/>
            </head>
            <body>
                <div class="container">{
                    for $category in $websites/category
                    order by $category/class
                    return
                        <div>
                            <div class="span-10">{ xf:apply($category) }</div>
                            <div class="span-14 last">{
                                for $site in $websites/sites/site[category=$category/class]
                                order by ($site/sortkey,$site/name)[1]
                                return
                                    xf:apply($site)
                            }</div>
                            <hr />
                        </div>
                }</div>  
             </body>
        </html>           
    }],

    ['category[not(../site)]', function($category as element(category)) {
        <div>{ $category/@*, xf:apply($category/node()) }</div>
    }],
    
    ['class', ()],

    ['description', function($description as element(description)) { 
        <div>{ $description/@*, xf:apply($description/node()) }</div> 
    }],
    
    ['em', function($em as element(em)) {
        <em>{ $em/@*, xf:apply($em/node()) }</em>
    }],

    ['hub', function($hub as element(hub)) {
        <hub>{ $hub/@*, xf:apply($hub/node()) }</hub>
    }],

    ['image', function($image as element(image)) {
        <div><img src="{ $image }"/></div>
    }],
    
    ['name', function($name as element(name)) {
        if ($parent($name)/site) then
            <span style="font-size: 16pt">{ 
                $name/@*, xf:apply($name/node()) 
            }</span>
        else
            <h1>{ $name/@*, xf:apply($name/node()) }</h1>
    }],
    
    ['p', function($p as element(p)) {
        <p>{ $p/@*, xf:apply($p/node()) }</p>    
    }],
    
    ['q', function($q as element(q)) {
        <q>{ $q/@*, xf:apply($q/node()) }</q>
    }],

    ['site', function($site as element(site)) {
        <div>
            <div>{ 
                xf:apply($site/name), 
                xf:apply($site/uri) 
            }</div>
            <xf:apply>{ 
                $site/node() except ($site/uri,$site/name) 
            }</xf:apply>
        </div>
    }],

    ['sites', function($sites as element(sites)) {
        for $site in $sites
        order by $site/sortkey
        return
            xf:apply($sites/site)
    }],

    ['sortkey', ()],
    
    ['subtitle', function($subtitle as element(subtitle)) {
        <div>{ $subtitle/@*, xf:apply($subtitle/node()) }</div>
    }],
    
    ['uri', function($uri as element(uri)) {
        <span><a href="{ $uri }">Link</a></span>
    }]
    
))

return $transform($input)

(:
    Parsing: 514.41 ms
    Compiling: 141.04 ms
    Evaluating: 1506.98 ms    <<<<< ridiculous!
    Printing: 13.98 ms
    Total Time: 2176.41 ms
 :) 
