resource "aws_s3_bucket" "blog" {
  bucket  = "${var.s3_bucket}"
  acl     = "public-read"
  website = {}
}

resource "cloudflare_record" "blog" {
  domain  = "${var.domain}"
  name    = "${var.subdomain}"
  value   = "${aws_s3_bucket.blog.website_endpoint}"
  type    = "CNAME"
  proxied = "true"
}
