# ১. Application Load Balancer
resource "aws_lb" "main_alb" {
  name               = "${var.project_name}-alb"
  internal           = false 
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets 

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ২. Target Group 
resource "aws_lb_target_group" "fastapi_tg" {
  name        = "${var.project_name}-tg"
  port        = 8000         
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"  
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ৩. Listener 
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"     
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastapi_tg.arn
  }
}