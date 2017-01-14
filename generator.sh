#!/bin/sh

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

    pandoc --to=html5 --katex --standalone --template=template.html \
        "$src_file" \
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

    title="$(pandoc --template="$metadata_tpl" "$src_file" | jq --raw-output .title)"
    cat <<-EOF >> vars.rb
	    {
	        'title' => '$title',
	        'fname' => '$gen_fname',
	    },
	EOF
done

echo "]" >> vars.rb
erb -r ./vars.rb index.html.erb > index.html

# Output JSON (Terraform requirement)
echo "{}"
