region        = "eu-west-1"
prefix        = "cmtr-n9nbj5cz"
vpc_name      = "cmtr-n9nbj5cz-vpc"
subnet_names  = ["cmtr-n9nbj5cz-public-subnet1", "cmtr-n9nbj5cz-public-subnet2"]
sg_ssh_name   = "cmtr-n9nbj5cz-sg-ssh"
sg_http_name  = "cmtr-n9nbj5cz-sg-http"
sg_lb_name    = "cmtr-n9nbj5cz-sg-lb"
instance_type = "t3.micro"
tags          = { Project = "blue-green", ManagedBy = "terraform" }
blue_weight   = 100
green_weight  = 0