#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extraction experte : chiffres, statistiques, entités factuelles
depuis les textes BUMIDOM.
Produit plusieurs CSV/JSON exploitables pour expertise.
"""

import re
import json
import csv
import unicodedata
from pathlib import Path
from collections import Counter, defaultdict

DOSSIER_TXT = Path("textes")
SORTIE_DIR  = Path("expertise")
SORTIE_DIR.mkdir(exist_ok=True)

# ============================================================
# REGEX DE CAPTURE
# ============================================================
MOIS = r"(janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|septembre|octobre|novembre|d[ée]cembre)"

# Dates longues : "26 octobre 1971"
RE_DATE_LONGUE = re.compile(rf"\b(\d{{1,2}})\s+{MOIS}\s+(\d{{4}})\b", re.IGNORECASE)

# Dates courtes : "15.02.1969", "1969-08-23"
RE_DATE_COURTE = re.compile(r"\b(\d{1,2})[./-](\d{1,2})[./-](\d{4})\b")
RE_DATE_ISO    = re.compile(r"\b(\d{4})-(\d{2})-(\d{2})\b")

# Nombres avec séparateurs : "3 011", "6 561 794,50", "10.000"
RE_NOMBRE = re.compile(
    r"\b(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,7}(?:,\d+)?)\s*"
    r"(habitants?|personnes?|migrants?|travailleurs?|Réunionnais|Antillais|"
    r"francs?|F|%|pour\s*cent)?",
    re.IGNORECASE
)

# Pourcentages
RE_POURCENTAGE = re.compile(r"\b(\d{1,3}(?:[.,]\d+)?)\s*(?:%|pour\s*cent|p\.\s*100)", re.IGNORECASE)

# Francs (montants)
RE_FRANC = re.compile(
    r"\b(\d{1,3}(?:[\s\u00a0]\d{3})*(?:[.,]\d+)?)\s*"
    r"(francs?|F|NF|nouveaux\s+francs?)",
    re.IGNORECASE
)

# Logements / foyers
RE_LOGEMENT = re.compile(
    r"\b(\d{1,4})\s*(logements?|lits?|foyers?|chambres?|places?)",
    re.IGNORECASE
)

# Articles
RE_ARTICLE = re.compile(r"\barticle\s+(\d+[a-z]?)\b", re.IGNORECASE)

# Institutions
INSTITUTIONS = [
    "BUMIDOM", "B.U.M.I.D.O.M", "Bumidom",
    "A.N.T.", "ANT", "Agence nationale pour l'insertion",
    "CASADOM", "C.A.S.A.D.O.M", "Casadom",
    "FIDOM", "F.I.D.O.M", "Fidom",
    "C.A.E.C.L", "CAECL",
    "S.M.I.C", "SMIC",
    "A.N.P.E", "ANPE",
    "C.N.R.S", "CNRS",
    "I.N.S.E.E", "INSEE",
]
RE_INSTITUTION = re.compile(
    r"\b(" + "|".join(re.escape(i) for i in INSTITUTIONS) + r")\b",
    re.IGNORECASE
)

# Noms propres de personnes (orateurs)
RE_ORATEUR = re.compile(
    r"\b(M\.|MM\.|Mme|Mmes|Mlle)\s+"
    r"([A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç\-']+(?:[-\s][A-ZÉÈÀÂÎÔÛÇ][a-zéèêëàâîïôûç\-']+)*)"
)

# Noms de lieux (communes, régions, pays)
LIEUX = [
    "Réunion", "La Réunion", "Guadeloupe", "Martinique", "Guyane",
    "Antilles", "DOM", "D.O.M.", "métropole",
    "Paris", "Marseille", "Lyon", "Bordeaux", "Nantes",
    "Fort-de-France", "Pointe-à-Pitre", "Cayenne", "Saint-Denis",
    "Afrique", "Madagascar", "Maurice", "Haïti",
    "Simandes", "Rush del Campo",
]
RE_LIEU = re.compile(
    r"\b(" + "|".join(re.escape(l) for l in LIEUX) + r")\b",
    re.IGNORECASE
)

# Verbes / expressions indiquant des données quantitatives
MOTS_QUANTI = [
    "effectif", "nombre", "total", "moyenne", "répartition",
    "augmentation", "diminution", "hausse", "baisse", "progression",
    "pourcentage", "proportion", "taux", "ratio",
    "budget", "crédit", "subvention", "dépense", "financement",
    "montant", "somme", "coût", "prix", "tarif",
]


# ============================================================
# UTILITAIRES
# ============================================================
def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()


def nettoyer_nombre(s):
    """'3 011' -> 3011 ; '6 561 794,50' -> 6561794.50"""
    s = re.sub(r"[\s\u00a0]", "", s)
    s = s.replace(".", "").replace(",", ".")
    try:
        return float(s)
    except:
        return None


def extraire_phrase_autour(texte, index, fenetre=200):
    """Extrait la phrase complète autour d'une position."""
    deb = texte.rfind(".", max(0, index - fenetre), index)
    fin = texte.find(".", index, min(len(texte), index + fenetre))
    if deb == -1: deb = max(0, index - fenetre)
    if fin == -1: fin = min(len(texte), index + fenetre)
    phrase = texte[deb+1:fin+1]
    phrase = re.sub(r"\s+", " ", phrase.replace("\n", " ")).strip()
    return phrase


def contexte_autour(texte, index, taille=300):
    deb = max(0, index - taille)
    fin = min(len(texte), index + taille)
    return re.sub(r"\s+", " ", texte[deb:fin].replace("\n", " ")).strip()


# ============================================================
# EXTRACTIONS SPÉCIFIQUES
# ============================================================
def extraire_montants(texte):
    """Retourne tous les montants en francs avec contexte."""
    montants = []
    for m in RE_FRANC.finditer(texte):
        valeur = nettoyer_nombre(m.group(1))
        if valeur and valeur >= 100:  # filtre le bruit
            montants.append({
                "valeur": valeur,
                "unite": m.group(2),
                "position": m.start(),
                "contexte": contexte_autour(texte, m.start(), 200),
            })
    return montants


def extraire_pourcentages(texte):
    """Retourne tous les pourcentages avec contexte."""
    pcts = []
    for m in RE_POURCENTAGE.finditer(texte):
        pcts.append({
            "valeur": m.group(1).replace(",", "."),
            "position": m.start(),
            "contexte": contexte_autour(texte, m.start(), 200),
        })
    return pcts


def extraire_effectifs(texte):
    """Retourne tous les effectifs (migrants, travailleurs, etc.)."""
    effectifs = []
    for m in RE_NOMBRE.finditer(texte):
        valeur = nettoyer_nombre(m.group(1))
        if not valeur or valeur < 10: continue
        unite = (m.group(2) or "").strip()
        # Filtre : garde uniquement si unité significative
        if unite.lower() in {"habitants","habitants","personnes","migrants","travailleurs",
                              "réunionnais","antillais","logements","lits","foyers",
                              "chambres","places"}:
            effectifs.append({
                "valeur": int(valeur),
                "unite": unite,
                "position": m.start(),
                "contexte": contexte_autour(texte, m.start(), 200),
            })
    return effectifs


def extraire_logements(texte):
    logements = []
    for m in RE_LOGEMENT.finditer(texte):
        logements.append({
            "valeur": int(m.group(1)),
            "unite": m.group(2),
            "position": m.start(),
            "contexte": contexte_autour(texte, m.start(), 150),
        })
    return logements


def extraire_dates(texte):
    dates = []
    for m in RE_DATE_LONGUE.finditer(texte):
        dates.append({
            "date": f"{m.group(1)} {m.group(2)} {m.group(3)}",
            "annee": int(m.group(3)),
        })
    for m in RE_DATE_ISO.finditer(texte):
        dates.append({
            "date": f"{m.group(3)}/{m.group(2)}/{m.group(1)}",
            "annee": int(m.group(1)),
        })
    for m in RE_DATE_COURTE.finditer(texte):
        dates.append({
            "date": f"{m.group(1)}/{m.group(2)}/{m.group(3)}",
            "annee": int(m.group(3)),
        })
    return dates


def extraire_institutions(texte):
    return Counter(m.group(0).upper() for m in RE_INSTITUTION.finditer(texte))


def extraire_lieux(texte):
    return Counter(m.group(0) for m in RE_LIEU.finditer(texte))


def extraire_articles(texte):
    return sorted(set(RE_ARTICLE.findall(texte)))


def extraire_orateurs(texte):
    orateurs = Counter()
    for m in RE_ORATEUR.finditer(texte):
        nom = m.group(2).strip()
        if len(nom) < 4 or len(nom.split()) < 2: continue
        if nom.isupper(): continue
        orateurs[f"{m.group(1)} {nom}"] += 1
    return orateurs


# ============================================================
# TRAITEMENT D'UN FICHIER
# ============================================================
def analyser_fichier(chemin_txt):
    texte = chemin_txt.read_text(encoding="utf-8", errors="ignore")
    if normaliser("bumidom") not in normaliser(texte):
        return None

    return {
        "fichier": chemin_txt.name,
        "montants": extraire_montants(texte),
        "pourcentages": extraire_pourcentages(texte),
        "effectifs": extraire_effectifs(texte),
        "logements": extraire_logements(texte),
        "dates": extraire_dates(texte),
        "institutions": dict(extraire_institutions(texte)),
        "lieux": dict(extraire_lieux(texte)),
        "articles": extraire_articles(texte),
        "orateurs": dict(extraire_orateurs(texte)),
    }


# ============================================================
# MAIN
# ============================================================
def main():
    print("🔬 EXTRACTION EXPERTE DES DONNÉES BUMIDOM\n")

    fichiers = sorted(DOSSIER_TXT.glob("*.txt"))
    print(f"📄 {len(fichiers)} fichiers à analyser\n")

    resultats = []
    for i, f in enumerate(fichiers, 1):
        r = analyser_fichier(f)
        if r:
            resultats.append(r)
            if i % 20 == 0:
                print(f"  … {i}/{len(fichiers)}")

    print(f"\n✅ {len(resultats)} documents traités")

    # ------------------------------------------------------------
    # 1. Tous les montants
    # ------------------------------------------------------------
    tous_montants = []
    for r in resultats:
        for m in r["montants"]:
            tous_montants.append({
                "fichier": r["fichier"],
                "valeur": m["valeur"],
                "unite": m["unite"],
                "contexte": m["contexte"][:250],
            })

    # Trie par valeur décroissante
    tous_montants.sort(key=lambda x: -x["valeur"])

    with open(SORTIE_DIR / "01_montants.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["fichier", "valeur_francs", "unite", "contexte"])
        for m in tous_montants:
            w.writerow([m["fichier"], int(m["valeur"]), m["unite"], m["contexte"]])
    print(f"\n📊 {len(tous_montants)} montants → 01_montants.csv")

    # ------------------------------------------------------------
    # 2. Tous les effectifs
    # ------------------------------------------------------------
    tous_effectifs = []
    for r in resultats:
        for e in r["effectifs"]:
            tous_effectifs.append({
                "fichier": r["fichier"],
                "valeur": e["valeur"],
                "unite": e["unite"],
                "contexte": e["contexte"][:250],
            })
    tous_effectifs.sort(key=lambda x: -x["valeur"])

    with open(SORTIE_DIR / "02_effectifs.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["fichier", "nombre", "unite", "contexte"])
        for e in tous_effectifs:
            w.writerow([e["fichier"], e["valeur"], e["unite"], e["contexte"]])
    print(f"📊 {len(tous_effectifs)} effectifs → 02_effectifs.csv")

    # ------------------------------------------------------------
    # 3. Pourcentages
    # ------------------------------------------------------------
    tous_pcts = []
    for r in resultats:
        for p in r["pourcentages"]:
            tous_pcts.append({
                "fichier": r["fichier"],
                "valeur": p["valeur"],
                "contexte": p["contexte"][:250],
            })

    with open(SORTIE_DIR / "03_pourcentages.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["fichier", "pourcentage", "contexte"])
        for p in tous_pcts:
            w.writerow([p["fichier"], p["valeur"], p["contexte"]])
    print(f"📊 {len(tous_pcts)} pourcentages → 03_pourcentages.csv")

    # ------------------------------------------------------------
    # 4. Logements
    # ------------------------------------------------------------
    tous_log = []
    for r in resultats:
        for l in r["logements"]:
            tous_log.append({
                "fichier": r["fichier"],
                "nombre": l["valeur"],
                "unite": l["unite"],
                "contexte": l["contexte"][:200],
            })
    tous_log.sort(key=lambda x: -x["nombre"])

    with open(SORTIE_DIR / "04_logements.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["fichier", "nombre", "type", "contexte"])
        for l in tous_log:
            w.writerow([l["fichier"], l["nombre"], l["unite"], l["contexte"]])
    print(f"📊 {len(tous_log)} logements → 04_logements.csv")

    # ------------------------------------------------------------
    # 5. Institutions
    # ------------------------------------------------------------
    toutes_institutions = Counter()
    for r in resultats:
        for inst, n in r["institutions"].items():
            toutes_institutions[inst] += n

    with open(SORTIE_DIR / "05_institutions.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["institution", "mentions"])
        for inst, n in toutes_institutions.most_common():
            w.writerow([inst, n])
    print(f"📊 {len(toutes_institutions)} institutions → 05_institutions.csv")

    # ------------------------------------------------------------
    # 6. Lieux
    # ------------------------------------------------------------
    tous_lieux = Counter()
    for r in resultats:
        for l, n in r["lieux"].items():
            tous_lieux[l] += n

    with open(SORTIE_DIR / "06_lieux.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["lieu", "mentions"])
        for l, n in tous_lieux.most_common():
            w.writerow([l, n])
    print(f"📊 {len(tous_lieux)} lieux → 06_lieux.csv")

    # ------------------------------------------------------------
    # 7. Articles de loi
    # ------------------------------------------------------------
    tous_articles = Counter()
    for r in resultats:
        for a in r["articles"]:
            tous_articles[a] += 1

    with open(SORTIE_DIR / "07_articles_loi.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["article", "mentions"])
        for a, n in sorted(tous_articles.items()):
            w.writerow([a, n])
    print(f"📊 {len(tous_articles)} articles → 07_articles_loi.csv")

    # ------------------------------------------------------------
    # 8. Dates citées
    # ------------------------------------------------------------
    toutes_dates = Counter()
    for r in resultats:
        for d in r["dates"]:
            toutes_dates[d["date"]] += 1

    with open(SORTIE_DIR / "08_dates.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["date", "mentions"])
        for d, n in toutes_dates.most_common():
            w.writerow([d, n])
    print(f"📊 {len(toutes_dates)} dates → 08_dates.csv")

    # ------------------------------------------------------------
    # 9. Statistiques globales (JSON)
    # ------------------------------------------------------------
    stats_globales = {
        "total_documents": len(resultats),
        "total_montants": len(tous_montants),
        "total_effectifs": len(tous_effectifs),
        "total_pourcentages": len(tous_pcts),
        "total_logements": len(tous_log),
        "montant_max": max((m["valeur"] for m in tous_montants), default=0),
        "montant_min": min((m["valeur"] for m in tous_montants), default=0),
        "effectif_max": max((e["valeur"] for e in tous_effectifs), default=0),
        "top_institutions": toutes_institutions.most_common(20),
        "top_lieux": tous_lieux.most_common(20),
        "top_dates": toutes_dates.most_common(20),
    }
    with open(SORTIE_DIR / "00_statistiques_globales.json", "w", encoding="utf-8") as f:
        json.dump(stats_globales, f, ensure_ascii=False, indent=2)
    print(f"📊 Statistiques globales → 00_statistiques_globales.json")

    # ------------------------------------------------------------
    # 10. Rapport lisible (Markdown)
    # ------------------------------------------------------------
    L = ["# Expertise chiffrée — BUMIDOM\n\n",
         f"*Généré le {__import__('datetime').datetime.now().strftime('%d/%m/%Y %H:%M')}*\n\n---\n\n"]

    L.append("## 1. Volumétrie\n\n")
    L.append(f"- Documents analysés : **{len(resultats)}**\n")
    L.append(f"- Montants cités : **{len(tous_montants)}**\n")
    L.append(f"- Effectifs cités : **{len(tous_effectifs)}**\n")
    L.append(f"- Pourcentages cités : **{len(tous_pcts)}**\n")
    L.append(f"- Logements mentionnés : **{len(tous_log)}**\n\n")

    L.append("## 2. Top 20 montants (francs)\n\n")
    L.append("| Rang | Montant | Fichier |\n|---|---|---|\n")
    for i, m in enumerate(tous_montants[:20], 1):
        L.append(f"| {i} | {int(m['valeur']):,} | {m['fichier']} |\n".replace(",", " "))

    L.append("\n## 3. Top 20 effectifs (personnes)\n\n")
    L.append("| Rang | Nombre | Unité | Fichier |\n|---|---|---|---|\n")
    for i, e in enumerate(tous_effectifs[:20], 1):
        L.append(f"| {i} | {e['valeur']} | {e['unite']} | {e['fichier']} |\n")

    L.append("\n## 4. Top 20 logements\n\n")
    L.append("| Rang | Nombre | Type | Fichier |\n|---|---|---|---|\n")
    for i, l in enumerate(tous_log[:20], 1):
        L.append(f"| {i} | {l['nombre']} | {l['unite']} | {l['fichier']} |\n")

    L.append("\n## 5. Institutions (fréquence)\n\n")
    L.append("| Institution | Mentions |\n|---|---|\n")
    for inst, n in toutes_institutions.most_common(20):
        L.append(f"| {inst} | {n} |\n")

    L.append("\n## 6. Lieux (fréquence)\n\n")
    L.append("| Lieu | Mentions |\n|---|---|\n")
    for l, n in tous_lieux.most_common(20):
        L.append(f"| {l} | {n} |\n")

    L.append("\n## 7. Pourcentages (extraits)\n\n")
    L.append("| % | Fichier |\n|---|---|\n")
    for p in tous_pcts[:30]:
        L.append(f"| {p['valeur']} | {p['fichier']} |\n")

    (SORTIE_DIR / "RAPPORT_EXPERTISE.md").write_text("".join(L), encoding="utf-8")
    print(f"📄 Rapport expert → RAPPORT_EXPERTISE.md")

    # ------------------------------------------------------------
    # Résumé console
    # ------------------------------------------------------------
    print("\n" + "="*60)
    print("✅ EXTRACTION EXPERTE TERMINÉE")
    print("="*60)
    print(f"\n📁 Tous les fichiers sont dans : {SORTIE_DIR}/")
    print("\n📊 Aperçu :")
    print(f"   Montants cités     : {len(tous_montants)}")
    print(f"   Effectifs cités    : {len(tous_effectifs)}")
    print(f"   Pourcentages cités : {len(tous_pcts)}")
    print(f"   Logements cités    : {len(tous_log)}")
    print(f"   Institutions       : {len(toutes_institutions)}")
    print(f"   Lieux              : {len(tous_lieux)}")
    print(f"   Dates              : {len(toutes_dates)}")

    print("\n💰 Top 5 montants :")
    for m in tous_montants[:5]:
        print(f"   {int(m['valeur']):>15,} {m['unite']:8s} — {m['fichier'][:50]}".replace(",", " "))

    print("\n👥 Top 5 effectifs :")
    for e in tous_effectifs[:5]:
        print(f"   {e['valeur']:>8} {e['unite']:15s} — {e['fichier'][:50]}")

    print("\n🏛️  Top institutions :")
    for inst, n in toutes_institutions.most_common(5):
        print(f"   {inst:30s} : {n}")


if __name__ == "__main__":
    main()