data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250530"]
  }
}

resource "random_id" "jc_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "jc_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "jc_main" {
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.jc_auth.key_name
  vpc_security_group_ids = [aws_security_group.jc_sg.id]
  subnet_id              = aws_subnet.jc_public_subnet[count.index].id
  #user_data              = templatefile("./main-userdata.tpl", { new_hostname = "jc-main-${random_id.jc_node_id[count.index].dec}" })
  root_block_device {
    volume_size = var.main_vol_size

  }
  tags = {
    Name = "jc-main-${random_id.jc_node_id[count.index].dec}"
  }

  provisioner "local-exec" {
   command = "echo ${self.public_ip} >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-2"
}
  provisioner "local-exec" {
    when = destroy 
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }
}

#resource "null_resource" "grafana_update" {
#  count = var.main_instance_count
#  provisioner "remote-exec" {
#    inline = ["sudo apt upgrade -y grafana && touch upgrade.log && echo 'I updated grafana' >> upgrade.log"]
#    connection {
#      type        = "ssh"
#      user        = "ubuntu"
#      private_key = file("jc-terransible")
#      host        = aws_instance.jc_main[count.index].public_ip
#    }
#  }
#
#}

#resource "null_resource" "main_ansible_install" {
#    depends_on = [aws_instance.jc_main]
#    provisioner "local-exec" {
#        command = "ansible-playbook -i aws_hosts playbooks/main_playbook.yml"
#    }
#}