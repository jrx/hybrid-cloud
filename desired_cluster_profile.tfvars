dcos_version = "1.11.0"
expiration = "6h"
num_of_masters = "1"
aws_region = "us-east-1"
aws_master_instance_type = "m4.xlarge"
aws_agent_instance_type = "m4.xlarge"
aws_public_agent_instance_type = "m4.xlarge"
aws_private_agent_instance_type = "m4.xlarge"
aws_bootstrap_instance_type = "m4.xlarge"
# ---- Private Agents Zone / Instance
aws_group_1_private_agent_az = "a"
aws_group_2_private_agent_az = "b"
aws_group_3_private_agent_az = "c"
num_of_private_agent_group_1 = "10"
num_of_private_agent_group_2 = "7"
num_of_private_agent_group_3 = "5"
# ---- Public Agents Zone / Instance
aws_group_1_public_agent_az = "a"
aws_group_2_public_agent_az = "b"
aws_group_3_public_agent_az = "c"
num_of_public_agent_group_1 = "0"
num_of_public_agent_group_2 = "0"
num_of_public_agent_group_3 = "1"
# ----- Remote Region Below
aws_remote_region = "us-west-2"
aws_group_1_remote_agent_az = "a"
aws_group_2_remote_agent_az = "b"
aws_group_3_remote_agent_az = "c"
num_of_remote_private_agents_group_1 = "0"
num_of_remote_private_agents_group_2 = "0"
num_of_remote_private_agents_group_3 = "0"
dcos_resolvers = ["8.8.8.8", "8.8.4.4"]
dcos_security = "permissive"
dcos_license_key_contents = "<ADD_LICENSE_HERE>"
