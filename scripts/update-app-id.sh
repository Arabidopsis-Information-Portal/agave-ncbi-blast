#!/bin/bash

auth-tokens-refresh -S
UUID=$(metadata-list -i -Q '{"name":"araport.ncbi-blast.applist"}')
metadata-addupdate -v -F araport.ncbi-blast.applist.json $UUID

for U in world public
do
    metadata-pems-addupdate -u $U -p READ $UUID
done

