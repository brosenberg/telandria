#!/bin/sh
echo "{\"armor\":{"
awk '{print "\"" $1 "\": {\n" \
            "\t\"cost\": \"" $2 "\",\n" \
            "\t\"armor/shield bonus\": \"" $3 "\",\n" \
            "\t\"max dex\": \"" $4 "\",\n" \
            "\t\"armor check\": \"" $5 "\",\n" \
            "\t\"arcane spell failure\": \"" $6 "\",\n" \
            "\t\"speed (30 ft)\": \"" $7 "\",\n" \
            "\t\"speed (20 ft)\": \"" $8 "\",\n" \
            "\t\"weight\": \"" $9 "\",\n" \
            "\t\"type\": \"" $10 "\"\n" \
    "},"}' armors | sed 's/^/\t/;s/_/ /g;$s/,//'
echo "}"
