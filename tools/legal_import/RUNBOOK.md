# RUNBOOK — Import du corpus juridique burkinabè & OHADA

Objectif : faire passer la bibliothèque de JurisIA d'un **catalogue de
référence** (métadonnées exactes + lien vers la source officielle, ~34
textes) à un **corpus consultable article par article** dans l'application.

L'app lit le corpus depuis Supabase (`legal_documents` / `legal_articles`,
créées par `server/supabase/migration_010_legal_corpus.sql`), avec le
catalogue local (`lib/features/library/data/datasources/legal_document_local_datasource.dart`)
comme repli hors-ligne. **Le serveur fait autorité** : un texte poussé ici
remplace sa fiche locale dans l'app.

---

## 0. Pré-requis (une seule fois)

```bash
# a) créer les tables
#    Supabase Studio → SQL Editor → coller migration_010_legal_corpus.sql → Run

# b) installer les dépendances de l'outil
cd tools/legal_import
dart pub get

# c) exporter les identifiants Supabase (clé service_role, PAS la clé anon)
export SUPABASE_URL="https://<projet>.supabase.co"
export SUPABASE_SERVICE_KEY="<clé service_role>"
```

Commandes disponibles :

| Commande | Rôle |
|---|---|
| `dart run legal_import fetch <source> <url> -o doc.json --set k=v` | récupère + normalise un texte HTML |
| `dart run legal_import parse fichier.txt -o doc.json --set k=v` | découpe un texte déjà extrait (PDF → txt) |
| `dart run legal_import validate <doc.json \| dossier>` | contrôles de cohérence |
| `dart run legal_import push <doc.json \| dossier> [--dry-run]` | écrit dans Supabase |

`--set` renseigne les métadonnées absentes de la page :
`type`, `domain`, `reference`, `date_publication` (AAAA-MM-JJ),
`date_entree_en_vigueur`, `status`, `summary`, `id`, `related_ids`.
Valeurs autorisées : voir `lib/imported_document.dart`.

**Toujours** : `fetch` → relire le JSON → `validate` → `push --dry-run` → `push`.

---

## Conditions d'utilisation des sources

| Source | Nature | À vérifier |
|---|---|---|
| **legiburkina.bf** | Base **officielle** (SGG). Les textes normatifs (loi, décret, arrêté) ne sont pas protégés par le droit d'auteur. | Débit raisonnable ; citer la source ; pas de revente de la base. |
| **Journal Officiel du Faso** | Publication authentique. | Idem. |
| **ohada.org / ohada.com** | Actes uniformes = normes communautaires librement diffusées. | Aucune restriction sur les textes eux-mêmes. |
| **droit-afrique.com** | Compilations/consolidations privées de textes publics. | **Lire les CGU** avant import de masse ; préférer Légiburkina quand le texte y est. Un mail au site pour un accord explicite est recommandé. |
| **Assemblée nationale** | Lois votées. | Idem Légiburkina. |

> Le mieux, à moyen terme : demander au **SGG / à la DGSGG** un accès en
> masse (export, API) à Légiburkina, voire un partenariat. Le pipeline
> ci‑dessous est conçu pour brancher n'importe quelle source.

---

## Phase 1 — Le socle (Constitution + grands codes + OHADA)

Cible : ~30 textes couvrant l'essentiel des consultations.

### 1a. OHADA — les 10 Actes uniformes (source la plus propre)

```bash
mkdir -p out/phase1

dart run legal_import fetch ohada "<url_ohada_AUDCG>"    -o out/phase1/audcg.json \
  --set id=doc-ohada-audcg --set title="Acte uniforme relatif au droit commercial général" \
  --set reference="AUDCG révisé du 15 décembre 2010" --set date_publication=2010-12-15

# … idem pour : AUSCGIE, AUS, AUPSRVE, AUPC, AUDA, AUDCIF, AUCTMR,
#    AU sociétés coopératives, AU médiation
#    (les identifiants doc-ohada-* existent déjà dans le catalogue local :
#     réutilise-les pour que le push remplace la fiche, sans doublon.)

dart run legal_import validate out/phase1
dart run legal_import push out/phase1 --dry-run
dart run legal_import push out/phase1
```

### 1b. Codes nationaux burkinabè

Ordre de priorité : Constitution → Code du travail → Code pénal → Code de
procédure pénale → Code des personnes et de la famille → Code général des
impôts → Code de procédure civile → foncier (034‑2009, RAF) → sécurité
sociale → environnement → minier → électoral → CGCT → investissements.

```bash
# depuis Légiburkina (préféré) :
dart run legal_import fetch legiburkina "<url_fiche_code_travail>" -o out/phase1/code-travail.json \
  --set id=doc-code-travail --set type=code --set domain=travail \
  --set reference="Loi n° 028-2008/AN du 13 mai 2008" --set date_publication=2008-05-13 \
  --set status=modifie

# depuis un PDF (droit-afrique, JO) :
pdftotext -layout -nopgbrk code-penal.pdf code-penal.txt
dart run legal_import parse code-penal.txt -o out/phase1/code-penal.json \
  --set id=doc-code-penal --set type=code --set domain=penal \
  --set title="Code pénal" --set reference="Loi n° 025-2018/AN du 31 mai 2018" \
  --set date_publication=2018-05-31 --set status=modifie

dart run legal_import validate out/phase1/code-penal.json
# → OUVRIR le JSON, vérifier : découpage des articles, hiérarchie (path),
#   pas de préambule collé à l'article 1, numéros « 12 bis » corrects.
dart run legal_import push out/phase1/code-penal.json
```

**Relecture obligatoire** de chaque code avant push : le parseur générique
se trompe sur les mises en forme atypiques (notes de bas de page, tableaux,
annexes). Corriger le JSON à la main si besoin (c'est du texte).

À la fin de la Phase 1, l'app affiche ces textes article par article, avec
sommaire — sans nouveau déploiement (lecture serveur).

---

## Phase 2 — Le flux (lois & décrets récents)

Cible : rendre la base vivante. Alimentation périodique depuis Légiburkina
(et le JO) des textes des 24–36 derniers mois, puis veille mensuelle.

1. Lister les textes à intégrer : parcourir Légiburkina par nature et par
   date (loi, décret, arrêté), ou repartir des sommaires du Journal
   Officiel.
2. Pour chacun : `fetch legiburkina <url> --set …` → `validate` → `push`.
3. Automatiser : un script `phase2_veille.sh` qui prend une liste d'URLs
   (`urls.txt`) et enchaîne fetch/validate/push, à lancer en tâche
   planifiée (cf. `/schedule` côté Claude Code, ou un cron serveur).
4. `status` : passer à `abroge` les textes remplacés (un `push` d'une fiche
   avec `--set status=abroge` suffit ; l'app l'affiche alors comme tel).

---

## Phase 3 — La jurisprudence

Cible : décisions marquantes (Cour de cassation, Conseil d'État, Cour
constitutionnelle, Cour commune de justice et d'arbitrage OHADA).

- Sources : recueils publiés, revues, portail de la Cour de cassation,
  base CCJA pour l'OHADA.
- `type = jurisprudence`, `reference` = juridiction + n° de rôle + date,
  `summary` = solution en une phrase, `full_content` = attendus principaux
  (résumés si le texte intégral n'est pas librement diffusable).
- Rattacher chaque décision au(x) texte(s) qu'elle applique via
  `--set related_ids=doc-code-travail`.
- Même boucle : `parse` (ou saisie manuelle du JSON) → `validate` → `push`.

---

## Format d'un document (rappel)

```jsonc
{
  "id": "doc-code-travail",
  "title": "Code du travail",
  "type": "code",
  "domain": "travail",
  "reference": "Loi n° 028-2008/AN du 13 mai 2008",
  "date_publication": "2008-05-13",
  "status": "modifie",
  "summary": "Relations individuelles et collectives de travail…",
  "full_content": "",                 // vide si le texte est en articles
  "outline": ["Titre I — Dispositions générales", "..."],
  "summary_only": true,               // true tant que "articles" est vide ; le badge
                                      // « Résumé — texte intégral à venir » s'affiche.
                                      // Repasser à false une fois les articles intégrés et relus.
  "official_source_name": "Légiburkina",
  "source_url": "https://www.legiburkina.bf/...",
  "tags": ["contrat de travail", "licenciement"],
  "related_ids": ["doc-jurisprudence-licenciement"],
  "articles": [
    { "number": "1", "heading": "Champ d'application",
      "body": "Le présent code s'applique …",
      "path": ["Titre I — Dispositions générales", "Chapitre 1 — Objet"] }
  ]
}
```

## Vérification finale après chaque lot

- [ ] `validate` passe sans erreur
- [ ] relecture visuelle du JSON (10 articles au hasard)
- [ ] `push --dry-run` liste bien les documents attendus
- [ ] après `push` : ouvrir le texte dans l'app (desktop) → sommaire,
      numéros d'articles, hiérarchie corrects
- [ ] la fiche cite la bonne source officielle
