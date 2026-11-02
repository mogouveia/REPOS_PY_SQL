#!/usr/bin/env python3
"""Gera uma escalação e um resumo de confrontos para a rodada aberta do Cartola."""

import csv
import json
import os
import statistics
import tempfile
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


BASE_URL = "https://api.cartolafc.globo.com"


def resolve_output_dir(script_path):
    script_dir = Path(script_path).resolve().parent
    for candidate in (script_dir, *script_dir.parents):
        if (candidate / "README.md").is_file() and (
            (candidate / "Database").is_dir()
            or (candidate / "data" / "processed").is_dir()
        ):
            return candidate / "data" / "processed"
    return script_dir / "data" / "processed"


OUTPUT_DIR = resolve_output_dir(__file__)
FALLBACK_OUTPUT_DIR = Path.home() / "cartola_scout" / "data" / "processed"
SCOUTS = ("DS", "FC", "FS", "FD", "FF", "FT", "DE", "G")
MIN_JOGOS_RECENTES = 3
MAX_JOGADORES_POR_TIME = 5


def get_json(path):
    request = urllib.request.Request(
        f"{BASE_URL}{path}",
        headers={"User-Agent": "Mozilla/5.0 (compatible; CartolaScout/1.0)"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def fetch_rounds(endpoint, rounds):
    paths = [f"/{endpoint}/{round_number}" for round_number in rounds]
    with ThreadPoolExecutor(max_workers=4) as executor:
        return list(executor.map(get_json, paths))


def mean(values, default=0.0):
    return statistics.mean(values) if values else default


def ensure_output_dir():
    configured_dir = os.environ.get("CARTOLA_OUTPUT_DIR")
    candidates = (
        [Path(configured_dir).expanduser()]
        if configured_dir
        else [OUTPUT_DIR, FALLBACK_OUTPUT_DIR]
    )
    errors = []
    for directory in candidates:
        try:
            directory.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=directory):
                pass
            return directory
        except OSError as error:
            errors.append(f"{directory}: {error}")
            if configured_dir:
                break

    details = "; ".join(errors)
    raise OSError(
        "Não foi possível gravar os CSVs. Configure CARTOLA_OUTPUT_DIR para "
        f"uma pasta gravável. Tentativas: {details}"
    )


def club_labels(clubs):
    labels = {}
    for key, club in clubs.items():
        club_id = int(club.get("id", key))
        labels[club_id] = {
            "nome": club.get("apelido") or club.get("nome") or str(club_id),
            "sigla": club.get("abreviacao") or club.get("nome") or str(club_id),
        }
    return labels


def win_form(games):
    wins = sum(goals_for > goals_against for _, goals_for, goals_against in games)
    draws = sum(goals_for == goals_against for _, goals_for, goals_against in games)
    losses = len(games) - wins - draws
    return wins, draws, losses


def main():
    status = get_json("/mercado/status")
    round_number = int(status["rodada_atual"])
    market = get_json("/atletas/mercado")
    fixtures_response = get_json(f"/partidas/{round_number}")

    club_data = market.get("clubes") or fixtures_response.get("clubes", {})
    clubs = club_labels(club_data)
    positions = {
        int(position_id): value["nome"]
        for position_id, value in market["posicoes"].items()
    }

    completed_rounds = list(range(1, round_number))
    fixture_rounds = fetch_rounds("partidas", completed_rounds)
    player_rounds = fetch_rounds("atletas/pontuados", completed_rounds)

    fixtures = []
    fixture_by_club_round = {}
    team_games = {}
    for round_data in fixture_rounds:
        played_round = int(round_data["rodada"])
        for fixture in round_data.get("partidas", []):
            home_id = fixture["clube_casa_id"]
            away_id = fixture["clube_visitante_id"]
            fixtures.append((played_round, fixture))
            fixture_by_club_round[(played_round, home_id)] = fixture
            fixture_by_club_round[(played_round, away_id)] = fixture

            home_score = fixture.get("placar_oficial_mandante")
            away_score = fixture.get("placar_oficial_visitante")
            if not fixture.get("valida") or home_score is None or away_score is None:
                continue
            team_games.setdefault((home_id, "Casa"), []).append(
                (played_round, home_score, away_score)
            )
            team_games.setdefault((away_id, "Fora"), []).append(
                (played_round, away_score, home_score)
            )

    player_history = {}
    opponent_points = {}
    team_round_scouts = {}
    for round_data in player_rounds:
        played_round = int(round_data["rodada"])
        for athlete_id, athlete in round_data.get("atletas", {}).items():
            club_id = athlete.get("clube_id")
            fixture = fixture_by_club_round.get((played_round, club_id))
            if fixture is None or not athlete.get("entrou_em_campo"):
                continue

            position = positions.get(athlete.get("posicao_id"), "Desconhecida")
            points = float(athlete.get("pontuacao") or 0)
            venue = (
                "Casa"
                if fixture["clube_casa_id"] == club_id
                else "Fora"
            )
            opponent_id = (
                fixture["clube_visitante_id"]
                if venue == "Casa"
                else fixture["clube_casa_id"]
            )
            opponent_venue = "Fora" if venue == "Casa" else "Casa"
            player_history.setdefault(str(athlete_id), []).append(
                {
                    "rodada": played_round,
                    "pontos": points,
                    "time_id": club_id,
                    "posicao": position,
                    "mando": venue,
                }
            )
            opponent_points.setdefault(
                (opponent_id, position, opponent_venue), []
            ).append(points)

            round_scouts = team_round_scouts.setdefault(
                (club_id, played_round), {scout: 0.0 for scout in SCOUTS}
            )
            scout_values = athlete.get("scout") or {}
            for scout in SCOUTS:
                round_scouts[scout] += float(scout_values.get(scout) or 0)

    current_fixtures = fixtures_response.get("partidas", [])
    opponents = {}
    for fixture in current_fixtures:
        home_id = fixture["clube_casa_id"]
        away_id = fixture["clube_visitante_id"]
        opponents[home_id] = (away_id, "Casa")
        opponents[away_id] = (home_id, "Fora")

    recent_round_floor = max(1, round_number - 5)
    league_allowed = {}
    for (opponent_id, position, venue), points in opponent_points.items():
        if opponent_id not in opponents:
            continue
        league_allowed.setdefault((position, venue), []).extend(points)

    candidate_players = []
    for athlete in market.get("atletas", []):
        athlete_id = str(athlete["atleta_id"])
        club_id = athlete.get("clube_id")
        position = positions.get(athlete.get("posicao_id"), "Desconhecida")
        if (
            club_id not in opponents
            or position == "Técnico"
            or athlete.get("status_id") != 7
        ):
            continue

        recent_history = [
            row
            for row in player_history.get(athlete_id, [])
            if row["rodada"] >= recent_round_floor
        ]
        if len(recent_history) < MIN_JOGOS_RECENTES:
            continue

        opponent_id, venue = opponents[club_id]
        allowed_home = mean(
            opponent_points.get((opponent_id, position, "Casa"), []),
            mean(league_allowed.get((position, "Casa"), [])),
        )
        allowed_away = mean(
            opponent_points.get((opponent_id, position, "Fora"), []),
            mean(league_allowed.get((position, "Fora"), [])),
        )
        opponent_venue = "Fora" if venue == "Casa" else "Casa"
        allowed_average = allowed_away if venue == "Casa" else allowed_home
        league_average = mean(
            league_allowed.get((position, opponent_venue), []), allowed_average
        )

        season_history = player_history.get(athlete_id, [])
        season_average = float(athlete.get("media_num") or 0)
        if not season_history and not season_average:
            continue
        recent_average = mean([row["pontos"] for row in recent_history])
        if not season_average:
            season_average = mean([row["pontos"] for row in season_history])
        points_home = mean(
            [row["pontos"] for row in season_history if row["mando"] == "Casa"]
        )
        points_away = mean(
            [row["pontos"] for row in season_history if row["mando"] == "Fora"]
        )

        games_at_venue = sorted(
            team_games.get((club_id, venue), []), reverse=True
        )[:5]
        wins, draws, losses = win_form(games_at_venue)
        form_rate = (wins + 0.5 * draws) / len(games_at_venue) if games_at_venue else 0.4

        baseline = 0.55 * recent_average + 0.45 * season_average
        opponent_adjustment = max(
            -1.5, min(1.5, 0.20 * (allowed_average - league_average))
        )
        form_adjustment = max(-0.5, min(0.5, 0.8 * (form_rate - 0.4)))
        home_adjustment = 0.25 if venue == "Casa" else 0.0
        projection = (
            baseline + opponent_adjustment + form_adjustment + home_adjustment
        )

        candidate_players.append(
            {
                "id": athlete_id,
                "nome": athlete.get("apelido") or athlete.get("nome"),
                "time_id": club_id,
                "time": clubs.get(club_id, {}).get("nome", str(club_id)),
                "sigla": clubs.get(club_id, {}).get("sigla", str(club_id)),
                "posicao": position,
                "adversario": clubs.get(opponent_id, {}).get("nome", str(opponent_id)),
                "adversario_id": opponent_id,
                "mando": venue,
                "status": athlete.get("status_id"),
                "jogos_recentes": len(recent_history),
                "media_recente": recent_average,
                "media_temporada": season_average,
                "pontos_casa": points_home,
                "pontos_fora": points_away,
                "cedidos_casa": allowed_home,
                "cedidos_fora": allowed_away,
                "pontos_cedidos": allowed_average,
                "vitorias_mando": wins,
                "empates_mando": draws,
                "derrotas_mando": losses,
                "projecao": projection,
            }
        )

    lineup = select_lineup(candidate_players)
    if len(lineup) != 11:
        raise RuntimeError(
            f"Não foi possível compor 11 titulares com os filtros atuais "
            f"(candidatos: {len(candidate_players)})."
        )

    output_dir = ensure_output_dir()
    lineup_path = output_dir / f"escalacao_rodada_{round_number}_amostra.csv"
    matchup_path = output_dir / f"confrontos_rodada_{round_number}_amostra.csv"
    write_lineup(lineup_path, round_number, lineup)
    write_matchups(
        matchup_path,
        round_number,
        current_fixtures,
        clubs,
        team_games,
        team_round_scouts,
    )

    projected_total = sum(player["projecao"] for player in lineup)
    print(f"Temporada {status.get('temporada')}, rodada {round_number}.")
    print(f"Escalação: {lineup_path} (11 atletas).")
    print(f"Confrontos: {matchup_path}.")
    if output_dir != OUTPUT_DIR:
        print(
            "A pasta do projeto não permitiu gravação; os arquivos foram "
            f"salvos em {output_dir}."
        )
    print(f"Projeção agregada: {projected_total:.2f} pontos; não é garantia de resultado.")
    if projected_total < 130:
        print("A projeção não alcança 130 pontos; não forcei a escalação para atingir a meta.")


def select_lineup(candidates):
    formations = []
    for defenders in range(3, 6):
        for midfielders in range(3, 6):
            attackers = 10 - defenders - midfielders
            if 1 <= attackers <= 3:
                formations.append((defenders, midfielders, attackers))

    best_lineup = []
    best_total = float("-inf")
    for defenders, midfielders, attackers in formations:
        groups = (
            ("Goleiro", 1, lambda p: p["posicao"] == "Goleiro"),
            ("Defesa", defenders, lambda p: p["posicao"] in ("Zagueiro", "Lateral")),
            ("Meia", midfielders, lambda p: p["posicao"] == "Meia"),
            ("Atacante", attackers, lambda p: p["posicao"] == "Atacante"),
        )
        selected = []
        team_counts = {}
        for _, required, predicate in groups:
            options = sorted(
                (player for player in candidates if predicate(player)),
                key=lambda player: player["projecao"],
                reverse=True,
            )
            for player in options:
                if len([item for item in selected if predicate(item)]) >= required:
                    break
                if any(item["id"] == player["id"] for item in selected):
                    continue
                if team_counts.get(player["time_id"], 0) >= MAX_JOGADORES_POR_TIME:
                    continue
                selected.append(player)
                team_counts[player["time_id"]] = team_counts.get(player["time_id"], 0) + 1

        if len(selected) == 11:
            total = sum(player["projecao"] for player in selected)
            if total > best_total:
                best_lineup = selected
                best_total = total
    return sorted(
        best_lineup,
        key=lambda player: (
            ("Goleiro", "Zagueiro", "Lateral", "Meia", "Atacante").index(
                player["posicao"]
            ),
            -player["projecao"],
        ),
    )


def write_lineup(path, round_number, lineup):
    columns = (
        "rodada", "atleta_id", "nome", "time", "sigla_time", "posicao",
        "adversario", "mando", "status_mercado", "jogos_ultimos_5",
        "media_ultimos_5", "media_temporada", "pontos_cedidos_posicao",
        "conquistados_casa", "conquistados_fora",
        "cedidos_casa_posicao", "cedidos_fora_posicao",
        "vitorias_ultimos_5_mando", "empates_ultimos_5_mando",
        "derrotas_ultimos_5_mando", "projecao_pontos",
    )
    with path.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=columns)
        writer.writeheader()
        for player in lineup:
            writer.writerow(
                {
                    "rodada": round_number,
                    "atleta_id": player["id"],
                    "nome": player["nome"],
                    "time": player["time"],
                    "sigla_time": player["sigla"],
                    "posicao": player["posicao"],
                    "adversario": player["adversario"],
                    "mando": player["mando"],
                    "status_mercado": "Provável",
                    "jogos_ultimos_5": player["jogos_recentes"],
                    "media_ultimos_5": f"{player['media_recente']:.2f}",
                    "media_temporada": f"{player['media_temporada']:.2f}",
                    "pontos_cedidos_posicao": f"{player['pontos_cedidos']:.2f}",
                    "conquistados_casa": f"{player['pontos_casa']:.2f}",
                    "conquistados_fora": f"{player['pontos_fora']:.2f}",
                    "cedidos_casa_posicao": f"{player['cedidos_casa']:.2f}",
                    "cedidos_fora_posicao": f"{player['cedidos_fora']:.2f}",
                    "vitorias_ultimos_5_mando": player["vitorias_mando"],
                    "empates_ultimos_5_mando": player["empates_mando"],
                    "derrotas_ultimos_5_mando": player["derrotas_mando"],
                    "projecao_pontos": f"{player['projecao']:.2f}",
                }
            )


def write_matchups(path, round_number, fixtures, clubs, team_games, team_round_scouts):
    columns = (
        "rodada", "time", "sigla_time", "adversario", "mando",
        "jogos_ultimos_5_mando", "vitorias", "empates", "derrotas",
        "gols_feitos_media", "gols_sofridos_media",
        "jogos_sem_sofrer_gol_media", "desarmes_media",
        "finalizacoes_certas_media", "finalizacoes_defendidas_media",
        "finalizacoes_para_fora_media", "finalizacoes_na_trave_media",
        "faltas_sofridas_media", "defesas_dificeis_goleiro_media",
        "faltas_cometidas_media",
    )
    with path.open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=columns)
        writer.writeheader()
        for fixture in fixtures:
            for club_id, opponent_id, venue, home in (
                (
                    fixture["clube_casa_id"],
                    fixture["clube_visitante_id"],
                    "Casa",
                    True,
                ),
                (
                    fixture["clube_visitante_id"],
                    fixture["clube_casa_id"],
                    "Fora",
                    False,
                ),
            ):
                history = sorted(
                    team_games.get((club_id, venue), []), reverse=True
                )[:5]
                wins, draws, losses = win_form(history)
                goals_for = [row[1] for row in history]
                goals_against = [row[2] for row in history]
                clean_sheets = sum(value == 0 for value in goals_against)
                metrics = {
                    scout: mean(
                        [
                            team_round_scouts.get((club_id, game_round), {}).get(
                                scout, 0.0
                            )
                            for game_round, _, _ in history
                        ]
                    )
                    for scout in SCOUTS
                }
                writer.writerow(
                    {
                        "rodada": round_number,
                        "time": clubs.get(club_id, {}).get("nome", str(club_id)),
                        "sigla_time": clubs.get(club_id, {}).get("sigla", str(club_id)),
                        "adversario": clubs.get(opponent_id, {}).get("nome", str(opponent_id)),
                        "mando": venue,
                        "jogos_ultimos_5_mando": len(history),
                        "vitorias": wins,
                        "empates": draws,
                        "derrotas": losses,
                        "gols_feitos_media": f"{mean(goals_for):.2f}",
                        "gols_sofridos_media": f"{mean(goals_against):.2f}",
                        "jogos_sem_sofrer_gol_media": (
                            f"{clean_sheets / len(history):.2f}" if history else ""
                        ),
                        "desarmes_media": f"{metrics['DS']:.2f}",
                        "finalizacoes_certas_media": f"{(metrics['FD'] + metrics['G']):.2f}",
                        "finalizacoes_defendidas_media": f"{metrics['FD']:.2f}",
                        "finalizacoes_para_fora_media": f"{metrics['FF']:.2f}",
                        "finalizacoes_na_trave_media": f"{metrics['FT']:.2f}",
                        "faltas_sofridas_media": f"{metrics['FS']:.2f}",
                        "defesas_dificeis_goleiro_media": f"{metrics['DE']:.2f}",
                        "faltas_cometidas_media": f"{metrics['FC']:.2f}",
                    }
                )


if __name__ == "__main__":
    main()
