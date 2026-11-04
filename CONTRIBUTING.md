# CONTRIBUTING — NovaSphere
## Règles d'équipe
1. Une branche par changement : `feat/...`, `fix/...` ou `docs/...`.
2. Chaque modification passe par une Pull Request vers `main`.
3. Un autre membre relit le code et le plan Terraform avant le merge.
4. Aucun `terraform.tfstate`, `*.tfvars`, plan binaire, secret, credential ou clé privée n'est commité.
5. Le backend S3 partagé est obligatoire dès le premier `terraform init` ; aucun state local ne doit être utilisé au-delà de l'initialisation.
6. Les modules externes sont appelés par tag immuable. Un tag publié ne doit jamais être déplacé ni réutilisé.
7. `terraform fmt -check`, `terraform validate`, les plans dev/prod et le scan Checkov doivent être examinés avant le merge.
8. Le déploiement de dev est fait par GitHub Actions au merge ; prod exige l'approbation de l'environnement GitHub `production`.
9. Les credentials AWS Academy sont temporaires : ils sont renouvelés dans les secrets GitHub au début de chaque session.
10. À la fin de chaque session, détruire les environnements facturés à l'heure avec le script documenté ; ne jamais laisser un ALB ou un ASG actif sans raison.
11. Les commits sont réalisés depuis le poste de chaque membre sous sa propre identité Git.
12. Le tag `rendu-final` n'est posé qu'après validation des livrables, du scan, des plans et de la démonstration.
## Cycle de revue
`branche -> commit -> Pull Request -> plan commenté -> revue -> merge -> apply-dev -> approbation -> apply-prod`
