# ── alb.tf ───────────────────────────────────────────────

resource "aws_lb" "public" {
  name               = "bookreview-public-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.web_1.id, aws_subnet.web_2.id]
  security_groups    = [aws_security_group.public_alb.id]
  tags = merge(var.tags, { Name = "bookreview-public-alb" })
}

resource "aws_lb_target_group" "web" {
  name     = "bookreview-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/"; healthy_threshold = 2 }
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.web.arn }
}

resource "aws_lb" "internal" {
  name               = "bookreview-internal-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.app_1.id, aws_subnet.app_2.id]
  security_groups    = [aws_security_group.internal_alb.id]
  tags = merge(var.tags, { Name = "bookreview-internal-alb" })
}

resource "aws_lb_target_group" "app" {
  name     = "bookreview-app-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/health"; healthy_threshold = 2 }
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 3001
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.app.arn }
}
