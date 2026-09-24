def parse:
  if . == "true" then true
  elif . == "false" then false
  elif . == "null" then null
  elif test("^-?[0-9]+$") then tonumber
  elif startswith("\"") then (gsub("\\\\\\$"; "$") | try fromjson catch {unparsed: true})
  elif startswith("[") then (gsub("\"\\s+\""; "\",\"") | gsub("^\\[\\s+"; "[") | gsub("\\s+\\]$"; "]") | try fromjson catch {unparsed: true})
  else {unparsed: true}
  end;

def isunparsed: type == "object" and has("unparsed");

($pending | split("\n") | map(select(length > 0) | split("\t") | {key: .[0], value: ((.[1] // "") | parse)}) | from_entries) as $set
| $base[0]
| map(
    . as $s
    | ($set | has($s.path)) as $configured
    | ($set[$s.path]) as $p
    | (if $configured and ($p | isunparsed | not) then $p elif $configured then $s.value else $s.base end) as $effective
    | . + {
        applied: $s.value,
        value: $effective,
        configured: $configured,
        pending: ($effective != $s.value),
        unparsed: ($configured and ($p | isunparsed))
      }
  )
