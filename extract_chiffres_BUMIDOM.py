#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extrait UNIQUEMENT les chiffres liés au BUMIDOM
(présents dans un rayon de N caractères autour du mot).
"""

import re, csv, unicodedata
from pathlib import Path

DOSSIER_TXT = Path("textes")
SORTIE      = Path("expertise_BUMIDOM")
SORTIE.mkdir(exist_ok=True)

# Rayon de contexte (en caractères)
RAYON = 800

# Regex
RE_DATE_LONGUE = re.compile(
    r"\b(\d{1,2})\s+(janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[uû]t|"
    r"septembre|octobre|novembre|d[ée]cembre)\s+(\d{4})\b", re.IGNORECASE)

RE_MONTANT = re.compile(
    r"\b(\d{1,3}(?:[\s\u00a0]\d{3})+(?:,\d+)?)\s*(francs?|F\b|NF\b)",
    re.IGNORECASE)

RE_EFFECTIF = re.compile(
    r"\b(\d{1,3}(?:[\s\u00a0]\d{3})+|\d{4,7})\s*"
    r"(migrants?|travailleurs?|Réunionnais|Antillais|personnes?|"
    r"habitants?|jeunes|stagiaires?|logements?|lits?|places?|foyers?)",
    re.IGNORECASE)

RE_POURCENTAGE = re.compile(
    r"\b(\d{1,3}(?:[.,]\d+)?)\s*(?:%|pour\s*cent|p\.\s*100)", re.IGNORECASE)

RE_LOGEMENT = re.compile(
    r"\b(\d{1,4})\s*(logements?|lits?|foyers?|chambres?|places?)", re.IGNORECASE)

RE_ARTICLE = re.compile(r"\barticle\s+(\d+[a-z]?)\b", re.IGNORECASE)


def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()


def trouver_positions_bumidom(texte):
    """Retourne toutes les positions du mot 'bumidom' dans le texte."""
    tn = normaliser(texte)
    return [m.start() for m in re.finditer(r"bumidom", tn)]


def extraire_dans_rayon(texte, positions, regex, valider=None):
    """Extrait les matches de `regex` dont la position est proche
    d'au moins une position BUMIDOM (dans le rayon RAYON)."""
    resultats = []
    for m in regex.finditer(texte):
        pos = m.start()
        if any(abs(pos - p) <= RAYON for p in positions):
            ctx = contexte_serre(texte, pos, 400)
            if valider is None or valider(m, ctx):
                resultats.append({
                    "match": m.group(0).strip(),
                    "groupes": m.groups(),
                    "position": pos,
                    "contexte": ctx,
                })
    return resultats


def contexte_serre(texte, pos, taille=400):
    """Contexte court et propre autour d'une position."""
    deb = max(0, pos - taille)
    fin = min(len(texte), pos + taille)
    # Cherche les limites de phrases
    avant = texte.rfind(".", deb, pos)
    apres = texte.find(".", pos, fin)
    if avant == -1: avant = deb
    if apres == -1: apres = fin
    ctx = texte[avant+1:apres+1]
    ctx = re.sub(r"\s+", " ", ctx.replace("\n", " ")).strip()
    return ctx


def nettoyer_nombre(s):
    s = re.sub(r"[\s\u00a0]", "", s).replace(",", ".")
    try: return float(s)
    except: return None


# ============================================================
# TRAITEMENT PAR FICHIER
# ============================================================
def analyser_fichier(chemin):
    texte = chemin.read_text(encoding="utf-8", errors="ignore")
    positions = trouver_positions_bumidom(texte)
    if not positions:
        return None

    resultats = {
        "fichier": chemin.name,
        "nb_mentions": len(positions),
        "montants": [],
        "effectifs": [],
        "pourcentages": [],
        "logements": [],
        "articles": [],
        "dates": [],
    }

    # Montants (dans rayon BUMIDOM)
    for m in extraire_dans_rayon(texte, positions, RE_MONTANT):
        v = nettoyer_nombre(m["groupes"][0])
        if v and 100 <= v <= 10_000_000_000:  # max 10 milliards (réaliste)
            resultats["montants"].append({
                "valeur": v, "unite": m["groupes"][1],
                "contexte": m["contexte"][:350],
            })

    # Effectifs
    for m in extraire_dans_rayon(texte, positions, RE_EFFECTIF):
        v = nettoyer_nombre(m["groupes"][0])
        if v and 5 <= v <= 5_000_000:
            resultats["effectifs"].append({
                "valeur": int(v), "unite": m["groupes"][1],
                "contexte": m["contexte"][:350],
            })

    # Pourcentages
    for m in extraire_dans_rayon(texte, positions, RE_POURCENTAGE):
        v = m["groupes"][0].replace(",", ".")
        try:
            f = float(v)
            if 0 < f <= 100:
                resultats["pourcentages"].append({
                    "valeur": v, "contexte": m["contexte"][:300],
                })
        except: pass

    # Logements
    for m in extraire_dans_rayon(texte, positions, RE_LOGEMENT):
        v = int(m["groupes"][0])
        if 5 <= v <= 10_000:
            resultats["logements"].append({
                "valeur": v, "unite": m["groupes"][1],
                "contexte": m["contexte"][:300],
            })

    # Articles de loi
    for m in extraire_dans_rayon(texte, positions, RE_ARTICLE):
        resultats["articles"].append(m["match"])

    # Dates
    for m in extraire_dans_rayon(texte, positions, RE_DATE_LONGUE):
        resultats["dates"].append(m["match"])

    return resultats


# ============================================================
# MAIN
# ============================================================
def main():
    print("🎯 EXTRACTION BUMIDOM-SPÉCIFIQUE (chiffres dans le contexte immédiat)\n")

    fichiers = sorted(DOSSIER_TXT.glob("*.txt"))
    tous = []
    for i, f in enumerate(fichiers, 1):
        r = analyser_fichier(f)
        if r:
            tous.append(r)
        if i % 20 == 0:
            print(f"  … {i}/{len(fichiers)}")

    print(f"\n✅ {len(tous)} documents BUMIDOM traités\n")

    # Aplatir les résultats
    tous_montants = []
    tous_effectifs = []
    tous_pcts = []
    tous_logements = []
    tous_articles = []
    tous_dates = []

    for d in tous:
        for m in d["montants"]:
            tous_montants.append({"fichier": d["fichier"], **m})
        for e in d["effectifs"]:
            tous_effectifs.append({"fichier": d["fichier"], **e})
        for p in d["pourcentages"]:
            tous_pcts.append({"fichier": d["fichier"], **p})
        for l in d["logements"]:
            tous_logements.append({"fichier": d["fichier"], **l})
        for a in d["articles"]:
            tous_articles.append({"fichier": d["fichier"], "article": a})
        for dt in d["dates"]:
            tous_dates.append({"fichier": d["fichier"], "date": dt})

    # Sauvegarde CSV
    def dump_csv(nom, rows, colonnes):
        with open(SORTIE / nom, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, delimiter=";")
            w.writerow(colonnes)
            for r in rows:
                w.writerow([r.get(c, "") for c in colonnes])

    tous_montants.sort(key=lambda x: -x["valeur"])
    dump_csv("BUMIDOM_montants.csv", tous_montants,
             ["fichier", "valeur", "unite", "contexte"])

    tous_effectifs.sort(key=lambda x: -x["valeur"])
    dump_csv("BUMIDOM_effectifs.csv", tous_effectifs,
             ["fichier", "valeur", "unite", "contexte"])

    dump_csv("BUMIDOM_pourcentages.csv", tous_pcts,
             ["fichier", "valeur", "contexte"])

    tous_logements.sort(key=lambda x: -x["valeur"])
    dump_csv("BUMIDOM_logements.csv", tous_logements,
             ["fichier", "valeur", "unite", "contexte"])

    dump_csv("BUMIDOM_articles.csv", tous_articles, ["fichier", "article"])
    dump_csv("BUMIDOM_dates.csv", tous_dates, ["fichier", "date"])

    # Résumé console
    print("📊 Résultats BUMIDOM-SPÉCIFIQUES :")
    print(f"   💰 Montants      : {len(tous_montants)}")
    print(f"   👥 Effectifs     : {len(tous_effectifs)}")
    print(f"   📊 Pourcentages  : {len(tous_pcts)}")
    print(f"   🏠 Logements     : {len(tous_logements)}")
    print(f"   📜 Articles      : {len(tous_articles)}")
    print(f"   📅 Dates         : {len(tous_dates)}")

    print(f"\n💰 Top 10 montants BUMIDOM :")
    for m in tous_montants[:10]:
        v = int(m["valeur"])
        print(f"   {v:>15,} {m['unite']:6s} — {m['fichier'][:45]}".replace(",", " "))

    print(f"\n👥 Top 10 effectifs BUMIDOM :")
    for e in tous_effectifs[:10]:
        print(f"   {e['valeur']:>8,} {e['unite']:15s} — {e['fichier'][:45]}".replace(",", " "))

    print(f"\n📁 Tous les fichiers dans : {SORTIE}/")


if __name__ == "__main__":
    main()
