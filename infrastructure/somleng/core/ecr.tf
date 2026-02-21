# =============================================================================
# ECR Repositories
# All images are built from source (vendored upstream + patches) and pushed here.
# No external registry dependencies at runtime.
# =============================================================================

locals {
  ecr_repos = [
    "somleng",        # Somleng API (built from source with patches)
    "switch",         # Switch app (built from source with patches)
    "freeswitch",     # FreeSWITCH media gateway
    "rating-engine",  # CGRates rating engine
  ]
}

resource "aws_ecr_repository" "images" {
  for_each             = toset(local.ecr_repos)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy: keep last 10 images, expire untagged after 1 day
resource "aws_ecr_lifecycle_policy" "images" {
  for_each   = toset(local.ecr_repos)
  repository = aws_ecr_repository.images[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest", "main", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
