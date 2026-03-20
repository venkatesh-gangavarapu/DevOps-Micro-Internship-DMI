# ── ec2.tf ───────────────────────────────────────────────

resource "aws_instance" "web" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = [aws_subnet.web_1.id, aws_subnet.web_2.id][count.index]
  vpc_security_group_ids      = [aws_security_group.web_tier.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name
  user_data                   = file("${path.module}/user-data/web-tier.sh")
  tags = merge(var.tags, { Name = "bookreview-web-${count.index + 1}", Tier = "web" })
}

resource "aws_instance" "app" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = [aws_subnet.app_1.id, aws_subnet.app_2.id][count.index]
  vpc_security_group_ids      = [aws_security_group.app_tier.id]
  associate_public_ip_address = false  # Private — no public IP
  key_name                    = var.key_pair_name
  user_data                   = file("${path.module}/user-data/app-tier.sh")
  tags = merge(var.tags, { Name = "bookreview-app-${count.index + 1}", Tier = "app" })
}

resource "aws_lb_target_group_attachment" "web" {
  count            = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app" {
  count            = 2
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 3001
}
