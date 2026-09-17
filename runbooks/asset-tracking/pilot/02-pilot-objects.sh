#!/usr/bin/env bash
set -euo pipefail
source "$HOME/Documents/Devin/skills-Helcim/.env"
API="https://api.atlassian.com/jsm/assets/workspace/9c2136e0-6a9b-4ea4-8df2-7e6e8bc80e32/v1"
OTID=139
AUTH=(-u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN")
H=(-H "Content-Type: application/json" -H "Accept: application/json")

mk_attr() { # name, defaultTypeId, options(optional)
  curl -s "${AUTH[@]}" "${H[@]}" "$API/objecttypeattribute/$OTID" \
    -d "{\"name\":\"$1\",\"type\":0,\"defaultTypeId\":$2${3:+,\"options\":\"$3\"}}" \
    | jq -r '"  \(.name) -> id \(.id) (\(.defaultType.name // .name // "ok"))"'
}

echo "=== attributes ==="
mk_attr "Platform"         10 "macOS,Windows"
mk_attr "Model"            0
mk_attr "Assigned User"    0
mk_attr "Lifecycle Status" 10 "In Stock,Assigned,Ready for Redeploy,In Repair,Retired"
mk_attr "Purchase Date"    4
mk_attr "Purchase Cost"    3
mk_attr "Warranty Expiry"  4

echo "=== attribute map ==="
curl -s "${AUTH[@]}" "${H[@]}" "$API/objecttype/$OTID/attributes" > /tmp/assets-attrs.json
jq -r '.[] | "\(.id)\t\(.name)"' /tmp/assets-attrs.json

aid() { jq -r --arg n "$1" '.[] | select(.name==$n) | .id' /tmp/assets-attrs.json; }
SN=$(aid "Serial Number"); PL=$(aid "Platform"); MD=$(aid "Model")
AU=$(aid "Assigned User"); ST=$(aid "Lifecycle Status"); NAMEID=$(aid "Name")
echo "Name attr id = $NAMEID"

mk_obj() { # name|serial|platform|model|user|status
  IFS='|' read -r oname ser plat mod usr stat <<< "$1"
  local payload
  payload=$(jq -n --arg ot "$OTID" --arg name "$NAMEID" --arg v "$oname" \
    --arg sn "$SN" --arg v2 "$ser" --arg pl "$PL" --arg v3 "$plat" \
    --arg md "$MD" --arg v4 "$mod" --arg au "$AU" --arg v5 "$usr" \
    --arg st "$ST" --arg v6 "$stat" '{
      objectTypeId: ($ot|tonumber),
      attributes: [
        {objectTypeAttributeId: ($name|tonumber), objectAttributeValues: [{value: $v}]},
        {objectTypeAttributeId: ($sn|tonumber),  objectAttributeValues: [{value: $v2}]},
        {objectTypeAttributeId: ($pl|tonumber),  objectAttributeValues: [{value: $v3}]},
        {objectTypeAttributeId: ($md|tonumber),  objectAttributeValues: [{value: $v4}]},
        {objectTypeAttributeId: ($au|tonumber),  objectAttributeValues: [{value: $v5}]},
        {objectTypeAttributeId: ($st|tonumber),  objectAttributeValues: [{value: $v6}]}
      ]}')
  curl -s "${AUTH[@]}" "${H[@]}" "$API/object/create" -d "$payload" \
    | jq -r '"  created: \(.label) (object id \(.id), key \(.objectKey))"'
}

echo "=== pilot objects ==="
mk_obj "HLC-0001|N6VN9M200T|macOS|MacBook Pro 14 (M3 Pro)|aobsiye@helcim.com|Assigned"
mk_obj "HLC-0002|WIN-DEMO-0012|Windows|Lenovo ThinkPad X1 (test)||In Stock"
mk_obj "HLC-0003|MAC-DEMO-0007|macOS|MacBook Air 13 (test)||Ready for Redeploy"

echo "=== verify count ==="
curl -s "${AUTH[@]}" "${H[@]}" "$API/objectschema/103/objecttypes/flat" | jq -r '.[] | select(.name=="Laptop") | "Laptop object count: \(.objectCount)"'
