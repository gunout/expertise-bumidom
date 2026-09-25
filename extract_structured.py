#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extraction structurée des données BUMIDOM depuis les fichiers texte déjà extraits.
"""

import re
import json
import unicodedata
from pathlib import Path
from collections import Counter, defaultdict

DOSSIER_TXT    = Path("textes")
FICHIER_SORTIE = "resultats_enrichis.json"
MOT_CLE        = "bumidom"

# ============================================================
# REGEX
# ============================================================
MOIS = r"(janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre)"
RE_DATE_LONGUE = re.compile(rf"\b(\d{{1,2}})\s+{MOIS}\s+(\d{{4}})\b", re.IGNORECASE)
RE_SEANCE      = re.compile(r"\b(\d{1,3})\s*[°oeè]?\s*s[ée]ance\b", re.IGNORECASE)
RE_LEGISLATURE = re.compile(r"(\d{1,2})\s*['°eè]?\s*[Ll][ée]gislature")
RE_ORATEUR     = re.compile(
    r"\b(M\.|MM\.|Mme|Mmes|Mlle)\s+"
    r"([A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç\-']+(?:\s+[A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç\-']+){0,3})")
RE_ARTICLE     = re.compile(r"\barticle\s+(\d+[a-z]?)\b", re.IGNORECASE)
RE_ANNEE       = re.compile(r"\b(19[4-9]\d)\b")
RE_NOMBRE      = re.compile(r"\b(\d{1,3}(?:[\s\u00a0]\d{3})+|\d{4,6})\b")
RE_POURCENTAGE = re.compile(r"\b(\d{1,3}(?:[.,]\d+)?)\s*%\b")
RE_FRANC       = re.compile(r"\b(\d{1,3}(?:[\s\u00a0]\d{3})*(?:[.,]\d+)?)\s*(francs?|F)\b", re.IGNORECASE)

# Thèmes
THEMES = {
    "migration":  ["migration", "migrant", "émigration", "immigration", "expatriation", "départ"],
    "formation":  ["formation", "stage", "préformation", "apprentissage"],
    "emploi":     ["emploi", "travail", "placement", "chômage", "recrutement"],
    "logement":   ["logement", "foyer", "hébergement"],
    "transport":  ["transport", "voyage", "billet", "tarif", "aérien"],
    "budget":     ["crédit", "budget", "financement", "subvention", "dépense"],
    "insertion":  ["insertion", "adaptation", "accueil", "installation"],
    "racisme":    ["racisme", "discrimination", "exploitation"],
    "reunion":    ["réunion", "réunionnais"],
    "antilles":   ["antilles", "antillais", "guadeloupe", "martinique", "guyane"],
}

# ============================================================
# NORMALISATION
# ============================================================
def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()

# ============================================================
# EXTRACTEURS
# ============================================================
def extraire_dates(texte):
    dates = []
    for m in RE_DATE_LONGUE.finditer(texte):
        dates.append(f"{m.group(1)} {m.group(2)} {m.group(3)}")
    return sorted(set(dates))

def extraire_orateurs(texte):
    orateurs = Counter()
    for m in RE_ORATEUR.finditer(texte):
        titre, nom = m.group(1), m.group(2).strip()
        if len(nom) < 3:
            continue
        # Filtres faux positifs fréquents
        if nom.lower() in {"le", "la", "les", "un", "une", "president", "presidente"}:
            continue
        if nom.isupper():
            continue
        orateurs[f"{titre} {nom}"] += 1
    # Garde les orateurs mentionnés ≥ 2 fois (moins de bruit)
    return [{"nom": n, "occurrences": c} for n, c in orateurs.most_common(50)]

def extraire_themes(texte):
    tn = normaliser(texte)
    themes = {}
    for theme, mots in THEMES.items():
        total = sum(tn.count(normaliser(m)) for m in mots)
        if total > 0:
            themes[theme] = total
    return dict(sorted(themes.items(), key=lambda x: -x[1]))

def extraire_statistiques(texte):
    stats = {
        "pourcentages": sorted(set(RE_POURCENTAGE.findall(texte)))[:20],
        "francs":       sorted(set(m.group(0) for m in RE_FRANC.finditer(texte)))[:20],
        "grands_nombres": sorted(set(
            int(re.sub(r"[\s\u00a0]", "", m.group(1)))
            for m in RE_NOMBRE.finditer(texte)
            if int(re.sub(r"[\s\u00a0]", "", m.group(1))) >= 1000
        ))[:30],
        "annees": sorted(set(RE_ANNEE.findall(texte))),
    }
    return stats

def extraire_articles(texte):
    return sorted(set(f"article {m}" for m in RE_ARTICLE.findall(texte)))

def extraire_legislatures(texte):
    return sorted(set(RE_LEGISLATURE.findall(texte)))

def extraire_seances(texte):
    return sorted(set(RE_SEANCE.findall(texte)))

def extraire_phrases_bumidom(texte, mot=MOT_CLE, max_phrases=20):
    """Extrait les phrases complètes contenant BUMIDOM."""
    tn = normaliser(texte)
    mn = normaliser(mot)
    phrases = []
    start = 0
    while True:
        i = tn.find(mn, start)
        if i == -1:
            break
        # Cherche la phrase
        deb = texte.rfind(".", max(0, i-500), i)
        fin = texte.find(".", i, min(len(texte), i+500))
        if deb == -1: deb = max(0, i-200)
        if fin == -1: fin = min(len(texte), i+200)
        phrase = texte[deb+1:fin+1].strip()
        phrase = re.sub(r"\s+", " ", phrase.replace("\n", " "))
        if 30 < len(phrase) < 2000:
            phrases.append(phrase)
        start = i + len(mot)
    return list(dict.fromkeys(phrases))[:max_phrases]

def extraire_contexte(texte, mot=MOT_CLE, taille=400):
    tn = normaliser(texte)
    mn = normaliser(mot)
    extraits = []
    start = 0
    while True:
        i = tn.find(mn, start)
        if i == -1:
            break
        deb = max(0, i - taille)
        fin = min(len(texte), i + len(mot) + taille)
        ex = re.sub(r"\s+", " ", texte[deb:fin].replace("\n", " ").strip())
        extraits.append({
            "position": i,
            "page_approx": i // 3000 + 1,
            "extrait": ex,
        })
        start = i + len(mot)
    uniq = []
    for e in extraits:
        if not uniq or e["position"] - uniq[-1]["position"] > taille:
            uniq.append(e)
    return uniq

# ============================================================
# TRAITEMENT D'UN FICHIER
# ============================================================
def analyser(chemin_txt: Path, idx: int):
    texte = chemin_txt.read_text(encoding="utf-8", errors="ignore")
    if normaliser(MOT_CLE) not in normaliser(texte):
        return None

    # Reconstruction URL depuis le nom du fichier
    # ex: 4_cri_1971-1972-ordinaire1_024.txt
    stem = chemin_txt.stem  # 4_cri_1971-1972-ordinaire1_024
    parts = stem.split("_")
    if len(parts) >= 4:
        leg, typ = parts[0], parts[1]
        periode = parts[2]
        num = parts[-1]
        url = f"https://archives.assemblee-nationale.fr/{leg}/{typ}/{periode}/{num}.pdf"
    else:
        url = ""

    return {
        "id": f"DOC_{idx:04d}",
        "fichier": chemin_txt.name,
        "url": url,

        # Contenu
        "nb_mentions": len(extraire_contexte(texte)),
        "extraits":    extraire_contexte(texte),
        "phrases":     extraire_phrases_bumidom(texte),

        # Métadonnées
        "dates":       extraire_dates(texte),
        "orateurs":    extraire_orateurs(texte),
        "legislatures":extraire_legislatures(texte),
        "seances":     extraire_seances(texte),
        "articles":    extraire_articles(texte),

        # Thèmes & stats
        "themes":      extraire_themes(texte),
        "statistiques":extraire_statistiques(texte),
    }

# ============================================================
# MAIN
# ============================================================
def main():
    fichiers = sorted(DOSSIER_TXT.glob("*.txt"))
    print(f"📄 {len(fichiers)} fichiers à analyser\n")

    resultats = []
    for i, f in enumerate(fichiers, 1):
        r = analyser(f, i)
        if r:
            resultats.append(r)
            print(f"  ✅ {f.name} → {r['nb_mentions']} mentions")

    # Stats globales
    tous_orateurs = Counter()
    tous_themes   = Counter()
    toutes_annees = Counter()
    for r in resultats:
        for o in r["orateurs"]:
            tous_orateurs[o["nom"]] += o["occurrences"]
        for t, n in r["themes"].items():
            tous_themes[t] += n
        for a in r["statistiques"]["annees"]:
            toutes_annees[a] += 1

    sortie = {
        "context": {
            "title": "Données BUMIDOM enrichies",
            "total_documents": len(resultats),
        },
        "statistiques_globales": {
            "top_orateurs":  tous_orateurs.most_common(30),
            "themes":        tous_themes.most_common(),
            "annees_citees": toutes_annees.most_common(30),
        },
        "results": resultats,
    }

    with open(FICHIER_SORTIE, "w", encoding="utf-8") as f:
        json.dump(sortie, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"✅ {len(resultats)} documents enrichis → {FICHIER_SORTIE}")
    print(f"\n📊 Top 10 orateurs :")
    for o, n in tous_orateurs.most_common(10):
        print(f"  {o:40s} : {n}")
    print(f"\n📊 Thèmes :")
    for t, n in tous_themes.most_common():
        print(f"  {t:15s} : {n}")
    print(f"\n📊 Années citées :")
    for a, n in toutes_annees.most_common(10):
        print(f"  {a} : {n}")

if __name__ == "__main__":
    main()