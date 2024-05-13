variable "lambda_ingestion_target" {
  default = "vgangann-ingestion-lambda-target-fluwehdw32876423"
}

variable "lambda_ingestion_target_runtime_env" {
  default = "python3.9"
}

variable "event_bridge_ingestion" {
  default = "vgangann-ingestion-event-bridge-tewgfj323wbfw"
}

variable "source_bucket"{
  default = "vgangann-source-bucket-fewo342"
}

variable "landing_bucket"{
  default = "vgangann-landing-bucket-fewo342"
}