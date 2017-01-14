#!/bin/sh

# Execute script from its own directory
cd "$(cd "$(dirname "$0")"; pwd -P)" || exit 1

# Dump stdin (Terraform requirement)
read -r

mkdir -p posts/generated
src_files=$(find posts -maxdepth 1 -type f)

truncate -s 0 posts.tf

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
	    content_type = "text/html"
	}
	EOF
done

# Output JSON (Terraform requirement)
echo "{}"
