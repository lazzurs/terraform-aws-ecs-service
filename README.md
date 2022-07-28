# terraform-module-ecs-service
Terraform module for creating an ECS service.

## Deploying a service with a Load Balancer
```hcl
module "task_with_alb" {
  source  = "lazzurs/ecs-service/aws"
  version = "0.4.0"
  ecs_cluster_id = "arn:aws:ecs:us-east-1:888888888888:cluster/ecs-0"
  image_name = "nginx:latest"
  service_name = "my-web-server"
  tld = "austincloud.guru"
  service_memory = 2048
  mount_points = [
    {
      sourceVolume  = "nginx_content"
      containerPath = "/usr/share/nginx/html"
      readOnly      = false
    }
  ]
  volumes = [
    {
      host_path = "/efs/nginx_content"
      name      = "nginx_content"
      docker_volume_configuration = []
    }
  ]
  service_desired_count = 2
  port_mappings = [
    {
      containerPort = 80
      hostPort = 8080
      protocol = "tcp"
    }
  ]
  target_groups = [
    {
      hostPort = 8080
      target_group_arn = "arn:aws:elasticloadbalancing:us-east-2:888888888888:targetgroup/my-web-server/b8fbca622c86d2dd"
    }
  ]
  deploy_with_tg = true
}

```

## Deploying a service wihtout a Load Balancer
```hcl
module "task_without_alb" {
  source  = "lazzurs/ecs-service/aws"
  version = "0.4.0"  
  ecs_cluster_id                = "arn:aws:ecs:us-east-1:888888888888:cluster/ecs-0"
  service_name                  = "datadog_agent"
  image_name                    = "datadog/agent:latest"
  service_cpu                   = 10
  service_memory                = 256
  essential                     = true
  mount_points                  = [
        {
          containerPath = "/var/run/docker.sock"
          sourceVolume = "docker_sock"
          readOnly = true
        },
        {
          containerPath = "/host/sys/fs/cgroup"
          sourceVolume = "cgroup"
          readOnly = true
        },
        {
          containerPath = "/host/proc"
          sourceVolume = "proc"
          readOnly = true
        }
  ]
  environment                   = [
        {
          name = "DD_API_KEY"
          value = "55555555555555555555555555555555"
        },
        {
          name = "DD_SITE"
          value = "datadoghq.com"
        }
  ]
  volumes                       =  [
    {
      host_path = "/var/run/docker.sock"
      name      = "docker_sock"
      docker_volume_configuration = []
    },
    {
      host_path = "/proc/"
      name      = "proc"
      docker_volume_configuration = []
    },
    {
      host_path = "/sys/fs/cgroup/"
      name      = "cgroup"
      docker_volume_configuration = []
    }
  ]
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 2.45 |

## Providers

| Name | Version |
|------|---------|
| aws | 4.20.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.main-no-lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.ecs_exec_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_exec_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.instance_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.ecs_exec_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_exec_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| command | The command that is passed to the container | `list(string)` | `[]` | no |
| container\_cpu | CPU Units to Allocate for the ECS task container. | `number` | `128` | no |
| container\_memory | Memory to Allocate (hard limit) for the ECS task container. | `number` | `0` | no |
| container\_memory\_reservation | Memory to Allocate (soft limit) for the ECS task container. https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#ContainerDefinition-memoryReservation | `number` | `1024` | no |
| deploy\_with\_tg | Deploy the service group attached to a target group | `bool` | `false` | no |
| dns\_search\_domains | List of DNS domains to search when a lookup happens | `list(string)` | `null` | no |
| docker\_volumes | Task volume definitions as list of configuration objects | ```list(object({ host_path = string name = string docker_volume_configuration = list(object({ autoprovision = bool driver = string driver_opts = map(string) labels = map(string) scope = string })) }))``` | `[]` | no |
| ecs\_cluster\_id | ID of the ECS cluster | `string` | n/a | yes |
| efs\_volumes | Task volume definitions as a list of configuration objects | ```list(object({ name = string efs_volume_configuration = list(object({ file_system_id = string root_directory = string transit_encryption = string transit_encryption_port = number authorization_config = list(object({ access_point_id = string iam = string })) })) }))``` | `[]` | no |
| environment | Environmental Variables to pass to the container | ```list(object({ name = string value = string }))``` | `null` | no |
| ephemeral\_storage\_size\_in\_gib | (Optional) The amount of ephemeral storage to allocate for the task. This parameter is used to expand the total amount of ephemeral storage available, beyond the default amount, for tasks hosted on AWS Fargate. The total amount, in GiB, of ephemeral storage to set for the task. The minimum supported value is 21 GiB and the maximum supported value is 200 GiB. [See Ephemeral Storage.](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-storage.html) | `number` | `0` | no |
| essential | Whether the task is essential | `bool` | `true` | no |
| exec\_iam\_policies | Additional IAM policies for the execution role | ```list(object({ effect = string actions = list(string) resources = list(string) }))``` | `[]` | no |
| image\_name | Name of the image to be deployed | `string` | n/a | yes |
| launch\_type | (Optional) Launch type on which to run your service. The valid values are ```EC2``` , ```FARGATE``` , and ```EXTERNAL``` . Defaults to ```EC2``` . | `string` | `"EC2"` | no |
| linux\_parameters | Additional Linux Parameters | ```object({ capabilities = object({ add = list(string) drop = list(string) }) })``` | `null` | no |
| log\_configuration | Log configuration options to send to a custom log driver for the container. | ```object({ logDriver = string options = map(string) secretOptions = list(object({ name = string valueFrom = string })) })``` | `null` | no |
| mount\_points | Mount points for the container | ```list(object({ containerPath = string sourceVolume = string readOnly = bool }))``` | `[]` | no |
| network\_configuration | Network configuration to be used with awsvpc networking type | ```list(object({ subnets = list(string) security_groups = list(string) assign_public_ip = bool }))``` | `[]` | no |
| network\_mode | The Network Mode to run the container at | `string` | `"bridge"` | no |
| port\_mappings | Port mappings for the docker Container | ```list(object({ hostPort = number containerPort = number protocol = string }))``` | `[]` | no |
| privileged | Whether the task is privileged | `bool` | `false` | no |
| requires\_compatibilities | (Optional) Set of launch types required by the task. The valid values are ```EC2``` and ```FARGATE``` | `list(string)` | ```[ "EC2" ]``` | no |
| secrets | List of secrets to add | ```list(object({ name = string valueFrom = string }))``` | `[]` | no |
| service\_desired\_count | Desired Number of Instances to run | `number` | `1` | no |
| service\_iam\_role | ARN for a Service IAM role note: You cannot specify an IAM role for services that require a service linked role. | `string` | `""` | no |
| service\_name | Name of the service being deployed | `string` | n/a | yes |
| systemControls | A list of namespaced kernel parameters to set in the container. | ```list(object({ namespace = string value = string }))``` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| target\_groups | Target group port mappings for the docker container | ```list(object({ port = number target_group_arn = string }))``` | `[]` | no |
| task\_cpu | CPU Units to Allocation for service | `number` | `128` | no |
| task\_iam\_policies | Additional IAM policies for the task | ```list(object({ effect = string actions = list(string) resources = list(string) }))``` | `[]` | no |
| task\_iam\_role | ARN for a task IAM role | `string` | `""` | no |
| task\_memory | Memory to Allocate for service | `number` | `1024` | no |
| tld | Top Level Domain to use | `string` | `""` | no |
| ulimits | A list of ulimits settings for container. This is a list of maps, where each map should contain "name", "hardLimit" and "softLimit" | ```list(object({ name = string hardLimit = number softLimit = number }))``` | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors
Module is forked from a module by [Mark Honomichl](https://github.com/austincloudguru).
Maintained by Rob Lazzurs

## License
MIT Licensed.  See LICENSE for full details
