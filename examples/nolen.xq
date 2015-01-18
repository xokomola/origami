xquery version "3.0";

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare option output:method "html";
declare option output:version 5.0;

let $tpl := function($name) {
    xf:html-resource(file:base-dir() || $name)
}

let $list1 :=
    <list>
        <item>One</item>
        <item>Two</item>
        <item>Three</item>
    </list>

let $list2 :=
    <list>
        <item>A</item>
        <item>B</item>
        <item>C</item>
        <item>D</item>
    </list>

(: 
 : This model function can only be arity 0 to 4, a reasonable limit, otherwise 
 : pass an array or map 
 :)
let $nav-model := function($list as element(list)) {

    ['span[@class="count"]', 
        xf:content(text { count($list/item) }) 
    ],

    ['div[text()][1]', 
        xf:replace(for $item in $list/item return <div>{ string($item) }</div>) 
    ],

    ['div[text()]', 
        ()
    ]
}

let $nav1 := xf:template($tpl('navs.html'), ['div[@id="nav1"]'], $nav-model)
let $nav2 := xf:template($tpl('navs.html'), ['div[@id="nav2"]'], $nav-model)
let $nav3 := xf:template($tpl('navs.html'), ['div[@id="nav3"]'], $nav-model)

let $base := 
    xf:template(
        $tpl('base.html'),
        function($context as map(*)?) {
            ['*[@id="title"]', xf:content(xf:text($context('title'))) ],
            ['*[@id="header"]', xf:content(xf:text($context('header'))) ],
            ['*[@id="main"]',  xf:content($context('main'))],
            ['*[@id="footer"]',  xf:content(xf:text($context('footer'))) ]
        }
    )


let $three-col :=
    xf:template(
        $tpl('3col.html'),
        ['div[@id="main"]'],
        function($left, $middle, $right) {
            ['div[@id="left"]', xf:content($left)],
            ['div[@id="middle"]', xf:content($middle)],
            ['div[@id="right"]', xf:content($right)]
        }
    )


let $viewa := function() {
    $base(
        map {
          'title': "View A", 
          'main': $three-col((),(),())
        }
    )  
}
  
let $viewb := function($left, $right) {
    $base(
        map {
          'title': "View B", 
          'main': $three-col($left, (), $right)
        }
    )  
}

let $viewc := function($action) {
    let $navs :=
        if ($action = 'reverse') then
          ($nav2, $nav1)
        else
          ($nav1, $nav2)
    return
        $base(
            map {
                'title': "View C",
                'header': "Templates a go-go",
                'footer': "Origami Template",
                'main': $three-col($navs[1]($list1), (), $navs[2]($list2))
            }
        )
}

let $index := function($context as map(*)?) {
    $base($context)
}

return
    (: $viewc(()) :)
    (: $viewc('reverse') :)
    (: $viewb($nav1($list2), $nav2($list1)) :)
    (: $viewa():) 
    $index(
        map { 
            'title': 'My Index', 
            'header': 'A boring header', 
            'footer': 'A boring footer',
            'main': $three-col($nav1($list1), $nav2($list2), $nav3($list1))
        })