#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Enrichissement thématique du corpus BUMIDOM.

Pour chaque thème détecté dans le corpus :
  - Analyse des documents concernés
  - Top orateurs par thème
  - Évolution chronologique
  - Cooccurrences avec d'autres thèmes
  - Extraction des passages clés

Produit :
  - 1 CSV par thème (documents, orateurs, années)
  - 1 JSON consolidé pour le dashboard
  - 1 rapport Markdown
"""

import json
import csv
import re
import unicodedata
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime

# ============================================================
# CONFIGURATION
# ============================================================
DOSSIER_RACINE = Path(".")
FICHIER_DOCS = DOSSIER_RACINE / "resultats_enrichis.json"
DOSSIER_SORTIE = DOSSIER_RACINE / "themes_enrichis"
DOSSIER_SORTIE.mkdir(exist_ok=True)

# Rayon de contexte pour extraire les passages
RAYON_CONTEXTE = 400


# ============================================================
# UTILITAIRES
# ============================================================
def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()


def slug(s):
    s = normaliser(s)
    s = re.sub(r"[^a-z0-9]+", "_", s)
    return s.strip("_")


def esc_csv(s, sep=";"):
    """Échappe une chaîne pour CSV."""
    if s is None:
        return ""
    s = str(s).replace("\n", " ").replace("\r", " ")
    s = " ".join(s.split())
    if sep in s or '"' in s:
        s = '"' + s.replace('"', '""') + '"'
    return s


def charger_documents():
    """Charge resultats_enrichis.json."""
    if not FICHIER_DOCS.exists():
        print(f"❌ Fichier introuvable : {FICHIER_DOCS}")
        print("   Assurez-vous d'être à la racine du projet.")
        return None
    
    with open(FICHIER_DOCS, encoding="utf-8") as f:
        data = json.load(f)
    
    return data.get("results", [])


def extraire_annee(fichier):
    """Extrait l'année depuis le nom de fichier."""
    m = re.search(r"(\d{4})", fichier)
    return int(m.group(1)) if m else None


def type_document(fichier):
    """Détermine le type de document."""
    if "_qst_" in fichier:
        return "Question écrite"
    if "_cri_" in fichier:
        return "Compte rendu"
    if "tanalytique" in fichier:
        return "Table analytique"
    return "Autre"


# ============================================================
# ANALYSE PAR THÈME
# ============================================================
def analyser_theme(nom_theme, documents):
    """Analyse tous les documents pour un thème donné."""
    
    # Documents traitant du thème
    docs_theme = [d for d in documents if d.get("themes") and nom_theme in d["themes"]]
    
    if not docs_theme:
        return None
    
    # ---- 1. Statistiques générales ----
    total_occurrences = sum(d["themes"].get(nom_theme, 0) for d in docs_theme)
    
    # ---- 2. Répartition par année ----
    par_annee = defaultdict(lambda: {"documents": 0, "occurrences": 0})
    for d in docs_theme:
        annee = extraire_annee(d.get("fichier", ""))
        if annee:
            par_annee[annee]["documents"] += 1
            par_annee[annee]["occurrences"] += d["themes"].get(nom_theme, 0)
    
    # ---- 3. Top orateurs sur ce thème ----
    orateurs_theme = Counter()
    for d in docs_theme:
        for o in d.get("orateurs", []):
            orateurs_theme[o["nom"]] += o.get("occurrences", 1)
    
    top_orateurs = orateurs_theme.most_common(30)
    
    # ---- 4. Cooccurrences avec d'autres thèmes ----
    cooccurrences = Counter()
    for d in docs_theme:
        for autre_theme, n in d.get("themes", {}).items():
            if autre_theme != nom_theme:
                cooccurrences[autre_theme] += n
    
    top_cooccurrences = cooccurrences.most_common(10)
    
    # ---- 5. Documents détaillés ----
    docs_details = []
    for d in docs_theme:
        annee = extraire_annee(d.get("fichier", ""))
        docs_details.append({
            "fichier": d.get("fichier", ""),
            "annee": annee,
            "occurrences_theme": d["themes"].get(nom_theme, 0),
            "mentions_bumidom": d.get("nb_mentions", 0),
            "type": type_document(d.get("fichier", "")),
            "orateurs": [o["nom"] for o in d.get("orateurs", [])[:5]],
            "legislatures": d.get("legislatures", []),
        })
    
    # Trier par occurrences décroissantes
    docs_details.sort(key=lambda x: -x["occurrences_theme"])
    
    # ---- 6. Extraction des passages clés ----
    passages_cles = []
    for d in docs_theme[:20]:  # Top 20 documents
        for e in d.get("extraits", [])[:3]:
            if isinstance(e, dict) and "extrait" in e:
                passages_cles.append({
                    "fichier": d.get("fichier", ""),
                    "annee": extraire_annee(d.get("fichier", "")),
                    "page": e.get("page_approx", "?"),
                    "extrait": e.get("extrait", "")[:RAYON_CONTEXTE],
                })
    
    return {
        "theme": nom_theme,
        "total_documents": len(docs_theme),
        "total_occurrences": total_occurrences,
        "par_annee": dict(par_annee),
        "top_orateurs": top_orateurs,
        "cooccurrences": top_cooccurrences,
        "documents": docs_details,
        "passages_cles": passages_cles,
    }


# ============================================================
# GÉNÉRATION DES FICHIERS
# ============================================================
def sauvegarder_csv_theme(analyse):
    """Sauvegarde les données d'un thème en CSV."""
    nom = slug(analyse["theme"])
    
    # ---- Fichier principal ----
    fichier_csv = DOSSIER_SORTIE / f"theme_{nom}.csv"
    with open(fichier_csv, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["=== THÈME ===", analyse["theme"]])
        w.writerow(["Total documents", analyse["total_documents"]])
        w.writerow(["Total occurrences", analyse["total_occurrences"]])
        w.writerow([])
        
        # Orateurs
        w.writerow(["=== TOP ORATEURS ==="])
        w.writerow(["Rang", "Orateur", "Mentions"])
        for i, (nom_o, n) in enumerate(analyse["top_orateurs"], 1):
            w.writerow([i, esc_csv(nom_o), n])
        w.writerow([])
        
        # Cooccurrences
        w.writerow(["=== COOCCURRENCES ==="])
        w.writerow(["Thème associé", "Occurrences"])
        for theme_co, n in analyse["cooccurrences"]:
            w.writerow([esc_csv(theme_co), n])
        w.writerow([])
        
        # Documents
        w.writerow(["=== DOCUMENTS ==="])
        w.writerow(["Fichier", "Année", "Occurrences", "Mentions BUMIDOM", "Type"])
        for d in analyse["documents"]:
            w.writerow([
                esc_csv(d["fichier"]),
                d["annee"] or "",
                d["occurrences_theme"],
                d["mentions_bumidom"],
                esc_csv(d["type"]),
            ])
    
    # ---- Fichier chronologie ----
    fichier_chrono = DOSSIER_SORTIE / f"theme_{nom}_chrono.csv"
    with open(fichier_chrono, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["Année", "Documents", "Occurrences"])
        for annee in sorted(analyse["par_annee"].keys()):
            data = analyse["par_annee"][annee]
            w.writerow([annee, data["documents"], data["occurrences"]])
    
    # ---- Fichier passages clés ----
    if analyse["passages_cles"]:
        fichier_passages = DOSSIER_SORTIE / f"theme_{nom}_passages.csv"
        with open(fichier_passages, "w", encoding="utf-8", newline="") as f:
            w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
            w.writerow(["Fichier", "Année", "Page", "Extrait"])
            for p in analyse["passages_cles"]:
                w.writerow([
                    esc_csv(p["fichier"]),
                    p["annee"] or "",
                    p["page"],
                    esc_csv(p["extrait"]),
                ])
    
    return fichier_csv


def sauvegarder_json_consolide(analyses):
    """Sauvegarde un JSON consolidé pour le dashboard."""
    data = {
        "date_generation": datetime.now().isoformat(),
        "nombre_themes": len(analyses),
        "themes": {},
    }
    
    for analyse in analyses:
        if analyse is None:
            continue
        nom = analyse["theme"]
        data["themes"][nom] = {
            "slug": slug(nom),
            "total_documents": analyse["total_documents"],
            "total_occurrences": analyse["total_occurrences"],
            "par_annee": analyse["par_annee"],
            "top_orateurs": [
                {"nom": n, "mentions": m} for n, m in analyse["top_orateurs"]
            ],
            "cooccurrences": [
                {"theme": t, "occurrences": m} for t, m in analyse["cooccurrences"]
            ],
            "documents": analyse["documents"][:100],
            "passages_cles": analyse["passages_cles"][:20],
        }
    
    fichier = DOSSIER_SORTIE / "themes_consolide.json"
    with open(fichier, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    return fichier


def sauvegarder_rapport_markdown(analyses):
    """Génère un rapport Markdown complet."""
    L = ["# Analyse thématique du corpus BUMIDOM\n\n",
         f"*Généré le {datetime.now().strftime('%d/%m/%Y %H:%M')}*\n\n---\n\n"]
    
    L.append("## 📊 Vue d'ensemble\n\n")
    L.append("| Thème | Documents | Occurrences |\n")
    L.append("|---|---|---|\n")
    for analyse in sorted(analyses, key=lambda x: -(x["total_occurrences"] if x else 0)):
        if analyse is None:
            continue
        L.append(f"| {analyse['theme']} | {analyse['total_documents']} | "
                 f"{analyse['total_occurrences']} |\n")
    
    L.append("\n---\n\n")
    
    # Détail par thème
    for analyse in sorted(analyses, key=lambda x: -(x["total_occurrences"] if x else 0)):
        if analyse is None:
            continue
        
        L.append(f"## 🏷️ {analyse['theme']}\n\n")
        L.append(f"- **Documents** : {analyse['total_documents']}\n")
        L.append(f"- **Occurrences** : {analyse['total_occurrences']}\n\n")
        
        # Orateurs
        if analyse["top_orateurs"]:
            L.append("### 🎤 Top orateurs\n\n")
            L.append("| Rang | Orateur | Mentions |\n")
            L.append("|---|---|---|\n")
            for i, (nom, n) in enumerate(analyse["top_orateurs"][:10], 1):
                L.append(f"| {i} | {nom} | {n} |\n")
            L.append("\n")
        
        # Cooccurrences
        if analyse["cooccurrences"]:
            L.append("### 🔗 Thèmes associés\n\n")
            for theme_co, n in analyse["cooccurrences"][:5]:
                L.append(f"- **{theme_co}** ({n} occurrences)\n")
            L.append("\n")
        
        # Chronologie
        if analyse["par_annee"]:
            L.append("### 📅 Évolution chronologique\n\n")
            L.append("| Année | Documents | Occurrences |\n")
            L.append("|---|---|---|\n")
            for annee in sorted(analyse["par_annee"].keys()):
                data = analyse["par_annee"][annee]
                L.append(f"| {annee} | {data['documents']} | {data['occurrences']} |\n")
            L.append("\n")
        
        L.append("---\n\n")
    
    fichier = DOSSIER_SORTIE / "RAPPORT_THEMES.md"
    with open(fichier, "w", encoding="utf-8") as f:
        f.write("".join(L))
    
    return fichier


# ============================================================
# MAIN
# ============================================================
def main():
    print("🏷️  ENRICHISSEMENT THÉMATIQUE DU CORPUS BUMIDOM\n")
    
    documents = charger_documents()
    if documents is None:
        return
    
    print(f"📄 {len(documents)} documents chargés\n")
    
    # ---- Détecter tous les thèmes ----
    tous_themes = Counter()
    for d in documents:
        for theme, n in d.get("themes", {}).items():
            tous_themes[theme] += n
    
    themes_tries = [t for t, _ in tous_themes.most_common()]
    print(f"🏷️  {len(themes_tries)} thèmes détectés :\n")
    for i, (t, n) in enumerate(tous_themes.most_common(), 1):
        print(f"   {i:2d}. {t:20s} ({n} occurrences)")
    print()
    
    # ---- Analyser chaque thème ----
    print("🔬 Analyse des thèmes...\n")
    analyses = []
    for i, theme in enumerate(themes_tries, 1):
        print(f"  … {i}/{len(themes_tries)} : {theme}")
        analyse = analyser_theme(theme, documents)
        if analyse:
            analyses.append(analyse)
            sauvegarder_csv_theme(analyse)
    
    print(f"\n✅ {len(analyses)} thèmes analysés")
    
    # ---- Sauvegarder JSON consolidé ----
    fichier_json = sauvegarder_json_consolide(analyses)
    print(f"📦 JSON consolidé → {fichier_json}")
    
    # ---- Rapport Markdown ----
    fichier_rapport = sauvegarder_rapport_markdown(analyses)
    print(f"📄 Rapport → {fichier_rapport}")
    
    # ---- Résumé console ----
    print("\n" + "=" * 60)
    print("✅ ENRICHISSEMENT TERMINÉ")
    print("=" * 60)
    print(f"\n📁 Fichiers dans : {DOSSIER_SORTIE}/")
    print(f"\n📊 Top 5 thèmes par occurrences :")
    for analyse in sorted(analyses, key=lambda x: -x["total_occurrences"])[:5]:
        print(f"   {analyse['theme']:20s} : {analyse['total_documents']:3d} docs, "
              f"{analyse['total_occurrences']:5d} occurrences")


if __name__ == "__main__":
    main()