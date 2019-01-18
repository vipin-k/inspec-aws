# AWS Terraform Templates for InSpec Testing

terraform {
  required_version = "~> 0.11.10"
}

# Configure variables

variable "aws_region" {}
variable "aws_vpc_name" {}
variable "aws_vpc_instance_tenancy" {}
variable "aws_vpc_cidr_block" {}
variable "aws_subnet_name" {}
variable "aws_availability_zone" {}
variable "aws_vm_name" {}
variable "aws_vm_size" {}
variable "aws_vm_image_filter" {}
variable "aws_enable_creation" {}
variable "aws_ebs_volume_name" {}
variable "aws_key_description_enabled" {}
variable "aws_key_description_disabled" {}
variable "aws_internet_gateway_name" {}
variable "aws_bucket_public_name" {}
variable "aws_bucket_private_name" {}
variable "aws_bucket_public_objects_name" {}
variable "aws_bucket_auth_name" {}
variable "aws_bucket_acl_policy_name" {}
variable "aws_bucket_log_delivery_name" {}
variable "aws_bucket_log_sender_name" {}
variable "aws_bucket_logging_disabled" {}
variable "aws_bucket_encryption_enabled" {}
variable "aws_bucket_encryption_disabled" {}
variable "aws_sns_topic_with_subscription" {}
variable "aws_sns_topic_no_subscription" {}
variable "aws_sns_topic_subscription_sqs" {}
variable "aws_security_group_alpha" {}
variable "aws_security_group_beta" {}
variable "aws_security_group_gamma" {}
variable "aws_security_group_omega" {}
variable "aws_rds_db_identifier" {}
variable "aws_rds_db_name" {}
variable "aws_rds_db_engine" {}
variable "aws_rds_db_engine_version" {}
variable "aws_rds_db_storage_type" {}
variable "aws_rds_db_master_user" {}
variable "aws_cloud_trail_name" {}
variable "aws_cloud_trail_bucket_name" {}
variable "aws_cloud_trail_log_group" {}
variable "aws_cloud_trail_key_description" {}
variable "aws_cloud_watch_logs_role_name" {}
variable "aws_cloud_watch_logs_role_policy_name" {}
variable "aws_cloud_trail_open_name" {}

provider "aws" {
  version = "= 1.48.0"
  region = "${var.aws_region}"
}

data "aws_caller_identity" "creds" {}
data "aws_region" "current" {}

# default VPC always exists for every AWS region
data "aws_vpc" "default" {
  default = "true"
}

resource "aws_vpc" "inspec_vpc" {
  count = "${var.aws_enable_creation}"
  cidr_block = "${var.aws_vpc_cidr_block}"
  instance_tenancy = "${var.aws_vpc_instance_tenancy}"

  tags {
    Name = "${var.aws_vpc_name}"
  }
}

resource "aws_subnet" "inspec_subnet" {
  count = "${var.aws_enable_creation}"
  vpc_id = "${aws_vpc.inspec_vpc.id}"
  availability_zone = "${var.aws_availability_zone}"
  cidr_block = "${cidrsubnet(aws_vpc.inspec_vpc.cidr_block, 1, 1)}"
  # will result in /28 (or 16) IP addresses

  tags {
    Name = "${var.aws_subnet_name}"
  }
}


data "aws_ami" "linux_ubuntu" {

  most_recent = true

  filter {
    name = "name"
    values = [
      "${var.aws_vm_image_filter}"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  owners = [
    "099720109477"]
  # Canonical
}

resource "aws_instance" "linux_ubuntu_vm" {
  count = "${var.aws_enable_creation}"
  ami = "${data.aws_ami.linux_ubuntu.id}"
  instance_type = "${var.aws_vm_size}"

  tags {
    Name = "${var.aws_vm_name}"
  }
}

resource "aws_ebs_volume" "inspec_ebs_volume" {
  count = "${var.aws_enable_creation}"
  availability_zone = "${var.aws_availability_zone}"
  size = 1

  tags {
    Name = "${var.aws_ebs_volume_name}"
  }
}

# KMS Keys
resource "aws_kms_key" "kms_key_enabled_rotating" {
  count = "${var.aws_enable_creation}"
  description = "${var.aws_key_description_enabled}"
  deletion_window_in_days = 10
  key_usage = "ENCRYPT_DECRYPT"
  is_enabled = true
  enable_key_rotation = true
}

resource "aws_kms_key" "kms_key_disabled_non_rotating" {
  count = "${var.aws_enable_creation}"
  description = "${var.aws_key_description_disabled}"
  deletion_window_in_days = 10
  key_usage = "ENCRYPT_DECRYPT"
  is_enabled = false
  enable_key_rotation = false
}


# Route tables
resource "aws_internet_gateway" "inspec_internet_gateway" {
  count = "${var.aws_enable_creation}"
  vpc_id = "${aws_vpc.inspec_vpc.id}"

  tags {
    Name = "${var.aws_internet_gateway_name}"
  }
}

resource "aws_route_table" "route_table_first" {
  count = "${var.aws_enable_creation}"
  vpc_id = "${aws_vpc.inspec_vpc.id}"

  route {
    cidr_block = "10.0.0.0/25"
    gateway_id = "${aws_internet_gateway.inspec_internet_gateway.id}"
  }
}

resource "aws_route_table" "route_table_second" {
  count = "${var.aws_enable_creation}"
  vpc_id = "${aws_vpc.inspec_vpc.id}"

  route {
    cidr_block = "10.0.0.0/25"
    gateway_id = "${aws_internet_gateway.inspec_internet_gateway.id}"
  }
}

# S3
resource "aws_s3_bucket" "bucket_public" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_public_name}"
  acl = "public-read"
}

resource "aws_s3_bucket" "bucket_private" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_private_name}"
  acl = "private"
}

resource "aws_s3_bucket" "bucket_public_for_objects" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_public_objects_name}"
  acl = "public-read"
}

resource "aws_s3_bucket" "bucket_auth" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_auth_name}"
  acl = "authenticated-read"
}

resource "aws_s3_bucket" "bucket_private_acl_public_policy" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_acl_policy_name}"
  acl = "private"
}

resource "aws_s3_bucket" "bucket_log_delivery" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_log_delivery_name}"
  force_destroy = true
  acl = "log-delivery-write"
}

resource "aws_s3_bucket" "bucket_access_logging_enabled" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_log_sender_name}"
  acl = "private"

  logging {
    target_bucket = "${aws_s3_bucket.bucket_log_delivery.id}"
    target_prefix = "log/"
  }
}

resource "aws_s3_bucket" "bucket_access_logging_not_enabled" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_logging_disabled}"
  acl = "private"
}


resource "aws_s3_bucket" "bucket_default_encryption_enabled" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_encryption_enabled}"
  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket" "bucket_default_encryption_disabled" {
  count = "${var.aws_enable_creation}"
  bucket = "${var.aws_bucket_encryption_disabled}"
  acl = "private"
}


resource "aws_s3_bucket_policy" "allow_public" {
  count = "${var.aws_enable_creation}"
  bucket = "${aws_s3_bucket.bucket_public.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket_public.id}/*"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_policy" "deny_private" {
  count = "${var.aws_enable_creation}"
  bucket = "${aws_s3_bucket.bucket_private.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyGetObject",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket_private.id}/*"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_policy" "allow-private-acl-public-policy" {
  count = "${var.aws_enable_creation}"
  bucket = "${aws_s3_bucket.bucket_private_acl_public_policy.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket_private_acl_public_policy.id}/*"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_object" "inspec_logo_public" {
  count = "${var.aws_enable_creation}"
  bucket = "${aws_s3_bucket.bucket_public_for_objects.id}"
  key = "inspec-logo-public"
  source = "inspec-logo.png"
  acl = "public-read"
}

resource "aws_s3_bucket_object" "inspec_logo_private" {
  count = "${var.aws_enable_creation}"
  bucket = "${aws_s3_bucket.bucket_public_for_objects.id}"
  key = "inspec-logo-private"
  source = "inspec-logo.png"
  acl = "private"
}


# SNS resources
resource "aws_sns_topic" "sns_topic_subscription" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_sns_topic_with_subscription}"
}

resource "aws_sqs_queue" "sns_sqs_queue" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_sns_topic_subscription_sqs}"
}

resource "aws_sns_topic_subscription" "sqs_test_queue_subscription" {
  count = "${var.aws_enable_creation}"
  topic_arn = "${aws_sns_topic.sns_topic_subscription.arn}"
  protocol = "sqs"
  endpoint = "${aws_sqs_queue.sns_sqs_queue.arn}"
}

resource "aws_sns_topic" "sns_topic_no_subscription" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_sns_topic_no_subscription}"
}

# Security Groups and Rules
data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name = "default"
}

resource "aws_security_group" "alpha" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_security_group_alpha}"
  description = "SG alpha"
  vpc_id = "${data.aws_vpc.default.id}"
}

resource "aws_security_group" "beta" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_security_group_beta}"
  description = "SG beta"
  vpc_id = "${data.aws_vpc.default.id}"
}

resource "aws_security_group" "gamma" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_security_group_gamma}"
  description = "SG gamma"
  vpc_id = "${data.aws_vpc.default.id}"
}

// Note this gets created in a new VPC and with no rules defined
resource "aws_security_group" "omega" {
  count = "${var.aws_enable_creation}"
  name = "${var.aws_security_group_omega}"
  description = "SG omega"
  vpc_id = "${aws_vpc.inspec_vpc.id}"
}

resource "aws_security_group_rule" "alpha_http_world" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = "${aws_security_group.alpha.id}"
}

resource "aws_security_group_rule" "alpha_ssh_in" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "tcp"
  cidr_blocks = [
    "10.1.2.0/24"]
  security_group_id = "${aws_security_group.alpha.id}"
}

resource "aws_security_group_rule" "alpha_x11" {
  count = "${var.aws_enable_creation}"
  description = "Only allow X11 out for some reason"
  type = "egress"
  from_port = "6000"
  to_port = "6007"
  protocol = "tcp"
  cidr_blocks = [
    "10.1.2.0/24",
    "10.3.2.0/24"]
  ipv6_cidr_blocks = [
    "2001:db8::/122"]
  security_group_id = "${aws_security_group.alpha.id}"
}

resource "aws_security_group_rule" "alpha_all_ports" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "0"
  to_port = "65535"
  protocol = "tcp"
  cidr_blocks = [
    "10.1.2.0/24"]
  security_group_id = "${aws_security_group.alpha.id}"
}

resource "aws_security_group_rule" "alpha_piv6_all_ports" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "0"
  to_port = "65535"
  protocol = "tcp"
  ipv6_cidr_blocks = [
    "2001:db8::/122"]
  security_group_id = "${aws_security_group.alpha.id}"
}

resource "aws_security_group_rule" "beta_http_world" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = "${aws_security_group.beta.id}"
}

resource "aws_security_group_rule" "beta_ssh_in_alfa" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.alpha.id}"
  security_group_id = "${aws_security_group.beta.id}"
}

resource "aws_security_group_rule" "beta_all_ports_in_gamma" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "0"
  to_port = "65535"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.gamma.id}"
  security_group_id = "${aws_security_group.beta.id}"
}

resource "aws_security_group_rule" "gamma_ssh_in_alfa" {
  count = "${var.aws_enable_creation}"
  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.alpha.id}"
  security_group_id = "${aws_security_group.gamma.id}"
}

resource "aws_db_instance" "db_rds" {
  count = "${var.aws_enable_creation}"
  allocated_storage = 10
  storage_type = "${var.aws_rds_db_storage_type}"
  engine ="${var.aws_rds_db_engine}"
  engine_version = "${var.aws_rds_db_engine_version}"
  instance_class = "db.t2.micro"
  identifier = "${var.aws_rds_db_identifier}"
  name = "${var.aws_rds_db_name}"
  username = "${var.aws_rds_db_master_user}"
  password = "testpassword"
  parameter_group_name = "default.mysql5.6"
  skip_final_snapshot = true
}

# Cloudtrail

resource "aws_s3_bucket" "trail_1_bucket" {
  bucket        = "${var.aws_cloud_trail_bucket_name}"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.aws_cloud_trail_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.aws_cloud_trail_bucket_name}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role" "cloud_watch_logs_role" {
  name = "${var.aws_cloud_watch_logs_role_name}"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "cloudtrail.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy" "cloud_watch_logs_role_policy" {
  depends_on = ["aws_iam_role.cloud_watch_logs_role"]

  name = "${var.aws_cloud_watch_logs_role_policy_name}"
  role = "${var.aws_cloud_watch_logs_role_name}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailCreateLogStream",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.creds.account_id}:log-group:${aws_cloudwatch_log_group.trail_1_log_group.name}:log-stream:${data.aws_caller_identity.creds.account_id}_CloudTrail_${data.aws_region.current.name}*"
            ]
        },
        {
            "Sid": "AWSCloudTrailPutLogEvents",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.creds.account_id}:log-group:${aws_cloudwatch_log_group.trail_1_log_group.name}:log-stream:${data.aws_caller_identity.creds.account_id}_CloudTrail_${data.aws_region.current.name}*"
            ]
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "trail_1_log_group" {
  name = "${var.aws_cloud_trail_log_group}"
}

resource "aws_kms_key" "trail_1_key" {
  description             = "${var.aws_cloud_trail_key_description}"
  deletion_window_in_days = 10

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "Key policy created by CloudTrail",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.creds.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudTrail to encrypt logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:GenerateDataKey*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.creds.account_id}:trail/*"
        }
      }
    },
    {
      "Sid": "Allow CloudTrail to describe key",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:DescribeKey",
      "Resource": "*"
    },
    {
      "Sid": "Allow principals in the account to decrypt log files",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "kms:Decrypt",
        "kms:ReEncryptFrom"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${data.aws_caller_identity.creds.account_id}"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.creds.account_id}:trail/*"
        }
      }
    },
    {
      "Sid": "Allow alias creation during setup",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "kms:CreateAlias",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ec2.${data.aws_region.current.name}.amazonaws.com",
          "kms:CallerAccount": "${data.aws_caller_identity.creds.account_id}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_cloudtrail" "trail_1" {
  depends_on                    = ["aws_iam_role_policy.cloud_watch_logs_role_policy"]
  name                          = "${var.aws_cloud_trail_name}"
  s3_bucket_name                = "${aws_s3_bucket.trail_1_bucket.id}"
  include_global_service_events = true
  enable_logging                = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail_1_log_group.arn}"
  cloud_watch_logs_role_arn  = "${aws_iam_role.cloud_watch_logs_role.arn}"
  kms_key_id                 = "${aws_kms_key.trail_1_key.arn}"
}

resource "aws_cloudtrail" "trail_2" {
  name           = "${var.aws_cloud_trail_open_name}"
  s3_bucket_name = "${aws_s3_bucket.trail_1_bucket.id}"
}