module "api" {
  source     = "./modules/api"
  project_id = var.project_id
}

module "networking" {
  source     = "./modules/networking"
  pubIP      = var.pubIP
  depends_on = [module.api]
}

module "compute" {
  source         = "./modules/compute"
  depends_on     = [module.networking]
  sshKey         = var.sshKey
  serviceAccount = var.serviceAccount
  subnetwork_id  = module.networking.splunk_subnet_id
}