#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, json, time, subprocess, unicodedata
from pathlib import Path
from urllib.parse import urlparse

import requests, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from tqdm import tqdm

# --- Extraction rapide ---
try:
    import fitz  # PyMuPDF
    USE_PYMUPDF = True
except ImportError:
    import pdfplumber
    USE_PYMUPDF = False
    print("⚠️  PyMuPDF non installé, utilise pdfplumber (lent).")
    print("   → pip install pymupdf\n")

# ============================================================
# CONFIGURATION
# ============================================================
FICHIER_URLS   = "urls_bumidom.txt"
DOSSIER_PDF    = Path("pdfs")
DOSSIER_TXT    = Path("textes")
FICHIER_SORTIE = "resultats.json"
MOT_CLE        = "bumidom"
CONTEXTE       = 400
DELAI          = 0.2
TIMEOUT        = 60
MAX_PAGES      = 40  # limite par PDF (accélère énormément)
USER_AGENT     = "Mozilla/5.0 (compatible; BumidomScraper/1.0)"

DOSSIER_PDF.mkdir(exist_ok=True)
DOSSIER_TXT.mkdir(exist_ok=True)


# ============================================================
# TÉLÉCHARGEMENT
# ============================================================
def nettoyer_url(u): return u.strip().lstrip("\ufeff").strip()

def nom_fichier_depuis_url(url):
    p = urlparse(url)
    chemin = p.path.strip("/").replace("/", "_")
    return chemin if chemin.endswith(".pdf") else chemin + ".pdf"

def telecharger_pdf(url, dest):
    if dest.exists() and dest.stat().st_size > 1000:
        return True
    # curl
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
    # requests
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


# ============================================================
# EXTRACTION RAPIDE
# ============================================================
def extraire_texte_pdf(chemin_pdf):
    """Extraction rapide (PyMuPDF si dispo, sinon pdfplumber)."""
    if USE_PYMUPDF:
        try:
            doc = fitz.open(chemin_pdf)
            pages = []
            for i, page in enumerate(doc):
                if i >= MAX_PAGES:
                    break
                pages.append(page.get_text())
            doc.close()
            return "\n".join(pages)
        except Exception as e:
            print(f"   ⚠️  PyMuPDF : {e}")
            return ""
    else:
        try:
            import pdfplumber
            with pdfplumber.open(chemin_pdf) as pdf:
                pages = []
                for i, page in enumerate(pdf.pages):
                    if i >= MAX_PAGES:
                        break
                    pages.append(page.extract_text() or "")
                return "\n".join(pages)
        except Exception:
            return ""


# ============================================================
# RECHERCHE
# ============================================================
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

def extraire_metadonnees(url, titre=""):
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


# ============================================================
# MAIN
# ============================================================
def main():
    if not os.path.exists(FICHIER_URLS):
        print(f"❌ Introuvable : {FICHIER_URLS}"); return

    with open(FICHIER_URLS, encoding="utf-8") as f:
        urls = [nettoyer_url(l) for l in f if l.strip().startswith("http")]

    print(f"📄 {len(urls)} URLs à traiter (mode {'PyMuPDF ⚡' if USE_PYMUPDF else 'pdfplumber 🐢'})\n")

    resultats, erreurs = [], []

    for i, url in enumerate(tqdm(urls, desc="Traitement", unit="doc"), 1):
        nom = nom_fichier_depuis_url(url)
        pdf = DOSSIER_PDF / nom
        txt = DOSSIER_TXT / (nom.replace(".pdf",".txt"))

        if not telecharger_pdf(url, pdf):
            erreurs.append(url); continue

        if txt.exists():
            texte = txt.read_text(encoding="utf-8", errors="ignore")
        else:
            texte = extraire_texte_pdf(pdf)
            txt.write_text(texte, encoding="utf-8", errors="ignore")

        if not texte.strip():
            continue

        extraits = extraire_contexte(texte, MOT_CLE)
        if not extraits: continue

        meta = extraire_metadonnees(url)
        desc = extraits[0]["extrait"]
        resultats.append({
            "id": f"DOC_{i:04d}", "position": i,
            "title": meta["titre"], "titleNoFormatting": meta["titre"],
            "url": url, "unescapedUrl": url, "formattedUrl": url,
            "visibleUrl": urlparse(url).netloc,
            "content": desc, "contentNoFormatting": desc,
            "type": meta["type"], "legislature": meta["legislature"],
            "periode": meta["periode"], "date": meta["date"],
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
    with open(FICHIER_SORTIE, "w", encoding="utf-8") as f:
        json.dump(sortie, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Terminé : {len(resultats)} documents contiennent « {MOT_CLE} »")
    if erreurs: print(f"⚠️  {len(erreurs)} échecs")
    print(f"📁 PDF       : {DOSSIER_PDF}/")
    print(f"📁 Textes    : {DOSSIER_TXT}/")
    print(f"📄 Résultats : {FICHIER_SORTIE}")

if __name__ == "__main__":
    main()