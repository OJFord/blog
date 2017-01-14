#!/bin/sh
read -r # dump stdin

mkdir -p posts/generated
for post in posts/*.md; do
    pandoc --to=html5 --katex --standalone "$post" --output="$post.html"
done

echo "{\"fnames\": \"$(ls posts/generated)\"}"
