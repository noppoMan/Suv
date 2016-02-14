#!/bin/sh

cd ./Xcode

jazzy \
  --clean \
  --author Yuki Takei \
  --author_url https://github.com/noppoMan/Suv \
  --github_url https://github.com/noppoMan/Suv \
  --module Suv \
  --output ../docs/api
