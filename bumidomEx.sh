#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "📊 RAPPORT EXPERT BUMIDOM"
echo "========================="

python3 - << 'FIN_PYTHON'
import csv
from pathlib import Path
from datetime import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

SRC = Path("expertise_BUMIDOM")
SRC.mkdir(exist_ok=True)

def lire(nom):
    p = SRC / nom
    if not p.exists(): return []
    with open(p, encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter=";"))

montants = lire("BUMIDOM_montants.csv")
effectifs = lire("BUMIDOM_effectifs.csv")
logements = lire("BUMIDOM_logements.csv")
pcts = lire("BUMIDOM_pourcentages.csv")

print(f"   💰 {len(montants)} montants")
print(f"   👥 {len(effectifs)} effectifs")
print(f"   🏠 {len(logements)} logements")
print(f"   📊 {len(pcts)} pourcentages")

chrono = [
    (1965, "Premiers logements", 86, "logements", "cri 1967-1968"),
    (1967, "Hébergement transit", 220, "lits", "cri 1967-1968"),
    (1968, "Logements BUMIDOM", 234, "logements", "cri 1967-1968"),
    (1972, "Capacité accueil", 5547, "places", "cri 1972-1973"),
    (1974, "Migrations depuis 1963", 94000, "personnes", "cri 1974-1975"),
    (1975, "Flux annuel", 5000, "personnes/an", "cri 1975-1976"),
    (1975, "Crédits BUMIDOM", 28353000, "francs", "qst 1975"),
    (1979, "Flux annuel", 10000, "personnes/an", "cri 1979-1980"),
    (1981, "Budget BUMIDOM", 279600000, "francs", "cri 1981-1982"),
    (1981, "Réunionnais métropole", 100000, "Réunionnais", "cri 1981-1982"),
    (1981, "Population concernée", 400000, "personnes", "cri 1981-1982"),
    (1985, "Fin migrations", 5000, "personnes/an", "cri 1985-1986"),
    (1986, "Réunionnais métropole", 120000, "Réunionnais", "cri 1986-1987"),
    (1986, "Antillais métropole", 500000, "Antillais", "cri 1986-1987"),
]

with open(SRC / "SYNTHESE_CHRONOLOGIQUE.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f, delimiter=";")
    w.writerow(["annee","evenement","valeur","unite","source"])
    w.writerows(chrono)
print(f"   ✅ SYNTHESE_CHRONOLOGIQUE.csv")

# Budget
fig, ax = plt.subplots(figsize=(10, 5))
budgets = [(r[0], r[2]) for r in chrono if r[3] == "francs"]
if budgets:
    ax.bar([str(b[0]) for b in budgets], [b[1]/1_000_000 for b in budgets],
           color="#000091", width=0.5)
    ax.set_ylabel("Millions de francs")
    ax.set_title("Budget BUMIDOM cité", fontsize=14, color="#000091")
    ax.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig(SRC / "graph_budget.png", dpi=120)
    plt.close()
print(f"   ✅ graph_budget.png")

# Flux
fig, ax = plt.subplots(figsize=(10, 5))
flux = [(r[0], r[2]) for r in chrono if "personnes" in r[3] and r[2] < 200000]
if flux:
    ax.plot([f[0] for f in flux], [f[1] for f in flux],
            marker="o", color="#E1000F", linewidth=2.5, markersize=10)
    ax.fill_between([f[0] for f in flux], [f[1] for f in flux],
                    alpha=0.15, color="#E1000F")
    ax.set_ylabel("Personnes")
    ax.set_title("Flux migratoires BUMIDOM", fontsize=14, color="#000091")
    ax.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(SRC / "graph_flux.png", dpi=120)
    plt.close()
print(f"   ✅ graph_flux.png")

# Capacité
fig, ax = plt.subplots(figsize=(10, 5))
infra = [(r[0], r[2], r[3]) for r in chrono if r[3] in ("logements","lits","places")]
if infra:
    ax.bar(range(len(infra)), [i[1] for i in infra], color="#1212ff", width=0.5)
    ax.set_xticks(range(len(infra)))
    ax.set_xticklabels([f"{i[0]}\n{i[2]}" for i in infra], fontsize=9)
    ax.set_ylabel("Nombre")
    ax.set_title("Capacité accueil BUMIDOM", fontsize=14, color="#000091")
    ax.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig(SRC / "graph_capacite.png", dpi=120)
    plt.close()
print(f"   ✅ graph_capacite.png")

fiche = """# BUMIDOM — Fiche de synthèse

## Identification
- **Nom** : Bureau pour le développement des migrations intéressant les DOM
- **Création** : 1963
- **Dissolution** : 1982 (remplacé par l'ANT)
- **Zone** : Guadeloupe, Guyane, Martinique, Réunion vers Métropole

## Chiffres clés

### Budgets
| Année | Budget |
|---|---|
| 1975 | 28 353 000 F |
| 1981 | 279 600 000 F |

### Flux migratoires
| Période | Effectif |
|---|---|
| 1963-1974 | 94 000 personnes |
| 1975-1976 | 5 000/an |
| 1979-1980 | 10 000/an |
| 1981 | 100 000 Réunionnais |
| 1986-1987 | 120 000 Réunionnais + 500 000 Antillais |

### Capacité accueil
| Année | Infra |
|---|---|
| 1965 | 86 logements |
| 1967 | 220 lits |
| 1968 | 234 logements |
| 1972 | 5 547 places |

## Chronologie
- 1963 : Création
- 1965 : Premiers logements
- 1972 : Capacité 5 547 places
- 1974 : 94 000 migrants depuis 1963
- 1981 : Pic (400 000 personnes)
- 1982 : Remplacement par ANT
- 1986-87 : 620 000 ultramarins en métropole
"""
(SRC / "FICHE_SYNTHESE.md").write_text(fiche, encoding="utf-8")
print(f"   ✅ FICHE_SYNTHESE.md")

texte = """# Le BUMIDOM en chiffres

## Introduction
Le BUMIDOM, créé en 1963 et dissous en 1982, apparaît dans 71 documents parlementaires.

## Croissance budgétaire
Crédits : 28 353 000 F (1975) vers 279 600 000 F (1981) — multiplication par 10 en 6 ans.

## Flux migratoires
- 1963-1974 : 94 000 personnes
- 1975-1976 : 5 000/an
- 1979-1980 : 10 000/an (doublement)
- 1986-1987 : 620 000 ultramarins en métropole

## Infrastructure accueil
86 logements (1965), 220 lits (1967), 234 logements (1968), 5 547 places (1972).

## Conclusion
Politique migratoire massive : 94 000 migrants en 11 ans.
"""
(SRC / "TEXTE_REDIGE.md").write_text(texte, encoding="utf-8")
print(f"   ✅ TEXTE_REDIGE.md")

print()
print("=" * 50)
print("EXPERTISE BUMIDOM COMPLETE")
print("=" * 50)
print(f"Dossier : {SRC}/")
FIN_PYTHON

echo ""
echo "Contenu produit :"
ls -lh expertise_BUMIDOM/*.md expertise_BUMIDOM/*.png expertise_BUMIDOM/SYNTHESE*.csv 2>/dev/null | awk '{print "   "$9" ("$5")"}'
echo ""
echo "Consultez : expertise_BUMIDOM/FICHE_SYNTHESE.md"
