# GitHub Actions vers AWS avec OIDC (compte AWS personnel)

Cette procédure concerne un compte AWS personnel. **Ne pas l'exécuter dans AWS Academy Learner Lab** si la création de rôles IAM est interdite. Dans le Learner Lab, le workflow utilise les trois credentials de session dans les secrets GitHub.

## 1. Fournisseur OIDC

Créer une fois dans le compte AWS le fournisseur d'identité :

- URL : `https://token.actions.githubusercontent.com`
- Audience : `sts.amazonaws.com`

AWS peut déjà avoir ce fournisseur si un autre dépôt l'utilise.

## 2. Politique de confiance du rôle CI

Créer un rôle IAM, par exemple `NovaSphereGitHubActions`, avec la politique de confiance suivante. Remplacer `<ACCOUNT_ID>` et `<GITHUB_OWNER>` ; le dépôt principal doit s'appeler `novasphere-infra` (adapter le sujet si le nom diffère).

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:<GITHUB_OWNER>/novasphere-infra:*"
      }
    }
  }]
}
```

Le motif restreint le rôle à un dépôt donné ; un motif plus strict peut séparer la branche `main`, les PR et le sujet d'environnement `production` en rôles distincts. Ne pas utiliser un sujet `*` ouvert à tous les dépôts.

## 3. Permissions du rôle

Attacher une politique de permissions construite pour ce projet et le bucket backend :

- lecture/écriture du state et du fichier `.tflock` uniquement dans le bucket d'équipe ; `s3:ListBucket` restreint au préfixe `novasphere/*`, `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` sur les clés state et lock ;
- actions de lecture `Describe*` nécessaires au provider AWS ;
- création, modification et suppression des VPC, subnets, routes, Internet Gateway et Security Groups du projet ;
- gestion des ALB, listeners, target groups, Launch Templates, instances et Auto Scaling Groups ;
- création, mise à jour et suppression du paramètre SSM sous `/novasphere/*` ;
- `iam:PassRole` uniquement sur le rôle EC2 `novasphere-*-ec2` ; opérations IAM nécessaires pour le rôle/profil EC2 hors Learner Lab.

Les opérations `Describe*` nécessitent souvent `Resource: "*"`, mais les actions d'écriture doivent être resserrées autant que possible par ARN, tags et préfixes. Ne pas attacher `AdministratorAccess` en configuration finale. Si le compte ne permet pas encore une politique assez restreinte, traiter cette étape comme un privilège temporaire et documenter sa réduction avant le rendu.

## 4. Configurer le dépôt GitHub

Dans **Settings > Secrets and variables > Actions > Variables**, ajouter :

- `AWS_ROLE_ARN` : ARN du rôle IAM créé ;
- `TEAM_OWNER` : trigramme de l'équipe ;
- `APP_SECRET_VERSION` : version entière du secret.

Ajouter `APP_SECRET` dans les secrets GitHub. Les workflows détectent `AWS_ROLE_ARN` : s'il est renseigné, ils utilisent OIDC et n'utilisent pas les clés AWS statiques.

## 5. Différence à expliquer en soutenance

- **Learner Lab** : credentials temporaires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, copiés dans les secrets du dépôt et renouvelés à chaque session. Le lab fournit `LabInstanceProfile` et peut interdire la création de rôles.
- **Compte personnel** : GitHub émet un jeton OIDC à chaque job ; AWS valide l'audience et le sujet, puis retourne des credentials STS temporaires pour le rôle IAM. Aucun secret de clé AWS n'est stocké dans GitHub.
