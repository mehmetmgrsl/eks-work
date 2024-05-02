variable "managed_node_group" {
  type = object({
    min_size     = number
    max_size     = number 
    desired_size = number

    instance_types = list(string)
    capacity_type  = string
  })

  default = {
    min_size     = 1
    max_size     = 3
    desired_size = 1

    instance_types = ["t2.small", "t3.small"]
    capacity_type  = "ON_DEMAND"
  }
}