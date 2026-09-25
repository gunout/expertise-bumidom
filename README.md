# Expertise BUMIDOM

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Plotly](https://img.shields.io/badge/Plotly-2.27-3F4F75.svg)](https://plotly.com/)
[![spaCy](https://img.shields.io/badge/spaCy-3.7-09A3D5.svg)](https://spacy.io/)
[![Status](https://img.shields.io/badge/status-completed-success.svg)]()
[![GitHub last commit](https://img.shields.io/github/last-commit/gunout/expertise-bumidom)]()
[![GitHub repo size](https://img.shields.io/github/repo-size/gunout/expertise-bumidom)]()

**Un projet d'analyse quantitative et qualitative du BUMIDOM à partir de 100 documents parlementaires.**

---

## À propos

Le **BUMIDOM** (Bureau pour le développement des migrations intéressant les départements d'outre-mer) fut l'instrument central d'une politique migratoire d'État entre **1963 et 1982**.

Ce projet propose une analyse systématique des débats parlementaires qui lui ont été consacrés :

- **100 documents** téléchargés depuis les archives de l'Assemblée nationale
- **71 documents** contenant des mentions du BUMIDOM
- **166 mentions** identifiées et contextualisées
- **838 orateurs** détectés
- **+100 chiffres clés** extraits automatiquement

---

## Chiffres clés

| Indicateur | Valeur | Période |
|:---|:---:|:---:|
| Documents analysés | **71** | 1964-1990 |
| Mentions BUMIDOM | **166** | 1964-1990 |
| Orateurs identifiés | **838** | 1964-1990 |
| Thèmes détectés | **10** | — |
| Migrants (1963-1974) | **94 000** | 1963-1974 |
| Budget BUMIDOM 1981 | **279,6 M F** | 1981 |
| Ultramarins en métropole | **620 000** | 1986 |
| Capacité d'accueil 1972 | **5 547 places** | 1972 |

### Top 5 orateurs

| Rang | Orateur | Mentions |
|:---:|:---|:---:|
| 1 | M. Jean Fontaine | 219 |
| 2 | M. Michel Debré | 179 |
| 3 | M. Henri Emmanuelli | 104 |
| 4 | M. Victor Sablé | 96 |
| 5 | M. Olivier Stirn | 90 |

### Thèmes dominants

| Rang | Thème | Occurrences |
|:---:|:---|:---:|
| 1 | Budget | 10 686 |
| 2 | Emploi | 10 469 |
| 3 | Migration | 9 594 |
| 4 | Antilles | 3 319 |
| 5 | Formation | 3 262 |
| 6 | Transport | 2 812 |
| 7 | Réunion | 2 017 |
| 8 | Insertion | 1 464 |
| 9 | Logement | 1 460 |
| 10 | Racisme | 1 137 |

---

## Démo en ligne

- Dashboard interactif : https://gunout.github.io/expertise-bumidom/dashboard_interactif.html
- Site web : https://gunout.github.io/expertise-bumidom/site_bumidom/

---

## Démarrage rapide

### Prérequis

- Python 3.10+
- curl (pour le téléchargement des PDF)
- pandoc (optionnel, pour l'export PDF)

### Installation

1. Cloner le dépôt : `git clone https://github.com/gunout/expertise-bumidom.git`
2. Entrer dans le dossier : `cd expertise-bumidom`
3. Créer un environnement virtuel : `python3 -m venv .venv`
4. Activer l'environnement : `source .venv/bin/activate`
5. Installer les dépendances : `pip install -r requirements.txt`
6. Installer le modèle français : `python -m spacy download fr_core_news_sm`

### Utilisation

- `./run_all.sh` — Téléchargement des PDF + analyses
- `./analyse.sh` — Analyses complémentaires
- `./expertise_all.sh` — Expertise chiffrée
- `python3 -m http.server 8889` — Lancer le serveur local

Puis ouvrir : http://localhost:8889/dashboard_interactif.html

---

## Structure du projet

- **README.md** — Ce fichier
- **LICENSE** — Licence MIT
- **CONTRIBUTING.md** — Guide de contribution
- **requirements.txt** — Dépendances Python
- **.gitignore** — Fichiers exclus
- **Scripts .sh** — Orchestration (run_all.sh, analyse.sh, etc.)
- **Scripts .py** — Analyse (scraper_bumidom.py, extract_chiffres.py, etc.)
- **Dashboards .html** — Interfaces (dashboard_interactif.html, etc.)
- **site_bumidom/** — Site web statique
- **resultats.json** — Données brutes
- **resultats_enrichis.json** — Données enrichies
- **nlp_results.json** — Analyse NLP
- **analyse_*.csv** — Analyses CSV
- **expertise_BUMIDOM/** — Expertise chiffrée
- **plotly.min.js** — Bibliothèque graphique

---

## Méthodologie

1. **Collecte** : 100 PDF téléchargés depuis archives.assemblee-nationale.fr
2. **Extraction** : Analyse via PyMuPDF (rapide) avec fallback pdfplumber
3. **Recherche** : Détection du mot-clé BUMIDOM dans un rayon de 800 caractères
4. **Enrichissement** : Détection des orateurs, thèmes et dates
5. **NLP** : Analyse via spaCy (personnes, lieux, organisations)
6. **Restitution** : Dashboards Plotly interactifs + rapports Markdown

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

---

## Contribution

Les contributions sont bienvenues ! Voir CONTRIBUTING.md.

1. Fork le projet
2. Créer une branche : `git checkout -b feature/nouvelle-analyse`
3. Commit : `git commit -m "feat: ajout analyse XYZ"`
4. Push : `git push origin feature/nouvelle-analyse`
5. Ouvrir une Pull Request

---

## Licence

Ce projet est sous licence **MIT** — voir le fichier LICENSE.

Note importante : les PDF sources et les textes extraits appartiennent à l'**Assemblée nationale française**.

---

## Sources et remerciements

- Archives de l'Assemblée nationale : https://archives.assemblee-nationale.fr/
- PyMuPDF : https://pymupdf.readthedocs.io/
- spaCy : https://spacy.io/
- Plotly : https://plotly.com/

---

## Citation

Si vous utilisez ce travail dans vos recherches :

    @misc{gunout2026bumidom,
      title={Expertise BUMIDOM},
      author={Gunout},
      year={2026},
      url={https://github.com/gunout/expertise-bumidom}
    }
