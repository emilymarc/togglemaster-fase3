resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# A NAT Gateway -> static public IP
resource "aws_eip" "nat" {
  domain = "vpc"
}

# Lives in a PUBLIC subnet, but serves the PRIVATE ones
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat" }
}