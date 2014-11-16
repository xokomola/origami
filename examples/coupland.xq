xquery version "3.0";

(:~
 : Origami transformer example: XQuery wiki example
 :
 : A more extensive HTML templating example and a port of the example
 : on the XQuery wikibook. This incorporates a few different types
 : of transformation all of which are supported using Origami transformers.
 :
 : - default action
 : - change element name
 : - ignore element
 : - define custom transformation
 : - transformation depends on context
 : - reordering elements
 :
 : @see http://en.wikibooks.org/wiki/XQuery/Transformation_idioms
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:
 : Required to avoid whitespace 'chopping' around inline elements
 : This has the consequence that too much whitespace will be inserted
 : into output.
 :)
declare option db:chop 'false';

(: Little helper function, may become part of the module :)
declare function local:parent($node) {
    $node/ancestor::*[not(self::xf:*)][1]
};

let $transform := xf:transform((

        xf:template('category', function($category as element(category)) {
            if (local:parent($category)/site) then
                ()
            else
                <div>{ $category/@*, xf:apply($category/node()) }</div>
        }),
        
        xf:template('class', ()),

        xf:template('description', function($description as element(description)) { 
            <div>{ $description/@*, xf:apply($description/node()) }</div> 
        }),
        
        xf:template('em', function($em as element(em)) {
            <em>{ $em/@*, xf:apply($em/node()) }</em>
        }),

        xf:template('hub', function($hub as element(hub)) {
            <hub>{ $hub/@*, xf:apply($hub/node()) }</hub>
        }),

        xf:template('image', function($image as element(image)) {
            <div><img src="{ $image }"/></div>
        }),
        
        xf:template('name', function($name as element(name)) {
            if (local:parent($name)/site) then
                <span style="font-size: 16pt">{ 
                    $name/@*, xf:apply($name/node()) 
                }</span>
            else
                <h1>{ $name/@*, xf:apply($name/node()) }</h1>
        }),
        
        xf:template('p', function($p as element(p)) {
            <p>{ $p/@*, xf:apply($p/node()) }</p>    
        }),
        
        xf:template('q', function($q as element(q)) {
            <q>{ $q/@*, xf:apply($q/node()) }</q>
        }),

        xf:template('site', function($site as element(site)) {
            <div>
                <div>{ 
                    xf:apply($site/name), 
                    xf:apply($site/uri) 
                }</div>
                <xf:apply>{ 
                    $site/node() except ($site/uri,$site/name) 
                }</xf:apply>
            </div>
        }),

        xf:template('sites', function($sites as element(sites)) {
            for $site in $sites
            order by $site/sortkey
            return
                xf:apply($sites/site)
        }),

        xf:template('sortkey', ()),
        
        xf:template('subtitle', function($subtitle as element(subtitle)) {
            <div>{ $subtitle/@*, xf:apply($subtitle/node()) }</div>
        }),
        
        xf:template('uri', function($uri as element(uri)) {
            <span><a href="{ $uri }">Link</a></span>
        }),
        
        xf:template('websites', function($websites as element(websites)) {
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
        })
    ))
   
let $input :=
    doc("http://www.cems.uwe.ac.uk/xmlwiki/eXist/transformation/Coupland1.xml")/*

return prof:time($transform($input))

