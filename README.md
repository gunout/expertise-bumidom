# Expertise BUMIDOM

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Plotly](https://img.shields.io/badge/Plotly-2.27-3F4F75.svg)](https://plotly.com/)
[![spaCy](https://img.shields.io/badge/spaCy-3.7-09A3D5.svg)](https://spacy.io/)
[![pandas](https://img.shields.io/badge/pandas-2.0-150458.svg)](https://pandas.pydata.org/)
[![SQLite](https://img.shields.io/badge/SQLite-3-003B57.svg)](https://www.sqlite.org/)
[![Status](https://img.shields.io/badge/status-completed-success.svg)]()
[![GitHub last commit](https://img.shields.io/github/last-commit/gunout/expertise-bumidom)]()
[![GitHub repo size](https://img.shields.io/github/repo-size/gunout/expertise-bumidom)]()
[![GitHub stars](https://img.shields.io/github/stars/gunout/expertise-bumidom?style=social)](https://github.com/gunout/expertise-bumidom/stargazers)

**Un projet d'analyse quantitative et qualitative du BUMIDOM à partir de 100 documents parlementaires (1963-1990).**

[Chiffres clés](#chiffres-clés) · [Démo](#démo-en-ligne) · [Installation](#démarrage-rapide) · [Structure](#structure-du-projet) · [Documentation](#documentation) · [Licence](#licence)

---

## À propos

Le **BUMIDOM** (Bureau pour le développement des migrations intéressant les départements d'outre-mer) fut l'instrument central d'une politique migratoire d'État entre **1963 et 1982**, organisant le déplacement de populations des Antilles, de Guyane et de La Réunion vers la métropole.

Ce projet propose une analyse systématique et reproductible des débats parlementaires qui lui ont été consacrés, à travers :

- **100 documents PDF** téléchargés depuis les archives de l'Assemblée nationale
- **71 documents** contenant des mentions du BUMIDOM (1964-1990)
- **166 mentions** identifiées et contextualisées
- **838 orateurs** détectés et profilés
- **+100 chiffres clés** extraits automatiquement
- **10 thèmes** identifiés par analyse textuelle

---

## Chiffres clés

### Volumétrie générale

| Indicateur | Valeur | Période |
|:---|:---:|:---:|
| Documents analysés | **71** | 1964-1990 |
| Mentions BUMIDOM | **166** | 1964-1990 |
| Orateurs identifiés | **838** | 1964-1990 |
| Thèmes détectés | **10** | — |
| Chiffres extraits | **+100** | — |
| Période couverte | **1964-1990** | — |

### Chiffres historiques majeurs

| Indicateur | Valeur | Année |
|:---|:---:|:---:|
| Migrants via BUMIDOM | **94 000** | 1963-1974 |
| Budget BUMIDOM | **28,4 M F** | 1975 |
| Budget BUMIDOM | **279,6 M F** | 1981 |
| Flux annuel | **5 000** | 1975-1976 |
| Flux annuel | **10 000** | 1979-1980 |
| Réunionnais en métropole | **100 000** | 1981 |
| Population concernée | **400 000** | 1981 |
| Ultramarins en métropole | **620 000** | 1986 |
| Capacité d'accueil | **5 547 places** | 1972 |
| Logements BUMIDOM | **234** | 1968 |

### Top 10 orateurs

| Rang | Orateur | Mentions | Rôle |
|:---:|:---|:---:|:---|
| 1 | M. Jean Fontaine | 219 | Député de La Réunion |
| 2 | M. Michel Debré | 179 | Ministre puis député |
| 3 | M. Henri Emmanuelli | 104 | Député des Landes |
| 4 | M. Victor Sablé | 96 | Député de Martinique |
| 5 | M. Olivier Stirn | 90 | Secrétaire d'État DOM |
| 6 | M. Paul Dijoud | 81 | Secrétaire d'État DOM |
| 7 | M. Emmanuel Hamel | 79 | Sénateur |
| 8 | M. Jean-Paul de Rocca Serra | 77 | Député de Corse |
| 9 | M. Didier Julia | 73 | Député |
| 10 | M. Robert-André Vivien | 63 | Député |

### Thèmes dominants

| Rang | Thème | Occurrences | Description |
|:---:|:---|:---:|:---|
| 1 | Budget | 10 686 | Crédits, subventions, financement |
| 2 | Emploi | 10 469 | Travail, placement, chômage |
| 3 | Migration | 9 594 | Migrants, immigration, expatriation |
| 4 | Antilles | 3 319 | Guadeloupe, Martinique, Guyane |
| 5 | Formation | 3 262 | Stages, apprentissage, préformation |
| 6 | Transport | 2 812 | Billets, tarifs, voyages aériens |
| 7 | Réunion | 2 017 | La Réunion, Réunionnais |
| 8 | Insertion | 1 464 | Adaptation, accueil, installation |
| 9 | Logement | 1 460 | Foyers, hébergement, cités |
| 10 | Racisme | 1 137 | Discrimination, exploitation |

---

## Démo en ligne

- **Dashboard interactif** : https://gunout.github.io/expertise-bumidom/dashboard_interactif.html
- **Dashboard unifié** : https://gunout.github.io/expertise-bumidom/dashboard_unifie.html
- **Site web** : https://gunout.github.io/expertise-bumidom/site_bumidom/

---

## Fonctionnalités

### Analyse quantitative

- Extraction automatique des chiffres (montants, effectifs, pourcentages)
- Détection des dates, articles de loi, institutions
- Comptage des mentions par document, par année, par législature
- Statistiques agrégées (moyennes, totaux, distributions)

### Analyse qualitative

- Détection des orateurs (députés, ministres)
- Classification thématique (10 catégories)
- Analyse de sentiment (positif/négatif par année)
- Réseau de cooccurrence entre orateurs
- Extraction du contexte des mentions

### Restitution interactive

- **5 dashboards HTML** avec Plotly
- Graphiques zoomables, cliquables
- Filtres par type, thème, orateur, année
- Recherche full-text dans les extraits
- Export CSV/JSON

### Analyse NLP

- Entités nommées (personnes, lieux, organisations)
- Modèle français spaCy (fr_core_news_sm)
- Mots fréquents et cooccurrences
- Réseau sémantique

---

## Démarrage rapide

### Prérequis

- **Python 3.10+**
- **curl** (pour le téléchargement des PDF)
- **pandoc** (optionnel, pour l'export PDF)
- **~500 Mo d'espace disque** (pour les PDF téléchargés)

### Installation

1. Cloner le dépôt :
   `git clone https://github.com/gunout/expertise-bumidom.git`

2. Entrer dans le dossier :
   `cd expertise-bumidom`

3. Créer un environnement virtuel :
   `python3 -m venv .venv`

4. Activer l'environnement :
   `source .venv/bin/activate`

5. Installer les dépendances :
   `pip install -r requirements.txt`

6. Installer le modèle français :
   `python -m spacy download fr_core_news_sm`

### Utilisation

**Pipeline complet** (téléchargement + extraction + analyses) :

`./run_all.sh`

**Analyses complémentaires** :

`./analyse.sh`

**Expertise chiffrée** :

`./expertise_all.sh`

**Pipeline final unifié** :

`./pipeline_final.sh`

**Lancer les dashboards** :

`python3 -m http.server 8889`

Puis ouvrir : http://localhost:8889/dashboard_interactif.html

---

## Structure du projet

### Fichiers principaux

- **README.md** — Ce fichier
- **LICENSE** — Licence MIT
- **CONTRIBUTING.md** — Guide de contribution
- **requirements.txt** — Dépendances Python
- **.gitignore** — Fichiers exclus du versionnement

### Scripts d'orchestration (.sh)

- **run_all.sh** — Pipeline complet (téléchargement + analyses)
- **analyse.sh** — Analyses complémentaires (chrono, réseau, sentiment)
- **analyse_all.sh** — Variante des analyses
- **expertise_all.sh** — Expertise chiffrée
- **pipeline.sh** — Pipeline principal
- **pipeline_final.sh** — Pipeline final unifié
- **tout_faire.sh** — Package complet (dashboard + rapport)
- **rapport_BUMIDOM_expert.sh** — Génération du rapport expert
- **netoyage_all.sh** — Nettoyage et filtrage des données

### Scripts Python (.py)

- **scraper_bumidom.py** — Téléchargement des PDF
- **extract_chiffres.py** — Extraction des chiffres (large)
- **extract_chiffres_BUMIDOM.py** — Extraction ciblée (contexte)
- **extract_structured.py** — Extraction structurée (JSON)

### Dashboards HTML

- **dashboard_interactif.html** — Dashboard interactif complet
- **dashboard_unifie.html** — Dashboard unifié (9 onglets)
- **dashboard_expert.html** — Dashboard d'expertise chiffrée
- **dashboard_enrichi.html** — Dashboard enrichi
- **dashboard.html** — Dashboard simple
- **index.html** — Page d'accueil avec redirection

### Site web statique

- **site_bumidom/index.html** — Page d'accueil du site
- **site_bumidom/dashboard.html** — Dashboard intégré
- **site_bumidom/ressources/** — Images, CSV, Markdown

### Données produites (non versionnées)

- **pdfs/** — 100 PDF sources (467 Mo)
- **textes/** — 100 textes extraits (29 Mo)
- **bumidom.db** — Base SQLite (6 tables)
- **analyse_*.csv** — Analyses CSV
- **fiches_orateurs/** — 30 fiches Markdown

---

## Documentation

### Méthodologie

1. **Collecte** : 100 PDF téléchargés depuis archives.assemblee-nationale.fr
2. **Extraction** : Analyse via PyMuPDF (rapide) avec fallback pdfplumber
3. **Recherche** : Détection du mot-clé BUMIDOM dans un rayon de 800 caractères
4. **Enrichissement** : Détection des orateurs, thèmes et dates
5. **NLP** : Analyse via spaCy (personnes, lieux, organisations)
6. **Restitution** : Dashboards Plotly interactifs + rapports Markdown

### Sources

- **Type de documents** : Comptes rendus intégraux (CRI), questions écrites (QST), tables analytiques
- **Origine** : Archives de l'Assemblée nationale française
- **Période** : 1964-1990
- **Législatures** : 2e à 8e

### Fichiers d'analyse

- **analyse_chrono.csv** — Évolution par année
- **analyse_cooccurrences.csv** — Top 100 mots associés
- **analyse_legislatures.csv** — Comparaison par législature
- **analyse_sentiment.csv** — Tonalité par année
- **analyse_reseau.csv** — Cooccurrences entre orateurs
- **orateurs_profils.csv** — Profil des 30 top orateurs

### Expertise chiffrée

- **expertise_BUMIDOM/FICHE_SYNTHESE.md** — Fiche 1 page
- **expertise_BUMIDOM/TEXTE_REDIGE.md** — Texte structuré
- **expertise_BUMIDOM/RAPPORT_EXPERTISE_ENRICHI.md** — Rapport complet
- **expertise_BUMIDOM/SYNTHESE_CHRONOLOGIQUE.csv** — Chronologie
- **expertise_BUMIDOM/BUMIDOM_montants.csv** — Tous les montants
- **expertise_BUMIDOM/BUMIDOM_effectifs.csv** — Tous les effectifs
- **expertise_BUMIDOM/BUMIDOM_logements.csv** — Logements
- **expertise_BUMIDOM/BUMIDOM_articles.csv** — Articles de loi
- **expertise_BUMIDOM/BUMIDOM_dates.csv** — Dates citées

---

## Technologies utilisées

| Catégorie | Technologie |
|:---:|:---|
| Langage | Python 3.10+, Bash |
| Extraction PDF | PyMuPDF, pdfplumber |
| NLP | spaCy (fr_core_news_sm) |
| Data | pandas, NumPy |
| Visualisation | Plotly, Matplotlib |
| Base de données | SQLite |
| Réseau | NetworkX |
| Excel | openpyxl |
| HTTP | requests, urllib3 |

---

## Contribution

Les contributions sont bienvenues ! Voir CONTRIBUTING.md pour les détails.

### Workflow

1. Fork le projet
2. Créer une branche : `git checkout -b feature/nouvelle-analyse`
3. Commit : `git commit -m "feat: ajout analyse XYZ"`
4. Push : `git push origin feature/nouvelle-analyse`
5. Ouvrir une Pull Request

### Style des commits

- `feat:` — nouvelle fonctionnalité
- `fix:` — correction de bug
- `docs:` — documentation
- `style:` — formatage
- `refactor:` — refactorisation
- `test:` — ajout de tests
- `chore:` — maintenance

---

## Licence

Ce projet est sous licence **MIT** — voir le fichier LICENSE.

Note importante : les PDF sources et les textes extraits appartiennent à l'**Assemblée nationale française** et sont soumis aux conditions d'utilisation de leur site.

---

## Sources et remerciements

- **Archives de l'Assemblée nationale** : https://archives.assemblee-nationale.fr/
- **PyMuPDF** : https://pymupdf.readthedocs.io/
- **spaCy** : https://spacy.io/
- **Plotly** : https://plotly.com/
- **pandas** : https://pandas.pydata.org/

---

## Citation

Si vous utilisez ce travail dans vos recherches :

    @misc{gunout2026bumidom,
      title={Expertise BUMIDOM},
      author={Gunout},
      year={2026},
      url={https://github.com/gunout/expertise-bumidom}
    }

---

## Contact

- **GitHub** : https://github.com/gunout
- **Issues** : https://github.com/gunout/expertise-bumidom/issues

---

**Si ce projet vous est utile, n'hésitez pas à lui donner une étoile !**
