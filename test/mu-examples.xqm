xquery version "3.1";

(:~
 : Examples for μ-documents
 :)
module namespace ex = 'http://xokomola.com/xquery/origami/examples';

import module namespace o = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

(: Example 1 :)

declare function ex:list-template-traditional() 
{
    let $groceries := ('Apples', 'Bananas', 'Pears')
    let $template :=   
        function($items) {
            <ul class="groceries">{ 
                for $item in $items
                return 
                    <li>{ $item }</li>
            }</ul>
        }
    return $template($groceries)
};

declare %unit:test function ex:test-list-template-traditional()
{
    unit:assert-equals(
        ex:list-template-traditional(),
        <ul class="groceries">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>,
        'Traditional template'
    )
};

(: Example 2 :)

declare function ex:list-template-pure() 
{
    let $groceries := ('Apples', 'Bananas', 'Pears')
    let $template :=   
        function($items) {
            ['ul', map { 'class': 'groceries' }, 
                for $item in $items
                return 
                    ['li', $item]
            ]
        }
    return o:xml($template($groceries))
};

declare %unit:test function ex:test-list-template-pure()
{
    unit:assert-equals(
        ex:list-template-pure(),
        <ul class="groceries">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>,
        'Pure code template'
    )
};

(: Example 3 :)

declare function ex:list-template-apply() 
{
    (: TODO: to pass this you must wrap it like this! Not ideal. :)
    let $groceries := [('Apples', 'Bananas', 'Pears')]
    let $template :=   
        ['ul', map { 'class': 'groceries' },  
            function($items) {
                for $item in $items
                return 
                    ['li', $item]
            }
        ]
    return o:xml(o:apply($template, $groceries))
};

declare %unit:test function ex:test-list-template-apply()
{
    unit:assert-equals(
        ex:list-template-apply(),
        <ul class="groceries">
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>,
        'Apply template'
    )
};

(: Example 4 :)

declare function ex:list-template-dsl()
{
    (: TODO: It's hard to explain why here one array is enough :)
    let $groceries := [('Apples', 'Bananas', 'Pears')]
    let $list := 
        ex:template(
            <ul>
                <li ex:for-each=".">item 1</li>
                <li ex:remove=".">item 2</li>
                <li ex:remove=".">item 3</li>
            </ul>
        )
    return o:apply($list, $groceries)
};

declare function ex:for-each($nodes, $items) {
    for $item in $items
    return
        $nodes => o:remove-attr('ex:for-each') => o:insert($item)
};

declare function ex:template($xml) {
    o:template(
        $xml,
        (
            ['li[@ex:for-each]', ex:for-each#2],
            ['li[@ex:remove]', ()]
        )
    )
};

(: TODO: mu namespace shouldn't be here, see comment in code :)
declare %unit:test function ex:test-list-template-dsl()
{
    unit:assert-equals(
        o:xml(ex:list-template-dsl()),
        <ul>
            <li>Apples</li>
            <li>Bananas</li>
            <li>Pears</li>
        </ul>,
        'Template DSL'
    )  
};

(:
 : Composing templates.
 :
 : Free functions do not receive the node as automatic first arg.
 :)
declare variable $ex:list-item :=
  ['li', map {'class': 'calc'}, function($pair) { sum($pair) }];
  
declare variable $ex:ol-list :=
  ['ol', function($seq) {
    for $pair in $seq
    return o:apply($ex:list-item, $pair)      
  }];

(:
 : The top level takes 1 argument, the list item
 : takes 2 arguments. 
 :)
declare function ex:list-template3() 
{
    (: TODO: and this is even harder to explain :)
    o:apply($ex:ol-list, [[1,2],[3,4],[5,6]])
};

declare %unit:test function ex:test-list-template3()
{
    unit:assert-equals(
        o:xml(ex:list-template3()),
        <ol>
            <li class="calc">3</li>
            <li class="calc">7</li>
            <li class="calc">11</li>
        </ol>,
        'Compose a template'
    )
};

declare variable $ex:svg := 
  ['rect', map { 'x': 0, 'y': 0 },
    ['rect',
      ['rect', map { 'width': 30, 'height': 20 }],
      ['rect', map { 'width': 40, 'height': 20 }]
    ],
    ['rect',
      ['rect', map { 'width': 50, 'height': 20 }],
      ['rect', map { 'width': 60, 'height': 20 }]    
    ]
  ];

declare function ex:layout($n) {
    let $tag := o:tag($n)
    let $atts := o:attributes($n)
    let $content := o:content($n)
    let $atts := 
      if (exists($content))
      then map:merge((
        $atts,
        map:entry('height', sum(for $node in $content return o:attributes($node)?height)),
        map:entry('width', sum(for $node in $content return o:attributes($node)?width))
      ))
      else $atts      
    return
      array { $tag, $atts, $content }
};

declare %unit:test function ex:test-postwalk-layout-example()
{
    unit:assert-equals(
      o:xml(o:postwalk(ex:layout#1, $ex:svg)),
      <rect width="180" height="80" x="0" y="0">
        <rect width="70" height="40">
          <rect width="30" height="20"/>
          <rect width="40" height="20"/>
        </rect>
        <rect width="110" height="40">
          <rect width="50" height="20"/>
          <rect width="60" height="20"/>
        </rect>
      </rect>,
      'Generate SVG'
    )  
};

(:~ 
 : A bar chart
 :
 : see http://bost.ocks.org/mike/bar/2/
 :)
declare variable $ex:chart-data := (4,8,15,16,23,42);
declare variable $ex:chart-width := 420;
declare variable $ex:chart-bar-height := 20;

declare function ex:scale-linear($domain,$range)
{
   let $factor := ( $range?2 - $range?1 ) idiv  ( $domain?2 - $domain?1 )
   return
     function($x) {
       $x * $factor
     } 
};

declare function ex:bars($data)
{
    let $text-atts := map { 
        'fill': 'white', 
        'font': '10px sans-serif', 
        'text-anchor': 'end' }
    let $width := ex:scale-linear([0, max($data)], [0, $ex:chart-width])
    for $bar at $pos in $data
    return
      ['g', map { 
        'transform': "translate(0," || ($pos - 1) * $ex:chart-bar-height || ")" },
        ['rect', map { 
            'width': $width($bar) , 
            'height': $ex:chart-bar-height - 1, 
            'fill': 'steelblue' }],
        ['text', map:merge(($text-atts, map { 
            'x': $width($bar) - 4, 
            'y': $ex:chart-bar-height div 2, 
            'dy': '.35em' })), $bar]
      ]  
};

declare function ex:bar-chart($data)
{
    o:xml(
      ['svg', 
        map { 
          'class': 'chart', 
          'width': $ex:chart-width, 
          'height': $ex:chart-bar-height * count($data) },
      ex:bars($data)
    ])
};

declare %unit:test function ex:test-bar-chart()
{
    unit:assert-equals(
        ex:bar-chart($ex:chart-data),
        <svg width="420" height="120" class="chart">
          <g transform="translate(0,0)">
            <rect fill="steelblue" width="40" height="19"/>
            <text fill="white" font="10px sans-serif" dy=".35em" text-anchor="end" x="36" y="10">4</text>
          </g>
          <g transform="translate(0,20)">
            <rect fill="steelblue" width="80" height="19"/>
            <text fill="white" font="10px sans-serif" dy=".35em" text-anchor="end" x="76" y="10">8</text>
          </g>
          <g transform="translate(0,40)">
            <rect fill="steelblue" width="150" height="19"/>
            <text fill="white" font="10px sans-serif" dy=".35em" text-anchor="end" x="146" y="10">15</text>
          </g>
          <g transform="translate(0,60)">
            <rect fill="steelblue" width="160" height="19"/>
            <text fill="white" font="10px sans-serif" dy=".35em" text-anchor="end" x="156" y="10">16</text>
          </g>
          <g transform="translate(0,80)">
            <rect fill="steelblue" width="230" height="19"/>
            <text fill="white" font="10px sans-serif" dy=".35em" text-anchor="end" x="226" y="10">23</text>
          </g>
          <g transform="translate(0,100)">
            <rect fill="steelblue" width="420" height="19"/>
            <text fill="white" font="10px sans-serif" dy=".35em" text-anchor="end" x="416" y="10">42</text>
          </g>
        </svg>,
        'Generate bar chart'
    )
};