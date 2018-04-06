variable "num_of_private_agent_group_2" {
  description = "DC/OS Private Agents Count"
  default = 3
}

variable "aws_group_2_private_agent_az" {
  description = "AWS Default Zone"
  default     = "b"
}

# Create a subnet to launch slave private node into
resource "aws_subnet" "default_group_2_private" {
  
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${cidrsubnet("10.11.0.0/16", 6, 2)}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}${var.aws_group_2_private_agent_az}"
}


# Private agent instance deploy
resource "aws_instance" "agent_group_2" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "${module.aws-tested-oses.user}"

    # The connection will use the local SSH agent for authentication.
  }

  root_block_device {
    volume_size = "${var.aws_agent_instance_disk_size}"
  }

  count = "${var.num_of_private_agent_group_2}"
  instance_type = "${var.aws_agent_instance_type}"

  # ebs_optimized = "true" # Not supported for all configurations

  tags {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   Name =  "${data.template_file.cluster-name.rendered}-pvtagt-${count.index + 1}"
   cluster = "${data.template_file.cluster-name.rendered}"
  }
  # Lookup the correct AMI based on the region
  # we specified
  ami = "${module.aws-tested-oses.aws_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${var.ssh_key_name}"

  # Our Security group to allow http and SSH access
  vpc_security_group_ids = ["${var.aws_sg}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.default_group_2_private.id}"

  # OS init script
  provisioner "file" {
   content = "${module.aws-tested-oses.os-setup}"
   destination = "/tmp/os-setup.sh"
   }

 # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
    provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/os-setup.sh",
      "sudo bash /tmp/os-setup.sh",
    ]
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
  availability_zone       = "${var.aws_region}${var.aws_group_2_private_agent_az}"
}

# Execute generated script on agent
resource "null_resource" "agent_group_2" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_ec2_instance_id = "${aws_instance.agent_group_2.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(aws_instance.agent_group_2.*.public_ip, count.index)}"
    user = "${module.aws-tested-oses.user}"
  }

  count = "${var.num_of_private_agent_group_2}"

  # Generate and upload Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${aws_instance.bootstrap.private_ip}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  # Install Slave Node
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
  # Mesos poststart check workaround. Engineering JIRA filed to Mesosphere team to fix.  
  provisioner "remote-exec" {
    inline = [
     "sudo sed -i.bak '131 s/1s/5s/' /opt/mesosphere/packages/dcos-config--setup*/etc/dcos-diagnostics-runner-config.json",
     "sudo sed -i.bak '162 s/1s/5s/' /opt/mesosphere/packages/dcos-config--setup*/etc/dcos-diagnostics-runner-config.json"
    ]
  }
}
#output "Private Agent Public IP Address" {
#  value = ["${aws_instance.agent_group_2.*.public_ip}"]
#}
