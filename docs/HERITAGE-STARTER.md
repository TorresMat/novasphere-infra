# Évolution depuis `novasphere-infra-starter`
Le starter est bien le point de départ du dépôt. La base Bac+4 provisionnait une seule EC2 Debian accessible en SSH, puis générait `ansible/inventory.ini` avec `local_file` et la configurait avec le rôle Ansible `web`.
Pour respecter le cahier des charges Bac+5, le chemin de déploiement a été refactoré :
- `owner`, les tags `NovaSphere`, la région `us-east-1` et le contenu de la page d'accueil restent dans le projet ;
- le template de page / rôle NGINX d'origine est conservé sous `examples/starter-ansible/` comme référence de l'étape prérequis ;
- l'EC2 unique est remplacée par un Launch Template + ASG (minimum deux instances) derrière un ALB multi-AZ ;
- le Security Group SSH de l'ancien starter est supprimé ; le Security Group Web n'accepte que le port 80 depuis le SG ALB ;
- l'inventaire SSH et la ressource `local_file` sont abandonnés, puisqu'il n'existe plus d'accès SSH direct aux instances ;
- les scripts start/stop d'une instance unique sont remplacés par un script de destruction ciblée d'un environnement, car un ASG recrée automatiquement une instance arrêtée ;
- le bootstrap NGINX est court et lit le paramètre SSM via le profil IAM.
Le rôle Ansible du starter n'est pas branché dans l'ASG final : `ansible-pull` / SSM Run Command aurait constitué une extension supplémentaire. Le projet retient une seule extension, les tests du module Security Group.
