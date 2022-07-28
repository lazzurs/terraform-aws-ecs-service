#------------------------------------------------------------------------------
# Variables for ECS Service Module
#------------------------------------------------------------------------------
variable "service_name" {
  description = "Name of the service being deployed"
  type        = string
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "service_desired_count" {
  description = "Desired Number of Instances to run"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "task_iam_policies" {
  description = "Additional IAM policies for the task"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "exec_iam_policies" {
  description = "Additional IAM policies for the execution role"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}


variable "image_name" {
  description = "Name of the image to be deployed"
  type        = string
}

variable "task_cpu" {
  description = "CPU Units to Allocation for service"
  type        = number
  default     = 128
}

variable "task_memory" {
  description = "Memory to Allocate for service"
  type        = number
  default     = 1024
}

variable "container_cpu" {
  description = "CPU Units to Allocate for the ECS task container."
  type        = number
  default     = 128
}

variable "container_memory" {
  description = "Memory to Allocate (hard limit) for the ECS task container."
  type        = number
  default     = 0
}

variable "container_memory_reservation" {
  description = <<-EOT
    Memory to Allocate (soft limit) for the ECS task container.
    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#ContainerDefinition-memoryReservation
  EOT
  type        = number
  default     = 1024
}

variable "essential" {
  description = "Whether the task is essential"
  type        = bool
  default     = true
}

variable "privileged" {
  description = "Whether the task is privileged"
  type        = bool
  default     = false
}

variable "command" {
  description = "The command that is passed to the container"
  type        = list(string)
  default     = []
}

variable "port_mappings" {
  description = "Port mappings for the docker Container"
  type = list(object({
    hostPort      = number
    containerPort = number
    protocol      = string
  }))
  default = []
}

variable "target_groups" {
  description = "Target group port mappings for the docker container"
  type = list(object({
    port             = number
    target_group_arn = string
  }))
  default = []
}

variable "mount_points" {
  description = "Mount points for the container"
  type = list(object({
    containerPath = string
    sourceVolume  = string
    readOnly      = bool
  }))
  default = []
}

variable "environment" {
  description = "Environmental Variables to pass to the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = null
}

variable "linux_parameters" {
  description = "Additional Linux Parameters"
  type = object({
    capabilities = object({
      add  = list(string)
      drop = list(string)
    })
  })
  default = null
}

variable "network_mode" {
  description = "The Network Mode to run the container at"
  type        = string
  default     = "bridge"
}

variable "docker_volumes" {
  description = "Task volume definitions as list of configuration objects"
  type = list(object({
    host_path = string
    name      = string
    docker_volume_configuration = list(object({
      autoprovision = bool
      driver        = string
      driver_opts   = map(string)
      labels        = map(string)
      scope         = string
    }))
  }))
  default = []
}

variable "efs_volumes" {
  description = "Task volume definitions as a list of configuration objects"
  type = list(object({
    name = string
    efs_volume_configuration = list(object({
      file_system_id          = string
      root_directory          = string
      transit_encryption      = string
      transit_encryption_port = number
      authorization_config = list(object({
        access_point_id = string
        iam             = string
      }))
    }))
  }))
  default = []
}

variable "tld" {
  description = "Top Level Domain to use"
  type        = string
  default     = ""
}

variable "log_configuration" {
  description = "Log configuration options to send to a custom log driver for the container."
  type = object({
    logDriver = string
    options   = map(string)
    secretOptions = list(object({
      name      = string
      valueFrom = string
    }))
  })
  default = null
}

variable "network_configuration" {
  description = "Network configuration to be used with awsvpc networking type"
  type = list(object({
    subnets          = list(string)
    security_groups  = list(string)
    assign_public_ip = bool
  }))
  default = []
}

variable "deploy_with_tg" {
  description = "Deploy the service group attached to a target group"
  type        = bool
  default     = false
}

variable "dns_search_domains" {
  description = "List of DNS domains to search when a lookup happens"
  type        = list(string)
  default     = null
}

variable "secrets" {
  description = "List of secrets to add"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "systemControls" {
  description = "A list of namespaced kernel parameters to set in the container. "
  type = list(object({
    namespace = string
    value     = string
  }))
  default = []
}

variable "ulimits" {
  description = "A list of ulimits settings for container. This is a list of maps, where each map should contain \"name\", \"hardLimit\" and \"softLimit\""
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  default = null
}

variable "task_iam_role" {
  description = "ARN for a task IAM role"
  type        = string
  default     = ""
}

variable "service_iam_role" {
  description = <<-EOT
        ARN for a Service IAM role
        note: You cannot specify an IAM role for services that require a service linked role.
  EOT
  type        = string
  default     = ""
}

variable "ephemeral_storage_size_in_gib" {
  description = <<-EOT
        (Optional) The amount of ephemeral storage to allocate for the task.
        This parameter is used to expand the total amount of ephemeral storage available,
        beyond the default amount, for tasks hosted on AWS Fargate.
        The total amount, in GiB, of ephemeral storage to set for the task.
        The minimum supported value is 21 GiB and the maximum supported value is 200 GiB.
        [See Ephemeral Storage.](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-storage.html)
  EOT
  type        = number
  default     = 0
}

variable "requires_compatibilities" {
  description = <<-EOT
  (Optional) Set of launch types required by the task. The valid values are ```EC2``` and ```FARGATE```
  EOT
  type        = list(string)
  default     = ["EC2"]

}
variable "launch_type" {
  description = <<-EOT
    (Optional) Launch type on which to run your service.
    The valid values are ```EC2```, ```FARGATE```, and ```EXTERNAL```.
    Defaults to ```EC2```.
  EOT
  type        = string
  default     = "EC2"

}