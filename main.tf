# 这里使用的AK和region都是从profile里面来的
provider "alicloud" {
  profile = "default"
}

data "alicloud_ram_policies" "policies_ds" {
  type = "System"
  # name_regex = "AdministratorAccess"
  name_regex = "Administrator"
}

# 创建用户: admin
resource "alicloud_ram_user" "user_admin" {
  name         = "admin"
  display_name = "管理员"
}

# admin 授权
resource "alicloud_ram_user_policy_attachment" "user_admin_administratorAccess" {
  policy_name = "AdministratorAccess"
  policy_type = "System"
  user_name   = alicloud_ram_user.user_admin.name
}

# admin 创建AK
resource "alicloud_ram_access_key" "admin_ak" {
  user_name   = alicloud_ram_user.user_admin.name
  secret_file = "./admin_ak.txt"
}

# 创建运维用户组
resource "alicloud_ram_group" "ops_group" {
  name     = "ops_group"
  comments = "运维组"
  force    = true
}

# 创建开发用户组
resource "alicloud_ram_group" "dev_group" {
  name     = "dev_group"
  comments = "开发组"
  force    = true
}

# 创建DBA用户组
resource "alicloud_ram_group" "dba_group" {
  name     = "dba_group"
  comments = "DBA组"
  force    = true
}

# 创建运维权限策略
resource "alicloud_ram_policy" "ops_policy" {
  name        = "CustomOpsAccess"
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

# 为运维用户组授权
resource "alicloud_ram_group_policy_attachment" "ops_group_policy_attachment" {
  policy_name = alicloud_ram_policy.ops_policy.name
  policy_type = alicloud_ram_policy.ops_policy.type
  group_name  = alicloud_ram_group.ops_group.name
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

# 将运维用户加入运维组
resource "alicloud_ram_group_membership" "membership_ops" {
  group_name = alicloud_ram_group.ops_group.name
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

# 定义一个输出,方便调试
output "test" {
  value = alicloud_ram_group.ops_group
}
