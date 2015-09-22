xquery version "3.1";

(:~
 : Examples for μ-documents
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 
import module namespace o = 'http://xokomola.com/xquery/origami' at '../origami.xqm'; 

declare function ex:html($name) 
{ 
    o:read-html(file:base-dir() || $name) 
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

declare variable $ex:main := 
    o:template(ex:html('base.html'), (
        ['title', μ:insert('TITLE') ],
        ['div[@id="header"]', μ:insert('HEADER') ],
        ['div[@id="main"]', μ:insert('MAIN') ],
        ['div[@id="footer"]', μ:insert('FOOTER') ]   
    ));

(: Snippets should be able to combine both o:snippet/o:template e.g o:template#3 would do extract and transform :)
declare variable $ex:three-col := 
    o:template(
        o:snippets(ex:html('3col.html'), [ 'div[@id="main"]', μ:copy() ]),
        (
            [ 'div[@id="left"]', μ:insert('LEFT') ],
            [ 'div[@id="middle"]', μ:insert('MIDDLE') ],
            [ 'div[@id="right"]', μ:insert('RIGHT') ]
        )
    );

(: it requires an extra apply to invoke the inner handlers but that's not the same as above :)
(: it's harder to explain this though, i think, otoh it has some resemblence to XSLT :)
(: TODO: other idea snippet and handler can be node transformers if we make a #1 version for them :)
declare variable $ex:three-col2 := 
    o:apply(o:snippets(ex:html('3col.html'), 
        [ 'div[@id="main"]', o:template((
            [ 'div[@id="left"]', μ:insert('LEFT') ],
            [ 'div[@id="middle"]', μ:insert('MIDDLE') ],
            [ 'div[@id="right"]', μ:insert('RIGHT') ]
        ))]
    ));

declare variable $ex:nav-model := 
    function($list as element(list)) {
        ['span[@class="count"]', 
            μ:insert(μ:text(count($list/item))) ],
        ['div[text()][1]', 
            μ:replace(for $item in $list/item return <div>{ string($item) }</div>) ],
        ['div[text()]', () ]
    };

declare variable $ex:nav1 := o:template(ex:html('navs.html'), (: ['div[@id="nav1"]'],:) $ex:nav-model);
declare variable $ex:nav2 := o:template(ex:html('navs.html'), (:['div[@id="nav2"]'],:) $ex:nav-model);
declare variable $ex:nav3 := o:template(ex:html('navs.html'), (:['div[@id="nav3"]'],:) $ex:nav-model);

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
