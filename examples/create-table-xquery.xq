xquery version "3.0";

declare variable $rows as xs:integer external := 10;

let $input :=
  <result>{
     for $i in (1 to $rows)
     return
       <record name="foo" age="{ $i }"/> 
  }
  </result>
return
  <table>{
    for $row in $input/record
    return
      <tr>
        <td>{ string($row/@name) }</td>
        <td>{ string(($row/@age,'unknown')[1]) }</td>
      </tr>
  }</table>