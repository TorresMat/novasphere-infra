# NovaSphere — Infrastructure as Code
## Description
Dépôt d'infrastructure de NovaSphere.
Provisioning via Terraform, configuration via Ansible.
## Stack
- **Provisioning** : Terraform (provider AWS)
- **Configuration** : Ansible
- **Cloud** : AWS (EC2, VPC, Security Groups)
- **Image Building** : Packer (AMI)
## Structure du dépôt
_À compléter au fil des séances._
## Auteur
- Nom : mat-terraform-ansible
- Date de création : 25/02/2026
## Structure du dépôt
- `docs/` — Documentation d'architecture
## Stack
<<<<<<< HEAD
- **Provisioning**: Terraform (provider AWS + Proxmox optionnel)
- **Configuration**: Ansible
- **Cloud**: AWS (EC2, VPC, Security Groups)
- **Image Building**: Packer (AMI)
- **CI/CD**: GitHub Actions (à venir)
=======
- **Provisioning**: Terraform 1.14+ (provider AWS)
- **Configuration**: Ansible 2.17+ (via pipx)
- **Cloud**: AWS (EC2, VPC, Security Groups, IAM)
- **Image Building**: Packer 1.11+ (AMI)
>>>>>>> feat/stack-update
