#### Terraform Plan — aula-10 📖

| Etapa | Resultado |
|---|---|
| fmt | ✅ |
| init | ✅ |
| validate | ✅ |
| plan | ✅ |

<details open><summary>Saída do plan</summary>

```terraform
data.aws_ami.al2023: Reading...
data.aws_availability_zones.available: Reading...
aws_key_pair.deploy: Refreshing state... [id=technova-6322006-aula10-key]
aws_ecr_repository.technova_api: Refreshing state... [id=technova-api]
aws_vpc.main: Refreshing state... [id=vpc-0dd43956096c08227]
data.aws_availability_zones.available: Read complete after 1s [id=us-east-1]
aws_ecr_lifecycle_policy.technova_api: Refreshing state... [id=technova-api]
data.aws_ami.al2023: Read complete after 1s [id=ami-04b938437b69a2c9c]
aws_internet_gateway.main: Refreshing state... [id=igw-06e0ac20eb576d0ab]
aws_subnet.public: Refreshing state... [id=subnet-0fcf33ed90d8b1cf6]
aws_security_group.technova_api: Refreshing state... [id=sg-090c86d7ba5591cfc]
aws_route_table.public: Refreshing state... [id=rtb-05f4d3bcca7f79c51]
aws_route_table_association.public: Refreshing state... [id=rtbassoc-0b40b5270133dc132]
aws_instance.app: Refreshing state... [id=i-03dd65c9088f35605]
aws_eip.app: Refreshing state... [id=eipalloc-04e9ba3eb9f8a123a]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_security_group.technova_api will be updated in-place
  ~ resource "aws_security_group" "technova_api" {
        id                     = "sg-090c86d7ba5591cfc"
      ~ ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = "Allow HTTPS inbound"
              + from_port        = 443
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 443
            },
            # (2 unchanged elements hidden)
        ]
        name                   = "technova-6322006-aula10-api"
        tags                   = {
            "Name" = "technova-6322006-aula10-api-sg"
        }
        # (8 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"

```

</details>

*Disparado por @rafadical em `feat/aula-10-https-sg-rule` — o apply só roda após o merge na main.*
