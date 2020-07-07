# 这里使用的AK和region都是从profile里面来的
provider "alicloud" {
  profile = "default"
}

######################## 步骤一 [账号创建和初始化]######################
#控制台操作

######################## 步骤二 [云账号安全加固]########################
# 创建用户: admin
resource "alicloud_ram_user" "user_admin" {
  name         = "admin"
  display_name = "管理员"
}

# 指定admin用户的控制台登录密码
resource "alicloud_ram_login_profile" "user_admin_profile" {
  user_name = alicloud_ram_user.user_admin.name
  password  = "Your_password1234"
}


# 为admin授权AdministratorAccess
resource "alicloud_ram_user_policy_attachment" "user_admin_AdministratorAccess" {
  policy_name = "AdministratorAccess"
  policy_type = "System"
  user_name   = alicloud_ram_user.user_admin.name
}

# 为admin 创建AK,后面的操作可以用这把AK替换主账号的AK
resource "alicloud_ram_access_key" "admin_ak" {
  user_name   = alicloud_ram_user.user_admin.name
  secret_file = "./admin_ak.txt"
}

# 密码策略
resource "alicloud_ram_account_password_policy" "password_policy" {
  minimum_password_length      = 8
  require_lowercase_characters = true
  require_uppercase_characters = true
  require_numbers              = true
  require_symbols              = true
  hard_expiry                  = false
  max_password_age             = 90
  password_reuse_prevention    = 8
  max_login_attempts           = 5
}


######################## 步骤三 [RAM配置]########################
# 创建系统管理的权限策略
resource "alicloud_ram_policy" "system_admin_policy" {
  name        = "SystemAdministratorAccess"
  document    = <<EOF
  {
    "Statement": [
        {
            "Effect": "Allow",
            "NotAction":
                [
                    "ram:*",
                    "ims:*",
                    "resourcemanager:*",
                    "bss:*",
                    "bssapi:*",
                    "efc:*"
                ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action":
                [
                    "ram:GetRole",
                    "ram:ListRoles",
                    "ram:CreateServiceLinkedRole",
                    "ram:DeleteServiceLinkedRole",
                    "bss:DescribeOrderList",
                    "bss:DescribeOrderDetail",
                    "bss:PayOrder",
                    "bss:CancelOrder"
                ],
            "Resource": "*"
        }
    ],
    "Version": "1"
}
  EOF
  description = "系统管理员权限"
  force       = true
}

# 创建云管理员组
resource "alicloud_ram_group" "cloud_admin_group" {
  name     = "CloudAdminGroup"
  comments = "云管理员组"
  force    = true
}

# 为云管理员组授权
resource "alicloud_ram_group_policy_attachment" "cloud_admin_group_policy_attachment" {
  policy_name = "AdministratorAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.cloud_admin_group.name
}

# 创建系统管理员组
resource "alicloud_ram_group" "system_admin_group" {
  name     = "SystemAdminGroup"
  comments = "系统管理员组"
  force    = true
}


# 为系统管理员组授权
resource "alicloud_ram_group_policy_attachment" "system_admin_group_policy_attachment" {
  policy_name = alicloud_ram_policy.system_admin_policy.name
  policy_type = alicloud_ram_policy.system_admin_policy.type
  group_name  = alicloud_ram_group.system_admin_group.name
}


# 创建财务账单管理员组
resource "alicloud_ram_group" "billing_admin_group" {
  name     = "BillingAdminGroup"
  comments = "财务账单管理员组"
  force    = true
}

# 为财务组授权AliyunBSSFullAccess
resource "alicloud_ram_group_policy_attachment" "bss_group_policy_attachment_AliyunBSSFullAccess" {
  policy_name = "AliyunBSSFullAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.billing_admin_group.name
}

# 为财务组授权AliyunFinanceConsoleFullAccess
resource "alicloud_ram_group_policy_attachment" "bss_group_policy_attachment_AliyunFinanceConsoleFullAccess" {
  policy_name = "AliyunFinanceConsoleFullAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.billing_admin_group.name
}

# 创建普通用户组
resource "alicloud_ram_group" "common_user_group" {
  name     = "CommonUserGroup"
  comments = "普通用户组"
  force    = true
}


######################## 步骤四 [网络配置]########################
# 创建VPC
resource "alicloud_vpc" "default_vpc" {
  name       = "default_vpc"
  cidr_block = "192.168.0.0/16"
}

# 创建交换机
resource "alicloud_vswitch" "default_vswitch" {
  name              = "default_vswitch"
  vpc_id            = alicloud_vpc.default_vpc.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "cn-hangzhou-h"
}

# 创建安全组
resource "alicloud_security_group" "charles_security_group" {
  name   = "default-sg"
  vpc_id = alicloud_vpc.default_vpc.id
}
