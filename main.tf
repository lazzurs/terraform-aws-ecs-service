#------------------------------------------------------------------------------
# Create the executor role
#------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_exec_role" {
  name               = join("", [var.service_name, "-exec"])
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_assume_role_policy.json
  tags = merge(
    {
      "Name" = join("", [var.service_name, "-exec"])
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "ecs_exec_role_policy" {
  name   = join("", [var.service_name, "-exec"])
  role   = aws_iam_role.ecs_exec_role.id
  policy = data.aws_iam_policy_document.ecs_exec_policy.json
}

data "aws_iam_policy_document" "ecs_exec_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = var.exec_iam_policies
    content {
      effect    = lookup(statement.value, "effect", null)
      actions   = lookup(statement.value, "actions", null)
      resources = lookup(statement.value, "resources", null)
    }
  }
}

data "aws_iam_policy_document" "ecs_exec_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

#------------------------------------------------------------------------------
# Create the task profile
#------------------------------------------------------------------------------
resource "aws_iam_role" "instance_role" {
  count              = var.deploy_with_tg ? 1 : 0
  name               = join("", [var.service_name, "-task"])
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy[0].json
  tags = merge(
    {
      "Name" = join("", [var.service_name, "-task"])
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "instance_role_policy" {
  count  = var.deploy_with_tg ? 1 : 0
  name   = join("", [var.service_name, "-task"])
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.role_policy[0].json
}

data "aws_iam_policy_document" "role_policy" {
  count = var.deploy_with_tg ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
    ]
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = var.task_iam_policies
    content {
      effect    = lookup(statement.value, "effect", null)
      actions   = lookup(statement.value, "actions", null)
      resources = lookup(statement.value, "resources", null)
    }
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  count = var.deploy_with_tg ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

#------------------------------------------------------------------------------
# Launch Docker Service
#------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = var.requires_compatibilities
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  network_mode             = var.network_mode
  task_role_arn            = var.task_iam_role
  memory                   = var.task_memory
  cpu                      = var.task_cpu
  container_definitions = jsonencode([
    {
      name              = var.service_name
      image             = var.image_name
      cpu               = var.container_cpu
      memory            = var.container_memory
      memoryReservation = var.container_memory_reservation
      essential         = var.essential
      privileged        = var.privileged
      command           = var.command
      mountPoints       = var.mount_points
      environment       = var.environment
      linuxParameters   = var.linux_parameters
      logConfiguration  = var.log_configuration
      portMappings      = var.port_mappings
      dnsSearchDomains  = var.dns_search_domains
      secrets           = var.secrets
      systemControls    = var.systemControls
      ulimits           = var.ulimits
    }
  ])

  dynamic "ephemeral_storage" {
    for_each = toset(var.ephemeral_storage_size_in_gib > 0 ? [var.ephemeral_storage_size_in_gib] : [])
    content {
      size_in_gib = ephemeral_storage.value
    }
  }

  dynamic "volume" {
    for_each = var.docker_volumes
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
          scope         = lookup(docker_volume_configuration.value, "scope", null)
        }
      }
    }
  }

  dynamic "volume" {
    for_each = var.efs_volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id          = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", [])
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }

    }
  }


  tags = merge(
    {
      "Name" = var.service_name
    },
    var.tags
  )
}

resource "aws_ecs_service" "main" {
  count           = var.deploy_with_tg ? 1 : 0
  name            = var.service_name
  task_definition = aws_ecs_task_definition.this.arn
  cluster         = var.ecs_cluster_id
  desired_count   = var.service_desired_count
  iam_role        = ""
  launch_type     = var.launch_type
  dynamic "network_configuration" {
    for_each = var.network_configuration
    content {
      subnets          = lookup(network_configuration.value, "subnets")
      security_groups  = lookup(network_configuration.value, "security_groups")
      assign_public_ip = lookup(network_configuration.value, "assign_public_ip")
    }
  }
  dynamic "load_balancer" {
    for_each = var.target_groups
    content {
      target_group_arn = lookup(load_balancer.value, "target_group_arn")
      container_name   = var.service_name
      container_port   = lookup(load_balancer.value, "port")
    }
  }
}

resource "aws_ecs_service" "main-no-lb" {
  count           = var.deploy_with_tg ? 0 : 1
  name            = var.service_name
  task_definition = aws_ecs_task_definition.this.arn
  cluster         = var.ecs_cluster_id
  desired_count   = var.service_desired_count
  iam_role        = var.service_iam_role
  launch_type     = var.launch_type
  dynamic "network_configuration" {
    for_each = var.network_configuration
    content {
      subnets          = lookup(network_configuration.value, "subnets")
      security_groups  = lookup(network_configuration.value, "security_groups")
      assign_public_ip = lookup(network_configuration.value, "assign_public_ip")
    }
  }
}
