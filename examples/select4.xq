xquery version "3.0";

(:~
 : Origami extract example
 :
 : Demonstrates composability of xf:select().
 :
 : NOTE: There is a bug in olders snapshots that doesn't compile
 :       the obvious xf:select(('ul','li')) correctly.
 :       @see http://www.mail-archive.com/basex-talk%40mailman.uni-konstanz.de/msg05107.html
 : 
 : Of course in this simple example using xf:select('ul/li') would
 : be preferable.
 :)
import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

let $extract :=
    xf:extract(xf:select(('ul','li')))

let $input :=
    document {
        <div>
            <li>item 1</li>
            <li>item 2</li>
            <ul>
                <li>item 3</li>
                <li>item 4</li>
            </ul>
            <li>item 5</li>
        </div>    
    }
 
return prof:time($extract($input))