cd ~/Desktop/BUMIDOM

cat > expertise_all.sh <<'SH_EOF'
#!/usr/bin/env bash
# ============================================================
# expertise_all.sh — Pipeline d'expertise complète BUMIDOM
# Produit : CSV, fiches thématiques, analyses comparatives, rapport, Excel
# ============================================================
set -euo pipefail

BLEU='\033[0;34m'; ROUGE='\033[0;31m'; VERT='\033[0;32m'
JAUNE='\033[1;33m'; NC='\033[0m'

echo -e "${BLEU}"
cat <<'BANNER'
╔══════════════════════════════════════════════════════════╗
║   EXPERTISE COMPLÈTE BUMIDOM                             ║
║   Chiffres · Thèmes · Comparaisons · Recherches · Excel  ║
╚══════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

cd "$(dirname "$0")"

# Venv
[[ -d ".venv" ]] && source .venv/bin/activate

# Deps
python3 -c "import pandas" 2>/dev/null || pip install --quiet pandas
python3 -c "import openpyxl" 2>/dev/null || pip install --quiet openpyxl

echo -e "${VERT}✅ Dépendances prêtes${NC}\n"

# ============================================================
# ÉTAPE 1 — EXTRACTION DES CHIFFRES BRUTS
# ============================================================
echo -e "${BLEU}[1/6] Extraction des chiffres bruts…${NC}"

cat > _expertise_extract.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re, json, csv, unicodedata
from pathlib import Path
from collections import Counter, defaultdict

DOSSIER_TXT = Path("textes")
SORTIE_DIR  = Path("expertise")
SORTIE_DIR.mkdir(exist_ok=True)

MOIS = r"(janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre)"
RE_DATE_LONGUE = re.compile(rf"\b(\d{{1,2}})\s+{MOIS}\s+(\d{{4}})\b", re.IGNORECASE)
RE_DATE_ISO    = re.compile(r"\b(\d{4})-(\d{2})-(\d{2})\b")
RE_DATE_COURTE = re.compile(r"\b(\d{1,2})[./-](\d{1,2})[./-](\d{4})\b")

RE_NOMBRE = re.compile(
    r"\b(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,7}(?:,\d+)?)\s*"
    r"(habitants?|personnes?|migrants?|travailleurs?|Réunionnais|Antillais|"
    r"francs?|F|%|pour\s*cent)?", re.IGNORECASE)

RE_POURCENTAGE = re.compile(r"\b(\d{1,3}(?:[.,]\d+)?)\s*(?:%|pour\s*cent|p\.\s*100)", re.IGNORECASE)
RE_FRANC = re.compile(r"\b(\d{1,3}(?:[\s\u00a0]\d{3})*(?:[.,]\d+)?)\s*(francs?|F|NF|nouveaux\s+francs?)", re.IGNORECASE)
RE_LOGEMENT = re.compile(r"\b(\d{1,4})\s*(logements?|lits?|foyers?|chambres?|places?)", re.IGNORECASE)
RE_ARTICLE = re.compile(r"\barticle\s+(\d+[a-z]?)\b", re.IGNORECASE)

INSTITUTIONS = ["BUMIDOM","B.U.M.I.D.O.M","Bumidom","A.N.T.","ANT","CASADOM","C.A.S.A.D.O.M",
                "FIDOM","F.I.D.O.M","C.A.E.C.L","S.M.I.C","A.N.P.E","I.N.S.E.E"]
RE_INSTITUTION = re.compile(r"\b(" + "|".join(re.escape(i) for i in INSTITUTIONS) + r")\b", re.IGNORECASE)

LIEUX = ["Réunion","La Réunion","Guadeloupe","Martinique","Guyane","Antilles","DOM","D.O.M.",
         "métropole","Paris","Marseille","Lyon","Bordeaux","Nantes","Fort-de-France",
         "Pointe-à-Pitre","Cayenne","Saint-Denis","Afrique","Madagascar","Maurice","Haïti",
         "Simandes","Rush del Campo"]
RE_LIEU = re.compile(r"\b(" + "|".join(re.escape(l) for l in LIEUX) + r")\b", re.IGNORECASE)

RE_ORATEUR = re.compile(r"\b(M\.|MM\.|Mme|Mmes|Mlle)\s+"
                        r"([A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç\-']+(?:[-\s][A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç\-']+)*)")

def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()

def nettoyer_nombre(s):
    s = re.sub(r"[\s\u00a0]", "", s)
    s = s.replace(".", "").replace(",", ".")
    try: return float(s)
    except: return None

def contexte(texte, index, taille=250):
    deb = max(0, index - taille); fin = min(len(texte), index + taille)
    return re.sub(r"\s+", " ", texte[deb:fin].replace("\n", " ")).strip()

def extraire(texte):
    return {
        "montants": [{"valeur": nettoyer_nombre(m.group(1)), "unite": m.group(2),
                      "contexte": contexte(texte, m.start())}
                     for m in RE_FRANC.finditer(texte)
                     if nettoyer_nombre(m.group(1)) and nettoyer_nombre(m.group(1)) >= 100],
        "effectifs": [{"valeur": int(nettoyer_nombre(m.group(1))), "unite": (m.group(2) or "").strip(),
                       "contexte": contexte(texte, m.start())}
                      for m in RE_NOMBRE.finditer(texte)
                      if nettoyer_nombre(m.group(1)) and nettoyer_nombre(m.group(1)) >= 10
                      and (m.group(2) or "").lower() in {"habitants","habitants","personnes","migrants",
                                                          "travailleurs","réunionnais","antillais",
                                                          "logements","lits","foyers","chambres","places"}],
        "pourcentages": [{"valeur": m.group(1).replace(",","."), "contexte": contexte(texte, m.start())}
                         for m in RE_POURCENTAGE.finditer(texte)],
        "logements": [{"valeur": int(m.group(1)), "unite": m.group(2),
                       "contexte": contexte(texte, m.start(), 150)}
                      for m in RE_LOGEMENT.finditer(texte)],
        "dates": [{"date": f"{m.group(1)} {m.group(2)} {m.group(3)}", "annee": int(m.group(3))}
                  for m in RE_DATE_LONGUE.finditer(texte)] +
                 [{"date": f"{m.group(3)}/{m.group(2)}/{m.group(1)}", "annee": int(m.group(1))}
                  for m in RE_DATE_ISO.finditer(texte)] +
                 [{"date": f"{m.group(1)}/{m.group(2)}/{m.group(3)}", "annee": int(m.group(3))}
                  for m in RE_DATE_COURTE.finditer(texte)],
        "institutions": dict(Counter(m.group(0).upper() for m in RE_INSTITUTION.finditer(texte))),
        "lieux": dict(Counter(m.group(0) for m in RE_LIEU.finditer(texte))),
        "articles": sorted(set(RE_ARTICLE.findall(texte))),
        "orateurs": dict(Counter(f"{m.group(1)} {m.group(2).strip()}"
                                 for m in RE_ORATEUR.finditer(texte)
                                 if len(m.group(2).strip()) >= 4
                                 and len(m.group(2).split()) >= 2
                                 and not m.group(2).isupper())),
    }

def annee_fichier(f):
    m = re.search(r"(\d{4})-\d{2}-\d{2}", f) or re.search(r"(\d{4})-(\d{4})", f)
    return int(m.group(1)) if m else None

print(f"📄 Analyse de {len(list(DOSSIER_TXT.glob('*.txt')))} fichiers…\n")

docs = []
for f in sorted(DOSSIER_TXT.glob("*.txt")):
    texte = f.read_text(encoding="utf-8", errors="ignore")
    if normaliser("bumidom") not in normaliser(texte): continue
    r = extraire(texte)
    r["fichier"] = f.name
    r["annee"] = annee_fichier(f.name)
    r["legislature"] = f.name.split("_")[0] if f.name.split("_")[0].isdigit() else "?"
    r["type"] = "CRI" if "_cri_" in f.name else "QST" if "_qst_" in f.name else "TAB"
    docs.append(r)

print(f"✅ {len(docs)} documents traités\n")

# ============================================================
# ÉCRITURE DES CSV
# ============================================================
def dump_csv(nom, colonnes, lignes):
    with open(SORTIE_DIR / nom, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(colonnes)
        w.writerows(lignes)

# 01 Montants
tous_montants = sorted([
    (d["fichier"], d["annee"], int(m["valeur"]), m["unite"], m["contexte"])
    for d in docs for m in d["montants"]
], key=lambda x: -x[2])
dump_csv("01_montants.csv", ["fichier","annee","valeur_francs","unite","contexte"], tous_montants)

# 02 Effectifs
tous_eff = sorted([
    (d["fichier"], d["annee"], e["valeur"], e["unite"], e["contexte"])
    for d in docs for e in d["effectifs"]
], key=lambda x: -x[2])
dump_csv("02_effectifs.csv", ["fichier","annee","nombre","unite","contexte"], tous_eff)

# 03 Pourcentages
tous_pct = [(d["fichier"], d["annee"], p["valeur"], p["contexte"])
            for d in docs for p in d["pourcentages"]]
dump_csv("03_pourcentages.csv", ["fichier","annee","pourcentage","contexte"], tous_pct)

# 04 Logements
tous_log = sorted([(d["fichier"], d["annee"], l["valeur"], l["unite"], l["contexte"])
                   for d in docs for l in d["logements"]], key=lambda x: -x[2])
dump_csv("04_logements.csv", ["fichier","annee","nombre","type","contexte"], tous_log)

# 05 Institutions
toutes_inst = Counter()
for d in docs:
    for k, n in d["institutions"].items(): toutes_inst[k] += n
dump_csv("05_institutions.csv", ["institution","mentions"],
         [[k, v] for k, v in toutes_inst.most_common()])

# 06 Lieux
tous_lieux = Counter()
for d in docs:
    for k, n in d["lieux"].items(): tous_lieux[k] += n
dump_csv("06_lieux.csv", ["lieu","mentions"], [[k, v] for k, v in tous_lieux.most_common()])

# 07 Articles
tous_art = Counter()
for d in docs:
    for a in d["articles"]: tous_art[a] += 1
dump_csv("07_articles_loi.csv", ["article","mentions"],
         sorted(tous_art.items(), key=lambda x: -x[1]))

# 08 Dates
toutes_dates = Counter()
for d in docs:
    for dt in d["dates"]: toutes_dates[dt["date"]] += 1
dump_csv("08_dates.csv", ["date","mentions"], [[k, v] for k, v in toutes_dates.most_common()])

# JSON global
json_global = {
    "total_documents": len(docs),
    "total_montants": len(tous_montants),
    "total_effectifs": len(tous_eff),
    "total_pourcentages": len(tous_pct),
    "total_logements": len(tous_log),
    "montant_max": max((m[2] for m in tous_montants), default=0),
    "effectif_max": max((e[2] for e in tous_eff), default=0),
    "top_institutions": toutes_inst.most_common(20),
    "top_lieux": tous_lieux.most_common(20),
    "top_dates": toutes_dates.most_common(20),
    "par_annee": {},
}
for d in docs:
    if d["annee"]:
        json_global["par_annee"].setdefault(str(d["annee"]), {"docs":0,"montants":0,"effectifs":0})
        json_global["par_annee"][str(d["annee"])]["docs"] += 1
        json_global["par_annee"][str(d["annee"])]["montants"] += len(d["montants"])
        json_global["par_annee"][str(d["annee"])]["effectifs"] += len(d["effectifs"])

(SORTIE_DIR / "00_global.json").write_text(json.dumps(json_global, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"📊 {len(tous_montants):>4} montants     → 01_montants.csv")
print(f"📊 {len(tous_eff):>4} effectifs     → 02_effectifs.csv")
print(f"📊 {len(tous_pct):>4} pourcentages  → 03_pourcentages.csv")
print(f"📊 {len(tous_log):>4} logements     → 04_logements.csv")
print(f"📊 {len(toutes_inst):>4} institutions → 05_institutions.csv")
print(f"📊 {len(tous_lieux):>4} lieux         → 06_lieux.csv")

# Sauvegarde intermédiaire pour les étapes suivantes
(SORTIE_DIR / "_docs.json").write_text(json.dumps(docs, ensure_ascii=False), encoding="utf-8")
PYEOF

python3 _expertise_extract.py

# ============================================================
# ÉTAPE 2 — TABLEAU DE SYNTHÈSE ANNUELLE
# ============================================================
echo -e "\n${BLEU}[2/6] Tableau de synthèse annuelle…${NC}"

cat > _expertise_synthese.py <<'PYEOF'
#!/usr/bin/env python3
import json, csv
from pathlib import Path
from collections import defaultdict

SORTIE = Path("expertise")
docs = json.loads((SORTIE / "_docs.json").read_text(encoding="utf-8"))

par_annee = defaultdict(lambda: {
    "docs": 0, "cri": 0, "qst": 0,
    "mentions_bumidom": 0,
    "montants": 0, "montant_total": 0, "montant_max": 0,
    "effectifs": 0, "effectif_total": 0, "effectif_max": 0,
    "pourcentages": 0, "logements": 0,
})

for d in docs:
    if not d["annee"]: continue
    a = d["annee"]
    par_annee[a]["docs"] += 1
    if d["type"] == "CRI": par_annee[a]["cri"] += 1
    if d["type"] == "QST": par_annee[a]["qst"] += 1
    par_annee[a]["mentions_bumidom"] += len([1])  # placeholder
    par_annee[a]["montants"] += len(d["montants"])
    par_annee[a]["montant_total"] += sum(m["valeur"] for m in d["montants"])
    if d["montants"]:
        par_annee[a]["montant_max"] = max(par_annee[a]["montant_max"],
                                           max(m["valeur"] for m in d["montants"]))
    par_annee[a]["effectifs"] += len(d["effectifs"])
    par_annee[a]["effectif_total"] += sum(e["valeur"] for e in d["effectifs"])
    if d["effectifs"]:
        par_annee[a]["effectif_max"] = max(par_annee[a]["effectif_max"],
                                            max(e["valeur"] for e in d["effectifs"]))
    par_annee[a]["pourcentages"] += len(d["pourcentages"])
    par_annee[a]["logements"] += len(d["logements"])

with open(SORTIE / "TABLEAU_SYNTHESE.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f, delimiter=";")
    w.writerow(["annee","documents","cri","qst","montants","montant_total_francs",
                "montant_max_francs","effectifs","effectif_total","effectif_max",
                "pourcentages","logements"])
    for annee in sorted(par_annee):
        v = par_annee[annee]
        w.writerow([annee, v["docs"], v["cri"], v["qst"],
                    v["montants"], int(v["montant_total"]), int(v["montant_max"]),
                    v["effectifs"], v["effectif_total"], v["effectif_max"],
                    v["pourcentages"], v["logements"]])

print(f"✅ TABLEAU_SYNTHESE.csv ({len(par_annee)} années)")
PYEOF

python3 _expertise_synthese.py

# ============================================================
# ÉTAPE 3 — FICHES THÉMATIQUES
# ============================================================
echo -e "\n${BLEU}[3/6] Fiches thématiques…${NC}"

cat > _expertise_fiches.py <<'PYEOF'
#!/usr/bin/env python3
import json, re
from pathlib import Path
from collections import defaultdict

SORTIE = Path("expertise")
FICHES = SORTIE / "FICHES_THEMATIQUES"
FICHES.mkdir(exist_ok=True)

docs = json.loads((SORTIE / "_docs.json").read_text(encoding="utf-8"))

THEMES = {
    "budget_financement": ["budget","crédit","subvention","financement","dépense","franc"],
    "migration_flux":     ["migration","migrant","immigration","départ","expatriation"],
    "emploi_formation":   ["emploi","travail","placement","formation","stage","apprentissage"],
    "logement":           ["logement","foyer","hébergement","lit"],
    "transport_tarifs":   ["transport","tarif","billet","voyage","aérien"],
    "conditions_sociales":["salaire","rémunération","SMIC","protection","sécurité"],
    "discrimination":     ["racisme","discrimination","exploitation","injustice"],
    "reunion_antilles":   ["Réunion","Réunionnais","Antilles","Guadeloupe","Martinique","Guyane"],
}

for theme, mots in THEMES.items():
    extraits = []
    for d in docs:
        for m in d["montants"] + d["effectifs"] + d["logements"]:
            ctx = m.get("contexte", "").lower()
            if any(mot.lower() in ctx for mot in mots):
                extraits.append({
                    "fichier": d["fichier"],
                    "annee": d["annee"],
                    "type": m.get("unite", m.get("type", "chiffre")),
                    "valeur": m.get("valeur", m.get("nombre")),
                    "contexte": m.get("contexte", ""),
                })
        for p in d["pourcentages"]:
            if any(mot.lower() in p["contexte"].lower() for mot in mots):
                extraits.append({
                    "fichier": d["fichier"], "annee": d["annee"],
                    "type": "%", "valeur": p["valeur"],
                    "contexte": p["contexte"],
                })

    L = [f"# Fiche thématique : {theme.replace('_',' ').title()}\n\n",
         f"**Nombre de données extraites** : {len(extraits)}\n\n---\n\n"]

    # Résumé par année
    par_annee = defaultdict(int)
    for e in extraits:
        if e["annee"]: par_annee[e["annee"]] += 1
    if par_annee:
        L.append("## Répartition par année\n\n| Année | Données |\n|---|---|\n")
        for a in sorted(par_annee):
            L.append(f"| {a} | {par_annee[a]} |\n")
        L.append("\n---\n\n")

    # Chiffres clés (valeur maximale)
    if extraits:
        try:
            top = sorted(extraits, key=lambda x: float(str(x["valeur"]).replace(",",".")), reverse=True)[:10]
            L.append("## Top 10 valeurs\n\n| Fichier | Année | Valeur | Contexte |\n|---|---|---|---|\n")
            for e in top:
                ctx = e["contexte"][:150].replace("|", " ")
                L.append(f"| {e['fichier']} | {e['annee']} | {e['valeur']} | {ctx}... |\n")
            L.append("\n---\n\n")
        except: pass

    L.append("## Tous les extraits\n\n")
    for e in extraits[:50]:
        L.append(f"### {e['fichier']} ({e['annee']})\n\n")
        L.append(f"**Valeur** : {e['valeur']} {e['type']}\n\n")
        L.append(f"> {e['contexte'][:500]}\n\n---\n\n")

    (FICHES / f"{theme}.md").write_text("".join(L), encoding="utf-8")
    print(f"  📄 {theme}.md ({len(extraits)} données)")

print(f"✅ Fiches dans {FICHES}/")
PYEOF

python3 _expertise_fiches.py

# ============================================================
# ÉTAPE 4 — ANALYSE COMPARATIVE
# ============================================================
echo -e "\n${BLEU}[4/6] Analyse comparative par législature…${NC}"

cat > _expertise_comparative.py <<'PYEOF'
#!/usr/bin/env python3
import json
from pathlib import Path
from collections import defaultdict

SORTIE = Path("expertise")
docs = json.loads((SORTIE / "_docs.json").read_text(encoding="utf-8"))

par_legis = defaultdict(lambda: {
    "docs": 0, "cri": 0, "qst": 0,
    "montants": [], "effectifs": [],
    "institutions": defaultdict(int), "lieux": defaultdict(int),
})

for d in docs:
    leg = d["legislature"]
    if leg == "?": continue
    par_legis[leg]["docs"] += 1
    if d["type"] == "CRI": par_legis[leg]["cri"] += 1
    if d["type"] == "QST": par_legis[leg]["qst"] += 1
    par_legis[leg]["montants"].extend([m["valeur"] for m in d["montants"]])
    par_legis[leg]["effectifs"].extend([e["valeur"] for e in d["effectifs"]])
    for k, n in d["institutions"].items(): par_legis[leg]["institutions"][k] += n
    for k, n in d["lieux"].items(): par_legis[leg]["lieux"][k] += n

L = ["# Analyse comparative par législature\n\n",
     "*Comparaison des données chiffrées entre les législatures*\n\n---\n\n"]

for leg in sorted(par_legis, key=int):
    v = par_legis[leg]
    L.append(f"## Législature {leg}\n\n")
    L.append(f"- Documents : **{v['docs']}** ({v['cri']} CRI, {v['qst']} QST)\n")
    L.append(f"- Montants cités : **{len(v['montants'])}**\n")
    if v['montants']:
        L.append(f"  - Total : {int(sum(v['montants'])):,} francs\n".replace(",", " "))
        L.append(f"  - Maximum : {int(max(v['montants'])):,} francs\n".replace(",", " "))
        L.append(f"  - Moyenne : {int(sum(v['montants'])/len(v['montants'])):,} francs\n".replace(",", " "))
    L.append(f"- Effectifs cités : **{len(v['effectifs'])}**\n")
    if v['effectifs']:
        L.append(f"  - Total : {sum(v['effectifs'])} personnes\n")
        L.append(f"  - Maximum : {max(v['effectifs'])} personnes\n")
    L.append("\n**Top 5 institutions** :\n\n")
    for k, n in sorted(v["institutions"].items(), key=lambda x: -x[1])[:5]:
        L.append(f"- {k} : {n}\n")
    L.append("\n**Top 5 lieux** :\n\n")
    for k, n in sorted(v["lieux"].items(), key=lambda x: -x[1])[:5]:
        L.append(f"- {k} : {n}\n")
    L.append("\n---\n\n")

(SORTIE / "ANALYSE_COMPARATIVE.md").write_text("".join(L), encoding="utf-8")
print(f"✅ ANALYSE_COMPARATIVE.md")
PYEOF

python3 _expertise_comparative.py

# ============================================================
# ÉTAPE 5 — RECHERCHES CIBLÉES
# ============================================================
echo -e "\n${BLEU}[5/6] Recherches ciblées…${NC}"

cat > _expertise_recherches.py <<'PYEOF'
#!/usr/bin/env python3
import re, unicodedata
from pathlib import Path
from collections import Counter

SORTIE = Path("expertise/RECHERCHE_CIBLEE")
SORTIE.mkdir(parents=True, exist_ok=True)
DOSSIER_TXT = Path("textes")

RECHERCHES = {
    "chiffres_cles":     r"\b(\d{1,3}(?:[\s\u00a0]\d{3})+|\d{4,7})\b",
    "mots_bumidom":      r"\bB\.?U\.?M\.?I\.?D\.?O\.?M\.?\b",
    "dates_precises":    r"\b\d{1,2}\s+(?:janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre)\s+\d{4}\b",
    "articles_loi":      r"\barticle\s+\d+[a-z]?\b",
    "montants_francs":   r"\b\d{1,3}(?:[\s\u00a0]\d{3})+(?:,\d+)?\s*francs?\b",
    "pourcentages":      r"\b\d{1,3}(?:[.,]\d+)?\s*(?:%|pour\s*cent|p\.\s*100)",
    "noms_deputes":      r"\bM\.\s+[A-ZÉÈÀ][a-zéèêëàâîïôûç]+\s+[A-ZÉÈÀ][a-zéèêëàâîïôûç]+",
    "lieux_DOM":         r"\b(?:Réunion|Guadeloupe|Martinique|Guyane|Antilles)\b",
    "institutions":      r"\b(?:BUMIDOM|Bumidom|CASADOM|Casadom|A\.?N\.?T\.?|FIDOM|SMIC|ANPE)\b",
}

def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()

def contexte(texte, i, taille=200):
    deb = max(0, i - taille); fin = min(len(texte), i + taille)
    return re.sub(r"\s+", " ", texte[deb:fin].replace("\n", " ")).strip()

# Parcourt tous les fichiers
textes = {}
for f in sorted(DOSSIER_TXT.glob("*.txt")):
    t = f.read_text(encoding="utf-8", errors="ignore")
    if normaliser("bumidom") in normaliser(t):
        textes[f.name] = t

print(f"  📄 {len(textes)} fichiers à scanner")

for nom, pattern in RECHERCHES.items():
    regex = re.compile(pattern, re.IGNORECASE)
    lignes = []
    for fichier, texte in textes.items():
        for m in regex.finditer(texte):
            lignes.append({
                "fichier": fichier,
                "match": m.group(0),
                "contexte": contexte(texte, m.start()),
            })
    # Déduplique
    vus = set()
    uniques = []
    for l in lignes:
        cle = (l["fichier"], l["match"])
        if cle not in vus:
            vus.add(cle)
            uniques.append(l)

    with open(SORTIE / f"{nom}.md", "w", encoding="utf-8") as f:
        f.write(f"# Recherche ciblée : {nom}\n\n")
        f.write(f"**Total** : {len(uniques)} résultats\n\n---\n\n")
        for i, l in enumerate(uniques[:100], 1):
            f.write(f"## {i}. {l['match']}\n\n")
            f.write(f"**Fichier** : `{l['fichier']}`\n\n")
            f.write(f"> {l['contexte']}\n\n---\n\n")

    print(f"  📄 {nom}.md ({len(uniques)} résultats)")

print(f"✅ Recherches dans {SORTIE}/")
PYEOF

python3 _expertise_recherches.py

# ============================================================
# ÉTAPE 6 — RAPPORT EXPERTISE COMPLET
# ============================================================
echo -e "\n${BLEU}[6/6] Rapport d'expertise complet…${NC}"

cat > _expertise_rapport.py <<'PYEOF'
#!/usr/bin/env python3
import json, csv
from pathlib import Path
from datetime import datetime

SORTIE = Path("expertise")

def lire_csv(nom):
    p = SORTIE / nom
    if not p.exists(): return []
    with open(p, encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter=";"))

global_stats = json.loads((SORTIE / "00_global.json").read_text(encoding="utf-8"))
synthese = lire_csv("TABLEAU_SYNTHESE.csv")
montants = lire_csv("01_montants.csv")
effectifs = lire_csv("02_effectifs.csv")
pourcentages = lire_csv("03_pourcentages.csv")
logements = lire_csv("04_logements.csv")
institutions = lire_csv("05_institutions.csv")
lieux = lire_csv("06_lieux.csv")
articles = lire_csv("07_articles_loi.csv")
dates = lire_csv("08_dates.csv")

L = [
    "# Rapport d'expertise — BUMIDOM\n\n",
    f"*Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M')}*\n\n",
    "## Synthèse chiffrée\n\n",
    f"- **Documents analysés** : {global_stats['total_documents']}\n",
    f"- **Montants extraits** : {global_stats['total_montants']}\n",
    f"- **Effectifs extraits** : {global_stats['total_effectifs']}\n",
    f"- **Pourcentages extraits** : {global_stats['total_pourcentages']}\n",
    f"- **Logements mentionnés** : {global_stats['total_logements']}\n",
    f"- **Montant maximum cité** : {int(global_stats['montant_max']):,} francs\n".replace(",", " "),
    f"- **Effectif maximum cité** : {global_stats['effectif_max']} personnes\n\n",
    "---\n\n## 1. Évolution chronologique\n\n",
    "| Année | Docs | CRI | QST | Montants | Total francs | Effectifs | Personnes |\n",
    "|---|---|---|---|---|---|---|---|\n",
]
for r in synthese:
    L.append(f"| {r['annee']} | {r['documents']} | {r['cri']} | {r['qst']} | "
             f"{r['montants']} | {r['montant_total_francs']} | "
             f"{r['effectifs']} | {r['effectif_total']} |\n")

L.append("\n---\n\n## 2. Top 30 montants cités\n\n")
L.append("| Rang | Montant (francs) | Année | Fichier |\n|---|---|---|---|\n")
for i, m in enumerate(montants[:30], 1):
    try:
        v = int(m["valeur_francs"])
        L.append(f"| {i} | {v:,} | {m['annee']} | {m['fichier']} |\n".replace(",", " "))
    except: pass

L.append("\n---\n\n## 3. Top 30 effectifs cités\n\n")
L.append("| Rang | Nombre | Unité | Année | Fichier |\n|---|---|---|---|---|\n")
for i, e in enumerate(effectifs[:30], 1):
    L.append(f"| {i} | {e['nombre']} | {e['unite']} | {e['annee']} | {e['fichier']} |\n")

L.append("\n---\n\n## 4. Institutions\n\n")
L.append("| Institution | Mentions |\n|---|---|\n")
for inst in institutions[:20]:
    L.append(f"| {inst['institution']} | {inst['mentions']} |\n")

L.append("\n---\n\n## 5. Lieux\n\n")
L.append("| Lieu | Mentions |\n|---|---|\n")
for l in lieux[:20]:
    L.append(f"| {l['lieu']} | {l['mentions']} |\n")

L.append("\n---\n\n## 6. Pourcentages (top 30)\n\n")
L.append("| % | Année | Fichier |\n|---|---|---|\n")
for p in pourcentages[:30]:
    L.append(f"| {p['pourcentage']} | {p['annee']} | {p['fichier']} |\n")

L.append("\n---\n\n## 7. Logements (top 20)\n\n")
L.append("| Nombre | Type | Année | Fichier |\n|---|---|---|---|\n")
for l in logements[:20]:
    L.append(f"| {l['nombre']} | {l['type']} | {l['annee']} | {l['fichier']} |\n")

L.append("\n---\n\n## 8. Articles de loi cités\n\n")
L.append("| Article | Mentions |\n|---|---|\n")
for a in articles[:20]:
    L.append(f"| {a['article']} | {a['mentions']} |\n")

L.append("\n---\n\n## 9. Dates les plus citées\n\n")
L.append("| Date | Mentions |\n|---|---|\n")
for d in dates[:20]:
    L.append(f"| {d['date']} | {d['mentions']} |\n")

L.append("\n---\n\n## 10. Annexes\n\n")
L.append("- `01_montants.csv` : tous les montants en francs\n")
L.append("- `02_effectifs.csv` : tous les effectifs (personnes)\n")
L.append("- `03_pourcentages.csv` : tous les pourcentages\n")
L.append("- `04_logements.csv` : logements, lits, foyers\n")
L.append("- `05_institutions.csv` : BUMIDOM, ANT, CASADOM...\n")
L.append("- `06_lieux.csv` : Réunion, Paris, Antilles...\n")
L.append("- `07_articles_loi.csv` : articles de loi cités\n")
L.append("- `08_dates.csv` : dates précises citées\n")
L.append("- `TABLEAU_SYNTHESE.csv` : tableau croisé annuel\n")
L.append("- `ANALYSE_COMPARATIVE.md` : comparaison entre législatures\n")
L.append("- `FICHES_THEMATIQUES/` : 8 fiches par thème\n")
L.append("- `RECHERCHE_CIBLEE/` : 9 recherches pré-remplies\n")

(SORTIE / "RAPPORT_EXPERTISE.md").write_text("".join(L), encoding="utf-8")
print(f"✅ RAPPORT_EXPERTISE.md")

# ============================================================
# EXCEL (si openpyxl installé)
# ============================================================
try:
    import pandas as pd
    excel_path = SORTIE / "DONNEES_EXPERTISE.xlsx"
    with pd.ExcelWriter(excel_path, engine='openpyxl') as writer:
        pd.DataFrame(synthese).to_excel(writer, sheet_name="Synthese", index=False)
        pd.DataFrame(montants).to_excel(writer, sheet_name="Montants", index=False)
        pd.DataFrame(effectifs).to_excel(writer, sheet_name="Effectifs", index=False)
        pd.DataFrame(pourcentages).to_excel(writer, sheet_name="Pourcentages", index=False)
        pd.DataFrame(logements).to_excel(writer, sheet_name="Logements", index=False)
        pd.DataFrame(institutions).to_excel(writer, sheet_name="Institutions", index=False)
        pd.DataFrame(lieux).to_excel(writer, sheet_name="Lieux", index=False)
        pd.DataFrame(articles).to_excel(writer, sheet_name="Articles_loi", index=False)
        pd.DataFrame(dates).to_excel(writer, sheet_name="Dates", index=False)
    print(f"✅ DONNEES_EXPERTISE.xlsx (9 onglets)")
except Exception as e:
    print(f"⚠️  Excel non généré : {e}")
PYEOF

python3 _expertise_rapport.py

# Nettoyage
rm -f _expertise_*.py

# Résumé
echo -e "\n${VERT}══════════════════════════════════════════════════════════${NC}"
echo -e "${VERT}  ✅ EXPERTISE TERMINÉE${NC}"
echo -e "${VERT}══════════════════════════════════════════════════════════${NC}\n"

echo -e "${BLEU}📁 Dossier produit : expertise/${NC}\n"
ls -la expertise/ 2>/dev/null | grep -v "^total" | awk 'NR>2 {print "   "$9" ("$5" octets)"}'
[ -d expertise/FICHES_THEMATIQUES ] && echo "   📂 FICHES_THEMATIQUES/ ($(ls expertise/FICHES_THEMATIQUES | wc -l) fichiers)"
[ -d expertise/RECHERCHE_CIBLEE ] && echo "   📂 RECHERCHE_CIBLEE/ ($(ls expertise/RECHERCHE_CIBLEE | wc -l) fichiers)"

echo -e "\n${BLEU}📊 Aperçu :${NC}"
for csv_file in expertise/01_montants.csv expertise/02_effectifs.csv expertise/TABLEAU_SYNTHESE.csv; do
    [[ -f "$csv_file" ]] && echo "   $(basename $csv_file) : $(wc -l < $csv_file) lignes"
done

echo -e "\n${BLEU}🎯 Pour explorer :${NC}"
echo -e "   ${JAUNE}less expertise/RAPPORT_EXPERTISE.md${NC}"
echo -e "   ${JAUNE}libreoffice expertise/DONNEES_EXPERTISE.xlsx${NC} (si installé)"
echo -e "   ${JAUNE}ls expertise/FICHES_THEMATIQUES/${NC}\n"
SH_EOF

chmod +x expertise_all.sh