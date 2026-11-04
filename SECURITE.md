# SECURITE — NovaSphere
## 1. Secrets et cycle de vie
| Élément | Emplacement | Règle |
|---|---|---|
| `APP_SECRET` | Secret GitHub `APP_SECRET` ou variable d'environnement locale `TF_VAR_app_secret` | Jamais dans Git, `tfvars`, user-data, output ou logs |
| Paramètre applicatif | AWS Systems Manager Parameter Store, type `SecureString`, chemin `/novasphere/<env>/<owner>/app-secret` | Valeur écrite avec `value_wo` et `value_wo_version` ; jamais relue par Terraform |
| Credentials AWS Learner Lab | Secrets GitHub `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` et variables d'environnement locales | Credentials de session temporaires, à renouveler à chaque session |
| Credentials hors lab | OIDC GitHub Actions via `AWS_ROLE_ARN` | Pas de clé AWS permanente stockée dans GitHub |
| Clé privée SSH du starter | N'est plus utilisée par l'architecture cible | Le Security Group des instances n'ouvre pas TCP/22 |
`app_secret` est déclaré comme variable `sensitive` et `ephemeral`, puis transmis uniquement à l'argument write-only `value_wo`. L'argument `value_wo_version` déclenche les mises à jour sans enregistrer la valeur. La valeur du paramètre est lue par l'instance via son instance profile au démarrage. La page Web ne révèle que l'état de lecture (`lu au démarrage`), jamais la valeur du secret.
## 2. Politique IAM de l'instance
Dans un compte AWS personnel, le projet crée un rôle EC2 et un profil avec une politique minimale :
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["ssm:GetParameter"],
    "Resource": "arn:aws:ssm:us-east-1:<ACCOUNT_ID>:parameter/novasphere/<ENV>/<OWNER>/app-secret"
  }]
}
```
Le rôle ne reçoit pas `ssm:*`, `ssm:GetParametersByPath` global ni `AdministratorAccess`. Si une clé KMS gérée par le client remplace la clé AWS `alias/aws/ssm`, ajouter uniquement `kms:Decrypt` sur cette clé et vérifier la politique KMS.
Dans AWS Academy Learner Lab, le nom `LabInstanceProfile` est directement fourni au Launch Template (sans tenter de créer ou de modifier le profil) car la création de rôles IAM peut être interdite. L'équipe doit vérifier que le profil préexistant autorise `ssm:GetParameter` sur le paramètre. Si ce droit manque et que le lab interdit de modifier le rôle, le démontrer et demander le profil adapté à l'intervenant ; ne pas contourner en plaçant le secret dans user-data.
## 3. Réseau et instance
- ALB : seul point d'entrée public, TCP/80 pour le socle HTTP du cours.
- Instances : ingress TCP/80 uniquement depuis le Security Group de l'ALB ; aucun ingress SSH/22 ni RDP/3389.
- Sortie instance : TCP/80 et TCP/443 nécessaires à l'installation et à l'appel SSM ; pas de règle egress `-1` dans le module de Security Group.
- IMDSv2 obligatoire : `http_tokens = "required"`.
- Subnets publics sans NAT Gateway, selon le cahier des charges ; l'IP publique n'autorise pas un accès entrant si le Security Group le bloque.
- Le state bucket S3 est chiffré, versionné et bloqué en accès public. Terraform crée un fichier de verrouillage natif `.tflock` via `use_lockfile = true`.
## 4. Hygiène du dépôt
Le `.gitignore` exclut les states, plans, `*.tfvars`, `.env`, inventaires et clés privées. Avant publication :
```bash
git grep -n -I -E 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|password[[:space:]]*=[[:space:]]*"[^$]' -- ':!*.md' || true
find . -type f \( -name '*.tfstate*' -o -name '*.tfvars' -o -name '*.pem' -o -name '*.tfplan' \) -not -name '*.example' -print
```
Ne pas publier les résultats bruts d'un `terraform state pull` ou d'un plan contenant des informations sensibles.
## 5. Scan Checkov
Commande locale :
```bash
python3 -m pip install --user checkov
checkov --directory . --framework terraform --output cli
```
Le workflow `terraform-pr.yml` exécute le scan sur le dépôt principal et sur le dépôt du module Security Group versionné (après publication du tag `v2.0.0`) ; il conserve les deux résultats dans l’artefact `checkov-report`. **Le scan n'a pas été exécuté dans l'environnement de génération du ZIP** : aucun résultat fictif n'est inscrit ici. Après le premier run CI, recopier dans le tableau les contrôles réellement remontés, leur sévérité, le traitement et le lien vers le run.
| ID Checkov | Sévérité | Résultat du run | Décision / correction / justification | Lien du run |
|---|---|---|---|---|
| [À compléter] | [À compléter] | [PASS/FAIL/SKIP] | [À compléter] | [À compléter] |
Les points d'architecture imposés (ALB public, subnets publics, absence de NAT) doivent être documentés s'ils déclenchent un contrôle ; ne pas masquer globalement des contrôles pour obtenir un résultat vert.

## Bilan du scan Checkov — 04/11/2026

### Résultats

| Périmètre | Passed | Failed | Skipped |
|---|---:|---:|---:|
| Stack NovaSphere | 43 | 13 | 0 |
| Module Security Group isolé | 13 | 1 | 0 |

### Anomalies et décisions

| Contrôle | Constat | Décision |
|---|---|---|
| CKV_TF_1 | Sources de modules référencées par versions/tag | Tags versionnés conservés conformément au cahier des charges. |
| CKV_AWS_394 | Availability Zones découvertes dynamiquement | Comportement conservé pour la portabilité régionale ; à surveiller. |
| CKV_AWS_337 | SecureString utilisant la clé KMS gérée par AWS | Accepté pour ce projet pédagogique ; CMK dédiée recommandée en production. |
| CKV_AWS_150 | Protection contre suppression ALB désactivée | Choix lié aux destructions Terraform de l'environnement de test. |
| CKV_AWS_91 | Journaux d'accès ALB désactivés | Fonctionnalité non activée dans le périmètre actuel ; à activer en production. |
| CKV_AWS_2 / 103 / 378 / 2_20 | Listener et Target Group en HTTP, HTTPS absent | Limitation connue du prototype. Certificat TLS, listener HTTPS et redirection nécessaires avant exposition en production. |
| CKV2_AWS_28 | WAF absent | Non déployé dans le périmètre actuel ; recommandé pour une exposition publique en production. |
| CKV2_AWS_5 | Attachement des Security Groups non reconnu par le scan isolé | Vérifier les associations dans le contexte de déploiement ; ne pas considérer le contrôle comme corrigé sur la seule base du scan isolé. |

### Conclusion

Le scan identifie des améliorations de sécurité encore nécessaires.
Les résultats ne signifient pas que l'ensemble des contrôles sont conformes.
Les choix liés au périmètre pédagogique sont documentés et les protections
HTTPS, WAF, journalisation et KMS dédiée restent des améliorations recommandées
avant une exploitation réelle en production.
