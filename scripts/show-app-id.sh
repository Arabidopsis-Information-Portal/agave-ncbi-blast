#!/bin/bash

auth-tokens-refresh -S
metadata-list -i -v -Q '{"name":"araport.ncbi-blast.applist"}'
