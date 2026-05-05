output "SSM_role_name" {
  value = aws_iam_role.ssmrole.name

}
output "sg-outs" {
  value = {
    for k, sg in aws_security_group.security_groups :
    k => sg.id
  }
}