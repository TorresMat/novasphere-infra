# NovaSphere — infrastructure AWS Terraform multi-environnements
Projet fil rouge du Master SRC : infrastructure Web NovaSphere en `dev` et `prod`, provisionnée par Terraform et déployée par GitHub Actions. Le dépôt part du starter Bac+4 `novasphere-infra` (EC2 Debian + NGINX + Ansible) et le fait évoluer vers l'architecture imposée par le cahier des charges Bac+5.
> **Attention coûts AWS :** chaque environnement crée un ALB et au moins deux instances EC2. Ne lancez pas `apply` pour tester sans lire le plan et sans prévoir `scripts/destroy-env.sh`. Le bucket S3 de state est conservé ; le reste doit être détruit à la fin des sessions.
## 1. Architecture cible
- Deux environnements : `envs/dev` et `envs/prod`, deux clés de state S3.
- Un VPC par environnement, deux zones de disponibilité, deux subnets publics, aucune NAT Gateway.
- Un ALB HTTP (80), un target group avec health check `/`, un Launch Template et un ASG (`min=2`, `desired=2`, `max=4`, `health_check_type=ELB`).
- Le Security Group des instances accepte le port 80 uniquement depuis celui de l'ALB ; aucune règle SSH.
- IMDSv2 obligatoire.
- Une valeur applicative `SecureString` par environnement dans Parameter Store ; Terraform la transmet avec `value_wo`, puis l'instance la lit au démarrage via son profil IAM.
- Le module Security Group de l'équipe est appelé depuis le dépôt Git `terraform-aws-web-sg` par tag `v2.0.0`.
- GitHub Actions : plan commenté en PR, apply dev à partir d'un fichier de plan sauvegardé au merge, prod protégée par approbation, job de détection de dérive.
## 1 bis. Publier le dépôt principal sur GitHub
Le ZIP contient les fichiers du projet, pas le répertoire Git ni l'historique du starter. Créer un **nouveau dépôt principal vide** sur GitHub (par exemple `novasphere-infra`, sans README généré), puis depuis le dossier décompressé :
```bash
git init -b main
git config user.name "Votre nom GitHub"
git config user.email "votre-email-git@example.com"
git add .
git status
git commit -m "Initialisation du projet NovaSphere Terraform"
git remote add origin <URL_HTTPS_DU_DEPOT_PRINCIPAL>
git push -u origin main
```
Chaque membre doit ensuite commiter depuis son propre compte GitHub. Le dépôt du module `terraform-aws-web-sg` reste séparé ; publier d'abord sa version `v2.0.0` comme expliqué dans `docs/MODULE-SECURITY-GROUP.md`.

## 2. Prérequis
- Terraform >= 1.14 ; provider AWS 6.x.
- AWS CLI v2 et credentials valides pour le contexte de l'école.
- Git >= 2.30 ; compte GitHub.
- Checkov pour le scan local ; Python 3 pour l'installer.
- Accès au dépôt public `RaiZing955/terraform-aws-web-sg` avec le tag `v2.0.0` publié (voir `docs/MODULE-SECURITY-GROUP.md`).
- Accès AWS Academy Learner Lab (région imposée `us-east-1`).
- Les fichiers `envs/dev/.terraform.lock.hcl` et `envs/prod/.terraform.lock.hcl` fixent le provider AWS pour rendre les plans reproductibles.
Vérifier :
```bash
git --version
terraform version
aws --version
aws sts get-caller-identity
```
**Prérequis impératif pour Terraform :** publier d’abord la v2.0.0 du module Security Group sur GitHub. Le dépôt public consulté au moment de la préparation exposait encore l’interface v1 ; le projet principal est volontairement épinglé sur la v2 locale, qui corrige le plan avec un ID de Security Group inconnu. Suivre `docs/MODULE-SECURITY-GROUP.md` avant le premier `terraform init`.

## 3. Credentials AWS locaux
Ne collez jamais de credentials dans un fichier du dépôt. Pour le Learner Lab, copiez les credentials de session AWS Academy dans le terminal ou le fichier `~/.aws/credentials` protégé ; la session comporte `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` **et** `AWS_SESSION_TOKEN`.
Exemple avec variables d'environnement dans le terminal (remplacer les valeurs par les credentials temporaires du lab, sans les commiter) :
```bash
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_SESSION_TOKEN='...'
export AWS_DEFAULT_REGION='us-east-1'
aws sts get-caller-identity
```
Ces credentials expirent. Les renouveler au début de chaque session et dans les secrets GitHub avant la soutenance.
## 4. Initialiser le backend S3 partagé (une seule fois par équipe)
Le bucket doit exister avant `terraform init`. Le script utilise AWS CLI, active le versioning, le chiffrement et le blocage de l'accès public, puis renseigne le même bucket dans les deux backends.
```bash
chmod +x scripts/*.sh
./scripts/bootstrap-state.sh novasphere-tfstate-abc-123456789012
```
Le nom S3 doit être mondialement unique, en minuscules, sans espace. Exemple de forme : `novasphere-tfstate-abc-123456789012`.
Contrôler :
```bash
aws s3api get-bucket-versioning --bucket novasphere-tfstate-<trigramme>-<account-id>
aws s3api get-bucket-encryption --bucket novasphere-tfstate-<trigramme>-<account-id>
grep -R -E 'bucket|key|use_lockfile' envs/*/backend.tf
```
Le résultat doit montrer `Status=Enabled`, le chiffrement AES256 (ou meilleur) et `use_lockfile = true`. Les clés sont différentes : `novasphere/dev/terraform.tfstate` et `novasphere/prod/terraform.tfstate`.
## 5. Configurer les paramètres non secrets
```bash
cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
cp envs/prod/terraform.tfvars.example envs/prod/terraform.tfvars
```
Dans les deux fichiers, remplacer `owner = "abc"` par le trigramme de l'équipe (trois lettres minuscules). Les CIDR VPC diffèrent déjà : `10.10.0.0/16` en dev et `10.20.0.0/16` en prod. Les fichiers `terraform.tfvars` ne sont jamais commités.
Le secret ne va **pas** dans les tfvars. Le fournir dans l'environnement du shell :
```bash
read -rsp 'Secret applicatif NovaSphere: ' TF_VAR_app_secret; echo
export TF_VAR_app_secret
export TF_VAR_owner='abc'
export TF_VAR_app_secret_version='1'
```
Le secret doit être une valeur non vide et suffisamment longue (16 caractères minimum dans la validation). `value_wo` est write-only ; la variable est éphémère. Ne faites pas `set -x`, ne l'affichez pas et fermez le terminal après usage. Ne passez pas le secret comme argument CLI.
Pour utiliser le profil Learner Lab (par défaut) : `use_lab_instance_profile = true` et `lab_instance_profile_name = "LabInstanceProfile"`. Le profil doit autoriser `ssm:GetParameter` sur le paramètre de l'environnement. Sur un compte personnel, mettre `use_lab_instance_profile = false` : Terraform créera un rôle et un profil avec une permission restreinte à l'ARN du paramètre.
## 6. Vérification locale avant CI
Le déploiement de référence doit passer par GitHub Actions ; les commandes locales servent au formatage, à la validation et au diagnostic. Ne lancez pas un apply local pour contourner la chaîne du projet.
```bash
terraform fmt -recursive
terraform fmt -check -recursive
terraform -chdir=envs/dev init -input=false
terraform -chdir=envs/dev validate
terraform -chdir=envs/dev plan
terraform -chdir=envs/prod init -input=false
terraform -chdir=envs/prod validate
terraform -chdir=envs/prod plan
```
Le plan attendu doit afficher notamment deux VPC isolés (si les environnements n'existent pas), deux subnets publics par VPC, un ALB, un target group, un listener, un Launch Template, un ASG, les groupes de sécurité, le profil (ou le profil Lab existant) et le paramètre SSM. Aucun port 22 ne doit être ouvert. Le secret ne doit pas être visible dans le plan.
## 7. Configurer GitHub Actions
Dans **Settings > Secrets and variables > Actions**, créer :
### Repository variables
- `TEAM_OWNER` : trigramme en trois minuscules.
- `APP_SECRET_VERSION` : nombre (`1` au premier déploiement ; incrémenter pour renouveler le paramètre).
- `AWS_ROLE_ARN` : uniquement sur compte personnel configuré en OIDC ; laisser absent dans Learner Lab.
- `USE_LAB_INSTANCE_PROFILE` : `true` pour AWS Academy Learner Lab (défaut) ; `false` pour un compte personnel qui crée son propre rôle et profil IAM.
- `LAB_INSTANCE_PROFILE_NAME` : optionnel ; `LabInstanceProfile` par défaut.
- `ENABLE_PROD_APPLY` : valeur `true` **uniquement après** avoir créé l'environnement GitHub `production` et configuré ses approbateurs requis. Sans cette variable, le job de plan prod peut s'exécuter mais aucun apply prod n'est lancé (garde-fou).
- `DRIFT_CHECK_ENABLED` : valeur `true` pour activer le contrôle planifié les nuits où les environnements sont censés être déployés. Laisser absent ou `false` quand les ressources ont été détruites ; `workflow_dispatch` reste disponible manuellement.
### Repository secrets (Learner Lab)
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `APP_SECRET`
Les credentials AWS Academy sont temporaires et doivent être remis à jour à chaque session. Sur compte AWS personnel, configurer `AWS_ROLE_ARN` et le trust OIDC GitHub selon `docs/OIDC.md` ; les workflows n'utilisent alors pas les trois secrets de clés AWS.
Dans **Settings > Environments**, créer l'environnement `production`, ajouter un ou plusieurs reviewers requis et interdire l'auto-approbation. Le nom doit correspondre à `environment: production` dans le workflow.
### Chaîne attendue
1. Ouvrir une PR : workflow `terraform-pr.yml` exécute `fmt`, `validate`, plan dev/prod et ajoute les plans dans un commentaire ; Checkov est exécuté et son rapport est conservé comme artefact.
2. Faire relire et merger la PR sur `main`.
3. `terraform-apply.yml` calcule un plan dev sauvegardé (`tfplan`) puis applique **ce même fichier** avec `terraform apply tfplan`.
4. Après le déploiement dev, un job prépare et affiche un plan prod, puis le transmet comme artefact à durée de vie d'un jour. Le job `apply-prod`, protégé par l'environnement GitHub `production`, attend l'approbation et applique exactement ce fichier de plan. Le job reste désactivé tant que `ENABLE_PROD_APPLY=true` n'a pas été ajouté après configuration des approbateurs.
5. `workflow_dispatch` permet de déclencher la vérification de dérive à la demande. Le déclenchement planifié est configuré, mais ne s'exécute que si `DRIFT_CHECK_ENABLED=true` (à activer quand l'infrastructure reste volontairement en service pendant la nuit).
6. Le job `module-tests` clone le tag du module de l’équipe et exécute `terraform test` sans credentials AWS.
La première exécution GitHub Actions ne sera opérationnelle qu'après création du bucket, modification des backends, configuration des variables/secrets et accès au module Git.
## 8. Vérifier l'application
Après un apply-dev réussi, récupérer `alb_dns_name` dans les outputs du job / du dossier `envs/dev` puis tester :
```bash
curl -i http://<alb_dns_name>/
```
Attendu : code HTTP 200, page contenant `NovaSphere - dev`, le nom d'hôte et `Secret Parameter Store : lu au démarrage`. La valeur réelle du secret n'est jamais affichée. Répéter avec l'ALB de prod après approbation : `NovaSphere - prod`.
## 9. Détruire les ressources facturées
En fin de session, détruire dev et prod, chacun depuis son répertoire / state dédié :
```bash
./scripts/destroy-env.sh dev
./scripts/destroy-env.sh prod
```
Le script demande une confirmation explicite et applique un fichier de plan de destruction sauvegardé. Il ne supprime pas le bucket backend S3 ; celui-ci doit être conservé pour les sessions suivantes. Ne supprimez le bucket qu'après export/archivage du state et accord explicite de toute l'équipe.
## 10. Livrables avant gel
- `README.md`, `ARCHITECTURE.md`, `SECURITE.md`, `CONTRIBUTING.md`, `CADRAGE.md`, `RESTE_A_FAIRE.md` complétés.
- Deux environnements isolés et un plan vide sur le dépôt gelé (après déploiement puis état conforme).
- Scan Checkov réellement exécuté, résultats et remédiations documentés.
- Démonstration PR → plan commenté → merge → apply dev → page ALB avec secret lu depuis SSM → approbation prod.
- Tag `rendu-final` créé par l'équipe avant la date confirmée par l'intervenant.
## 11. Arborescence
```text
novasphere-infra/
├── .github/workflows/       # PR, apply dev/prod et drift
├── envs/dev/                # backend + variables + appel du module commun
├── envs/prod/               # même code, backend/state et valeurs séparés
├── modules/nova-web-stack/  # VPC, ALB, ASG, IAM, SSM, bootstrap
├── scripts/                 # bootstrap S3, scan, destroy sécurisé
├── examples/starter-ansible/# rôle Ansible fourni dans le starter, conservé en référence
├── .gitignore
└── livrables Markdown
```
