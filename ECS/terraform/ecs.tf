resource "aws_ecs_cluster" "main" {
  name = "ecs-lab-cluster"
}

resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-lab-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-lab-tasks-sg"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "ecs-lab-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        { name = "WORDPRESS_DB_HOST", value = "127.0.0.1" },
        { name = "WORDPRESS_DB_USER", value = "wordpress" },
        { name = "WORDPRESS_DB_PASSWORD", value = "wordpress123" },
        { name = "WORDPRESS_DB_NAME", value = "wordpress" }
      ]
    },
    {
      name      = "mysql"
      image     = "mysql:5.7"
      essential = true
      environment = [
        { name = "MYSQL_ROOT_PASSWORD", value = "wordpress123" },
        { name = "MYSQL_DATABASE", value = "wordpress" },
        { name = "MYSQL_USER", value = "wordpress" },
        { name = "MYSQL_PASSWORD", value = "wordpress123" }
      ]
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "ecs-lab-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.front_end]
}
