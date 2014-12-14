xquery version "3.0";

module namespace coupland = "http://www.cems.uwe.ac.uk/xmlwiki/coupland";

(: conversion module generated from a set of tags :)
 
declare function coupland:convert($nodes as node()*) as item()* {
  for $node in $nodes
  return 
     typeswitch ($node)
       case element(category) return coupland:category($node)
       case element(class) return coupland:class($node)
       case element(description) return coupland:description($node)
       case element(em) return coupland:em($node)
       case element(hub) return coupland:hub($node)
       case element(image) return coupland:image($node)
       case element(name) return coupland:name($node)
       case element(p) return coupland:p($node)
       case element(q) return coupland:q($node)
       case element(site) return coupland:site($node)
       case element(sites) return coupland:sites($node)
       case element(sortkey) return coupland:sortkey($node)
       case element(subtitle) return coupland:subtitle($node)
       case element(uri) return coupland:uri($node)
       case element(websites) return coupland:websites($node)
 
       default return 
         coupland:convert-default($node)
};
 
declare function coupland:convert-default($node as node()) as item()* {
  $node
};

declare function coupland:number($node) as xs:string {
     concat(count($node/preceding-sibling::node()[name(.) = name($node)]) + 1,". ")
};

declare function coupland:category($node as element(category)) as item()* {
  if ($node/parent::node() instance of element(site))
  then ()
  else 
    element div{
     $node/@*,
     coupland:convert($node/node()) 
    }
};
 
declare function coupland:class($node as element(class)) as item()* {
  ()
};
 
declare function coupland:description($node as element(description)) as item()* {
  element div{
     $node/@*,
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:em($node as element(em)) as item()* {
  element em{
     $node/@*,
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:hub($node as element(hub)) as item()* {
  element hub{
     $node/@*,
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:image($node as element(image)) as item()* {
  element div {
    element img {
     attribute src { $node}
    }
  }
};
 
declare function coupland:name($node as element(name)) as item()* {
  if ($node/parent::node() instance of element(site))
  then 
    element span {
     attribute style {"font-size: 16pt"},
     $node/@*,
     coupland:convert($node/node())
     }
  else 
    element h1{
     $node/@*,
     coupland:number($node/parent::node()), 
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:p($node as element(p)) as item()* {
  element p{
     $node/@*,
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:q($node as element(q)) as item()* {
  element q{
     $node/@*,
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:site($node as element(site)) as item()* {
  element div{
     element div { 
        coupland:convert($node/name),
        coupland:convert($node/uri)
       } ,
     coupland:convert($node/(node() except (uri,name)))
     }
};
 
declare function coupland:sites($node as element(sites)) as item()* {
    for $site in $node/site
    order by $node/sortkey
    return 
       coupland:convert($node/site) 
};
 
declare function coupland:sortkey($node as element(sortkey)) as item()* {
  ()
};
 
declare function coupland:subtitle($node as element(subtitle)) as item()* {
  element div{
     $node/@*,
     coupland:convert($node/node()) 
     }
};
 
declare function coupland:uri($node as element(uri)) as item()* {
  <span>
    {element a{
     attribute href {$node },
     "Link"
     }
    }
  </span>
};
 
declare function coupland:websites($node as element(websites)) as item()* {
(: the rot element so convert to html :)
  <html>
     <head>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
        <title>Web Sites by Coupland</title>
        <link rel="stylesheet" href="../../css/blueprint/screen.css" type="text/css" media="screen, projection"/>
        <link rel="stylesheet" href="../../css/blueprint/print.css" type="text/css" media="print"/>
        <!--[if IE ]><link rel="stylesheet" href="../../css/blueprint/ie.css" type="text/css" media="screen, projection" /><![endif]-->
        <link rel="stylesheet" href="screen.css" type="text/css" media="screen"/>
     </head>
     <body>
       <div class="container">
       {
        for $category in $node/category
        order by $category/class
        return
          <div>
            <div class="span-10">
              {coupland:convert($category)}
            </div>
            <div class="span-14 last">
              {for $site in $node/sites/site[category=$category/class]
               order by ($site/sortkey,$site/name)[1]
               return
                 coupland:convert($site)
              }
            </div>
            <hr />
          </div>
        }
        </div>  
      </body>
   </html>
};

