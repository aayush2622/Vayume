BEGIN {
  pattern = key
  gsub(/\./, "\\.", pattern)
  pattern = "^[ \t]*" pattern "[ \t]*="
  skipping = 0
  done = 0
  n = 0
}
{
  if (skipping) {
    if ($0 ~ /;[ \t]*$/) skipping = 0
    next
  }
  if ($0 ~ pattern) {
    if (mode == "set" && !done) {
      out[++n] = "  " key " = " value ";"
      done = 1
    }
    if ($0 !~ /;[ \t]*$/) skipping = 1
    next
  }
  out[++n] = $0
}
END {
  last = 0
  for (i = n; i >= 1; i--) {
    if (out[i] ~ /^}[ \t]*$/) { last = i; break }
  }
  for (i = 1; i <= n; i++) {
    if (mode == "set" && !done && i == last) {
      print "  " key " = " value ";"
      done = 1
    }
    print out[i]
  }
}
