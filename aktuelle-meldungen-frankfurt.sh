#!/bin/bash
set -euo pipefail

declare_vars() {
  url_id="https://frankfurt.de/aktuelle-meldung/meldungen/"
  url_content="https://frankfurt.de/api/Category/NewsSearchResults"
  pattern_id='<input type="hidden" value="\{(.*)\}" id="CurrentCategoryId" />'
  pattern_date='<div class="td _date".*<span>(.*)</span>.*'
  pattern_url='<a href="(.*)">'
  pattern_title='<span class="_block">(.*)</span>'
}

footer() {
  cat << END
</feed>
END
}

header() {
  cat << END
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Aktuelle Meldungen der Stadt Frankfurt</title>
  <id>https://frankfurt.de/aktuelle-meldung/meldungen/</id>
  <updated>$(date --iso-8601=seconds)</updated>
END
}

entry() {
  cat << END
  <entry>
    <title>$1</title>
    <link href="$2"/>
    <id>$2</id>
    <updated>$(date -d "$3" --iso-8601=seconds)</updated>
  </entry>
END
}

get_content() {
  id="$1"
  data="querystring=&renderingId=%7B${id}%7D&page=0&resultsToShow=20"
  curl -s "$url_content" \
       --compressed \
       -X POST \
       -H 'Accept: text/html, */*; q=0.01' \
       -H 'Accept-Encoding: gzip, deflate, br' \
       -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
       -H 'X-Requested-With: XMLHttpRequest' \
       -H 'Referer: https://frankfurt.de/aktuelle-meldung/meldungen/' \
       --data-raw "$data" | \


  while IFS= read -r line
  do
    if [[ $line =~ $pattern_date ]]; then
      date_de="${BASH_REMATCH[1]}"
      date="${date_de:6:4}${date_de:3:2}${date_de:0:2}"
    elif [[ $line =~ $pattern_url ]]; then
      url="${BASH_REMATCH[1]}"
    elif [[ $line =~ $pattern_title ]]; then
      title="${BASH_REMATCH[1]}"
      entry "$title" "$url" "$(date -d "$date" --iso-8601=seconds)"
    fi
  done
}

get_id() {
  curl -s "$url_id" | \
  
  # Read each line
  while IFS= read -r line
  do
    if [[ $line =~ $pattern_id ]]; then
      local id="${BASH_REMATCH[1]}"
      echo "$id"
    fi
  done
}

main() {
  declare_vars
  if id=$(get_id); then
    header
    get_content "$id"
    footer
  else
    echo "Error loading $url"
    exit 1
  fi
}

main "$@"
