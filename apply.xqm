module namespace apply = 'http://xokomola.com/xquery/common/apply';

(:~
 : Apply function (using xquery:eval) contributed by
 : Rob Stapper in answer to my proposal for adding
 : fn:apply to XQuery 3.1.
 :
 : @see https://www.w3.org/Bugs/Public/show_bug.cgi?id=26585
 :)

declare %private function apply:sequence($items) {
    concat('(', string-join($items, ', '), ')') 
};

declare %private function apply:parameter-list($argcount) {
    apply:sequence(
        (1 to $argcount) ! concat("$arg", .)
    )
};

declare %private variable $apply:argument-list-constructor-name := 'local:argument-list';

declare %private function apply:argument-list-constructor($parameter-list) {
    fn:concat(
        "declare %private function ",
        $apply:argument-list-constructor-name,
        $parameter-list,
        "{ function($f) { $f",
        $parameter-list,
        "}};"
    )
};

declare function apply:argument($arg) {
    typeswitch ($arg)
        case xs:string
            return '"' || string($arg) || '"'
        case array(*)
            return array:serialize($arg)
        case map(*)
            return map:serialize($arg)
        case xs:anyAtomicType
            return string($arg)
        case item()+
            return apply:argument-list($arg)
        default
            return string($arg)
};

declare function apply:argument-list($args) {
    apply:sequence(
        typeswitch ($args)
            case array(*)
                return 
                    for $i in 1 to array:size($args) 
                        return apply:argument($args($i))
            default
                return $args ! apply:argument(.)
    )
};

declare %private function apply:argument-list-constructor-caller($argument-list) {
    concat(
        $apply:argument-list-constructor-name,
        $argument-list
    )
};

declare function apply:apply($fn, $args) {
    xquery:eval(
        concat(
            apply:argument-list-constructor(
                apply:parameter-list(
                    typeswitch ($args)
                        case array(*)
                            return array:size($args)
                        default
                            return count($args)
                )
            ),
            apply:argument-list-constructor-caller(
                apply:argument-list($args)),
            '(.)'
        ),
        map { '': $fn }
    )
};
