# 这里使用的AK和region都是从profile里面来的
provider "alicloud" {
  profile = "default"
}

data "alicloud_ram_policies" "policies_ds" {
  type = "System"
  # name_regex = "AdministratorAccess"
  name_regex = "Administrator"
}

# 创建超级管理员组
resource "alicloud_ram_group" "cloud_admin_group" {
  name     = "CloudAdminGroup"
  comments = "超级管理员组"
  force    = true
}

# 创建系统管理员组
resource "alicloud_ram_group" "system_admin_group" {
  name     = "SystemAdminGroup"
  comments = "系统管理员组"
  force    = true
}

# 创建财务组
resource "alicloud_ram_group" "billing_admin_group" {
  name     = "BillingAdminGroup"
  comments = "财务组"
  force    = true
}

# 创建普通用户组
resource "alicloud_ram_group" "common_user_group" {
  name     = "CommonUserGroup"
  comments = "普通用户组"
  force    = true
}



# 创建开发用户组
resource "alicloud_ram_group" "dev_group" {
  name     = "DevGroup"
  comments = "开发组"
  force    = true
}

# 创建DBA用户组
resource "alicloud_ram_group" "dba_group" {
  name     = "DBAGroup"
  comments = "DBA组"
  force    = true
}



# 创建运维权限策略
resource "alicloud_ram_policy" "system_admin_policy" {
  name        = "CustomSystemAdminAccess"
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
  description = "ops policy"
  force       = true
}



# 为超级管理员组授权
resource "alicloud_ram_group_policy_attachment" "cloud_admin_group_policy_attachment" {
  policy_name = "AdministratorAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.cloud_admin_group.name
}


# 为财务组授权AliyunBSSFullAccess
resource "alicloud_ram_group_policy_attachment" "bss_group_policy_attachment_AliyunBSSFullAccess" {
  policy_name = "AliyunBSSFullAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.billing_admin_group.name
}

# 为财务组授权AliyunFinanceConsoleFullAccess
resource "alicloud_ram_group_policy_attachment" "cloud_admin_group_policy_attachment_AliyunFinanceConsoleFullAccess" {
  policy_name = "AliyunFinanceConsoleFullAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.billing_admin_group.name
}

# 为运维用户组授权
resource "alicloud_ram_group_policy_attachment" "system_admin_group_policy_attachment" {
  policy_name = alicloud_ram_policy.system_admin_policy.name
  policy_type = alicloud_ram_policy.system_admin_policy.type
  group_name  = alicloud_ram_group.system_admin_group.name
}

# 为开发用户组授权
resource "alicloud_ram_group_policy_attachment" "dev_group_policy_attachment" {
  policy_name = "AliyunECSFullAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.dev_group.name
}

# 为DBA用户组授权
resource "alicloud_ram_group_policy_attachment" "dba_group_policy_attachment" {
  policy_name = "AliyunRDSFullAccess"
  policy_type = "System"
  group_name  = alicloud_ram_group.dba_group.name
}

# 创建用户: admin
resource "alicloud_ram_user" "user_admin" {
  name         = "admin"
  display_name = "管理员"
}

# admin 创建AK
resource "alicloud_ram_access_key" "admin_ak" {
  user_name   = alicloud_ram_user.user_admin.name
  secret_file = "./admin_ak.txt"
}

# 创建运维用户
resource "alicloud_ram_user" "user_ops_1" {
  name         = "ops_cheng"
  display_name = "程运维"
}
# 创建开发用户
resource "alicloud_ram_user" "user_dev_1" {
  name         = "dev_wang"
  display_name = "王开发"
}
# 创建DBA用户
resource "alicloud_ram_user" "user_dba_1" {
  name         = "dba_li"
  display_name = "李数据"
}

# 创建财务用户
resource "alicloud_ram_user" "user_bill_1" {
  name         = "bill_zhao"
  display_name = "赵管钱"
}

# 将admin加入超级管理员组
resource "alicloud_ram_group_membership" "membership_admin" {
  group_name = alicloud_ram_group.cloud_admin_group.name
  user_names = [alicloud_ram_user.user_admin.name]
}

# 将运维用户加入运维组
resource "alicloud_ram_group_membership" "membership_ops" {
  group_name = alicloud_ram_group.system_admin_group.name
  user_names = [alicloud_ram_user.user_ops_1.name]
}
# 将开发用户加入开发组
resource "alicloud_ram_group_membership" "membership_dev" {
  group_name = alicloud_ram_group.dev_group.name
  user_names = [alicloud_ram_user.user_dev_1.name]
}
# 将DBA用户加入DBA组
resource "alicloud_ram_group_membership" "membership_dba" {
  group_name = alicloud_ram_group.dba_group.name
  user_names = [alicloud_ram_user.user_dba_1.name]
}


# 将财务用户加入财务组
resource "alicloud_ram_group_membership" "membership_bill" {
  group_name = alicloud_ram_group.billing_admin_group.name
  user_names = [alicloud_ram_user.user_bill_1.name]
}
