/^[ \t]*vayume\.[A-Za-z0-9_.]+[ \t]*=/ {
  line = $0
  sub(/^[ \t]*vayume\./, "", line)
  path = line
  sub(/[ \t]*=.*/, "", path)
  value = line
  sub(/^[^=]*=[ \t]*/, "", value)
  if (value ~ /^\{/) next
  while (value !~ /;[ \t]*$/ && (getline more) > 0) value = value " " more
  sub(/;[ \t]*$/, "", value)
  print path "\t" value
}
