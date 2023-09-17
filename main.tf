# Creating a Virtual Private Cloud (VPC) named "hashi_vpc"
resource "aws_vpc" "hashi_vpc" {
  cidr_block           = var.vpc_cidr # Change to your desired VPC CIDR block
  enable_dns_hostnames = true         # You can disable DNS hostnames if not needed
  enable_dns_support   = true         # You can disable DNS support if not needed

  tags = {
    Name = "dev" # Customize the VPC name/tag
  }
}

# Creating a private subnet within the VPC
resource "aws_subnet" "hashi_private_subnet" {
  vpc_id                  = aws_vpc.hashi_vpc.id
  cidr_block              = var.private_subnet_cidr # Change to your desired private subnet CIDR block
  map_public_ip_on_launch = false                   # Set to true if you want instances in this subnet to have public IPs
  availability_zone       = var.availability_zone_a # Change to your desired availability zone

  tags = {
    Name = "dev-private" # Customize the subnet name/tag
  }
}

# Creating a public subnet within the VPC
resource "aws_subnet" "hashi_public_subnet" {
  vpc_id                  = aws_vpc.hashi_vpc.id
  cidr_block              = var.public_subnet_cidr  # Change to your desired public subnet CIDR block
  map_public_ip_on_launch = true                    # Set to false if you don't want instances in this subnet to have public IPs
  availability_zone       = var.availability_zone_a # Change to your desired availability zone

  tags = {
    Name = "dev-public" # Customize the subnet name/tag
  }
}

# Creating another public subnet in a different availability zone
resource "aws_subnet" "hashi_public_subnet_2" {
  vpc_id                  = aws_vpc.hashi_vpc.id
  cidr_block              = var.public_subnet_2_cidr # Change to your desired public subnet CIDR block
  map_public_ip_on_launch = true                     # Set to false if you don't want instances in this subnet to have public IPs
  availability_zone       = var.availability_zone_b  # Change to your desired availability zone

  tags = {
    Name = "dev-public-2" # Customize the subnet name/tag
  }
}

# Associating the first public subnet with a route table
resource "aws_route_table_association" "hashi_public_subnet_assoc" {
  subnet_id      = aws_subnet.hashi_public_subnet.id
  route_table_id = aws_route_table.hashi_public_rt.id
}

# Associating the second public subnet with the same route table
resource "aws_route_table_association" "hashi_public_subnet_2_assoc" {
  subnet_id      = aws_subnet.hashi_public_subnet_2.id
  route_table_id = aws_route_table.hashi_public_rt.id
}

# Creating an internet gateway and attaching it to the VPC
resource "aws_internet_gateway" "hashi_internet_gateway" {
  vpc_id = aws_vpc.hashi_vpc.id

  tags = {
    Name = "dev-igw" # Customize the internet gateway name/tag
  }
}

# Creating a public route table for the VPC
resource "aws_route_table" "hashi_public_rt" {
  vpc_id = aws_vpc.hashi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hashi_internet_gateway.id
  }

  tags = {
    Name = "dev_public_rt" # Customize the route table name/tag
  }
}

# Allocating an Elastic IP for the NAT gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Creating a NAT gateway within the first public subnet
resource "aws_nat_gateway" "hashi_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.hashi_public_subnet.id

  tags = {
    Name = "dev-nat" # Customize the NAT gateway name/tag
  }
}

# Creating a private route table for the VPC
resource "aws_route_table" "hashi_private_rt" {
  vpc_id = aws_vpc.hashi_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hashi_nat_gateway.id
  }

  tags = {
    Name = "dev_private_rt" # Customize the route table name/tag
  }
}

# Associating the private subnet with the private route table
resource "aws_route_table_association" "hashi_private_assoc" {
  subnet_id      = aws_subnet.hashi_private_subnet.id
  route_table_id = aws_route_table.hashi_private_rt.id
}

# Creating a security group for the web server
resource "aws_security_group" "hashi_web_sg" {
  name        = "web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.hashi_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating a security group for the Application Load Balancer (ALB)
resource "aws_security_group" "hashi_alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.hashi_vpc.id

  # Allowing incoming traffic on port 80 and 443
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Permitting the ALB to forward traffic to the web server on port 80
resource "aws_security_group_rule" "allow_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.hashi_web_sg.id
  source_security_group_id = aws_security_group.hashi_alb_sg.id
}

# Permitting the ALB to forward traffic to the web server on port 443
resource "aws_security_group_rule" "allow_alb_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.hashi_web_sg.id
  source_security_group_id = aws_security_group.hashi_alb_sg.id
}

# Creating an AWS Key Pair for authentication
resource "aws_key_pair" "hashi_auth" {
  key_name   = "hashikey"
  public_key = file("~/.ssh/hashikey.pub") # Provide the path to your public key file
}

# Creating an IAM role for EC2 instances to use Amazon SSM
resource "aws_iam_role" "ssm_role" {
  name = "SSMRoleForEC2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attaching the SSM policy to the IAM role
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.ssm_role.name
}

# Creating an IAM instance profile for EC2 instances
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# Creating an EC2 instance for the web server
resource "aws_instance" "dev_node" {
  instance_type          = var.instance_type          # Change to your desired instance type
  ami                    = data.aws_ami.server_ami.id # Use the appropriate AMI ID
  key_name               = var.key_name               # Change to your SSH key name
  vpc_security_group_ids = [aws_security_group.hashi_web_sg.id]
  subnet_id              = aws_subnet.hashi_private_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
    <powershell>
    # Logging Function
    function Write-Log {
        param (
            [string]$Message,
            [string]$LogFilePath = "C:\terraform_web_setup.log"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $fullMessage = "$timestamp : $Message"
        
        Add-Content -Path $LogFilePath -Value $fullMessage
    }

    Write-Log "Starting the installation of Web-Server feature."
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Write-Log "Web-Server feature installation completed."

    # Professional-looking HTML content
    $htmlContent = @"
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Professional Web App</title>
        <style>
            body {
                margin: 0;
                padding: 0;
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                background-image: linear-gradient(to right, #2b5876, #4e4376);
                color: white;
            }
            h1 {
                font-size: 2.5em;
            }
            p {
                font-size: 1.2em;
            }
            .container {
                text-align: center;
                padding: 20px;
                background: rgba(0, 0, 0, 0.5);
                border-radius: 10px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to the Professional Web App on IIS</h1>
            <p>Deployed with excellence via Terraform.</p>
        </div>
    </body>
    </html>
    "@

    Write-Log "Generating the HTML content for the web app."
    
    # Write the content to the default IIS folder
    $htmlContent | Out-File -Encoding ASCII C:\inetpub\wwwroot\index.html
    Write-Log "HTML content written to C:\inetpub\wwwroot\index.html successfully."

    </powershell>
EOF

  tags = {
    Name = "dev-node" # Customize the instance name/tag
  }

  root_block_device {
    # volume_size = 8  # You can specify the root volume size if needed
  }
}

# Creating an Application Load Balancer (ALB)
resource "aws_lb" "web_alb" {
  name               = "dev-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.hashi_alb_sg.id]
  subnets            = [aws_subnet.hashi_public_subnet.id, aws_subnet.hashi_public_subnet_2.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
}

# Creating a target group for the ALB
resource "aws_lb_target_group" "web_tg" {
  name     = "dev-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.hashi_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attaching the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.dev_node.id
  port             = 80
}

# Creating a listener for the ALB to forward traffic to the target group
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Creating a bastion host for SSH access
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.server_ami.id # Change to a suitable Linux/Windows AMI ID
  instance_type = "t2.micro"                 # Change to your desired instance type
  subnet_id     = aws_subnet.hashi_public_subnet.id
  key_name      = aws_key_pair.hashi_auth.key_name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "BastionHost" # Customize the bastion host name/tag
  }
}

# Creating a security group for the bastion host
resource "aws_security_group" "bastion_sg" {
  name   = "BastionSG"
  vpc_id = aws_vpc.hashi_vpc.id

  ingress {
    from_port   = 22 # Use 3389 for Windows instances using RDP
    to_port     = 22 # Use 3389 for Windows instances using RDP
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict SSH access to a specific IP range for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BastionSG"
  }
}
