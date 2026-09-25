#!/usr/bin/env bash
# nettoyer_all.sh — Filtre les faux positifs dans toutes les extractions
set -e
cd "$(dirname "$0")"

echo "🧹 NETTOYAGE DES EXTRACTIONS"

# --- Montants ---
python3 << 'EOF'
import csv
from pathlib import Path

MOTS_BUDGET = ["franc","budget","crédit","subvention","dépense","financement",
               "somme","montant","coût","prix","budgétaire","fiscal"]

def contexte_ok(ctx):
    return sum(1 for m in MOTS_BUDGET if m in ctx.lower()) >= 2

src = Path("expertise/01_montants.csv")
dst = Path("expertise/01_montants_NETTOYE.csv")
with open(src, encoding="utf-8") as f:
    lignes = list(csv.DictReader(f, delimiter=";"))

valides = [l for l in lignes
           if l["valeur_francs"]
           and 100 <= float(l["valeur_francs"]) <= 500_000_000_000
           and contexte_ok(l.get("contexte", ""))]

with open(dst, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=lignes[0].keys(), delimiter=";")
    w.writeheader(); w.writerows(valides)
print(f"💰 Montants : {len(valides)}/{len(lignes)} conservés")
EOF

# --- Effectifs ---
python3 << 'EOF'
import csv
from pathlib import Path

MOTS_EFF = ["personne","habitant","migrant","travailleur","réunionnais",
            "antillais","jeune","femme","homme","famille","population"]

def contexte_ok(ctx):
    return any(m in ctx.lower() for m in MOTS_EFF)

src = Path("expertise/02_effectifs.csv")
dst = Path("expertise/02_effectifs_NETTOYE.csv")
with open(src, encoding="utf-8") as f:
    lignes = list(csv.DictReader(f, delimiter=";"))

valides = [l for l in lignes
           if l["nombre"]
           and 10 <= int(float(l["nombre"])) <= 5_000_000
           and contexte_ok(l.get("contexte", ""))]

with open(dst, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=lignes[0].keys(), delimiter=";")
    w.writeheader(); w.writerows(valides)
print(f"👥 Effectifs : {len(valides)}/{len(lignes)} conservés")
EOF

# --- Pourcentages ---
python3 << 'EOF'
import csv
from pathlib import Path

src = Path("expertise/03_pourcentages.csv")
dst = Path("expertise/03_pourcentages_NETTOYE.csv")
with open(src, encoding="utf-8") as f:
    lignes = list(csv.DictReader(f, delimiter=";"))

valides = [l for l in lignes
           if l["pourcentage"]
           and 0 < float(l["pourcentage"].replace(",", ".")) <= 100]

with open(dst, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=lignes[0].keys(), delimiter=";")
    w.writeheader(); w.writerows(valides)
print(f"📊 Pourcentages : {len(valides)}/{len(lignes)} conservés")
EOF

# --- Logements ---
python3 << 'EOF'
import csv
from pathlib import Path

src = Path("expertise/04_logements.csv")
dst = Path("expertise/04_logements_NETTOYE.csv")
with open(src, encoding="utf-8") as f:
    lignes = list(csv.DictReader(f, delimiter=";"))

valides = [l for l in lignes
           if l["nombre"]
           and 5 <= int(l["nombre"]) <= 10_000]

with open(dst, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=lignes[0].keys(), delimiter=";")
    w.writeheader(); w.writerows(valides)
print(f"🏠 Logements : {len(valides)}/{len(lignes)} conservés")
EOF

echo -e "\n✅ Fichiers nettoyés :"
ls -la expertise/*_NETTOYE.csv | awk '{print "   "$9" ("$5" octets)"}'