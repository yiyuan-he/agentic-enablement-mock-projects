app_name           = "nodejs-express-ecs-terraform"
image_name         = "nodejs-express"
language           = "nodejs"
port               = 3000
app_directory      = "../../../sample-apps/nodejs/express"
health_check_path  = "/health"
service_name       = "nodejs-express-ecs-terraform"
