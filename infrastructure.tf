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

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.domain}", "https://*.${var.domain}"]
    expose_headers = ["ETag"]
    max_age_seconds = 3000
  }

  website = {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = "${aws_s3_bucket.blog.bucket}"
  key          = "${aws_s3_bucket.blog.website.0.index_document}"
  source       = "${path.module}/${aws_s3_bucket.blog.website.0.index_document}"
  etag         = "${md5(file("${path.module}/${aws_s3_bucket.blog.website.0.index_document}"))}"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "post_css" {
  bucket       = "${aws_s3_bucket.blog.bucket}"
  key          = "post.css"
  source       = "${path.module}/post.css"
  etag         = "${md5(file("${path.module}/post.css"))}"
  content_type = "text/css"
}

data "external" "post_generator" {
  program = ["${path.module}/generator.sh"]
}

resource "cloudflare_record" "blog" {
  domain  = "${var.domain}"
  name    = "${var.subdomain}"
  value   = "${aws_s3_bucket.blog.website_endpoint}"
  type    = "CNAME"
  proxied = "true"
}
