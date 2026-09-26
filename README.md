# 🏛️ Expertise BUMIDOM

**Analyse quantitative et qualitative du BUMIDOM à partir de 100 documents parlementaires (1963-1990).**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Plotly](https://img.shields.io/badge/Plotly-2.27-3F4F75.svg)](https://plotly.com/)
[![spaCy](https://img.shields.io/badge/spaCy-3.7-09A3D5.svg)](https://spacy.io/)
[![DSFR](https://img.shields.io/badge/Design-DSFR-000091.svg)](https://www.systeme-de-design.gouv.fr/)
[![Status](https://img.shields.io/badge/status-completed-success.svg)]()
[![GitHub last commit](https://img.shields.io/github/last-commit/gunout/expertise-bumidom)]()
[![GitHub repo size](https://img.shields.io/github/repo-size/gunout/expertise-bumidom)]()

> **⚠️ Projet indépendant** — Ce projet est un outil d'analyse de données publiques. Il n'est **ni édité ni approuvé** par le Gouvernement français, l'Assemblée nationale ou le Sénat. Voir la section [⚖️ Mentions légales](#️-mentions-légales).

---

## 📖 Table des matières

- [🎯 À propos](#-à-propos)
- [📊 Chiffres clés](#-chiffres-clés)
- [🌐 Démo en ligne](#-démo-en-ligne)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🚀 Démarrage rapide](#-démarrage-rapide)
- [📁 Structure du projet](#-structure-du-projet)
- [📖 Documentation](#-documentation)
- [🛠️ Technologies](#️-technologies)
- [🤝 Contribution](#-contribution)
- [⚖️ Mentions légales](#️-mentions-légales)
- [🙏 Sources et remerciements](#-sources-et-remerciements)
- [📝 Citation](#-citation)
- [📧 Contact](#-contact)

---

## 🎯 À propos

Le **BUMIDOM** (Bureau pour le développement des migrations intéressant les départements d'outre-mer) fut l'instrument central d'une politique migratoire d'État entre **1963 et 1982**, organisant le déplacement de populations des Antilles, de Guyane et de La Réunion vers la métropole.

Ce projet propose une **analyse systématique** des débats parlementaires qui lui ont été consacrés, en combinant :

- 🔢 **Analyse quantitative** (chiffres, statistiques)
- 📝 **Analyse qualitative** (orateurs, thèmes, sentiments)
- 📊 **Restitution interactive** (dashboards Plotly)

### Pipeline du projet

| Étape | Action | Résultat |
|:---:|:---|:---|
| 1️⃣ | 📥 Télécharge les sources | 100 PDF (467 Mo) depuis l'Assemblée nationale |
| 2️⃣ | 📝 Extrait le texte | 29 Mo de texte brut (99 fichiers) |
| 3️⃣ | 🔍 Détecte les mentions | 71 documents contenant BUMIDOM |
| 4️⃣ | 👤 Identifie les orateurs | 838 personnes détectées |
| 5️⃣ | 🏷️ Classe les thèmes | 10 catégories thématiques |
| 6️⃣ | 💰 Extrait les chiffres | +100 chiffres clés |
| 7️⃣ | 📊 Génère des dashboards | 5 interfaces Plotly interactives |

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
| 💾 Taille texte extrait | **29 Mo** | — |

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

### 🎤 Top 10 orateurs

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

### 🏷️ Thèmes dominants

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

| Interface | Description | URL |
|:---:|:---|:---|
| 🎯 | **Dashboard interactif** | [dashboard_interactif.html](https://gunout.github.io/expertise-bumidom/dashboard_interactif.html) |
| 📊 | Dashboard unifié | [dashboard_unifie.html](https://gunout.github.io/expertise-bumidom/dashboard_unifie.html) |
| 🔬 | Dashboard expert | [dashboard_expert.html](https://gunout.github.io/expertise-bumidom/dashboard_expert.html) |
| 🌐 | Site web | [site_bumidom/](https://gunout.github.io/expertise-bumidom/site_bumidom/) |

---

## ✨ Fonctionnalités

### 🔢 Analyse quantitative

- ✅ Extraction automatique des chiffres (montants, effectifs, pourcentages)
- ✅ Détection des dates, articles de loi, institutions
- ✅ Comptage des mentions par document, année, législature
- ✅ Statistiques agrégées (moyennes, totaux, distributions)

### 📝 Analyse qualitative

- ✅ Détection des orateurs (députés, ministres)
- ✅ Classification thématique (10 catégories)
- ✅ Analyse de sentiment (positif/négatif par année)
- ✅ Réseau de cooccurrence entre orateurs
- ✅ Extraction du contexte des mentions

### 📊 Restitution interactive

- ✅ 5 dashboards HTML avec Plotly
- ✅ Graphiques zoomables et cliquables
- ✅ Filtres par type, thème, orateur, année
- ✅ Recherche full-text dans les extraits
- ✅ Export CSV/JSON

### 🧠 Analyse NLP

- ✅ Entités nommées (personnes, lieux, organisations)
- ✅ Modèle français spaCy (`fr_core_news_sm`)
- ✅ Mots fréquents et cooccurrences
- ✅ Réseau sémantique

### 🎨 Design

- ✅ Interface conforme au **DSFR** (Système de Design de l'État)
- ✅ Palette bleu-blanc-rouge
- ✅ Mode sombre automatique
- ✅ Accessibilité RGAA

---

## 🚀 Démarrage rapide

### Prérequis

| Outil | Version | Note |
|:---|:---:|:---|
| 🐍 Python | 3.10+ | Obligatoire |
| 📥 curl | — | Pour télécharger les PDF |
| 📄 pandoc | — | Optionnel (export PDF) |
| 💾 Espace disque | ~500 Mo | Pour les PDF |

### Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/gunout/expertise-bumidom.git
cd expertise-bumidom

# 2. Créer un environnement virtuel
python3 -m venv .venv
source .venv/bin/activate      # Linux/Mac
# ou .venv\Scripts\activate     # Windows

# 3. Installer les dépendances
pip install -r requirements.txt

# 4. Installer le modèle français spaCy
python -m spacy download fr_core_news_sm
```

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

```text
expertise-bumidom/
│
├── 📄 README.md                    # Ce fichier
├── 📄 LICENSE                      # Licence MIT
├── 📄 CONTRIBUTING.md              # Guide de contribution
├── 📄 requirements.txt             # Dépendances Python
├── 📄 .gitignore                   # Exclusions
│
├── 🔧 Scripts shell (9)
│   ├── run_all.sh                  # Pipeline complet
│   ├── analyse.sh                  # Analyses
│   ├── expertise_all.sh            # Expertise chiffrée
│   ├── pipeline.sh                 # Pipeline principal
│   ├── pipeline_final.sh           # Pipeline final
│   ├── tout_faire.sh               # Package complet
│   ├── rapport_BUMIDOM_expert.sh   # Rapport expert
│   ├── analyse_all.sh              # Toutes analyses
│   └── netoyage_all.sh             # Nettoyage
│
├── 🐍 Scripts Python (5)
│   ├── scraper_bumidom.py          # Téléchargement
│   ├── extract_chiffres.py         # Extraction chiffres
│   ├── extract_chiffres_BUMIDOM.py # Extraction BUMIDOM
│   ├── extract_structured.py       # Extraction structurée
│   └── budget.py                   # Extraction budgétaire
│
├── 🌐 Dashboards HTML (6)
│   ├── dashboard_interactif.html   # Dashboard principal
│   ├── dashboard_unifie.html       # Dashboard unifié
│   ├── dashboard_expert.html       # Dashboard expert
│   ├── dashboard_enrichi.html      # Dashboard enrichi
│   ├── dashboard.html              # Dashboard simple
│   └── index.html                  # Page d'accueil
│
├── 🎨 site_bumidom/                # Site web
│   ├── index.html
│   ├── dashboard.html
│   └── ressources/
│
├── 📊 Données
│   ├── resultats.json
│   ├── resultats_enrichis.json
│   ├── nlp_results.json
│   ├── analyse_*.csv
│   ├── expertise_BUMIDOM/
│   └── urls_bumidom.txt
│
└── 📚 Documentation
    ├── json.json
    └── rapport.md
```

---

## 📖 Documentation

### 🔬 Méthodologie

| # | Étape | Détail |
|:---:|:---|:---|
| 1 | **Collecte** | 100 PDF depuis `archives.assemblee-nationale.fr` |
| 2 | **Extraction** | PyMuPDF avec fallback pdfplumber |
| 3 | **Recherche** | Détection de BUMIDOM dans un rayon de 800 caractères |
| 4 | **Enrichissement** | Détection des orateurs, thèmes et dates |
| 5 | **NLP** | Analyse spaCy (personnes, lieux, organisations) |
| 6 | **Restitution** | Dashboards Plotly + rapports Markdown |

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
| `BUDGET_montants.csv` | Montants budgétaires (775 entrées) |
| `BUDGET_budget_annuel_estime.csv` | Budget annuel reconstitué |

---

## 🛠️ Technologies

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
| 🎨 Design | DSFR | Interface État |

---

## 🤝 Contribution

Les contributions sont **bienvenues** ! Voir [CONTRIBUTING.md](CONTRIBUTING.md).

### Workflow

```bash
# 1. Fork le projet (sur GitHub)

# 2. Créer une branche
git checkout -b feature/nouvelle-analyse

# 3. Commit
git commit -m "feat: ajout analyse XYZ"

# 4. Push
git push origin feature/nouvelle-analyse

# 5. Ouvrir une Pull Request sur GitHub
```

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

## ⚖️ Mentions légales

### 📜 Statut du projet

> **Ce projet est un outil indépendant d'analyse de données publiques.**
> 
> Il **n'est ni édité ni approuvé** par :
> 
> - Le Gouvernement français
> - L'Assemblée nationale
> - Le Sénat
> - Le Ministère chargé des Outre-mer
> - Aucune autre institution publique

### 📚 Sources des données

Les textes analysés proviennent des **débats parlementaires français** :

| Source | Statut légal |
|:---|:---|
| Comptes rendus de l'Assemblée nationale | 🟢 **Domaine public** (art. L211-1 CPI) |
| Questions écrites et orales | 🟢 **Domaine public** |
| Rapports officiels | 🟢 **Domaine public** |

**Article L. 211-1 du Code de la propriété intellectuelle** :

> *"Les dispositions relatives au droit d'auteur ne s'appliquent pas aux actes officiels de l'autorité publique."*

### 🎨 Ressources graphiques

| Ressource | Licence | Utilisation |
|:---|:---|:---|
| **DSFR** (Système de Design de l'État) | Etalab 2.0 | Interface |
| **Police Marianne** | Etalab 2.0 | Typographie |
| **Logo "République Française"** | Usage encadré | Informatif uniquement |
| **Plotly.js** | MIT | Graphiques |

⚠️ **Le logo "République Française" est utilisé à titre informatif et historique uniquement.** Il ne saurait en aucun cas laisser croire que ce projet émane du Gouvernement français.

### 📄 Licence du code

Ce projet est sous licence **MIT** — voir [LICENSE](LICENSE).

---

## 🙏 Sources et remerciements

| Source | Lien |
|:---|:---|
| 🏛️ Archives de l'Assemblée nationale | https://archives.assemblee-nationale.fr/ |
| 📄 PyMuPDF | https://pymupdf.readthedocs.io/ |
| 🧠 spaCy | https://spacy.io/ |
| 📈 Plotly | https://plotly.com/ |
| 🐼 pandas | https://pandas.pydata.org/ |
| 🎨 DSFR | https://www.systeme-de-design.gouv.fr/ |

---

## 📝 Citation

Si vous utilisez ce travail dans vos recherches :

```bibtex
@misc{gunout2026bumidom,
  title  = {Expertise BUMIDOM},
  author = {Gunout},
  year   = {2026},
  url    = {https://github.com/gunout/expertise-bumidom}
}
```

---

## 📧 Contact

| Canal | Lien |
|:---:|:---|
| 🐙 GitHub | https://github.com/gunout |
| 🐛 Issues | https://github.com/gunout/expertise-bumidom/issues |
| 💬 Discussions | https://github.com/gunout/expertise-bumidom/discussions |

---

<div align="center">

## ⭐ Si ce projet vous est utile, n'hésitez pas à lui donner une étoile ! ⭐

---

### 🇫🇷 Gunout · 2026

![Made in France](https://img.shields.io/badge/Made_in-France-002395?style=flat-square&labelColor=FFFFFF)
![GitHub](https://img.shields.io/badge/GitHub-gunout-181717?style=flat-square&logo=github&logoColor=white)
![Year](https://img.shields.io/badge/2026-ED2939?style=flat-square&labelColor=FFFFFF)

<sub>© 2026 <strong>Gunout</strong> — Tous droits réservés sur le code.</sub>

<sub>Les données sources appartiennent au <strong>domaine public</strong> (art. L211-1 CPI).</sub>

<sub>Fait avec ❤️ pour la recherche historique.</sub>

</div>


