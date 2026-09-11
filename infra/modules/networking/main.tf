resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true   # EKS requirement
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ── Public subnets: 10.0.1.0/24, 10.0.2.0/24 
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24" # index starts at 0, so...index+1
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    # EKS reads this tag to know where to put load balancers
    "kubernetes.io/role/elb" = "1"
  }
}

# ── Private subnets: 10.0.10.0/24, 10.0.11.0/24 
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1" # indicates where to connect internal lb to k8
  }
}