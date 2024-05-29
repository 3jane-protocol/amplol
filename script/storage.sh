#!/usr/bin/env bash

forge build

CONTRACTS=(
Amplol
)

>.storage-layout

for CONTRACT in ${CONTRACTS[@]}
do
    echo $CONTRACT >> .storage-layout
    forge inspect --pretty $CONTRACT storage-layout >> .storage-layout
    if [[ $CONTRACT != ${CONTRACTS[$((${#CONTRACTS[*]}-1))]} ]]; then
        echo "" >> .storage-layout
    fi
done

