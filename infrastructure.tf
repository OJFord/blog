resource "aws_s3_bucket" "blog" {
  bucket = "${var.subdomain}.${var.domain}"
  acl    = "public-read"

  policy = <<EOF
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Sid":"PublicReadGetObject",
            "Effect":"Allow",
            "Principal": "*",
            "Action":["s3:GetObject"],
            "Resource":["arn:aws:s3:::${var.subdomain}.${var.domain}/*"]
        }
    ]
}
EOF

  website = {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket = "${aws_s3_bucket.blog.bucket}"
  key    = "${aws_s3_bucket.blog.website.0.index_document}"
  source = "${path.module}/${aws_s3_bucket.blog.website.0.index_document}"
}

resource "cloudflare_record" "blog" {
  domain  = "${var.domain}"
  name    = "${var.subdomain}"
  value   = "${aws_s3_bucket.blog.website_endpoint}"
  type    = "CNAME"
  proxied = "true"
}
