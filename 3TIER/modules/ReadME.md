Terraform Resource Creation Patterns – Learning Progression

When working with Terraform, we often face situations where multiple resources need to be created. During development of infrastructure, we typically go through the following learning stages.

1. Initial Approach – Repeated Resource Blocks

At the beginning, the most straightforward way is to create each resource separately.

Example: Creating two subnets.

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "stationary-app-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "stationary-app-private-b"
  }
}
Problem with this approach

Code duplication

Hard to maintain

Scaling becomes difficult when more subnets are required

Example:

public subnet a
public subnet b
app subnet a
app subnet b
db subnet a
db subnet b

This leads to many repeated resource blocks.

2. Improvement – Using count

Terraform provides the count meta-argument to create multiple resources from a single block.

Example:

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
  }
}
What Terraform creates
aws_subnet.private[0]
aws_subnet.private[1]
Advantages

Removes duplicate resource blocks

Shorter code

Easy for identical resources

Limitation

All resources created with count share the same configuration pattern.

If we want to modify only one specific subnet, it becomes difficult.

Example scenario:

subnet A → needs special tag
subnet B → different CIDR or configuration

With count, handling such differences becomes messy.

3. Better Approach – Using for_each with locals

To allow different configurations per resource, Terraform provides for_each.

Instead of relying on index numbers, we define a map of configurations.

Step 1 – Define subnet configurations in locals
locals {
  private_subnets = {
    subnet_a = {
      cidr = "10.0.11.0/24"
      az   = data.aws_availability_zones.available.names[0]
      name = "private-a"
    }

    subnet_b = {
      cidr = "10.0.12.0/24"
      az   = data.aws_availability_zones.available.names[1]
      name = "private-b"
    }
  }
}

Here each subnet has its own:

CIDR block

Availability Zone

Name

Step 2 – Create resources using for_each
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-${each.value.name}"
  }
}
Resulting Terraform resources
aws_subnet.private["subnet_a"]
aws_subnet.private["subnet_b"]

Each subnet now has independent configuration.

4. Comparison of Approaches
Approach	When to Use	Limitation
Repeated resources	Very small setups	Code duplication
count	Identical resources	Hard to customize individual resources
for_each	Resources with different properties	Slightly more setup
5. Key Learning Summary

The progression typically looks like this:

1️⃣ Start with manual repeated resources
2️⃣ Improve with count to reduce duplication
3️⃣ Realize limitations of count when resources need customization
4️⃣ Move to for_each with locals for flexible configuration

Final Insight

A good Terraform design often follows this principle:

count   → identical resources
for_each → resources with individual configurations

Using locals with for_each allows us to define infrastructure cleanly, flexibly, and maintainably.