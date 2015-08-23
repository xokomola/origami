xquery version "3.1";

module namespace u = 'http://xokomola.com/xquery/origami/utils';

declare function u:select-keys($map as map(*)?, $keys as xs:anyAtomicType*)
as map(*)
{
    map:merge((
        for $k in map:keys(($map,map {})[1])
        where $k = $keys
        return map:entry($k, $map($k))
    ))
};

declare function u:walk($inner, $outer, $form)
{
    $outer(
        fold-left(
            $form,
            (),
            function($x,$y) { ($x, $inner($y)) }
        )
    )
};

