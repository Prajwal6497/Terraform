resource "aws_instance" "example" {
  ami           = "ami-0c94855ba95c71c99"  # Update with your desired AMI ID
  instance_type = "t2.micro"  # Update with your desired instance type

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, world! This is the bootstrap script."
    # Add any additional commands or configurations here
  EOF

  tags = {
    Name = "terraform-example"
  }
}
