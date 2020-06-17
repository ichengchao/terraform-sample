#!/bin/bash

# ============= 创建用户组 ==================

CloudAdminGroupName=CloudAdminGroup
SystemAdminGroupName=SystemAdminGroup
BillingAdminGroupName=BillingAdminGroup
CommonUserGroupName=CommonUserGroup
DevGroupName=DevGroup
DBAGroupName=DBAGroup

# 创建超级管理员组
aliyun ram CreateGroup --GroupName $CloudAdminGroupName --Comments 超级管理员组

# 创建系统管理员组
aliyun ram CreateGroup --GroupName $SystemAdminGroupName --Comments 系统管理员组

# 创建财务组
aliyun ram CreateGroup --GroupName $BillingAdminGroupName --Comments 财务组

# 创建普通用户组
aliyun ram CreateGroup --GroupName $CommonUserGroupName --Comments 普通用户组

# 创建开发用户组
aliyun ram CreateGroup --GroupName $DevGroupName --Comments 开发组

# 创建DBA用户组
aliyun ram CreateGroup --GroupName $DBAGroupName --Comments DBA组

# ============= 为用户组授权 ==================

SystemAdminAccessPolicyName=CustomSystemAdminAccess

# 创建运维权限策略
cat <<EOF > ./system_admin_access_policy.txt
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
aliyun ram CreatePolicy --PolicyName $SystemAdminAccessPolicyName --Description "ops policy" --PolicyDocument "$(cat ./system_admin_access_policy.txt)"

# 为超级管理员组授权
aliyun ram AttachPolicyToGroup --PolicyName "AdministratorAccess" --PolicyType "System" --GroupName $CloudAdminGroupName

# 为财务组授权AliyunBSSFullAccess
aliyun ram AttachPolicyToGroup --PolicyName "AliyunBSSFullAccess" --PolicyType "System" --GroupName $BillingAdminGroupName

# 为财务组授权AliyunFinanceConsoleFullAccess
aliyun ram AttachPolicyToGroup --PolicyName "AliyunFinanceConsoleFullAccess" --PolicyType "System" --GroupName $BillingAdminGroupName

# 为运维用户组授权
aliyun ram AttachPolicyToGroup --PolicyName $SystemAdminAccessPolicyName --PolicyType "Custom" --GroupName $SystemAdminGroupName

# 为开发用户组授权
aliyun ram AttachPolicyToGroup --PolicyName "AliyunECSFullAccess" --PolicyType "System" --GroupName $DevGroupName

# 为DBA用户组授权
aliyun ram AttachPolicyToGroup --PolicyName "AliyunRDSFullAccess" --PolicyType "System" --GroupName $DBAGroupName

# ============= 创建用户 ==================

AdminUserName=admin
OpsUserName=ops_cheng
DevUserName=dev_wang
DBAUserName=dba_li
BillUserName=bill_zhao

# 创建用户: admin
aliyun ram CreateUser --UserName $AdminUserName --DisplayName 管理员

# admin 创建AK
aliyun ram CreateAccessKey --UserName $AdminUserName >> ./admin_ak.txt

# 创建运维用户
aliyun ram CreateUser --UserName $OpsUserName --DisplayName 程运维

# 创建开发用户
aliyun ram CreateUser --UserName $DevUserName --DisplayName 王开发

# 创建DBA用户
aliyun ram CreateUser --UserName $DBAUserName --DisplayName 李数据

# 创建财务用户
aliyun ram CreateUser --UserName $BillUserName --DisplayName 赵管钱

# 将admin加入超级管理员组
aliyun ram AddUserToGroup --GroupName $CloudAdminGroupName --UserName $AdminUserName

# 将运维用户加入运维组
aliyun ram AddUserToGroup --GroupName $SystemAdminGroupName --UserName $OpsUserName

# 将开发用户加入开发组
aliyun ram AddUserToGroup --GroupName $DevGroupName --UserName $DevUserName

# 将DBA用户加入DBA组
aliyun ram AddUserToGroup --GroupName $DBAGroupName --UserName $DBAUserName

# 将财务用户加入财务组
aliyun ram AddUserToGroup --GroupName $BillingAdminGroupName --UserName $BillUserName
