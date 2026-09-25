
---

## 📖 Documentation

### 🔬 Méthodologie

1. **Collecte** — 100 PDF depuis archives.assemblee-nationale.fr
2. **Extraction** — PyMuPDF avec fallback pdfplumber
3. **Recherche** — Détection de "BUMIDOM" dans un rayon de 800 caractères
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


@misc{gunout2026bumidom,
title={Expertise BUMIDOM},
author={Gunout},
year={2026},
url={https://github.com/gunout/expertise-bumidom}
}


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

Fait avec ❤️ pour la recherche historique

</div>
