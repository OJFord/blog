#!/usr/bin/env bash

# Execute script from its own directory
cd "$(cd "$(dirname "$0")"; pwd -P)" || exit 1

# Dump stdin (Terraform requirement)
read -r

mkdir -p posts/generated
src_files=$(find posts -maxdepth 1 -type f)

truncate -s 0 posts.tf
echo "@posts = [" > vars.rb

metadata_tpl="/tmp/metadata.pandoc-template"
echo "\$meta-json\$" > "$metadata_tpl"

for src_file in $src_files; do
    src_fname="${src_file#posts/}"
    gen_fname="${src_fname%.md}.html"
    gen_file="posts/generated/$gen_fname"

    cat "$src_file" | kramdown \
        --to=html5 --katex --standalone --template=template.html \
        --output="$gen_file"

    cat <<- EOF >> posts.tf
	resource "aws_s3_bucket_object" "post_${src_fname%.md}" {
	    bucket       = "\${aws_s3_bucket.blog.bucket}"
	    key          = "post/$gen_fname"
	    source       = "\${path.module}/$gen_file"
	    etag         = "\${md5(file("\${path.module}/$gen_file"))}"
	    content_type = "text/html"
	}
	EOF

    mapfile -t metadata <<< "$(pandoc --template="$metadata_tpl" "$src_file" | jq --raw-output .title,.date)"
    cat <<-EOF >> vars.rb
	    {
	        'title' => '${metadata[0]}',
	        'date' => '${metadata[1]}',
	        'fname' => '$gen_fname',
	    },
	EOF
done

echo "]" >> vars.rb
erb -r ./vars.rb listing.html.erb > listing.html

pandoc --template=template.html --to=html5 /dev/null --output=posts/generated/index.html

# Output JSON (Terraform requirement)
echo "{}"
