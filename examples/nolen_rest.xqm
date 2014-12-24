xquery version "3.0";

module namespace app = 'http://xokomola.com/xquery/origami/example-app';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';


declare 
    %rest:path("origami") 
    %rest:GET 
    %output:method("html")
    function app:main() {
        app:index(
            map { 
                'title': 'My Index', 
                'header': 'A boring header', 
                'footer': 'A boring footer',
                'main': $app:three-col(
                            $app:nav1($app:list1), 
                            $app:nav2($app:list2), 
                            $app:nav3($app:list1))
            }
        )
};

declare 
    %rest:path("main.css") 
    %rest:GET 
    %output:method("text")
    function app:css() {
        xf:text-resource(file:base-dir() || 'main.css')
    };
    
declare %private function app:tpl($name) {
  xf:html-resource(file:base-dir() || $name)
};

declare variable $app:list1 :=
  <list>
    <item>One</item>
    <item>Two</item>
    <item>Three</item>
  </list>;

declare variable $app:list2 :=
  <list>
    <item>A</item>
    <item>B</item>
    <item>C</item>
    <item>D</item>
  </list>;

declare %private function app:nav-model($list as element(list)) {

    ['span[@class="count"]', 
        xf:content(text { count($list/item) }) ],
        
    ['div[text()][1]', 
        xf:replace(for $item in $list/item return <div>{ string($item) }</div>) ],
        
    ['div[text()]', 
        () ]
};

declare %private variable $app:nav1 := 
    xf:template(app:tpl('navs.html'), ['div[@id="nav1"]'], app:nav-model#1);
declare %private variable $app:nav2 := 
    xf:template(app:tpl('navs.html'), ['div[@id="nav2"]'], app:nav-model#1);
declare %private variable $app:nav3 := 
    xf:template(app:tpl('navs.html'), ['div[@id="nav3"]'], app:nav-model#1);

declare %private variable $app:base :=
    xf:template(
        app:tpl('base.html'),
        function ($context as map(*)?) {
            ['*[@id="title"]', xf:content(xf:text($context('title'))) ],
            ['*[@id="header"]', xf:content(xf:text($context('header'))) ],
            ['*[@id="main"]', xf:content($context('main')) ],
            ['*[@id="footer"]', xf:content(xf:text($context('footer'))) ]
        }
    );

declare %private variable $app:three-col := 
    xf:template(
        app:tpl('3col.html'),
        ['div[@id="main"]'],
        function($left, $middle, $right) {
            ['div[@id="left"]', xf:content($left)],
            ['div[@id="middle"]', xf:content($middle)],
            ['div[@id="right"]', xf:content($right)]
        }
    );

declare %private function app:index($context as map(*)?) {
    $app:base($context)
};
