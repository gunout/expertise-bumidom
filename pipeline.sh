#!/usr/bin/env bash
# ============================================================
# run_all.sh — Pipeline complet BUMIDOM
# Auteur : généré automatiquement
# Usage  : ./run_all.sh
# ============================================================
set -euo pipefail

# ---------- Couleurs ----------
BLEU='\033[0;34m'
ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[1;33m'
GRIS='\033[0;90m'
NC='\033[0m'

# ---------- Bannière ----------
echo -e "${BLEU}"
cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║   PIPELINE BUMIDOM — Archives Assemblée nationale       ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ---------- Se placer dans le dossier du script ----------
cd "$(dirname "$0")"
DOSSIER="$(pwd)"
echo -e "${GRIS}Dossier de travail : $DOSSIER${NC}\n"

# ---------- Vérifications ----------
verifier_fichier() {
    if [[ ! -f "$1" ]]; then
        echo -e "${ROUGE}❌ Fichier manquant : $1${NC}"
        exit 1
    fi
}

verifier_dossier() {
    if [[ ! -d "$1" ]]; then
        echo -e "${ROUGE}❌ Dossier manquant : $1${NC}"
        exit 1
    fi
}

# ---------- Détection du fichier d'URLs ----------
FICHIER_URLS=""
for f in urls_bumidom.txt urls.txt; do
    [[ -f "$f" ]] && FICHIER_URLS="$f" && break
done
if [[ -z "$FICHIER_URLS" ]]; then
    # Cherche n'importe quel .txt contenant le bon domaine
    for f in *.txt; do
        if grep -q "archives.assemblee-nationale.fr" "$f" 2>/dev/null; then
            FICHIER_URLS="$f"
            break
        fi
    done
fi

if [[ -z "$FICHIER_URLS" ]]; then
    echo -e "${ROUGE}❌ Aucun fichier d'URLs trouvé (.txt contenant 'archives.assemblee-nationale.fr')${NC}"
    exit 1
fi
echo -e "${VERT}📄 Fichier d'URLs : $FICHIER_URLS${NC}"

# ============================================================
# ÉTAPE 0 — Installation des dépendances Python
# ============================================================
echo -e "\n${BLEU}[0/6] Vérification des dépendances Python…${NC}"

installer_si_besoin() {
    local pkg="$1"
    local import_name="${2:-$1}"
    if ! python3 -c "import $import_name" 2>/dev/null; then
        echo -e "${JAUNE}   → Installation de $pkg…${NC}"
        pip install --quiet "$pkg"
    fi
}

installer_si_besoin "pymupdf"    "fitz"
installer_si_besoin "pdfplumber" "pdfplumber"
installer_si_besoin "requests"
installer_si_besoin "tqdm"
installer_si_besoin "certifi"

# ============================================================
# ÉTAPE 1 — Téléchargement + extraction PDF
# ============================================================
echo -e "\n${BLEU}[1/6] Téléchargement des PDF et extraction texte…${NC}"

cat > _etape1_scraper.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, json, time, subprocess, unicodedata
from pathlib import Path
from urllib.parse import urlparse
import requests, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from tqdm import tqdm

try:
    import pymupdf as fitz
except ImportError:
    try:
        import fitz
    except ImportError:
        fitz = None
        import pdfplumber

# --- Trouve le fichier d'URLs ---
def trouver_urls():
    for c in ["urls_bumidom.txt", "urls.txt"]:
        if Path(c).exists(): return c
    for f in sorted(Path(".").glob("*.txt")):
        try:
            if "archives.assemblee-nationale.fr" in f.read_text(errors="ignore"):
                return str(f)
        except: pass
    raise SystemExit("❌ Fichier d'URLs introuvable")

FICHIER_URLS = trouver_urls()
DOSSIER_PDF  = Path("pdfs")
DOSSIER_TXT  = Path("textes")
MOT_CLE      = "bumidom"
CONTEXTE     = 400
DELAI        = 0.2
TIMEOUT      = 60
MAX_PAGES    = 40
USER_AGENT   = "Mozilla/5.0 (compatible; BumidomScraper/1.0)"

DOSSIER_PDF.mkdir(exist_ok=True)
DOSSIER_TXT.mkdir(exist_ok=True)

def nettoyer_url(u): return u.strip().lstrip("\ufeff").strip()

def nom_fichier(url):
    p = urlparse(url)
    chemin = p.path.strip("/").replace("/", "_")
    return chemin if chemin.endswith(".pdf") else chemin + ".pdf"

def telecharger(url, dest):
    if dest.exists() and dest.stat().st_size > 1000:
        return True
    try:
        r = subprocess.run(
            ["curl","-L","--fail","--silent","--show-error","-A",USER_AGENT,
             "-o",str(dest),url],
            capture_output=True, text=True, timeout=TIMEOUT)
        if r.returncode == 0 and dest.exists() and dest.read_bytes()[:4] == b"%PDF":
            return True
        dest.unlink(missing_ok=True)
    except Exception:
        dest.unlink(missing_ok=True)
    try:
        resp = requests.get(url, headers={"User-Agent": USER_AGENT},
                            timeout=TIMEOUT, verify=False)
        resp.raise_for_status()
        if not resp.content.startswith(b"%PDF"):
            return False
        dest.write_bytes(resp.content)
        return True
    except Exception as e:
        print(f"   ❌ {url} : {str(e)[:100]}")
        return False

def extraire(chemin):
    if fitz:
        try:
            doc = fitz.open(chemin)
            pages = [p.get_text() for i, p in enumerate(doc) if i < MAX_PAGES]
            doc.close()
            return "\n".join(pages)
        except Exception as e:
            print(f"   ⚠️  PyMuPDF : {e}")
            return ""
    else:
        try:
            import pdfplumber
            with pdfplumber.open(chemin) as pdf:
                return "\n".join((p.extract_text() or "")
                                 for i, p in enumerate(pdf.pages) if i < MAX_PAGES)
        except Exception:
            return ""

def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()

def extraire_contexte(texte, mot, taille=CONTEXTE):
    tn, mn = normaliser(texte), normaliser(mot)
    out, start = [], 0
    while True:
        i = tn.find(mn, start)
        if i == -1: break
        deb, fin = max(0, i-taille), min(len(texte), i+len(mot)+taille)
        ex = re.sub(r"\s+", " ", texte[deb:fin].replace("\n"," ").strip())
        out.append({"position": i, "extrait": ex})
        start = i + len(mot)
    uniq = []
    for e in out:
        if not uniq or e["position"] - uniq[-1]["position"] > taille:
            uniq.append(e)
    return uniq

def meta(url, titre=""):
    if "/cri/" in url:            t = "Compte rendu"
    elif "/qst/" in url:          t = "Question écrite"
    elif "/tanalytique/" in url:  t = "Table analytique"
    elif "/tnominative/" in url:  t = "Table nominative"
    else:                         t = "PDF"
    m = re.search(r"/(\d+)/(cri|qst)/", url)
    leg = m.group(1) if m else ""
    m = re.search(r"/(\d{4})-(\d{4})", url)
    per = f"{m.group(1)}-{m.group(2)}" if m else "Inconnue"
    d = "Inconnue"
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", url)
    if m: d = f"{m.group(3)}/{m.group(2)}/{m.group(1)}"
    return {"type": t, "legislature": leg, "periode": per, "date": d,
            "titre": titre or Path(urlparse(url).path).name}

def main():
    urls = [nettoyer_url(l) for l in open(FICHIER_URLS, encoding="utf-8")
            if l.strip().startswith("http")]
    print(f"📄 {len(urls)} URLs à traiter ({'PyMuPDF ⚡' if fitz else 'pdfplumber 🐢'})\n")

    resultats = []
    for i, url in enumerate(tqdm(urls, desc="Traitement", unit="doc"), 1):
        nom = nom_fichier(url)
        pdf = DOSSIER_PDF / nom
        txt = DOSSIER_TXT / nom.replace(".pdf", ".txt")

        if not telecharger(url, pdf):
            continue
        if txt.exists():
            texte = txt.read_text(encoding="utf-8", errors="ignore")
        else:
            texte = extraire(pdf)
            txt.write_text(texte, encoding="utf-8", errors="ignore")
        if not texte.strip():
            continue
        extraits = extraire_contexte(texte, MOT_CLE)
        if not extraits:
            continue
        m = meta(url)
        desc = extraits[0]["extrait"]
        resultats.append({
            "id": f"DOC_{i:04d}", "position": i,
            "title": m["titre"], "titleNoFormatting": m["titre"],
            "url": url, "unescapedUrl": url, "formattedUrl": url,
            "visibleUrl": urlparse(url).netloc,
            "content": desc, "contentNoFormatting": desc,
            "type": m["type"], "legislature": m["legislature"],
            "periode": m["periode"], "date": m["date"],
            "fileFormat": "PDF/Adobe Acrobat",
            "nb_mentions": len(extraits), "extraits": extraits,
        })
        time.sleep(DELAI)

    sortie = {
        "context": {"title": "Données extraites BUMIDOM",
                    "date": time.strftime("%Y-%m-%dT%H:%M:%S"),
                    "mot_cle": MOT_CLE},
        "results": resultats,
    }
    with open("resultats.json", "w", encoding="utf-8") as f:
        json.dump(sortie, f, ensure_ascii=False, indent=2)

    print(f"\n✅ {len(resultats)} documents avec « {MOT_CLE} »")
    print("📄 resultats.json")

if __name__ == "__main__":
    main()
PYEOF

python3 _etape1_scraper.py

# ============================================================
# ÉTAPE 2 — Extraction structurée (orateurs, thèmes, stats)
# ============================================================
echo -e "\n${BLEU}[2/6] Extraction structurée des données…${NC}"

cat > _etape2_structured.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re, json, unicodedata
from pathlib import Path
from collections import Counter

DOSSIER_TXT    = Path("textes")
FICHIER_SORTIE = "resultats_enrichis.json"
MOT_CLE        = "bumidom"

MOIS = r"(janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre)"
RE_DATE_LONGUE = re.compile(rf"\b(\d{{1,2}})\s+{MOIS}\s+(\d{{4}})\b", re.IGNORECASE)
RE_SEANCE      = re.compile(r"\b(\d{1,3})\s*[°oeè]?\s*s[ée]ance\b", re.IGNORECASE)
RE_LEGISLATURE = re.compile(r"(\d{1,2})\s*['°eè]?\s*[Ll][ée]gislature")
RE_ORATEUR     = re.compile(
    r"\b(M\.|MM\.|Mme|Mmes|Mlle)\s+"
    r"([A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç]+(?:[-\s][A-ZÉÈÀÂÎÔÛÇ]?[a-zéèêëàâîïôûç]+)*)")
RE_ARTICLE     = re.compile(r"\barticle\s+(\d+[a-z]?)\b", re.IGNORECASE)
RE_ANNEE       = re.compile(r"\b(19[4-9]\d)\b")
RE_NOMBRE      = re.compile(r"\b(\d{1,3}(?:[\s\u00a0]\d{3})+|\d{4,6})\b")
RE_POURCENTAGE = re.compile(r"\b(\d{1,3}(?:[.,]\d+)?)\s*%\b")
RE_FRANC       = re.compile(r"\b(\d{1,3}(?:[\s\u00a0]\d{3})*(?:[.,]\d+)?)\s*(francs?|F)\b", re.IGNORECASE)

THEMES = {
    "migration":  ["migration","migrant","émigration","immigration","expatriation","départ"],
    "formation":  ["formation","stage","préformation","apprentissage"],
    "emploi":     ["emploi","travail","placement","chômage","recrutement"],
    "logement":   ["logement","foyer","hébergement"],
    "transport":  ["transport","voyage","billet","tarif","aérien"],
    "budget":     ["crédit","budget","financement","subvention","dépense"],
    "insertion":  ["insertion","adaptation","accueil","installation"],
    "racisme":    ["racisme","discrimination","exploitation"],
    "reunion":    ["réunion","réunionnais"],
    "antilles":   ["antilles","antillais","guadeloupe","martinique","guyane"],
}

def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()

def extraire_dates(t):
    return sorted(set(f"{m.group(1)} {m.group(2)} {m.group(3)}"
                      for m in RE_DATE_LONGUE.finditer(t)))

def extraire_orateurs(t):
    c = Counter()
    for m in RE_ORATEUR.finditer(t):
        titre, nom = m.group(1), m.group(2).strip()
        if len(nom) < 4: continue
        if nom.endswith('-') or nom.endswith("'"): continue
        if len(nom.split()) < 2: continue
        if nom.lower() in {"le","la","les","un","une","president","presidente"}: continue
        if nom.isupper(): continue
        c[f"{titre} {nom}"] += 1
    return [{"nom": n, "occurrences": k} for n, k in c.most_common(50) if k >= 2]

def extraire_themes(t):
    tn = normaliser(t)
    out = {}
    for th, mots in THEMES.items():
        total = sum(tn.count(normaliser(m)) for m in mots)
        if total > 0: out[th] = total
    return dict(sorted(out.items(), key=lambda x: -x[1]))

def extraire_stats(t):
    return {
        "pourcentages": sorted(set(RE_POURCENTAGE.findall(t)))[:20],
        "francs": sorted(set(m.group(0) for m in RE_FRANC.finditer(t)))[:20],
        "grands_nombres": sorted(set(int(re.sub(r"[\s\u00a0]","",m.group(1)))
                                     for m in RE_NOMBRE.finditer(t)
                                     if int(re.sub(r"[\s\u00a0]","",m.group(1))) >= 1000))[:30],
        "annees": sorted(set(RE_ANNEE.findall(t))),
    }

def extraire_phrases(t, mot=MOT_CLE, max_p=20):
    tn, mn = normaliser(t), normaliser(mot)
    ph, start = [], 0
    while True:
        i = tn.find(mn, start)
        if i == -1: break
        deb = t.rfind(".", max(0,i-500), i)
        fin = t.find(".", i, min(len(t), i+500))
        if deb == -1: deb = max(0, i-200)
        if fin == -1: fin = min(len(t), i+200)
        p = re.sub(r"\s+"," ", t[deb+1:fin+1].replace("\n"," ").strip())
        if 30 < len(p) < 2000: ph.append(p)
        start = i + len(mot)
    return list(dict.fromkeys(ph))[:max_p]

def extraire_contexte(t, mot=MOT_CLE, taille=400):
    tn, mn = normaliser(t), normaliser(mot)
    out, start = [], 0
    while True:
        i = tn.find(mn, start)
        if i == -1: break
        deb, fin = max(0,i-taille), min(len(t), i+len(mot)+taille)
        ex = re.sub(r"\s+"," ", t[deb:fin].replace("\n"," ").strip())
        out.append({"position": i, "page_approx": i//3000+1, "extrait": ex})
        start = i + len(mot)
    uniq = []
    for e in out:
        if not uniq or e["position"] - uniq[-1]["position"] > taille:
            uniq.append(e)
    return uniq

def analyser(f, idx):
    t = f.read_text(encoding="utf-8", errors="ignore")
    if normaliser(MOT_CLE) not in normaliser(t): return None
    stem = f.stem
    parts = stem.split("_")
    if len(parts) >= 4:
        url = f"https://archives.assemblee-nationale.fr/{parts[0]}/{parts[1]}/{parts[2]}/{parts[-1]}.pdf"
    else:
        url = ""
    ex = extraire_contexte(t)
    return {
        "id": f"DOC_{idx:04d}",
        "fichier": f.name,
        "url": url,
        "nb_mentions": len(ex),
        "extraits": ex,
        "phrases": extraire_phrases(t),
        "dates": extraire_dates(t),
        "orateurs": extraire_orateurs(t),
        "legislatures": sorted(set(RE_LEGISLATURE.findall(t))),
        "seances": sorted(set(RE_SEANCE.findall(t))),
        "articles": sorted(set(f"article {m}" for m in RE_ARTICLE.findall(t))),
        "themes": extraire_themes(t),
        "statistiques": extraire_stats(t),
    }

def main():
    fichiers = sorted(DOSSIER_TXT.glob("*.txt"))
    print(f"📄 {len(fichiers)} fichiers à analyser\n")
    resultats = []
    for i, f in enumerate(fichiers, 1):
        r = analyser(f, i)
        if r:
            resultats.append(r)
            print(f"  ✅ {f.name} → {r['nb_mentions']} mentions")

    tous_orateurs = Counter()
    tous_themes   = Counter()
    toutes_annees = Counter()
    for r in resultats:
        for o in r["orateurs"]: tous_orateurs[o["nom"]] += o["occurrences"]
        for th, n in r["themes"].items(): tous_themes[th] += n
        for a in r["statistiques"]["annees"]: toutes_annees[a] += 1

    sortie = {
        "context": {"title": "Données BUMIDOM enrichies",
                    "total_documents": len(resultats)},
        "statistiques_globales": {
            "top_orateurs": tous_orateurs.most_common(30),
            "themes": tous_themes.most_common(),
            "annees_citees": toutes_annees.most_common(30),
        },
        "results": resultats,
    }
    with open(FICHIER_SORTIE, "w", encoding="utf-8") as f:
        json.dump(sortie, f, ensure_ascii=False, indent=2)

    print(f"\n✅ {len(resultats)} documents → {FICHIER_SORTIE}")
    print("\n📊 Top 10 orateurs :")
    for o, n in tous_orateurs.most_common(10): print(f"  {o:40s} : {n}")
    print("\n📊 Thèmes :")
    for th, n in tous_themes.most_common(): print(f"  {th:15s} : {n}")

if __name__ == "__main__":
    main()
PYEOF

python3 _etape2_structured.py

# ============================================================
# ÉTAPE 3 — Base SQLite
# ============================================================
echo -e "\n${BLEU}[3/6] Construction de la base SQLite…${NC}"

cat > _etape3_sqlite.py <<'PYEOF'
#!/usr/bin/env python3
import json, sqlite3
from pathlib import Path

DB     = Path("bumidom.db")
SOURCE = Path("resultats_enrichis.json")

if DB.exists(): DB.unlink()
conn = sqlite3.connect(DB)
cur = conn.cursor()

cur.executescript("""
CREATE TABLE documents (id TEXT PRIMARY KEY, fichier TEXT, url TEXT,
                        nb_mentions INTEGER, nb_orateurs INTEGER);
CREATE TABLE extraits (id INTEGER PRIMARY KEY AUTOINCREMENT, doc_id TEXT,
                       position INTEGER, page_approx INTEGER, extrait TEXT);
CREATE TABLE orateurs (doc_id TEXT, nom TEXT, occurrences INTEGER);
CREATE TABLE themes (doc_id TEXT, theme TEXT, occurrences INTEGER);
CREATE TABLE annees (doc_id TEXT, annee TEXT);
CREATE TABLE dates (doc_id TEXT, date TEXT);
""")

data = json.loads(SOURCE.read_text(encoding="utf-8"))
for doc in data["results"]:
    cur.execute("INSERT INTO documents VALUES (?,?,?,?,?)",
                (doc["id"], doc["fichier"], doc["url"],
                 doc["nb_mentions"], len(doc["orateurs"])))
    for e in doc["extraits"]:
        cur.execute("INSERT INTO extraits (doc_id, position, page_approx, extrait) VALUES (?,?,?,?)",
                    (doc["id"], e["position"], e["page_approx"], e["extrait"]))
    for o in doc["orateurs"]:
        cur.execute("INSERT INTO orateurs VALUES (?,?,?)", (doc["id"], o["nom"], o["occurrences"]))
    for th, n in doc["themes"].items():
        cur.execute("INSERT INTO themes VALUES (?,?,?)", (doc["id"], th, n))
    for a in doc["statistiques"]["annees"]:
        cur.execute("INSERT INTO annees VALUES (?,?)", (doc["id"], a))
    for d in doc["dates"]:
        cur.execute("INSERT INTO dates VALUES (?,?)", (doc["id"], d))

conn.commit()
conn.close()
print(f"✅ Base : {DB}")
PYEOF

python3 _etape3_sqlite.py

# ============================================================
# ÉTAPE 4 — Corpus thématique
# ============================================================
echo -e "\n${BLEU}[4/6] Organisation du corpus par thème…${NC}"

cat > _etape4_corpus.py <<'PYEOF'
#!/usr/bin/env python3
import json
from pathlib import Path
from collections import defaultdict

SOURCE = Path("resultats_enrichis.json")
CORPUS = Path("corpus")
CORPUS.mkdir(exist_ok=True)

data = json.loads(SOURCE.read_text(encoding="utf-8"))
docs_par_theme = defaultdict(list)

for doc in data["results"]:
    themes = doc["themes"]
    theme = max(themes.items(), key=lambda x: x[1])[0] if themes else "divers"
    docs_par_theme[theme].append(doc)

for theme, docs in docs_par_theme.items():
    dossier = CORPUS / theme
    dossier.mkdir(exist_ok=True)
    index = [f"# Thème : {theme}\n\n", f"Nombre de documents : {len(docs)}\n\n"]
    for doc in sorted(docs, key=lambda d: -d["nb_mentions"]):
        nom = f"{doc['id']}_{doc['fichier'].replace('.txt','')}.txt"
        contenu = [
            f"# {doc['id']} — {doc['fichier']}\n",
            f"URL : {doc['url']}\n",
            f"Nb mentions : {doc['nb_mentions']}\n\n## Extraits\n\n",
        ]
        for i, e in enumerate(doc["extraits"], 1):
            contenu.append(f"### Extrait {i} (page ~{e['page_approx']})\n")
            contenu.append(e["extrait"] + "\n\n")
        if doc["phrases"]:
            contenu.append("\n## Phrases clés\n\n")
            for p in doc["phrases"]:
                contenu.append(f"- {p}\n")
        (dossier / nom).write_text("".join(contenu), encoding="utf-8")
        index.append(f"- [{nom}]({theme}/{nom}) — {doc['nb_mentions']} mentions\n")
    (dossier / "_index.md").write_text("".join(index), encoding="utf-8")
    print(f"  📁 {theme:15s} : {len(docs)} documents")

print(f"\n✅ Corpus : {CORPUS}/")
PYEOF

python3 _etape4_corpus.py

# ============================================================
# ÉTAPE 5 — Analyse NLP (spacy) — optionnelle
# ============================================================
echo -e "\n${BLEU}[5/6] Analyse NLP…${NC}"

if ! python3 -c "import spacy" 2>/dev/null; then
    echo -e "${JAUNE}   → Installation de spacy…${NC}"
    pip install --quiet spacy
fi

if ! python3 -c "import spacy; spacy.load('fr_core_news_sm')" 2>/dev/null; then
    echo -e "${JAUNE}   → Téléchargement du modèle français…${NC}"
    python3 -m spacy download fr_core_news_sm
fi

cat > _etape5_nlp.py <<'PYEOF'
#!/usr/bin/env python3
import json, re
from pathlib import Path
from collections import Counter
import spacy

SOURCE = Path("resultats_enrichis.json")
SORTIE = Path("nlp_results.json")

nlp = spacy.load("fr_core_news_sm")
data = json.loads(SOURCE.read_text(encoding="utf-8"))

extraits = []
for doc in data["results"]:
    for e in doc["extraits"]:
        extraits.append({"doc_id": doc["id"], "fichier": doc["fichier"], "texte": e["extrait"]})

print(f"📄 Analyse de {len(extraits)} extraits…")

entites = {"PER": Counter(), "LOC": Counter(), "ORG": Counter(), "MISC": Counter()}
for i, e in enumerate(extraits):
    if i % 50 == 0: print(f"  … {i}/{len(extraits)}")
    doc = nlp(e["texte"][:5000])
    for ent in doc.ents:
        if ent.label_ in entites:
            entites[ent.label_][ent.text.strip()] += 1

mots = Counter()
for e in extraits:
    for m in re.findall(r"\b[a-zéèêëàâîïôûç]{4,}\b", e["texte"].lower()):
        if m not in {"bumidom","cette","donc","alors","aussi","fait","être","avoir","comme"}:
            mots[m] += 1

resultats = {
    "top_personnes": entites["PER"].most_common(30),
    "top_lieux": entites["LOC"].most_common(30),
    "top_organisations": entites["ORG"].most_common(30),
    "mots_frequents": mots.most_common(50),
    "total_extraits": len(extraits),
}
SORTIE.write_text(json.dumps(resultats, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"\n✅ NLP → {SORTIE}")
PYEOF

python3 _etape5_nlp.py

# ============================================================
# ÉTAPE 6 — Rapport Markdown
# ============================================================
echo -e "\n${BLEU}[6/6] Génération du rapport Markdown…${NC}"

cat > _etape6_rapport.py <<'PYEOF'
#!/usr/bin/env python3
import json
from pathlib import Path
from datetime import datetime

RAPPORT = Path("rapport.md")
data = json.loads(Path("resultats_enrichis.json").read_text(encoding="utf-8"))
nlp  = json.loads(Path("nlp_results.json").read_text(encoding="utf-8"))

docs = data["results"]
stats = data["statistiques_globales"]

L = [
    "# Rapport d'analyse — Débats BUMIDOM à l'Assemblée nationale\n\n",
    f"*Généré le {datetime.now().strftime('%d/%m/%Y à %H:%M')}*\n\n---\n\n",
    "## 1. Synthèse\n\n",
    f"- **Documents** : {len(docs)}\n",
    f"- **Mentions totales** : {sum(d['nb_mentions'] for d in docs)}\n",
    f"- **Orateurs uniques** : {len({o['nom'] for d in docs for o in d['orateurs']})}\n",
    f"- **Thèmes détectés** : {len(stats['themes'])}\n\n---\n\n",
    "## 2. Thèmes\n\n| Thème | Occurrences |\n|---|---|\n",
]
for th, n in stats["themes"]:
    L.append(f"| {th} | {n} |\n")
L.append("\n---\n\n## 3. Top orateurs\n\n| Orateur | Occurrences |\n|---|---|\n")
for o, n in stats["top_orateurs"][:20]:
    L.append(f"| {o} | {n} |\n")
L.append("\n---\n\n## 4. Personnes citées (NLP)\n\n| Personne | Mentions |\n|---|---|\n")
for p, n in nlp["top_personnes"][:20]:
    L.append(f"| {p} | {n} |\n")
L.append("\n---\n\n## 5. Lieux cités (NLP)\n\n| Lieu | Mentions |\n|---|---|\n")
for l, n in nlp["top_lieux"][:20]:
    L.append(f"| {l} | {n} |\n")
L.append("\n---\n\n## 6. Chronologie (50 premiers)\n\n")
for doc in sorted(docs, key=lambda d: d["fichier"])[:50]:
    L.append(f"### {doc['id']} — `{doc['fichier']}`\n\n")
    L.append(f"- **Mentions** : {doc['nb_mentions']}\n")
    if doc["url"]: L.append(f"- **Source** : [{doc['url']}]({doc['url']})\n")
    if doc["themes"]:
        th = ", ".join(f"{k} ({v})" for k, v in list(doc["themes"].items())[:5])
        L.append(f"- **Thèmes** : {th}\n")
    L.append("\n**Premier extrait :**\n\n")
    L.append(f"> {doc['extraits'][0]['extrait']}\n\n")

RAPPORT.write_text("".join(L), encoding="utf-8")
print(f"✅ Rapport : {RAPPORT}")
PYEOF

python3 _etape6_rapport.py

# ============================================================
# NETTOYAGE
# ============================================================
rm -f _etape1_scraper.py _etape2_structured.py _etape3_sqlite.py \
      _etape4_corpus.py _etape5_nlp.py _etape6_rapport.py

# ============================================================
# RÉSUMÉ
# ============================================================
echo -e "\n${VERT}══════════════════════════════════════════════════════════${NC}"
echo -e "${VERT}  ✅ PIPELINE TERMINÉ${NC}"
echo -e "${VERT}══════════════════════════════════════════════════════════${NC}\n"

echo -e "${BLEU}📦 Fichiers produits :${NC}"
ls -lh resultats.json resultats_enrichis.json nlp_results.json \
       bumidom.db rapport.md 2>/dev/null | awk '{print "   "$9" ("$5")"}'

echo -e "\n${BLEU}📁 Dossiers produits :${NC}"
du -sh pdfs/ textes/ corpus/ 2>/dev/null | awk '{print "   "$2" ("$1")"}'

echo -e "\n${BLEU}📊 Aperçu :${NC}"
DOCS=$(python3 -c "import json;print(len(json.load(open('resultats_enrichis.json'))['results']))")
echo -e "   Documents BUMIDOM : ${VERT}$DOCS${NC}"
echo -e "   Requêtes SQL      : ${GRIS}sqlite3 bumidom.db 'SELECT * FROM documents;'${NC}"

echo -e "\n${BLEU}🌐 Pour lancer le dashboard :${NC}"
echo -e "   ${JAUNE}python3 -m http.server 8000${NC}"
echo -e "   puis ouvrir ${JAUNE}http://localhost:8000/timeline.html${NC}\n"