# Module Security Group de l'équipe — publication v2.0.0

Le dépôt principal consomme le module Git de l'équipe :

```hcl
source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v2.0.0"
```

## Pourquoi v2 est nécessaire

La version publique actuellement visible en `main` utilise `source_security_group_id` (singulier) et un bloc `dynamic` dont la condition dépend de la présence de cet identifiant. Dans notre architecture, l'ID du Security Group ALB est créé dans le même plan Terraform que le Security Group Web ; cet ID est donc inconnu au moment de planifier. La v2 locale remplace cette interface par `source_security_group_ids` (liste) et crée les règles de source avec `count`, dont la cardinalité est connue avant la création des IDs. Elle utilise également les ressources dédiées AWS provider v6 et `aws_vpc_security_group_rules_exclusive`.

La version v2 est disponible dans l'archive de module `terraform-aws-web-sg-v2.0.0.zip` préparée séparément. **Elle n'est pas encore publiée sur le dépôt GitHub public vérifié** : le tag `v2.0.0` doit être poussé avant le premier `terraform init` du dépôt principal.

## Publier le module (une seule fois)

1. Décompresser `terraform-aws-web-sg-v2.0.0.zip`.
2. Dans le dépôt `terraform-aws-web-sg`, remplacer les fichiers à la racine par le contenu du dossier `terraform-aws-web-sg/` (ne pas commiter `.terraform/` ni des états).
3. Créer une branche, ouvrir une PR, faire passer le workflow du module et merger sur `main`.
4. Depuis le dépôt du module, créer le tag immuable et le pousser :

```bash
git checkout main
git pull --ff-only
git tag v2.0.0
git push origin v2.0.0
```

5. Vérifier que `https://github.com/RaiZing955/terraform-aws-web-sg/tree/v2.0.0` affiche `main.tf`, `variables.tf`, `outputs.tf` et `tests/security_group.tftest.hcl`.

Ne jamais déplacer ni réutiliser un tag publié. Le workflow principal clone ce tag v2.0.0 et exécute `terraform test` sans credentials AWS.

## Interface utilisée par NovaSphere

- `sg_alb` : `allowed_cidrs = ["0.0.0.0/0"]`, port 80, egress 80.
- `sg_web` : `allowed_cidrs = []`, `source_security_group_ids = [module.sg_alb.security_group_id]`, port 80, egress 80 et 443.

La validation de la v2 exige exactement une source d'entrée : CIDR IPv4 ou liste de Security Groups. La validation refuse SSH (22), RDP (3389), les CIDR invalides et les sources contradictoires. Le test du module est lancé dans le job `module-tests` du workflow principal.
