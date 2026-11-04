# ARCHITECTURE — NovaSphere
## Schéma logique
```text
                         Internet
                            |
                   +-------------------+
                   | Application LB    |
                   | public, TCP/80     |
                   +-------------------+
                            |
                 Target Group HTTP :80 / /
                            |
             +--------------+--------------+
             |                             |
       +-----------+                 +-----------+
       | EC2 zone A|                 | EC2 zone B|
       | ASG >= 2  |                 | ASG        |
       +-----------+                 +-----------+
             \\                           //
              \--- Security Group web ---/
                Ingress TCP/80 depuis SG ALB
                Aucun port SSH entrant
    VPC /dev : 10.10.0.0/16       VPC /prod : 10.20.0.0/16
    2 subnets publics             2 subnets publics
    Internet Gateway              Internet Gateway
    Aucun NAT Gateway             Aucun NAT Gateway
    EC2 -> instance profile -> ssm:GetParameter -> SSM SecureString
    GitHub Actions -> PR plan/commentaire -> merge -> apply dev
                                            -> plan prod / artefact -> approbation
                                            -> apply du même plan prod
```
## Décisions et alternatives
1. **Deux répertoires et deux states** : `envs/dev` et `envs/prod`, chacun avec une clé S3 dédiée et le verrouillage natif `use_lockfile = true`. Workspaces écartés car le workspace actif serait un état implicite du terminal.
2. **VPC public multi-AZ sans NAT** : le module public `terraform-aws-modules/vpc/aws` gère la brique réseau. Les instances obtiennent une IP publique pour télécharger NGINX et AWS CLI ; leur Security Group n'accepte que TCP/80 depuis le Security Group de l'ALB. Pas de NAT Gateway, pour respecter le budget et la contrainte du cours.
3. **Security Groups dans un module Git de l'équipe** : `terraform-aws-web-sg` est appelé par tag immuable `v2.0.0` ; ce tag doit être publié à partir de l'archive v2 avant le premier `terraform init`. Le groupe ALB expose TCP/80 au public ; le groupe des instances référence celui de l'ALB.
4. **Launch Template + ASG** : les instances sont décrites par un Launch Template et maintenues à deux minimum ; `health_check_type = "ELB"` permet à l'ASG de remplacer une instance déclarée malsaine par l'ALB.
5. **Bootstrap court** : le script de démarrage comporte au plus dix lignes de commandes ; il installe NGINX/AWS CLI, lit le paramètre SSM puis génère la page identifiant l'environnement. Aucun secret n'est interpolé dans `user_data`.
6. **Secret write-only** : `aws_ssm_parameter.value_wo` reçoit une variable d'entrée éphémère ; la valeur ne doit pas apparaître dans le state ou le plan. L'instance reçoit le nom du paramètre, jamais sa valeur.
7. **IAM** : sur Learner Lab, lecture du profil préexistant `LabInstanceProfile` (aucune création de rôle dans ce contexte). Hors lab, le module crée un rôle et un profil avec `ssm:GetParameter` limité à l'ARN du paramètre de l'environnement.
8. **CI/CD** : PR = fmt, validate, plan commenté et scan ; merge main = plan sauvegardé puis apply de dev ; un plan prod est produit après dev, transmis comme artefact court, puis appliqué sans recalcul après approbation de l'environnement GitHub `production` ; workflow dispatch / schedule = plan de dérive.
9. **Extension unique** : tests `terraform test` du module de Security Group déjà séparé, exécutés par le workflow du dépôt de module. HTTPS, RDS, Session Manager et Ansible au démarrage ne sont pas retenus comme autres extensions.
## Héritage du starter Bac+4
- Conservés fonctionnellement : nommage/tag `NovaSphere`, région `us-east-1`, page d'accueil NGINX identifiant l'environnement, rôle Ansible web et ses templates comme exemple pédagogique.
- Remplacés : ressource unique `aws_instance.web`, clé SSH, règle SSH ouverte depuis l'IP du poste, inventaire créé par `local_file`, ainsi que les scripts start/stop d'une instance unique. Ces éléments ne sont pas adaptés à un ASG derrière ALB sans SSH.
- Le rôle Ansible d'origine est conservé sous `examples/starter-ansible/` à titre de référence ; il n'est pas exécuté dans le chemin de déploiement final.
