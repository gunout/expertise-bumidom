# Expertise BUMIDOM

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Plotly](https://img.shields.io/badge/Plotly-2.27-3F4F75.svg)](https://plotly.com/)
[![spaCy](https://img.shields.io/badge/spaCy-3.7-09A3D5.svg)](https://spacy.io/)
[![Status](https://img.shields.io/badge/status-completed-success.svg)]()
[![GitHub last commit](https://img.shields.io/github/last-commit/gunout/expertise-bumidom)]()
[![GitHub repo size](https://img.shields.io/github/repo-size/gunout/expertise-bumidom)]()

**Un projet d'analyse quantitative et qualitative du BUMIDOM a partir de 100 documents parlementaires.**

---

## 🎯 À propos

Le **BUMIDOM** (Bureau pour le développement des migrations intéressant les départements d'outre-mer) fut l'instrument central d'une politique migratoire d'État entre **1963 et 1982**, organisant le déplacement de populations des Antilles, de Guyane et de La Réunion vers la métropole.

Ce projet propose une analyse systématique des débats parlementaires qui lui ont été consacrés.

| Action du projet | Résultat |
|:---|:---|
| 📥 Télécharge les sources | 100 PDF (467 Mo) depuis l'Assemblée nationale |
| 📝 Extrait le texte | 29 Mo de texte brut (99 fichiers) |
| 🔍 Détecte les mentions | 71 documents contenant BUMIDOM |
| 👤 Identifie les orateurs | 838 personnes détectées |
| 🏷️ Classe les thèmes | 10 catégories thématiques |
| 💰 Extrait les chiffres | +100 chiffres clés |
| 📊 Génère des dashboards | 5 interfaces Plotly interactives |

---

## 📊 Chiffres clés

### Volumétrie générale

| Indicateur | Valeur | Période |
|:---|:---:|:---:|
| 📄 Documents analysés | **71** | 1964-1990 |
| 💬 Mentions BUMIDOM | **166** | 1964-1990 |
| 👤 Orateurs identifiés | **838** | 1964-1990 |
| 🏷️ Thèmes détectés | **10** | — |
| 🔢 Chiffres extraits | **+100** | — |
| 📅 Période couverte | **1964-1990** | — |

### Chiffres historiques majeurs

| Indicateur | Valeur | Année |
|:---|:---:|:---:|
| 👥 Migrants via BUMIDOM | **94 000** | 1963-1974 |
| 💰 Budget BUMIDOM | **28,4 M F** | 1975 |
| 💰 Budget BUMIDOM | **279,6 M F** | 1981 |
| 📈 Flux annuel | **5 000** | 1975-1976 |
| 📈 Flux annuel | **10 000** | 1979-1980 |
| 🌍 Réunionnais en métropole | **100 000** | 1981 |
| 🌍 Ultramarins en métropole | **620 000** | 1986 |
| 🏠 Capacité d'accueil | **5 547 places** | 1972 |
| 🏘️ Logements BUMIDOM | **234** | 1968 |

### Top 10 orateurs

| # | Orateur | Mentions | Rôle |
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

| # | Thème | Occurrences | Description |
|:---:|:---|:---:|:---|
| 1 | 💰 Budget | 10 686 | Crédits, subventions, financement |
| 2 | 💼 Emploi | 10 469 | Travail, placement, chômage |
| 3 | 🚢 Migration | 9 594 | Migrants, immigration, expatriation |
| 4 | 🌴 Antilles | 3 319 | Guadeloupe, Martinique, Guyane |
| 5 | 🎓 Formation | 3 262 | Stages, apprentissage, préformation |
| 6 | ✈️ Transport | 2 812 | Billets, tarifs, voyages aériens |
| 7 | 🏝️ Réunion | 2 017 | La Réunion, Réunionnais |
| 8 | 🏠 Insertion | 1 464 | Adaptation, accueil, installation |
| 9 | 🏘️ Logement | 1 460 | Foyers, hébergement, cités |
| 10 | ⚠️ Racisme | 1 137 | Discrimination, exploitation |

---

## 🌐 Démo en ligne

| Interface | URL |
|:---|:---|
| 🎯 **Dashboard interactif** | https://gunout.github.io/expertise-bumidom/dashboard_interactif.html |
| 📊 Dashboard unifié | https://gunout.github.io/expertise-bumidom/dashboard_unifie.html |
| 🔬 Dashboard expert | https://gunout.github.io/expertise-bumidom/dashboard_expert.html |
| 🌐 Site web | https://gunout.github.io/expertise-bumidom/site_bumidom/ |

---

## ✨ Fonctionnalités

### 🔢 Analyse quantitative
- Extraction automatique des chiffres (montants, effectifs, pourcentages)
- Détection des dates, articles de loi, institutions
- Comptage des mentions par document, année, législature
- Statistiques agrégées (moyennes, totaux, distributions)

### 📝 Analyse qualitative
- Détection des orateurs (députés, ministres)
- Classification thématique (10 catégories)
- Analyse de sentiment (positif/négatif par année)
- Réseau de cooccurrence entre orateurs
- Extraction du contexte des mentions

### 📊 Restitution interactive
- 5 dashboards HTML avec Plotly
- Graphiques zoomables, cliquables
- Filtres par type, thème, orateur, année
- Recherche full-text dans les extraits
- Export CSV/JSON

### 🧠 Analyse NLP
- Entités nommées (personnes, lieux, organisations)
- Modèle français spaCy (fr_core_news_sm)
- Mots fréquents et cooccurrences
- Réseau sémantique

---

## 🚀 Démarrage rapide

### Prérequis

- 🐍 **Python 3.10+**
- 📥 **curl** (pour le téléchargement des PDF)
- 📄 **pandoc** (optionnel, pour l'export PDF)
- 💾 **~500 Mo d'espace disque** (pour les PDF)

### Installation

1. 📥 Cloner le dépôt : `git clone https://github.com/gunout/expertise-bumidom.git`
2. 📂 Entrer dans le dossier : `cd expertise-bumidom`
3. 🐍 Créer un environnement virtuel : `python3 -m venv .venv`
4. ✅ Activer l'environnement : `source .venv/bin/activate`
5. 📦 Installer les dépendances : `pip install -r requirements.txt`
6. 🧠 Installer le modèle français : `python -m spacy download fr_core_news_sm`

### Utilisation

| Commande | Rôle |
|:---|:---|
| `./run_all.sh` | 📥 Pipeline complet (téléchargement + analyses) |
| `./analyse.sh` | 📊 Analyses complémentaires |
| `./expertise_all.sh` | 💰 Expertise chiffrée |
| `./pipeline_final.sh` | 🎯 Pipeline final unifié |
| `python3 -m http.server 8889` | 🌐 Lancer les dashboards |

Puis ouvrir : **http://localhost:8889/dashboard_interactif.html**

---

## 📁 Structure du projet
```bash
expertise-bumidom/
│
├── 📄 README.md Ce fichier
├── 📄 LICENSE MIT
├── 📄 CONTRIBUTING.md Guide de contribution
├── 📄 requirements.txt Dépendances Python
├── 📄 .gitignore Exclusions
│
├── 🔧 Scripts .sh (9)
│ ├── run_all.sh Pipeline complet
│ ├── analyse.sh Analyses
│ ├── expertise_all.sh Expertise
│ ├── pipeline.sh Pipeline principal
│ ├── pipeline_final.sh Pipeline final
│ ├── tout_faire.sh Package complet
│ ├── rapport_BUMIDOM_expert.sh
│ ├── analyse_all.sh
│ └── netoyage_all.sh
│
├── 🐍 Scripts .py (4)
│ ├── scraper_bumidom.py
│ ├── extract_chiffres.py
│ ├── extract_chiffres_BUMIDOM.py
│ └── extract_structured.py
│
├── 🌐 Dashboards .html (6)
│ ├── dashboard_interactif.html
│ ├── dashboard_unifie.html
│ ├── dashboard_expert.html
│ ├── dashboard_enrichi.html
│ ├── dashboard.html
│ └── index.html
│
├── 🎨 site_bumidom/
│ ├── index.html
│ ├── dashboard.html
│ └── ressources/
│
├── 📊 Données
│ ├── resultats.json
│ ├── resultats_enrichis.json
│ ├── nlp_results.json
│ ├── analyse_*.csv
│ ├── expertise_BUMIDOM/
│ └── urls_bumidom.txt
│
└── 📚 Documentation
├── json.json
└── rapport.md
```

---

## 📖 Documentation

### 🔬 Méthodologie

1. **Collecte** — 100 PDF depuis archives.assemblee-nationale.fr
2. **Extraction** — PyMuPDF avec fallback pdfplumber
3. **Recherche** — Détection de BUMIDOM dans un rayon de 800 caractères
4. **Enrichissement** — Détection des orateurs, thèmes et dates
5. **NLP** — Analyse spaCy (personnes, lieux, organisations)
6. **Restitution** — Dashboards Plotly + rapports Markdown

### 📄 Fichiers d'analyse produits

| Fichier | Contenu |
|:---|:---|
| `analyse_chrono.csv` | Évolution par année |
| `analyse_cooccurrences.csv` | Top 100 mots associés |
| `analyse_legislatures.csv` | Comparaison par législature |
| `analyse_sentiment.csv` | Tonalité par année |
| `analyse_reseau.csv` | Cooccurrences entre orateurs |
| `orateurs_profils.csv` | Profil des 30 top orateurs |

### 💰 Expertise chiffrée

| Fichier | Contenu |
|:---|:---|
| `FICHE_SYNTHESE.md` | Fiche 1 page |
| `TEXTE_REDIGE.md` | Texte structuré |
| `RAPPORT_EXPERTISE_ENRICHI.md` | Rapport complet |
| `SYNTHESE_CHRONOLOGIQUE.csv` | Chronologie |
| `BUMIDOM_montants.csv` | Tous les montants |
| `BUMIDOM_effectifs.csv` | Tous les effectifs |
| `BUMIDOM_logements.csv` | Logements |
| `BUMIDOM_articles.csv` | Articles de loi |
| `BUMIDOM_dates.csv` | Dates citées |

---

## 🛠️ Technologies utilisées

| Catégorie | Technologie | Usage |
|:---:|:---|:---|
| 🐍 Langage | Python 3.10+ | Scripts principaux |
| 💻 Shell | Bash | Orchestration |
| 📄 PDF | PyMuPDF, pdfplumber | Extraction |
| 🧠 NLP | spaCy | Entités nommées |
| 📊 Data | pandas, NumPy | Manipulation |
| 📈 Viz | Plotly, Matplotlib | Graphiques |
| 💾 BDD | SQLite | Base de données |
| 🕸️ Réseau | NetworkX | Graphes |

---

## 🤝 Contribution

Les contributions sont bienvenues ! Voir [CONTRIBUTING.md](CONTRIBUTING.md).

### Workflow

1. 🍴 Fork le projet
2. 🌿 Créer une branche : `git checkout -b feature/nouvelle-analyse`
3. ✏️ Commit : `git commit -m "feat: ajout analyse XYZ"`
4. 📤 Push : `git push origin feature/nouvelle-analyse`
5. 🎯 Ouvrir une Pull Request

### Style des commits

| Préfixe | Usage |
|:---:|:---|
| `feat:` | Nouvelle fonctionnalité |
| `fix:` | Correction de bug |
| `docs:` | Documentation |
| `style:` | Formatage |
| `refactor:` | Refactorisation |
| `test:` | Ajout de tests |
| `chore:` | Maintenance |

---

## 📄 Licence

Ce projet est sous licence **MIT** — voir le fichier [LICENSE](LICENSE).

⚠️ **Note importante** : les PDF sources et les textes extraits appartiennent à l'**Assemblée nationale française** et sont soumis aux conditions d'utilisation de leur site.

---

## 🙏 Sources et remerciements

| Source | Lien |
|:---|:---|
| 🏛️ Archives de l'Assemblée nationale | https://archives.assemblee-nationale.fr/ |
| 📄 PyMuPDF | https://pymupdf.readthedocs.io/ |
| 🧠 spaCy | https://spacy.io/ |
| 📈 Plotly | https://plotly.com/ |
| 🐼 pandas | https://pandas.pydata.org/ |

---

## 📝 Citation

Si vous utilisez ce travail dans vos recherches :
```bash
@misc{gunout2026bumidom,
title={Expertise BUMIDOM},
author={Gunout},
year={2026},
url={https://github.com/gunout/expertise-bumidom}
}
```

---

## 📧 Contact

| Canal | Lien |
|:---|:---|
| 🐙 GitHub | https://github.com/gunout |
| 🐛 Issues | https://github.com/gunout/expertise-bumidom/issues |
| 💬 Discussions | https://github.com/gunout/expertise-bumidom/discussions |

---

<div align="center">

**⭐ Si ce projet vous est utile, n'hésitez pas à lui donner une étoile ! ⭐**

---

<div align="center">

### 🇫🇷 Gunout · 2026

![Made in France](https://img.shields.io/badge/Made_in-France-002395?style=flat-square&labelColor=FFFFFF&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA5MDAgNjAwIj48cmVjdCB3aWR0aD0iOTAwIiBoZWlnaHQ9IjYwMCIgZmlsbD0iIzAwMjM5NSIvPjxyZWN0IHdpZHRoPSI5MDAiIGhlaWdodD0iNDAwIiB5PSIxMDAiIGZpbGw9IiNmZmYiLz48cmVjdCB3aWR0aD0iOTAwIiBoZWlnaHQ9IjIwMCIgeT0iNDAwIiBmaWxsPSIjZWQyOTM5Ii8+PC9zdmc+)
![GitHub](https://img.shields.io/badge/GitHub-gunout-181717?style=flat-square&logo=github&logoColor=white)
![Year](https://img.shields.io/badge/2026-ED2939?style=flat-square&labelColor=FFFFFF)

<sub>© 2026 <strong>Gunout</strong> — Tous droits réservés.</sub>

</div>

Fait avec ❤️ pour la recherche historique

</div>
