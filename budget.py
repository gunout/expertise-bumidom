#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extraction budgétaire BUMIDOM — version pragmatique avec score composite.

Score 0-13 basé sur :
- Densité BUMIDOM du document (0-3)
- Distance à la mention BUMIDOM (0-5)
- Vocabulaire budgétaire (0-2)
- Section budgétaire (TITRE, Article) (0-3)
"""

import re
import csv
import json
import unicodedata
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime

DOSSIER_TXT = Path("textes")
SORTIE      = Path("expertise_BUMIDOM")
SORTIE.mkdir(exist_ok=True)

# ✅ Paramètres
PLAFOND_ABSOLU = 2e9
FOURCHETTE_BUMIDOM = (1e6, 5e8)   # 1 M à 500 M F
PLANCHER_MONTANT = 100
TAILLE_MIN_PARAGRAPHE = 80
FENETRE_ADJACENCE = 1
FENETRE_PCT_SENS = 500
SEUIL_PCT_MAX = 100

# ============================================================
# PATTERNS
# ============================================================
RE_BUDGET_BUMIDOM_STRICT = re.compile(
    r"(budget|cr[ée]dits?|subventions?|d[ée]penses?|dotation|"
    r"ressources?|financement|apports?|enveloppe)\s+"
    r"(?:du\s+|de\s+|d[eu]\s+|pour\s+le\s+|allou[ée]s?\s+au\s+|"
    r"affect[ée]s?\s+au\s+|consacr[ée]s?\s+au\s+|d[ée]di[ée]s?\s+au\s+)?"
    r"BUMIDOM\b",
    re.IGNORECASE
)

RE_CONTEXTE_DOM_GLOBAL = re.compile(
    r"(?:budget|cr[ée]dits?|d[ée]penses?|ressources?|enveloppe)\s+"
    r"(?:des?\s+|du\s+)?"
    r"(?:d[ée]partements?\s+d'outre[- ]mer|DOM\b|"
    r"collectivit[ée]s?\s+d'outre[- ]mer|"
    r"minist[èe]re\s+des?\s+DOM|"
    r"budget\s+g[ée]n[ée]ral|budget\s+global)",
    re.IGNORECASE
)

RE_CTX_BUDGET = re.compile(
    r"budget|cr[ée]dit|subvention|dotation|financement|"
    r"ressource|d[ée]pense|fiscal|imp[oô]t|recette|"
    r"titre\s+[IVX]+|article\s+\d+",
    re.IGNORECASE
)

RE_SECTION = re.compile(
    r"(TITRE\s+[IVX]+|Article\s+\d+|CHAPITRE\s+[IVX\d]+)",
    re.IGNORECASE
)

RE_MONTANT = re.compile(
    r"\b(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d{1,2})?|\d{4,15}(?:,\d{1,2})?)\s*"
    r"(francs?|F\b|NF\b|nouveaux\s+francs?|centimes?)",
    re.IGNORECASE
)

RE_MONTANT_GRAND = re.compile(
    r"\b(\d{1,4}(?:[.,]\d{1,2})?)\s*"
    r"(millions?|milliards?|M\s*F|Md\s*F|MF|MdF)\s*"
    r"(?:de\s+)?(francs?)?",
    re.IGNORECASE
)

RE_SENS = re.compile(
    r"\b(augmentation|hausse|progression|accroissement|baisse|diminution|r[ée]duction)\b",
    re.IGNORECASE
)

RE_PCT = re.compile(
    r"(\d{1,3}(?:[.,]\d+)?)\s*(?:%|pour\s*cent|p\.?\s*100)",
    re.IGNORECASE
)

RE_COMPARAISON = re.compile(
    r"passe\s+(?:de\s+|d'un\s+montant\s+de\s+)"
    r"(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,15})\s*(?:francs?|F\b)?"
    r"\s+à\s+"
    r"(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,15})\s*(?:francs?|F\b)?",
    re.IGNORECASE
)

RE_CREDITS = re.compile(
    r"\b(?:cr[ée]dits?)\s+"
    r"(?:de\s+|d'un\s+montant\s+de\s+|s'[ée]levant\s+à\s+)?"
    r"(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,15})",
    re.IGNORECASE
)

RE_SUBVENTIONS = re.compile(
    r"\bsubventions?\s+"
    r"(?:de\s+|d'un\s+montant\s+de\s+|s'[ée]levant\s+à\s+)?"
    r"(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,15})",
    re.IGNORECASE
)

RE_MINISTERE = re.compile(
    r"\b(Ministère\s+(?:des?\s+)?(?:DOM|Outre[- ]mer|Finances|Budget|Intérieur)|"
    r"Secrétariat\s+d'[ÉE]tat\s+(?:aux?\s+)?(?:DOM|Outre[- ]mer))\b",
    re.IGNORECASE
)

RE_EXERCICE = re.compile(
    r"\b(?:exercice|budget|ann[ée]e|cr[ée]dits?)\s+(?:de\s+|du\s+|pour\s+)?(\d{4})",
    re.IGNORECASE
)

NATURES_DEPENSE = {
    "personnel": r"personnel|traitements?|salaires?|r[ée]mun[ée]rations?",
    "fonctionnement": r"fonctionnement|mat[ée]riel|fournitures",
    "investissement": r"investissement|[ée]quipement|immobilier|construction",
    "subvention": r"subventions?|aides?|allocations?",
    "transfert": r"transferts?|versements?",
    "logement": r"logements?|h[ée]bergement|foyers?",
    "formation": r"formation|stage|apprentissage",
    "transport": r"transport|voyage|d[ée]placement",
}

NATURES_RESSOURCE = {
    "etat": r"[ÉE]tat|budget\s+g[ée]n[ée]ral|cr[ée]dits?\s+minist[ée]riels?",
    "collectivites": r"collectivit[ée]s?|conseils?\s+g[ée]n[ée]raux?|r[ée]gions?",
    "europe": r"europ[ée]en|CEE|Communaut[ée]",
    "emprunt": r"emprunts?|dettes?",
    "recettes_propres": r"recettes?\s+propres?|cotisations?",
}


# ============================================================
# UTILITAIRES
# ============================================================
def normaliser(t):
    t = unicodedata.normalize("NFKD", t)
    return "".join(c for c in t if not unicodedata.combining(c)).lower()


def nettoyer_nombre(s):
    if s is None:
        return None
    s = str(s)
    s = re.sub(r"[\s\u00a0]", "", s)
    if s.count(".") > 1 or (s.count(".") == 1 and s.count(",") == 1):
        s = s.replace(".", "")
    s = s.replace(",", ".")
    try:
        return float(s)
    except:
        return None


def nettoyer_contexte(ctx, max_len=300):
    if not ctx:
        return ""
    ctx = str(ctx)
    ctx = ctx.replace(";", " ").replace("\n", " ").replace("\r", " ")
    ctx = ctx.replace("\t", " ")
    ctx = " ".join(ctx.split())
    return ctx[:max_len]


def decouper_paragraphes(texte):
    paragraphes = []
    blocs = re.split(r"\n\s*\n", texte)
    position = 0
    for i, bloc in enumerate(blocs):
        bloc = bloc.strip()
        if not bloc:
            continue
        idx = texte.find(bloc, position)
        if idx == -1:
            idx = position
        paragraphes.append({
            "texte": bloc,
            "debut": idx,
            "fin": idx + len(bloc),
            "index": len(paragraphes),
        })
        position = idx + len(bloc)

    if len(paragraphes) <= 1 and len(texte) > 1000:
        paragraphes = []
        for m in re.finditer(r"[^.]{100,800}\.", texte):
            bloc = m.group(0).strip()
            if len(bloc) >= TAILLE_MIN_PARAGRAPHE:
                paragraphes.append({
                    "texte": bloc,
                    "debut": m.start(),
                    "fin": m.end(),
                    "index": len(paragraphes),
                })
    return paragraphes


def paragraphes_bumidom(paragraphes, fenetre=None):
    """Propagation par densité BUMIDOM."""
    positions = [p["index"] for p in paragraphes
                 if "bumidom" in normaliser(p["texte"])]
    nb_mentions = len(positions)

    if nb_mentions == 0:
        return set()

    if nb_mentions >= 5:
        return {p["index"] for p in paragraphes}

    if fenetre is None:
        fenetre = 3 if nb_mentions >= 2 else 1

    indices_bumidom = set()
    for idx in positions:
        for offset in range(-fenetre, fenetre + 1):
            indices_bumidom.add(idx + offset)

    n = len(paragraphes)
    return {i for i in indices_bumidom if 0 <= i < n}


def calculer_score(texte_complet, position, positions_bumidom, densite_doc):
    """✅ NOUVEAU : Score composite 0-13.

    Composantes :
    - Densité BUMIDOM du document (0-3 pts)
    - Distance à BUMIDOM (0-5 pts)
    - Vocabulaire budgétaire (0-2 pts)
    - Section budgétaire (0-3 pts)
    """
    score = 0
    details = {}

    # 1. Densité BUMIDOM (0-3 pts)
    if densite_doc >= 5:
        pts = 3
    elif densite_doc >= 2:
        pts = 2
    elif densite_doc >= 1:
        pts = 1
    else:
        pts = 0
    score += pts
    details["densite"] = pts

    # 2. Distance à BUMIDOM (0-5 pts)
    if positions_bumidom:
        dist_min = min(abs(position - p) for p in positions_bumidom)
        if dist_min < 500:
            pts = 5
        elif dist_min < 2000:
            pts = 4
        elif dist_min < 5000:
            pts = 3
        elif dist_min < 20000:
            pts = 2
        elif dist_min < 50000:
            pts = 1
        else:
            pts = 0
    else:
        pts = 0
    score += pts
    details["distance"] = pts

    # 3. Vocabulaire budgétaire (0-2 pts)
    ctx = texte_complet[max(0, position - 300):position + 300]
    if RE_CTX_BUDGET.search(ctx):
        pts = 2
    else:
        pts = 0
    score += pts
    details["budget_ctx"] = pts

    # 4. Section budgétaire (0-3 pts)
    ctx_avant = texte_complet[max(0, position - 500):position]
    if RE_SECTION.search(ctx_avant):
        pts = 3
    else:
        pts = 0
    score += pts
    details["section"] = pts

    return score, details


def score_en_label(score):
    """Convertit un score 0-13 en label de confiance."""
    if score >= 10:
        return "strict"
    elif score >= 7:
        return "proche"
    elif score >= 4:
        return "moyen"
    else:
        return "large"


def est_dans_fourchette_bumidom(valeur):
    return FOURCHETTE_BUMIDOM[0] <= valeur <= FOURCHETTE_BUMIDOM[1]


# ============================================================
# EXTRACTIONS
# ============================================================
def extraire_matchs_avec_score(paragraphes, indices, positions_bumidom_abs,
                               texte_complet, densite_doc,
                               pattern, groupe_valeur=1, groupe_unite=None,
                               filtre_min=None, filtre_max=None,
                               contexte_taille=400):
    """Extraction avec score composite."""
    resultats = []
    for p in paragraphes:
        if p["index"] not in indices:
            continue
        texte_p = p["texte"]

        for m in pattern.finditer(texte_p):
            pos_abs = p["debut"] + m.start()
            if m.lastindex is None or m.lastindex < groupe_valeur:
                continue

            val = nettoyer_nombre(m.group(groupe_valeur))
            if val is None:
                continue
            if filtre_min is not None and val < filtre_min:
                continue
            if filtre_max is not None and val > filtre_max:
                continue

            unite = ""
            if groupe_unite is not None and m.lastindex >= groupe_unite:
                unite = m.group(groupe_unite) or ""

            ctx = texte_p[:contexte_taille]

            # ✅ Score composite
            score, details = calculer_score(
                texte_complet, pos_abs, positions_bumidom_abs, densite_doc
            )
            confiance = score_en_label(score)

            # Contexte étendu autour du montant
            ctx_etendu = texte_complet[max(0, pos_abs - 200):min(len(texte_complet), pos_abs + 400)]

            resultats.append({
                "valeur": val,
                "unite": unite,
                "position": pos_abs,
                "contexte": ctx_etendu,
                "score": score,
                "score_details": details,
                "confiance": confiance,
                "dans_fourchette": est_dans_fourchette_bumidom(val),
            })
    return resultats


def extraire_montants_francs(paragraphes, indices, positions_abs, texte, densite):
    return extraire_matchs_avec_score(
        paragraphes, indices, positions_abs, texte, densite,
        RE_MONTANT, groupe_valeur=1, groupe_unite=2,
        filtre_min=PLANCHER_MONTANT, filtre_max=PLAFOND_ABSOLU
    )


def extraire_montants_grands(paragraphes, indices, positions_abs, texte, densite):
    resultats = []
    for p in paragraphes:
        if p["index"] not in indices:
            continue
        for m in RE_MONTANT_GRAND.finditer(p["texte"]):
            val = nettoyer_nombre(m.group(1))
            if val is None:
                continue
            unite = (m.group(2) or "").lower()
            if "milliard" in unite or "md" in unite:
                val_fr = val * 1e9
            else:
                val_fr = val * 1e6

            if val_fr < PLANCHER_MONTANT or val_fr > PLAFOND_ABSOLU:
                continue

            pos_abs = p["debut"] + m.start()
            score, details = calculer_score(texte, pos_abs, positions_abs, densite)
            confiance = score_en_label(score)
            ctx_etendu = texte[max(0, pos_abs - 200):min(len(texte), pos_abs + 400)]

            resultats.append({
                "valeur": val_fr,
                "valeur_affichee": f"{val} {m.group(2)}",
                "unite": m.group(2),
                "position": pos_abs,
                "contexte": ctx_etendu,
                "score": score,
                "score_details": details,
                "confiance": confiance,
                "dans_fourchette": est_dans_fourchette_bumidom(val_fr),
            })
    return resultats


def extraire_credits(paragraphes, indices, positions_abs, texte, densite):
    return extraire_matchs_avec_score(
        paragraphes, indices, positions_abs, texte, densite,
        RE_CREDITS, groupe_valeur=1,
        filtre_min=PLANCHER_MONTANT, filtre_max=PLAFOND_ABSOLU
    )


def extraire_subventions(paragraphes, indices, positions_abs, texte, densite):
    return extraire_matchs_avec_score(
        paragraphes, indices, positions_abs, texte, densite,
        RE_SUBVENTIONS, groupe_valeur=1,
        filtre_min=PLANCHER_MONTANT, filtre_max=PLAFOND_ABSOLU
    )


def extraire_depenses(paragraphes, indices, positions_abs, texte, densite):
    resultats = []
    for nature, pat in NATURES_DEPENSE.items():
        pattern = re.compile(
            rf"\b(?:{pat})\b[^.]{{0,80}}?"
            r"(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,15})",
            re.IGNORECASE
        )
        for p in paragraphes:
            if p["index"] not in indices:
                continue
            for m in pattern.finditer(p["texte"]):
                val = nettoyer_nombre(m.group(1))
                if val and PLANCHER_MONTANT <= val <= PLAFOND_ABSOLU:
                    pos_abs = p["debut"] + m.start()
                    score, details = calculer_score(texte, pos_abs, positions_abs, densite)
                    resultats.append({
                        "nature": nature,
                        "valeur": val,
                        "position": pos_abs,
                        "contexte": texte[max(0, pos_abs - 200):min(len(texte), pos_abs + 400)],
                        "score": score,
                        "score_details": details,
                        "confiance": score_en_label(score),
                    })
    return resultats


def extraire_ressources(paragraphes, indices, positions_abs, texte, densite):
    resultats = []
    for nature, pat in NATURES_RESSOURCE.items():
        pattern = re.compile(
            rf"\b(?:{pat})\b[^.]{{0,80}}?"
            r"(\d{1,3}(?:[\s\u00a0\.]\d{3})+(?:,\d+)?|\d{4,15})",
            re.IGNORECASE
        )
        for p in paragraphes:
            if p["index"] not in indices:
                continue
            for m in pattern.finditer(p["texte"]):
                val = nettoyer_nombre(m.group(1))
                if val and PLANCHER_MONTANT <= val <= PLAFOND_ABSOLU:
                    pos_abs = p["debut"] + m.start()
                    score, details = calculer_score(texte, pos_abs, positions_abs, densite)
                    resultats.append({
                        "nature": nature,
                        "valeur": val,
                        "position": pos_abs,
                        "contexte": texte[max(0, pos_abs - 200):min(len(texte), pos_abs + 400)],
                        "score": score,
                        "score_details": details,
                        "confiance": score_en_label(score),
                    })
    return resultats


def extraire_evolutions(paragraphes, indices):
    resultats = []
    for p in paragraphes:
        if p["index"] not in indices:
            continue
        texte_p = p["texte"]

        sens_list = [(m.start(), m.group(1).lower()) for m in RE_SENS.finditer(texte_p)]
        pct_list = []
        for m in RE_PCT.finditer(texte_p):
            val = float(m.group(1).replace(",", "."))
            pct_list.append((m.start(), val))

        for pos_sens, sens in sens_list:
            for pos_pct, pct_val in pct_list:
                distance = abs(pos_pct - pos_sens)
                if distance > FENETRE_PCT_SENS:
                    continue

                deb_ctx = max(0, min(pos_sens, pos_pct) - 200)
                fin_ctx = min(len(texte_p), max(pos_sens, pos_pct) + 200)
                ctx_complet = texte_p[deb_ctx:fin_ctx]

                if pos_pct > pos_sens:
                    entre = texte_p[pos_sens:pos_pct]
                else:
                    entre = texte_p[pos_pct:pos_sens]

                if not RE_CTX_BUDGET.search(entre):
                    continue

                if pct_val > SEUIL_PCT_MAX:
                    s = str(int(pct_val))
                    if len(s) == 3 and s[0] == "1":
                        pct_val = float(s[0] + "." + s[1:])
                    else:
                        continue

                deja_vu = any(
                    abs(r.get("position", -1) - (p["debut"] + pos_pct)) < 20
                    for r in resultats
                )
                if deja_vu:
                    continue

                resultats.append({
                    "type": "evolution_pct",
                    "sens": sens,
                    "valeur": pct_val,
                    "position": p["debut"] + pos_pct,
                    "distance": distance,
                    "contexte": ctx_complet,
                })

    for p in paragraphes:
        if p["index"] not in indices:
            continue
        for m in RE_COMPARAISON.finditer(p["texte"]):
            val_avant = nettoyer_nombre(m.group(1))
            val_apres = nettoyer_nombre(m.group(2))
            if val_avant and val_apres:
                resultats.append({
                    "type": "comparaison",
                    "valeur_avant": val_avant,
                    "valeur_apres": val_apres,
                    "evolution": val_apres - val_avant,
                    "evolution_pct": ((val_apres - val_avant) / val_avant * 100) if val_avant else 0,
                    "position": p["debut"] + m.start(),
                    "contexte": p["texte"][:400],
                })
    return resultats


def extraire_exercices(paragraphes, indices):
    exercices = Counter()
    for p in paragraphes:
        if p["index"] not in indices:
            continue
        for m in RE_EXERCICE.finditer(p["texte"]):
            exercices[m.group(1)] += 1
    return exercices


def extraire_ministeres(paragraphes, indices):
    ministeres = Counter()
    for p in paragraphes:
        if p["index"] not in indices:
            continue
        for m in RE_MINISTERE.finditer(p["texte"]):
            ministeres[m.group(1)] += 1
    return ministeres


# ============================================================
# TRAITEMENT PAR FICHIER
# ============================================================
def analyser_fichier(chemin):
    texte = chemin.read_text(encoding="utf-8", errors="ignore")
    if "bumidom" not in normaliser(texte):
        return None

    paragraphes = decouper_paragraphes(texte)
    indices = paragraphes_bumidom(paragraphes)
    if not indices:
        return None

    positions_bumidom_abs = [m.start() for m in re.finditer(r"[Bb]umidom", texte)]
    densite = len(positions_bumidom_abs)

    annee = None
    m = re.search(r"(\d{4})", chemin.name)
    if m:
        annee = int(m.group(1))

    return {
        "fichier": chemin.name,
        "annee": annee,
        "densite_bumidom": densite,
        "positions_bumidom": positions_bumidom_abs,
        "nb_paragraphes_total": len(paragraphes),
        "nb_paragraphes_bumidom": len(indices),
        "montants_francs": extraire_montants_francs(paragraphes, indices, positions_bumidom_abs, texte, densite),
        "montants_grands": extraire_montants_grands(paragraphes, indices, positions_bumidom_abs, texte, densite),
        "credits": extraire_credits(paragraphes, indices, positions_bumidom_abs, texte, densite),
        "subventions": extraire_subventions(paragraphes, indices, positions_bumidom_abs, texte, densite),
        "depenses": extraire_depenses(paragraphes, indices, positions_bumidom_abs, texte, densite),
        "ressources": extraire_ressources(paragraphes, indices, positions_bumidom_abs, texte, densite),
        "evolutions": extraire_evolutions(paragraphes, indices),
        "exercices": dict(extraire_exercices(paragraphes, indices)),
        "ministeres": dict(extraire_ministeres(paragraphes, indices)),
    }


# ============================================================
# MAIN
# ============================================================
def main():
    print("💰 EXTRACTION BUDGÉTAIRE BUMIDOM — score composite 0-13\n")
    print(f"⚙️  Paramètres :")
    print(f"   • Fourchette BUMIDOM : {FOURCHETTE_BUMIDOM[0]/1e6:.0f} M - {FOURCHETTE_BUMIDOM[1]/1e6:.0f} M F")
    print(f"   • Score : 0-13 (densité + distance + budget + section)")
    print()

    fichiers = sorted(DOSSIER_TXT.glob("*.txt"))
    print(f"📄 {len(fichiers)} fichiers à analyser\n")

    tous = []
    for i, f in enumerate(fichiers, 1):
        r = analyser_fichier(f)
        if r:
            tous.append(r)
        if i % 20 == 0:
            print(f"  … {i}/{len(fichiers)}")

    print(f"\n✅ {len(tous)} documents BUMIDOM traités\n")

    # ------------------------------------------------------------
    # 1. TOUS LES MONTANTS avec score
    # ------------------------------------------------------------
    tous_montants = []
    for d in tous:
        for m in d["montants_francs"] + d["montants_grands"]:
            tous_montants.append({
                "fichier": d["fichier"],
                "annee": d["annee"] or "",
                "valeur": int(m["valeur"]),
                "unite": m.get("unite", "F"),
                "valeur_affichee": m.get("valeur_affichee", f"{int(m['valeur'])} F"),
                "score": m["score"],
                "confiance": m["confiance"],
                "densite_doc": d["densite_bumidom"],
                "dans_fourchette": m.get("dans_fourchette", False),
                "contexte": m["contexte"][:400],
            })

    # Trier par score puis valeur
    tous_montants.sort(key=lambda m: (-m["score"], -m["valeur"]))

    with open(SORTIE / "BUDGET_montants.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["fichier", "annee", "valeur_francs", "unite", "valeur_affichee",
                    "score", "confiance", "densite_doc", "dans_fourchette", "contexte"])
        for m in tous_montants:
            w.writerow([m["fichier"], m["annee"], m["valeur"], m["unite"],
                        m["valeur_affichee"], m["score"], m["confiance"],
                        m["densite_doc"], "oui" if m["dans_fourchette"] else "non",
                        nettoyer_contexte(m["contexte"])])
    print(f"💰 {len(tous_montants)} montants → BUDGET_montants.csv")

    # Stats score
    score_stats = Counter(m["score"] for m in tous_montants)
    conf_stats = Counter(m["confiance"] for m in tous_montants)
    print(f"   📊 Distribution score :")
    for s in sorted(score_stats.keys(), reverse=True):
        print(f"      score {s:>2} : {score_stats[s]:>4} montants")
    print(f"   📊 Confiance : strict={conf_stats.get('strict',0)}, "
          f"proche={conf_stats.get('proche',0)}, "
          f"moyen={conf_stats.get('moyen',0)}, "
          f"large={conf_stats.get('large',0)}")

    # ------------------------------------------------------------
    # 2. CRÉDITS / SUBVENTIONS / DÉPENSES / RESSOURCES
    # ------------------------------------------------------------
    for nom, cle in [("credits", "credits"), ("subventions", "subventions"),
                     ("depenses", "depenses"), ("ressources", "ressources")]:
        rows = []
        for d in tous:
            for item in d[cle]:
                rows.append({
                    "fichier": d["fichier"],
                    "annee": d["annee"] or "",
                    **item
                })
        with open(SORTIE / f"BUDGET_{nom}.csv", "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
            cols = ["fichier", "annee", "valeur", "score", "confiance", "contexte"]
            if rows and "nature" in rows[0]:
                cols = ["fichier", "annee", "nature", "valeur", "score", "confiance", "contexte"]
            w.writerow(cols)
            for r in rows:
                w.writerow([r.get(c, "") if c != "contexte" else nettoyer_contexte(r.get(c, ""))
                            for c in cols])
        print(f"💰 {len(rows)} {nom} → BUDGET_{nom}.csv")

    # ------------------------------------------------------------
    # 3. EXERCICES / MINISTÈRES
    # ------------------------------------------------------------
    exercices = Counter()
    for d in tous:
        for k, v in d["exercices"].items():
            exercices[k] += v

    with open(SORTIE / "BUDGET_exercices.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["annee", "mentions"])
        for annee in sorted(exercices):
            w.writerow([annee, exercices[annee]])
    print(f"💰 {len(exercices)} exercices → BUDGET_exercices.csv")

    ministeres = Counter()
    for d in tous:
        for k, v in d["ministeres"].items():
            ministeres[k] += v

    with open(SORTIE / "BUDGET_ministeres.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["ministere", "mentions"])
        for k, v in ministeres.most_common():
            w.writerow([k, v])
    print(f"🏛️  {len(ministeres)} ministères → BUDGET_ministeres.csv")

    # ------------------------------------------------------------
    # 4. ÉVOLUTIONS
    # ------------------------------------------------------------
    toutes_evolutions = []
    for d in tous:
        for e in d.get("evolutions", []):
            toutes_evolutions.append({
                "fichier": d["fichier"],
                "annee": d["annee"] or "",
                **e
            })

    with open(SORTIE / "BUDGET_evolutions.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["fichier", "annee", "type", "sens", "valeur",
                    "valeur_avant", "valeur_apres", "evolution",
                    "evolution_pct", "distance", "contexte"])
        for e in toutes_evolutions:
            w.writerow([
                e.get("fichier", ""), e.get("annee", ""), e.get("type", ""),
                e.get("sens", ""), e.get("valeur", ""),
                e.get("valeur_avant", ""), e.get("valeur_apres", ""),
                e.get("evolution", ""), e.get("evolution_pct", ""),
                e.get("distance", ""),
                nettoyer_contexte(e.get("contexte", "")),
            ])
    print(f"📈 {len(toutes_evolutions)} évolutions → BUDGET_evolutions.csv")

    # ------------------------------------------------------------
    # 5. BUDGET ANNUEL (score >= 7)
    # ------------------------------------------------------------
    budget_annuel = {}
    for d in tous:
        annee = d["annee"]
        if not annee:
            continue
        # Priorité aux scores élevés
        candidats = [m for m in d["montants_francs"] + d["montants_grands"]
                     if m["score"] >= 7 and est_dans_fourchette_bumidom(m["valeur"])]
        if not candidats:
            continue
        # Prendre le meilleur score
        candidats.sort(key=lambda m: (-m["score"], -m["valeur"]))
        if annee not in budget_annuel or candidats[0]["score"] > budget_annuel[annee]["score"]:
            budget_annuel[annee] = candidats[0]

    with open(SORTIE / "BUDGET_budget_annuel_estime.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["annee", "budget_francs", "budget_MF", "score", "confiance", "fichier", "contexte"])
        for annee in sorted(budget_annuel):
            b = budget_annuel[annee]
            w.writerow([
                annee, int(b["valeur"]), round(b["valeur"] / 1e6, 2),
                b["score"], b["confiance"],
                b.get("fichier", ""),
                nettoyer_contexte(b.get("contexte", ""), 200),
            ])
    print(f"📊 {len(budget_annuel)} budgets annuels (score≥7) → BUDGET_budget_annuel_estime.csv")

    # ------------------------------------------------------------
    # 6. SYNTHÈSE
    # ------------------------------------------------------------
    synthese = defaultdict(lambda: {"montants": [], "nb_fichiers": 0})
    for d in tous:
        annee = d["annee"]
        if not annee:
            continue
        s = synthese[annee]
        s["nb_fichiers"] += 1
        for m in d["montants_francs"] + d["montants_grands"]:
            if est_dans_fourchette_bumidom(m["valeur"]):
                s["montants"].append(m["valeur"])

    with open(SORTIE / "BUDGET_synthese_annuelle.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";", quoting=csv.QUOTE_ALL)
        w.writerow(["annee", "nb_fichiers", "nb_montants_fourchette",
                    "total", "moyenne", "max", "budget_estime"])
        for annee in sorted(synthese):
            s = synthese[annee]
            m = s["montants"]
            bf = budget_annuel.get(annee, {})
            w.writerow([
                annee, s["nb_fichiers"], len(m),
                int(sum(m)) if m else 0,
                int(sum(m)/len(m)) if m else 0,
                int(max(m)) if m else 0,
                int(bf["valeur"]) if bf else "",
            ])
    print(f"📊 Synthèse chronologique → BUDGET_synthese_annuelle.csv")

    # ------------------------------------------------------------
    # 7. RAPPORT MARKDOWN
    # ------------------------------------------------------------
    L = ["# Expertise budgétaire BUMIDOM\n\n",
         f"*Généré le {datetime.now().strftime('%d/%m/%Y %H:%M')}*\n\n---\n\n"]

    L.append("## 1. Volumétrie\n\n")
    L.append(f"- Documents BUMIDOM : **{len(tous)}**\n")
    L.append(f"- Montants : **{len(tous_montants)}**\n")
    L.append(f"- Évolutions : **{len(toutes_evolutions)}**\n")
    L.append(f"- Budgets annuels (score≥7) : **{len(budget_annuel)}**\n\n")

    L.append("## 2. Distribution des scores\n\n")
    L.append("| Score | Nombre | Confiance |\n|---|---|---|\n")
    for s in sorted(score_stats.keys(), reverse=True):
        L.append(f"| {s} | {score_stats[s]} | {score_en_label(s)} |\n")

    L.append("\n## 3. Budget BUMIDOM estimé (score≥7)\n\n")
    L.append("| Année | Budget (F) | Score | Conf. | Fichier |\n|---|---|---|---|---|\n")
    for annee in sorted(budget_annuel):
        b = budget_annuel[annee]
        L.append(f"| {annee} | {int(b['valeur']):,} | {b['score']} | {b['confiance']} | {b.get('fichier', '')[:40]} |\n".replace(",", " "))

    L.append("\n## 4. Top 50 montants (score ≥ 8)\n\n")
    L.append("| Rang | Montant (F) | Score | Conf. | Année | Fichier |\n|---|---|---|---|---|---|\n")
    top_score = [m for m in tous_montants if m["score"] >= 8]
    for i, m in enumerate(top_score[:50], 1):
        L.append(f"| {i} | {m['valeur']:,} | {m['score']} | {m['confiance']} | {m['annee']} | {m['fichier'][:30]} |\n".replace(",", " "))

    (SORTIE / "RAPPORT_BUDGET.md").write_text("".join(L), encoding="utf-8")
    print(f"📄 Rapport → RAPPORT_BUDGET.md")

    # ------------------------------------------------------------
    # Résumé
    # ------------------------------------------------------------
    print("\n" + "=" * 60)
    print("✅ EXTRACTION TERMINÉE")
    print("=" * 60)

    print(f"\n💰 Top 20 montants (score le plus élevé) :")
    for m in tous_montants[:20]:
        print(f"   [score {m['score']:>2}] {m['valeur']:>15,} F  {m['fichier'][:45]}".replace(",", " "))

    print(f"\n📊 Budgets annuels estimés :")
    for annee in sorted(budget_annuel):
        b = budget_annuel[annee]
        print(f"   {annee} : {int(b['valeur']):>15,} F  (score {b['score']})".replace(",", " "))


if __name__ == "__main__":
    main()
