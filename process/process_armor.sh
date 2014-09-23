#!/bin/sh
echo "{\"armor\":{"
sed '/^$/d' armors  | \
awk '{print "\"" $1 "\": {\n" \
            "\t\"cost\": \"" $2 "\",\n" \
            "\t\"armor/shield bonus\": \"" $3 "\",\n" \
            "\t\"hitpoints\": \"" $3*5 "\",\n" \
            "\t\"hardness\": \"" $10 "\",\n" \
            "\t\"max dex\": \"" $4 "\",\n" \
            "\t\"armor check\": \"" $5 "\",\n" \
            "\t\"arcane spell failure\": \"" $6 "\",\n" \
            "\t\"speed (30 ft)\": \"" $7 "\",\n" \
            "\t\"speed (20 ft)\": \"" $8 "\",\n" \
            "\t\"weight\": \"" $9 "\",\n" \
            "\t\"type\": \"" $11 "\"\n" \
    "},"}' | \
sed 's/^/\t/;s/_/ /g;$s/,//'
echo "}"
