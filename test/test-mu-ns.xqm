xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/μ/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/μ' at '../mu.xqm'; 

declare %unit:test function test:default-namespace() 
{
        let $xml := μ:xml(['p'])
        return
            unit:assert-equals(namespace-uri($xml), '')
        ,
        let $xml := μ:xml(['h:p'])
        return
            unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
        ,
        let $xml := μ:xml(['p'], μ:qname-resolver(map {}, 'http://foobar'))
        return
            unit:assert-equals(namespace-uri($xml), 'http://foobar')
        ,
        let $xml := μ:xml(['h:x',['p']], μ:qname-resolver(μ:ns(), 'http://foobar'))
        return (
            unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
            (: default is set to a uri so we cannot just use $xml/p to get at the child element :)
            unit:assert-equals(namespace-uri($xml/*[1]), 'http://foobar')
        )
        ,
        let $xml := μ:xml(['h:x',['p']], μ:qname-resolver(μ:ns(), ''))
        return (
            unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
            unit:assert-equals(namespace-uri($xml/p), '')
        )

};


