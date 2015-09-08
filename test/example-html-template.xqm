xquery version "3.1";

(:~
 : Examples for μ-documents
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

(:
declare variable $ex:html := function($name) 
{ 
    μ:read-html(file:base-dir() || $name) 
};

declare variable $ex:list1 :=
    <list>
        <item>One</item>
        <item>Two</item>
        <item>Three</item>
    </list>;

declare variable $ex:list2 :=
    <list>
        <item>A</item>
        <item>B</item>
        <item>C</item>
        <item>D</item>
    </list>;

(:
declare variable $ex:main := μ:template(
    $ex:html('base.html'),
    function($data as map(*)) {
      ['*[@id="title"]', μ:content($data('title')) ],
      ['*[@id="header"]', μ:content($data('header')) ],
      ['*[@id="main"]', μ:content($data('main')) ],
      ['*[@id="footer"]', μ:content($data('footer')) ]   
    }
);
:)

declare variable $ex:main := μ:template(
    $ex:html('base.html'), (
      ['title', μ:content('TITLE') ],
      ['div[@id="header"]', μ:content('HEADER') ],
      ['div[@id="main"]', μ:content('MAIN') ],
      ['div[@id="footer"]', μ:content('FOOTER') ]   
    )
);

declare variable $ex:three-col := μ:template(
    $ex:html('3col.html'),
    ['div[@id="main"]'],
    function ($left, $middle, $right) {
      ['div[@id="left"]', μ:content($left) ],
      ['div[@id="middle"]', μ:content($middle) ],
      ['div[@id="right"]', μ:content($right) ]
    }
);

declare variable $ex:nav-model := function($list as element(list))
{
   ['span[@class="count"]', 
     μ:content(μ:text(count($list/item))) ],
   ['div[text()][1]', 
     μ:replace(for $item in $list/item return <div>{ string($item) }</div>) ],
   ['div[text()]', () ]
};

declare variable $ex:nav1 := μ:template($ex:html('navs.html'), ['div[@id="nav1"]'], $ex:nav-model);
declare variable $ex:nav2 := μ:template($ex:html('navs.html'), ['div[@id="nav2"]'], $ex:nav-model);
declare variable $ex:nav3 := μ:template($ex:html('navs.html'), ['div[@id="nav3"]'], $ex:nav-model);

declare variable $ex:viewa := function() {
  $ex:main(
    map {
      'title': "View A", 
      'main': $ex:three-col((),(),())
    }
  )  
};

declare variable $ex:viewb := function($left, $right) {
  $ex:main(
    map {
      'title': "View B", 
      'main': $ex:three-col($left, (), $right)
    }
  )  
};

declare variable $ex:viewc := function($action) {
  let $navs :=
    if ($action = 'reverse') then
      ($ex:nav2, $ex:nav1)
    else
      ($ex:nav1, $ex:nav2)
  return
    $ex:main(
      map {
        'title': "View C",
        'header': "Templates a go-go",
        'footer': "Origami Template",
        'main': $ex:three-col($navs[1](), (), $navs[2]())
      }
    )
};

declare variable $ex:index := function($context as map(*)?)
{
    $ex:main($context)
};

declare variable $ex:context :=
    map { 
        'title': 'My Index', 
        'header': 'A boring header', 
        'footer': 'A boring footer',
        'main': $ex:three-col(
            $ex:nav1($ex:list1), 
            $ex:nav2($ex:list2), 
            $ex:nav3($ex:list1))
    };
:)