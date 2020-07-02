#!/bin/bash

######################## 步骤一 [账号创建和初始化]######################

# 控制台操作

######################## 步骤二 [云账号安全加固]########################
AdminUserName=admin


# 创建用户: admin
aliyun ram CreateUser --UserName $AdminUserName --DisplayName 管理员

# 为admin授权
aliyun ram AttachPolicyToUser --PolicyName "AdministratorAccess" --PolicyType "System" --UserName $AdminUserName

# 为admin 创建AK,后面的操作可以用这把AK替换主账号的AK
aliyun ram CreateAccessKey --UserName $AdminUserName >> ./admin_ak.txt

# 将admin加入云管理员组
aliyun ram AddUserToGroup --GroupName $CloudAdminGroupName --UserName $AdminUserName

# 密码策略
aliyun ram SetPasswordPolicy --MinimumPasswordLength 8 --RequireLowercaseCharacters true --RequireUppercaseCharacters true --RequireNumbers true --RequireSymbols true --HardExpiry false --MaxPasswordAge 90 --PasswordReusePrevention 8 --MaxLoginAttemps 5

######################## 步骤三 [RAM配置]########################

SystemAdminAccessPolicyName=SystemAdministratorAccess
SystemAdminGroupName=SystemAdminGroup
BillingAdminGroupName=BillingAdminGroup
CommonUserGroupName=CommonUserGroup
CloudAdminGroupName=CloudAdminGroup

# 创建系统管理的权限策略
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
aliyun ram CreatePolicy --PolicyName $SystemAdminAccessPolicyName --Description "系统管理员权限" --PolicyDocument "$(cat ./system_admin_access_policy.txt)"

# 创建云管理员组
aliyun ram CreateGroup --GroupName $CloudAdminGroupName --Comments 云管理员组

# 为云管理员组授权
aliyun ram AttachPolicyToGroup --PolicyName "AdministratorAccess" --PolicyType "System" --GroupName $CloudAdminGroupName


# 创建系统管理员组
aliyun ram CreateGroup --GroupName $SystemAdminGroupName --Comments 系统管理员组

# 为系统管理员组授权
aliyun ram AttachPolicyToGroup --PolicyName $SystemAdminAccessPolicyName --PolicyType "Custom" --GroupName $SystemAdminGroupName

# 创建财务账单管理员组
aliyun ram CreateGroup --GroupName $BillingAdminGroupName --Comments 财务账单管理员组

# 为财务组授权AliyunBSSFullAccess
aliyun ram AttachPolicyToGroup --PolicyName "AliyunBSSFullAccess" --PolicyType "System" --GroupName $BillingAdminGroupName

# 为财务组授权AliyunFinanceConsoleFullAccess
aliyun ram AttachPolicyToGroup --PolicyName "AliyunFinanceConsoleFullAccess" --PolicyType "System" --GroupName $BillingAdminGroupName

# 创建普通用户组
aliyun ram CreateGroup --GroupName $CommonUserGroupName --Comments 普通用户组

######################## 步骤四 [网络配置]########################

Region="cn-hangzhou"
Zone="cn-hangzhou-h"

# 创建 VPC
VpcId=$(aliyun vpc CreateVpc --region $Region --VpcName "default_vpc" --CidrBlock "192.168.0.0/16" | jq -r '.VpcId')

# 等待 VPC 可用（----Terraform 已处理-----）
aliyun vpc DescribeVpcs --region $Region --VpcId $VpcId --waiter expr="Vpcs.Vpc[0].Status" to="Available"

# 创建交换机
VswId=$(aliyun vpc CreateVSwitch --region $Region --CidrBlock "192.168.0.0/24" --VpcId $VpcId --ZoneId $Zone --VSwitchName "default_vswitch" | jq -r '.VSwitchId')

# 创建安全组
SgId=$(aliyun ecs CreateSecurityGroup --region $Region --SecurityGroupName "default_sg" --VpcId $VpcId | jq -r '.SecurityGroupId')
