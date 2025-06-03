data "aws_availability_zones" "available" {}

resource "random_id" "random" {
    byte_length = 2
}

resource "aws_vpc" "jc_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "jc_vpc-${random_id.random.dec}"
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_internet_gateway" "jc_internet_gateway" {
    vpc_id = aws_vpc.jc_vpc.id

    tags = {
        Name = "jc_igw-${random_id.random.dec}"
    }
}

resource "aws_route_table" "jc_public_rt" {
    vpc_id = aws_vpc.jc_vpc.id

    tags = {
        Name = "jc-public"
    }
}

resource "aws_route" "default_route" {
    route_table_id = aws_route_table.jc_public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jc_internet_gateway.id

}

resource "aws_default_route_table" "jc_private_rt" {
    default_route_table_id = aws_vpc.jc_vpc.default_route_table_id
}

resource "aws_subnet" "jc_public_subnet" {
    count = 2
    vpc_id = aws_vpc.jc_vpc.id
    cidr_block = var.public_cidrs[count.index]
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name = "jc-public-${count.index + 1}"
    }
}