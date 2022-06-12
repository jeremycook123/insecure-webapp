data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"]
}

#====================================

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  #userdata
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #! /bin/bash
    apt-get -y update
    apt-get -y install nginx
    apt-get -y install jq

    ALB_DNS=${var.alb_dns}
    POSTGRES_PRIVATEIP=${var.postgres_ip}
    
    mkdir -p /cloudacademy-app
    cd /cloudacademy-app

    echo ===========================
    echo FRONTEND - download latest release and install...
    mkdir -p ./frontend
    pushd ./frontend
    curl -sL https://api.github.com/repos/jeremycook123/owasp-example/releases/latest | jq -r '.assets[0].browser_download_url' | xargs curl -OL
    INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/jeremycook123/owasp-example/releases/latest | jq -r '.assets[0].name')
    tar -xvzf $INSTALL_FILENAME
    rm -rf /var/www/html
    cp -R build /var/www/html
    cat > /var/www/html/env-config.js << EOFF
    window._env_ = {REACT_APP_APIHOSTPORT: "$ALB_DNS"}
    EOFF
    popd

    echo ===========================
    echo API - download latest release, install, and start...
    mkdir -p ./api
    pushd ./api
    curl -sL https://api.github.com/repos/jeremycook123/owasp-example/releases/latest | jq -r '.assets[1].browser_download_url' | xargs curl -OL
    INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/jeremycook123/owasp-example/releases/latest | jq -r '.assets[1].name')
    tar -xvzf $INSTALL_FILENAME
    #start the API up...
    POSTGRES_USER=postgres POSTGRES_PASSWORD=cloudacademy POSTGRES_DB=cloudacademy POSTGRES_HOSTPORT=$POSTGRES_PRIVATEIP:5432java -jar webapp-insecure-1.0-SNAPSHOT.jar &
    java -jar webapp-insecure-1.0-SNAPSHOT.jar &
    popd

    systemctl restart nginx
    systemctl status nginx
    echo fin v1.00!

    EOF    
  }
}

#====================================

resource "aws_launch_template" "apptemplate" {
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.webserver_sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name  = "FrontendApp"
      Owner = "CloudAcademy"
    }
  }

  user_data = base64encode(data.template_cloudinit_config.config.rendered)
}

#====================================

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = var.subnets

  desired_capacity = var.asg_desired
  max_size         = var.asg_max_size
  min_size         = var.asg_min_size

  target_group_arns = var.target_group_arns

  launch_template {
    id      = aws_launch_template.apptemplate.id
    version = "$Latest"
  }
}
