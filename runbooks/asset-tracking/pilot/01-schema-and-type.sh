#!/usr/bin/env bash
# Assets pilot: schema + Laptop object type + attributes + 3 pilot objects
set -euo pipefail
source "$HOME/Documents/Devin/skills-Helcim/.env"
WS="9c2136e0-6a9b-4ea4-8df2-7e6e8bc80e32"
API="https://api.atlassian.com/jsm/assets/workspace/$WS/v1"
AUTH=(-u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN")
H=(-H "Content-Type: application/json" -H "Accept: application/json")

echo "=== 1. Create schema ==="
SCHEMA=$(curl -s "${AUTH[@]}" "${H[@]}" "$API/objectschema/create" -d '{
  "name": "Helcim IT Assets",
  "objectSchemaKey": "HLCA",
  "description": "Fleet inventory keyed on serial."
}')
echo "$SCHEMA" | tee /tmp/assets-schema.json | jq .
SID=$(jq -r '.id' /tmp/assets-schema.json)
echo "schema id=$SID"

echo "=== 2. Create object type: Laptop ==="
OT=$(curl -s "${AUTH[@]}" "${H[@]}" "$API/objecttype/create" -d "{
  \"name\": \"Laptop\",
  \"description\": \"Company laptops; identity = serial.\",
  \"objectSchemaId\": \"$SID\",
  \"iconId\": 1
}")
echo "$OT" | tee /tmp/assets-ot.json | jq .
OTID=$(jq -r '.id' /tmp/assets-ot.json)
echo "object type id=$OTID"

mk_attr() { # name, type, extra_json_fields
  local name="$1" type="$2" extra="${3:-}"
  curl -s "${AUTH[@]}" "${H[@]}" "$API/objecttypeattribute/$OTID" \
    -d "{\"name\":\"$name\",\"type\":$type${extra:+,$extra}}" | jq -r '"  attr: \(.name) -> id \(.id)"'
}

echo "=== 3. Add attributes ==="
mk_attr "Serial Number"   0 '"defaultTypeId":0,"uniqueAttribute":true'
mk_attr "Platform"        0 '"defaultTypeId":10,"options":"macOS,Windows"'
mk_attr "Model"           0 '"defaultTypeId":0'
mk_attr "Assigned User"   0 '"defaultTypeId":0'
mk_attr "Lifecycle Status" 0 '"defaultTypeId":10,"options":"In Stock,Assigned,Ready for Redeploy,In Repair,Retired"'
mk_attr "Purchase Date"   0 '"defaultTypeId":4'
mk_attr "Purchase Cost"   0 '"defaultTypeId":3'
mk_attr "Warranty Expiry" 0 '"defaultTypeId":4'

echo "=== 4. Attribute ID map ==="
ATTRS=$(curl -s "${AUTH[@]}" "${H[@]}" "$API/objecttype/$OTID/attributes")
echo "$ATTRS" > /tmp/assets-attrs.json
echo "$ATTRS" | jq -r '.[] | "\(.id)\t\(.name)"' | tee /tmp/assets-attr-map.txt

aid() { jq -r --arg n "$1" '.[] | select(.name==$n) | .id' /tmp/assets-attrs.json; }
SN=$(aid "Serial Number"); PL=$(aid "Platform"); MD=$(aid "Model"); AU=$(aid "Assigned User"); ST=$(aid "Lifecycle Status")
NAMEID=$(aid "Name")

mk_obj() { # name|serial|platform|model|user|status
  IFS='|' read -r oname ser plat mod usr stat <<< "$1"
  local attrs=()
  attrs+=("{\"objectTypeAttributeId\":$SN,\"objectAttributeValues\":[{\"value\":\"$ser\"}]}")
  attrs+=("{\"objectTypeAttributeId\":$PL,\"objectAttributeValues\":[{\"value\":\"$plat\"}]}")
  attrs+=("{\"objectTypeAttributeId\":$MD,\"objectAttributeValues\":[{\"value\":\"$mod\"}]}")
  attrs+=("{\"objectTypeAttributeId\":$AU,\"objectAttributeValues\":[{\"value\":\"$usr\"}]}")
  attrs+=("{\"objectTypeAttributeId\":$ST,\"objectAttributeValues\":[{\"value\":\"$stat\"}]}")
  curl -s "${AUTH[@]}" "${H[@]}" "$API/object/create" -d "{
    \"objectTypeId\": $OTID,
    \"attributes\": [
      {\"objectTypeAttributeId\":$NAMEID,\"objectAttributeValues\":[{\"value\":\"$oname\"}]},
      ${attrs[0]},${attrs[1]},${attrs[2]},${attrs[3]},${attrs[4]}
    ]
  }" | jq -r '"  created: \(.label) (object id \(.id))"'
}

echo "=== 5. Create pilot objects ==="
mk_obj "HLC-0001|N6VN9M200T|macOS|MacBook Pro 14 (M3 Pro, Mac15,6)|aobsiye@helcim.com|Assigned"
mk_obj "HLC-0002|WIN-DEMO-0012|Windows|Lenovo ThinkPad X1 (test)||In Stock"
mk_obj "HLC-0003|MAC-DEMO-0007|macOS|MacBook Air 13 (test)||Ready for Redeploy"

echo "=== 6. Verify: list objects ==="
curl -s "${AUTH[@]}" "${H[@]}" "$API/object/aql" -X POST -d "{
  \"qlQuery\": \"objectType = \\\"Laptop\\\"\",
  \"objectSchemaId\": \"$SID\",
  \"page\": 1, \"resultPerPage\": 25, \"includeAttributes\": true
}" | jq -r '.objectEntries[] | "\(.label)\t\(.objectType.name)"' 2>/dev/null || echo "(aql list shape differs on this API version — check UI)"

echo ""
echo "SCHEMA_ID=$SID"
echo "OBJECT_TYPE_ID=$OTID"
