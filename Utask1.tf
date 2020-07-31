provider "aws" {
  region     = "ap-south-1"
  profile    = "rohit"
}
resource "tls_private_key" "key" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}
resource "aws_key_pair" "key_reg" {
  key_name   = "mykeyEfs"
  public_key = tls_private_key.key.public_key_openssh
}
resource "local_file" "priavte_key" {
    content     = tls_private_key.key.private_key_pem
    filename = "mykey.pem"
}
#security Group
resource "aws_security_group" "Security" {
  name        = "EC2_EFS_SECURITY_GROUP"
  description = "EC2"

  ingress {
    description = "webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP ssh protocol"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "SECURITY_GROUP_t2"
  }
}
output "security"{
    value = aws_security_group.Security.id
}
#EFS security Group
// resource "aws_security_group" "EFSGROUP" {
//   name        = "EFS_SECURITY_GROUP"
//   description = "EC2"

//   ingress {
//     description = "NFS"
//     from_port   = 2049
//     to_port     = 2049
//     protocol    = "tcp"
//     cidr_blocks = ["0.0.0.0/0"]
//   }

//   egress {
//     from_port   = 0
//     to_port     = 0
//     protocol    = "-1"
//     cidr_blocks = ["0.0.0.0/0"]
//   }

//   tags = {
//     Name = "EFS_SECURITY_GROUP"
//   }
// }
#EFS
resource "aws_efs_file_system" "nat" {
  creation_token = "webserver-efs"
  tags = {
    Name = "mystorage"
  }
}
output "val"{
  value = aws_efs_file_system.nat
}
resource "aws_efs_mount_target" "efs_1a" {
   file_system_id  = aws_efs_file_system.nat.id
   subnet_id = "subnet-061d276e"
   security_groups = ["${aws_security_group.Security.id}"]
}
resource "aws_efs_mount_target" "efs_1b" {
   file_system_id  = aws_efs_file_system.nat.id
   subnet_id = "subnet-7d1a7131"
   security_groups = ["${aws_security_group.Security.id}"]
}
resource "aws_efs_mount_target" "efs_1c" {
   file_system_id  = aws_efs_file_system.nat.id
   subnet_id = "subnet-fd07b586"
   security_groups = ["${aws_security_group.Security.id}"]
}
#aws s3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "mybucket123123123123"
  acl    = "private"
  tags = {
    Name        = "My bucket"
  }
}
resource "aws_s3_bucket_object" "obj" {
  key = "Img.png"
  bucket = aws_s3_bucket.b.id
  source = "abc.png"
  acl = "public-read"
}

#cloud front
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}
data "aws_iam_policy_document" "distribution" {
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
    resources = ["${aws_s3_bucket.b.arn}/*"]
  }
}
resource "aws_s3_bucket_policy" "web_distribution" {
  bucket = aws_s3_bucket.b.id
  policy = data.aws_iam_policy_document.distribution.json
}
locals {
  depends_on = [
      aws_cloudfront_origin_access_identity.origin_access_identity
  ]
  s3_origin_id = aws_s3_bucket.b.id
}
#CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
      geo_restriction {
        restriction_type = "none"
      }
    }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#Instance
resource "aws_instance" "web" {
  depends_on  = [
   aws_security_group.Security
  ]
  ami           = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_reg.key_name
  security_groups = ["${aws_security_group.Security.name}"]

  tags = {
    Name = "webserver1"
  }
}
resource "aws_instance" "web2" {
  depends_on  = [
    aws_security_group.Security
  ]
  ami           = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_reg.key_name
  security_groups = ["${aws_security_group.Security.name}"]

  tags = {
    Name = "Backup@/efs"
  }
}
output "efs"{
  value = aws_efs_file_system.nat
}
resource "null_resource" "cluster" {
  depends_on = [
    aws_instance.web,
    aws_efs_file_system.nat,
    aws_efs_mount_target.efs_1c,
    aws_efs_mount_target.efs_1b,
    aws_efs_mount_target.efs_1a
  ]
   connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.key.private_key_pem
    host     = aws_instance.web.public_ip
  }
    provisioner "remote-exec" {
        inline = [
          "sudo yum install git httpd php  -y",
          "sudo systemctl start httpd",
          "sudo systemctl enable httpd",
          "sudo yum install amazon-efs-utils nfs-utils -y",
          "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.nat.id}.efs.ap-south-1.amazonaws.com:/ /var/www/html",
          "sudo rm -rf /var/www/html/*",
          "sudo git clone https://github.com/rohitraut3366/mulicloud.git /var/www/html"
        ]
      }
}
resource "null_resource" "cluster3" {
    depends_on = [
      aws_efs_file_system.nat,
      null_resource.cluster
    ]
    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key  =  tls_private_key.key.private_key_pem
    host     = aws_instance.web2.public_ip
  }
  provisioner "remote-exec" {
    inline = [
          "sudo yum install amazon-efs-utils nfs-utils -y",
          "sudo mkdir /efs",
          "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.nat.id}.efs.ap-south-1.amazonaws.com:/ /efs",
        ]
    }
}
output "e"{
  value = aws_efs_file_system.nat.id
}
