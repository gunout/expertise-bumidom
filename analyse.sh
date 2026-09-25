#!/usr/bin/env bash
# ============================================================
# analyse.sh — Analyse complète BUMIDOM (d'un seul coup)
# Usage : ./analyse.sh
# ============================================================
set -euo pipefail

BLEU='\033[0;34m'; ROUGE='\033[0;31m'; VERT='\033[0;32m'
JAUNE='\033[1;33m'; GRIS='\033[0;90m'; NC='\033[0m'

echo -e "${BLEU}"
cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║   ANALYSE COMPLÈTE BUMIDOM                               ║
║   Chronologie · Mots · Orateurs · Sentiment · Réseau     ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

cd "$(dirname "$0")"
echo -e "${GRIS}Dossier : $(pwd)${NC}\n"

# ---------- Vérifications ----------
if [[ ! -f "resultats_enrichis.json" ]]; then
    echo -e "${ROUGE}❌ resultats_enrichis.json manquant.${NC}"
    echo -e "${JAUNE}   → Lancez d'abord : ./run_all.sh${NC}"
    exit 1
fi

# Venv (optionnel mais recommandé)
if [[ -d ".venv" ]]; then
    source .venv/bin/activate
    echo -e "${VERT}✅ venv activé${NC}"
fi

# ---------- Dépendances ----------
echo -e "\n${BLEU}[0/8] Dépendances Python…${NC}"
python3 -c "import matplotlib" 2>/dev/null || pip install --quiet matplotlib
python3 -c "import networkx"   2>/dev/null || pip install --quiet networkx
echo -e "${VERT}   ✅ matplotlib + networkx prêts${NC}"

# ============================================================
# 1. ANALYSE CHRONOLOGIQUE
# ============================================================
echo -e "\n${BLEU}[1/8] Analyse chronologique…${NC}"
cat > _tmp_chrono.py <<'PYEOF'
import json, csv, re
from pathlib import Path
from collections import defaultdict
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
par_annee = defaultdict(lambda: {"docs": 0, "mentions": 0, "cri": 0, "qst": 0})

for d in data["results"]:
    annee = None
    m = re.search(r"(\d{4})-\d{2}-\d{2}", d["fichier"])
    if m: annee = int(m.group(1))
    else:
        m = re.search(r"(\d{4})-(\d{4})", d["fichier"])
        if m: annee = int(m.group(1))
    if not annee: continue
    par_annee[annee]["docs"] += 1
    par_annee[annee]["mentions"] += d["nb_mentions"]
    if "_cri_" in d["fichier"]: par_annee[annee]["cri"] += 1
    if "_qst_" in d["fichier"]: par_annee[annee]["qst"] += 1

with open("analyse_chrono.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["annee", "documents", "mentions", "comptes_rendus", "questions"])
    for a in sorted(par_annee):
        v = par_annee[a]
        w.writerow([a, v["docs"], v["mentions"], v["cri"], v["qst"]])

annees = sorted(par_annee)
fig, ax1 = plt.subplots(figsize=(14, 6))
ax1.bar(annees, [par_annee[a]["mentions"] for a in annees], color="#000091")
ax1.set_xlabel("Année"); ax1.set_ylabel("Mentions BUMIDOM", color="#000091")
ax1.tick_params(axis='y', labelcolor="#000091")
ax2 = ax1.twinx()
ax2.plot(annees, [par_annee[a]["docs"] for a in annees], color="#E1000F", marker="o", linewidth=2)
ax2.set_ylabel("Documents", color="#E1000F"); ax2.tick_params(axis='y', labelcolor="#E1000F")
plt.title("Évolution des mentions BUMIDOM", fontsize=14)
plt.tight_layout(); plt.savefig("analyse_chrono.png", dpi=100)
print(f"   ✅ analyse_chrono.csv + .png ({len(annees)} années)")
PYEOF
python3 _tmp_chrono.py

# ============================================================
# 2. COOCCURRENCES
# ============================================================
echo -e "\n${BLEU}[2/8] Cooccurrences…${NC}"
cat > _tmp_cooc.py <<'PYEOF'
import json, csv, re, unicodedata
from pathlib import Path
from collections import Counter

STOP = set("""le la les un une des du de d au aux et ou mais donc or ni car que qui quoi dont où ce cet cette ces mon ma mes ton ta tes son sa ses notre nos votre vos leur leurs je tu il elle nous vous ils elles on se s y en à dans par pour sur sous avec sans chez vers entre est sont était étaient être avoir a ont avait avaient fait faire plus moins très trop peu bien mal tout tous toute comme aussi alors donc ainsi encore déjà toujours jamais bumidom monsieur madame m mm mme mmes cette celui celle ceux celles c n l j m t qu peut doit faut va vont sera seront serait année années an ans jour jours mois fois""".split())

def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
compteur = Counter()
for doc in data["results"]:
    for e in doc["extraits"]:
        for m in re.findall(r"\b[a-zàâäéèêëîïôöùûüç]{4,}\b", e["extrait"].lower()):
            if m in STOP or m.isdigit(): continue
            compteur[m] += 1

top100 = compteur.most_common(100)
with open("analyse_cooccurrences.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["mot", "occurrences"])
    w.writerows(top100)
print(f"   ✅ analyse_cooccurrences.csv (top 100)")
PYEOF
python3 _tmp_cooc.py

# ============================================================
# 3. ORATEURS
# ============================================================
echo -e "\n${BLEU}[3/8] Profils des orateurs…${NC}"
cat > _tmp_orateurs.py <<'PYEOF'
import json, csv
from pathlib import Path
from collections import defaultdict, Counter

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
orateurs = defaultdict(lambda: {"total": 0, "docs": [], "themes": Counter(),
                                 "annees": Counter(), "extraits": []})
for d in data["results"]:
    for o in d["orateurs"]:
        nom = o["nom"]
        orateurs[nom]["total"] += o["occurrences"]
        orateurs[nom]["docs"].append(d["fichier"])
        for th, n in d["themes"].items(): orateurs[nom]["themes"][th] += n
        for a in d["statistiques"]["annees"]: orateurs[nom]["annees"][a] += 1
        orateurs[nom]["extraits"].append(d["extraits"][0]["extrait"][:200])

top = sorted(orateurs.items(), key=lambda x: -x[1]["total"])[:30]
with open("orateurs_profils.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["orateur", "mentions", "nb_docs", "theme_1", "score_1",
                "theme_2", "score_2", "theme_3", "score_3"])
    for nom, info in top:
        themes = info["themes"].most_common(3)
        row = [nom, info["total"], len(info["docs"])]
        for i in range(3):
            if i < len(themes): row.extend([themes[i][0], themes[i][1]])
            else: row.extend(["", ""])
        w.writerow(row)

DOSSIER = Path("fiches_orateurs"); DOSSIER.mkdir(exist_ok=True)
for nom, info in top:
    slug = nom.replace(" ", "_").replace(".", "").replace("'", "")
    L = [f"# {nom}\n\n",
         f"**Total mentions** : {info['total']}\n",
         f"**Documents** : {len(info['docs'])}\n\n## Thèmes\n\n| Thème | Occurrences |\n|---|---|\n"]
    for th, n in info["themes"].most_common(10): L.append(f"| {th} | {n} |\n")
    L.append("\n## Années citées\n\n| Année | Docs |\n|---|---|\n")
    for a, n in sorted(info["annees"].items(), key=lambda x: -x[1])[:10]:
        L.append(f"| {a} | {n} |\n")
    L.append("\n## Extraits\n\n")
    for e in info["extraits"][:5]: L.append(f"> {e}\n\n")
    (DOSSIER / f"{slug}.md").write_text("".join(L), encoding="utf-8")

print(f"   ✅ orateurs_profils.csv + {len(top)} fiches dans fiches_orateurs/")
PYEOF
python3 _tmp_orateurs.py

# ============================================================
# 4. LÉGISLATURES
# ============================================================
echo -e "\n${BLEU}[4/8] Comparaison par législature…${NC}"
cat > _tmp_legis.py <<'PYEOF'
import json, csv
from pathlib import Path
from collections import defaultdict, Counter

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
par_legis = defaultdict(lambda: {"docs": 0, "mentions": 0,
                                 "themes": Counter(), "orateurs": Counter(),
                                 "cri": 0, "qst": 0})
for d in data["results"]:
    parts = d["fichier"].split("_")
    if parts and parts[0].isdigit():
        leg = parts[0]
        par_legis[leg]["docs"] += 1
        par_legis[leg]["mentions"] += d["nb_mentions"]
        if "_cri_" in d["fichier"]: par_legis[leg]["cri"] += 1
        if "_qst_" in d["fichier"]: par_legis[leg]["qst"] += 1
        for th, n in d["themes"].items(): par_legis[leg]["themes"][th] += n
        for o in d["orateurs"]: par_legis[leg]["orateurs"][o["nom"]] += o["occurrences"]

with open("analyse_legislatures.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["legislature", "documents", "mentions", "cri", "qst",
                "theme_dominant", "orateur_dominant"])
    for leg in sorted(par_legis, key=int):
        v = par_legis[leg]
        th = v["themes"].most_common(1); ot = v["orateurs"].most_common(1)
        w.writerow([leg, v["docs"], v["mentions"], v["cri"], v["qst"],
                    th[0][0] if th else "", ot[0][0] if ot else ""])
print(f"   ✅ analyse_legislatures.csv ({len(par_legis)} législatures)")
PYEOF
python3 _tmp_legis.py

# ============================================================
# 5. SENTIMENT
# ============================================================
echo -e "\n${BLEU}[5/8] Analyse de sentiment…${NC}"
cat > _tmp_senti.py <<'PYEOF'
import json, csv, re
from pathlib import Path
from collections import defaultdict
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

POS = {"réussi","succès","fruits","efficace","utile","bien","progrès","amélioration",
       "développement","favorable","positif","avantage","excellent","bon",
       "satisfait","soutien","appuie","défend","protège","aide","améliore",
       "essentiel","nécessaire","indispensable","important","renforce"}
NEG = {"échec","problème","difficile","difficulté","crise","mauvais","insuffisant",
       "inadéquat","défaut","critique","dénonce","conteste","refuse","oppose",
       "scandale","honte","inadmissible","inacceptable","regrette","déplore",
       "faible","réduit","diminué","baisse","souffre","victime","discrimination",
       "racisme","exploitation","abus","désespoir","sinistre"}

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
par_annee = defaultdict(lambda: {"pos": 0, "neg": 0, "neutre": 0})
for d in data["results"]:
    m = re.search(r"(\d{4})", d["fichier"])
    annee = int(m.group(1)) if m else 1970
    for e in d["extraits"]:
        t = e["extrait"].lower()
        p = sum(1 for mot in POS if mot in t)
        n = sum(1 for mot in NEG if mot in t)
        if p > n: par_annee[annee]["pos"] += 1
        elif n > p: par_annee[annee]["neg"] += 1
        else: par_annee[annee]["neutre"] += 1

with open("analyse_sentiment.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["annee", "positifs", "negatifs", "neutres", "score"])
    for a in sorted(par_annee):
        v = par_annee[a]
        w.writerow([a, v["pos"], v["neg"], v["neutre"], v["pos"] - v["neg"]])

annees = sorted(par_annee)
scores = [par_annee[a]["pos"] - par_annee[a]["neg"] for a in annees]
colors = ["#1b7a2e" if s > 0 else "#E1000F" if s < 0 else "#888" for s in scores]

fig, ax = plt.subplots(figsize=(14, 6))
ax.bar(annees, scores, color=colors)
ax.axhline(0, color="#333", linewidth=1)
ax.set_xlabel("Année"); ax.set_ylabel("Score (positifs − négatifs)")
ax.set_title("Tonalité des débats BUMIDOM par année", fontsize=14)
plt.tight_layout(); plt.savefig("analyse_sentiment.png", dpi=100)
print(f"   ✅ analyse_sentiment.csv + .png")
PYEOF
python3 _tmp_senti.py

# ============================================================
# 6. RÉSEAU
# ============================================================
echo -e "\n${BLEU}[6/8] Réseau d'orateurs…${NC}"
cat > _tmp_reseau.py <<'PYEOF'
import json, csv
from pathlib import Path
from collections import defaultdict
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import networkx as nx

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
cooccur = defaultdict(int)
for d in data["results"]:
    noms = [o["nom"] for o in d["orateurs"][:15]]
    for i, n1 in enumerate(noms):
        for n2 in noms[i+1:]:
            cooccur[tuple(sorted([n1, n2]))] += 1

with open("analyse_reseau.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["orateur_1", "orateur_2", "cooccurrences"])
    for (a, b), n in sorted(cooccur.items(), key=lambda x: -x[1])[:100]:
        w.writerow([a, b, n])

G = nx.Graph()
for (a, b), n in cooccur.items():
    if n >= 3: G.add_edge(a, b, weight=n)

if len(G) > 0:
    plt.figure(figsize=(16, 12))
    pos = nx.spring_layout(G, k=0.5, iterations=50, seed=42)
    sizes = [G.degree(n) * 100 for n in G.nodes()]
    weights = [G[u][v]["weight"] for u, v in G.edges()]
    nx.draw_networkx_nodes(G, pos, node_size=sizes, node_color="#000091", alpha=0.7)
    nx.draw_networkx_labels(G, pos, font_size=8, font_color="white")
    nx.draw_networkx_edges(G, pos, width=[w/3 for w in weights],
                           alpha=0.4, edge_color="#E1000F")
    plt.title("Réseau des orateurs BUMIDOM", fontsize=14)
    plt.axis("off"); plt.tight_layout()
    plt.savefig("analyse_reseau.png", dpi=100, bbox_inches="tight")
    print(f"   ✅ analyse_reseau.csv + .png ({len(G)} orateurs, {len(G.edges())} liens)")
else:
    print("   ⚠️  Réseau trop faible (seuil 3 non atteint)")
PYEOF
python3 _tmp_reseau.py

# ============================================================
# 7. RAPPORT FINAL
# ============================================================
echo -e "\n${BLEU}[7/8] Rapport final Markdown…${NC}"
cat > _tmp_rapport.py <<'PYEOF'
import json, csv
from pathlib import Path
from datetime import datetime

def lire_csv(p):
    p = Path(p)
    if not p.exists(): return []
    with open(p, encoding="utf-8") as f:
        return list(csv.DictReader(f))

data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
docs = data["results"]
stats = data["statistiques_globales"]

chrono   = lire_csv("analyse_chrono.csv")
mots     = lire_csv("analyse_cooccurrences.csv")
orateurs = lire_csv("orateurs_profils.csv")
legis    = lire_csv("analyse_legislatures.csv")
senti    = lire_csv("analyse_sentiment.csv")

L = [
    "# Rapport final — BUMIDOM dans les débats parlementaires\n\n",
    f"*Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M')}*\n\n---\n\n",
    "## Synthèse générale\n\n",
    f"- **Documents analysés** : {len(docs)}\n",
    f"- **Mentions totales de « BUMIDOM »** : {sum(d['nb_mentions'] for d in docs)}\n",
    f"- **Orateurs uniques** : {len({o['nom'] for d in docs for o in d['orateurs']})}\n",
    f"- **Thèmes détectés** : {len(stats['themes'])}\n\n---\n\n",
    "## 1. Chronologie\n\n",
    "| Année | Documents | Mentions | CRI | QST |\n|---|---|---|---|---|\n",
]
for r in chrono:
    L.append(f"| {r['annee']} | {r['documents']} | {r['mentions']} | {r['comptes_rendus']} | {r['questions']} |\n")

L.append("\n---\n\n## 2. Top 30 mots associés\n\n| # | Mot | Occ. |\n|---|---|---|\n")
for i, r in enumerate(mots[:30], 1):
    L.append(f"| {i} | {r['mot']} | {r['occurrences']} |\n")

L.append("\n---\n\n## 3. Top orateurs\n\n| Orateur | Mentions | Docs | Thème 1 | Thème 2 |\n|---|---|---|---|---|\n")
for r in orateurs:
    L.append(f"| {r['orateur']} | {r['mentions']} | {r['nb_docs']} | "
             f"{r['theme_1']} ({r['score_1']}) | {r['theme_2']} ({r['score_2']}) |\n")

L.append("\n---\n\n## 4. Par législature\n\n| Lég. | Docs | Mentions | Thème dominant | Orateur dominant |\n|---|---|---|---|---|\n")
for r in legis:
    L.append(f"| {r['legislature']} | {r['documents']} | {r['mentions']} | "
             f"{r['theme_dominant']} | {r['orateur_dominant']} |\n")

L.append("\n---\n\n## 5. Tonalité par année\n\n| Année | + | − | = | Score |\n|---|---|---|---|---|\n")
for r in senti:
    L.append(f"| {r['annee']} | {r['positifs']} | {r['negatifs']} | {r['neutres']} | {r['score']} |\n")

L.append("\n---\n\n## 6. Thèmes globaux\n\n| Thème | Occurrences |\n|---|---|\n")
for th, n in stats["themes"]:
    L.append(f"| {th} | {n} |\n")

L.append("\n---\n\n## 7. Graphiques\n\n")
for png in ["analyse_chrono.png", "analyse_sentiment.png", "analyse_reseau.png"]:
    if Path(png).exists():
        L.append(f"### {png}\n\n![{png}]({png})\n\n")

L.append("\n---\n\n## 8. Ressources produites\n\n")
L.append("""- `analyse_chrono.csv` / `.png` — Évolution année par année
- `analyse_cooccurrences.csv` — Top 100 mots associés
- `orateurs_profils.csv` — Profil des 30 top orateurs
- `fiches_orateurs/*.md` — Une fiche par orateur
- `analyse_legislatures.csv` — Comparaison par législature
- `analyse_sentiment.csv` / `.png` — Tonalité par année
- `analyse_reseau.csv` / `.png` — Réseau de cooccurrence
- `bumidom.db` — Base SQLite

## 9. Pour aller plus loin

- Consulter `dashboard_enrichi.html` (dashboard interactif)
- Explorer `bumidom.db` avec DB Browser for SQLite
- Utiliser `corpus/` dans Obsidian pour analyse textuelle
- Consulter `fiches_orateurs/` pour des biographies
""")

Path("rapport_final.md").write_text("".join(L), encoding="utf-8")
print("   ✅ rapport_final.md")
PYEOF
python3 _tmp_rapport.py

# ============================================================
# 8. NETTOYAGE + RÉSUMÉ
# ============================================================
echo -e "\n${BLEU}[8/8] Nettoyage…${NC}"
rm -f _tmp_*.py
echo -e "${VERT}   ✅ Scripts temporaires supprimés${NC}"

echo -e "\n${VERT}══════════════════════════════════════════════════════════${NC}"
echo -e "${VERT}  ✅ ANALYSE TERMINÉE${NC}"
echo -e "${VERT}══════════════════════════════════════════════════════════${NC}\n"

echo -e "${BLEU}📦 CSV produits :${NC}"
for f in analyse_chrono.csv analyse_cooccurrences.csv orateurs_profils.csv \
         analyse_legislatures.csv analyse_sentiment.csv analyse_reseau.csv; do
    [[ -f "$f" ]] && echo "   $f ($(wc -l < "$f") lignes)"
done

echo -e "\n${BLEU}🖼️  Images PNG :${NC}"
for f in analyse_chrono.png analyse_sentiment.png analyse_reseau.png; do
    [[ -f "$f" ]] && echo "   $f ($(du -h "$f" | cut -f1))"
done

echo -e "\n${BLEU}📄 Rapport :${NC}"
[[ -f rapport_final.md ]] && echo "   rapport_final.md ($(wc -l < rapport_final.md) lignes)"

echo -e "\n${BLEU}📁 Fiches orateurs :${NC}"
[[ -d fiches_orateurs ]] && echo "   fiches_orateurs/ ($(ls fiches_orateurs | wc -l) fiches)"

echo -e "\n${BLEU}🌐 Pour visualiser :${NC}"
echo -e "   ${JAUNE}python3 -m http.server 8889${NC}"
echo -e "   puis ouvrir ${JAUNE}http://localhost:8889/dashboard_enrichi.html${NC}"
echo -e "   ou ${JAUNE}http://localhost:8889/timeline.html${NC}\n"