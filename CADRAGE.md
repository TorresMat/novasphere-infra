# CADRAGE — Projet NovaSphere
> Fiche à faire valider par l'intervenant avant le premier plan. Les champs entre crochets doivent être complétés par l'équipe ; aucune identité ni validation n'est présumée.
## Équipe et référents
- Nom de l'équipe : [À compléter]
- Membres (3 à 4) : [Nom, prénom de chaque membre]
- Référent Git : [À compléter]
- Référent AWS : [À compléter]
- Dépôt principal : `novasphere-infra`
- Module de l'équipe : `RaiZing955/terraform-aws-web-sg`, tag `v2.0.0` [à publier et vérifier avant le premier init]
## Contexte métier (cinq lignes)
1. NovaSphere est une entreprise fictive qui édite une plateforme SaaS.
2. Elle met à disposition une page Web de statut et de présentation du service.
3. L'équipe infrastructure doit fournir un service Internet réparti sur deux zones et capable de remplacer automatiquement une instance défaillante.
4. Les environnements de développement et de production sont séparés afin qu'un changement de test n'affecte pas la production.
5. Les déploiements sont versionnés et réalisés par une chaîne GitHub Actions revue par l'équipe.
## Application et infrastructure
- Application servie : page web NGINX identifiant NovaSphere, l'environnement et le nom d'hôte ; elle signale uniquement que le secret applicatif a été lu, sans afficher sa valeur.
- Environnements : `dev` et `prod`, chacun avec son VPC et son state S3 distinct.
- Calcul : Launch Template et Auto Scaling Group (minimum 2 instances) répartis sur deux zones.
- Accès : ALB public HTTP ; les instances acceptent HTTP uniquement depuis le Security Group de l'ALB ; aucun SSH entrant.
- Secret : Parameter Store `SecureString`, alimenté par `value_wo` et lu par l'instance via son profil IAM.
- Région : `us-east-1` (AWS Academy Learner Lab, selon le cahier des charges).
## Extension unique proposée
**Tests du module Terraform de l'équipe.** Le dépôt `terraform-aws-web-sg` contient des tests `terraform test` et un workflow GitHub Actions qui les exécute. Cette extension ne crée aucune ressource AWS supplémentaire. À confirmer par l'intervenant et à démontrer avec un run réussi du workflow du module.
## Éléments écartés
- NAT Gateway : écartée conformément au cahier des charges pour limiter les coûts ; les instances sont dans des subnets publics, reçoivent une IP publique mais restent protégées par leur Security Group.
- SSH direct : interdit sur les instances ; le profil du Learner Lab est utilisé dans le lab.
- Workspaces Terraform : écartés pour dev/prod ; les répertoires et les clés S3 distinctes rendent la cible explicite.
- HTTPS/ACM, RDS et second service : non retenus afin de garder une seule extension et de prioriser le socle.
## Compte de démonstration
- Type : AWS Academy Learner Lab fourni par l'école [à confirmer]
- Région : `us-east-1`
- Profil d'instance en lab : `LabInstanceProfile` [à confirmer par un plan / la console AWS]
## Validation
- Validation de l'intervenant : [En attente]
- Date : [À compléter]
