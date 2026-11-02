#!/usr/bin/env python3
"""Atualiza dimensões/fatos do Cartola e calcula uma escalação projetada."""

from datetime import datetime, timezone
import json
import os
import statistics
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


BASE_URL = "https://api.cartolafc.globo.com"
DDL_PATH = Path(__file__).resolve().with_name("cartola_schema.sql")
SCOUTS = ("DS", "FC", "FS", "FD", "FF", "FT", "DE", "G")
DATABASE_SCOUTS = ("DS", "G", "FS", "FC", "SG", "CV", "CA", "FD", "FF")
HISTORY_TABLE = "estatisticas_jogadores"
FIXTURES_TABLE = "proximos_confrontos"
CLUB_DIMENSION = "dim_clubes"
ATHLETE_DIMENSION = "dim_atletas"
ROUND_DIMENSION = "dim_rodadas"
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


def club_labels(clubs):
    labels = {}
    for key, club in clubs.items():
        club_id = int(club.get("id", key))
        labels[club_id] = {
            "nome": club.get("apelido") or club.get("nome") or str(club_id),
            "sigla": club.get("abreviacao") or club.get("nome") or str(club_id),
            "nome_api": club.get("nome") or str(club_id),
            "apelido": club.get("apelido") or club.get("nome") or str(club_id),
            "abreviacao": club.get("abreviacao"),
            "slug": club.get("slug"),
        }
    return labels


def win_form(games):
    wins = sum(goals_for > goals_against for _, goals_for, goals_against in games)
    draws = sum(goals_for == goals_against for _, goals_for, goals_against in games)
    losses = len(games) - wins - draws
    return wins, draws, losses


def build_history_row(
    round_number, season, athlete_id, athlete, fixture, clubs, positions
):
    club_id = athlete.get("clube_id")
    home = fixture["clube_casa_id"] == club_id
    opponent_id = (
        fixture["clube_visitante_id"] if home else fixture["clube_casa_id"]
    )
    scout_values = athlete.get("scout") or {}
    row = {
        "temporada": season,
        "rodada": round_number,
        "atleta_id": int(athlete_id),
        "time_id": club_id,
        "adversario_id": opponent_id,
        "partida_id": fixture.get("partida_id"),
        "nome": athlete.get("apelido") or athlete.get("nome") or "N/A",
        "posicao": positions.get(athlete.get("posicao_id"), "N/A"),
        "status": "N/A",
        "time": clubs.get(club_id, {}).get("nome", str(club_id)),
        "jogo": "Mandante" if home else "Visitante",
        "adversario": clubs.get(opponent_id, {}).get("nome", str(opponent_id)),
        "pontuacao": float(athlete.get("pontuacao") or 0),
    }
    for scout in DATABASE_SCOUTS:
        row[scout.lower()] = float(scout_values.get(scout) or 0)
    return row


def build_upcoming_rows(fixtures, clubs, season, round_number):
    rows = []
    for fixture in fixtures:
        home_id = fixture["clube_casa_id"]
        away_id = fixture["clube_visitante_id"]
        rows.append(
            {
                "temporada": season,
                "rodada": round_number,
                "partida_id": fixture.get("partida_id"),
                "meu_time_id": home_id,
                "adversario_id": away_id,
                "meu_time": clubs.get(home_id, {}).get("nome", str(home_id)),
                "adversario": clubs.get(away_id, {}).get("nome", str(away_id)),
                "condicao": "Mandante",
            }
        )
        rows.append(
            {
                "temporada": season,
                "rodada": round_number,
                "partida_id": fixture.get("partida_id"),
                "meu_time_id": away_id,
                "adversario_id": home_id,
                "meu_time": clubs.get(away_id, {}).get("nome", str(away_id)),
                "adversario": clubs.get(home_id, {}).get("nome", str(home_id)),
                "condicao": "Visitante",
            }
        )
    return rows


def build_dimension_rows(market, clubs, positions, status, round_number):
    status_labels = {
        2: "Dúvida",
        3: "Suspenso",
        5: "Contundido",
        6: "Nulo",
        7: "Provável",
    }
    club_rows = [
        {
            "clube_id": club_id,
            "nome": details["nome_api"],
            "apelido": details["apelido"],
            "abreviacao": details["abreviacao"],
            "slug": details["slug"],
        }
        for club_id, details in clubs.items()
    ]
    athlete_rows = []
    for athlete in market.get("atletas", []):
        position_id = athlete.get("posicao_id")
        status_id = athlete.get("status_id")
        athlete_rows.append(
            {
                "atleta_id": int(athlete["atleta_id"]),
                "nome": athlete.get("nome") or athlete.get("apelido") or "N/A",
                "apelido": athlete.get("apelido"),
                "clube_id": athlete.get("clube_id"),
                "posicao_id": position_id,
                "posicao": positions.get(position_id, "N/A"),
                "status_id": status_id,
                "status": status_labels.get(status_id, "N/A"),
                "media_num": athlete.get("media_num"),
                "pontos_num": athlete.get("pontos_num"),
                "jogos_num": athlete.get("jogos_num"),
                "preco_num": athlete.get("preco_num"),
                "variacao_num": athlete.get("variacao_num"),
            }
        )

    season = int(status["temporada"])
    round_rows = [
        {
            "temporada": season,
            "rodada": completed_round,
            "status": "Encerrada",
            "status_mercado": None,
            "fechamento": None,
        }
        for completed_round in range(1, round_number)
    ]
    closing_timestamp = status.get("fechamento", {}).get("timestamp")
    round_rows.append(
        {
            "temporada": season,
            "rodada": round_number,
            "status": "Aberta" if status.get("status_mercado") == 1 else "Fechada",
            "status_mercado": status.get("status_mercado"),
            "fechamento": (
                datetime.fromtimestamp(closing_timestamp, tz=timezone.utc)
                if closing_timestamp
                else None
            ),
        }
    )
    return club_rows, athlete_rows, round_rows


def persist_postgres_tables(
    database_url,
    season,
    current_round,
    club_rows,
    athlete_rows,
    round_rows,
    history_rows,
    upcoming_rows,
):
    try:
        from sqlalchemy import create_engine, text
    except ImportError as error:
        raise RuntimeError(
            "Dependências PostgreSQL ausentes. Instale o requirements.txt."
        ) from error

    if not upcoming_rows:
        raise RuntimeError("A API não retornou partidas; tabelas não foram alteradas.")

    club_columns = ("clube_id", "nome", "apelido", "abreviacao", "slug")
    athlete_columns = (
        "atleta_id", "nome", "apelido", "clube_id", "posicao_id", "posicao",
        "status_id", "status", "media_num", "pontos_num", "jogos_num",
        "preco_num", "variacao_num",
    )
    round_columns = (
        "temporada", "rodada", "status", "status_mercado", "fechamento"
    )
    history_columns = (
        "temporada", "rodada", "atleta_id", "time_id", "adversario_id",
        "partida_id", "nome", "posicao", "status", "time", "jogo",
        "adversario", "pontuacao",
        *(scout.lower() for scout in DATABASE_SCOUTS),
    )
    fixture_columns = (
        "temporada", "rodada", "partida_id", "meu_time_id", "adversario_id",
        "meu_time", "adversario", "condicao",
    )

    def upsert_statement(table, columns, key_columns):
        quoted_columns = ", ".join(f'"{column}"' for column in columns)
        parameters = ", ".join(f":{column}" for column in columns)
        updates = ", ".join(
            f'"{column}" = EXCLUDED."{column}"'
            for column in columns
            if column not in key_columns
        )
        return text(
            f"INSERT INTO {table} ({quoted_columns}) VALUES ({parameters}) "
            f"ON CONFLICT ({', '.join(key_columns)}) DO UPDATE SET "
            f"{updates}, atualizado_em = NOW()"
        )

    club_upsert = upsert_statement(
        CLUB_DIMENSION, club_columns, ("clube_id",)
    )
    athlete_upsert = upsert_statement(
        ATHLETE_DIMENSION, athlete_columns, ("atleta_id",)
    )
    round_upsert = upsert_statement(
        ROUND_DIMENSION, round_columns, ("temporada", "rodada")
    )
    history_insert = text(
        f"INSERT INTO {HISTORY_TABLE} "
        f"({', '.join(f'\"{column}\"' for column in history_columns)}) "
        f"VALUES ({', '.join(f':{column}' for column in history_columns)})"
    )
    fixtures_insert = text(
        f"INSERT INTO {FIXTURES_TABLE} "
        f"({', '.join(f'\"{column}\"' for column in fixture_columns)}) "
        f"VALUES ({', '.join(f':{column}' for column in fixture_columns)})"
    )
    engine = create_engine(database_url, pool_pre_ping=True)
    try:
        with engine.begin() as connection:
            connection.exec_driver_sql(DDL_PATH.read_text(encoding="utf-8"))
            connection.execute(club_upsert, club_rows)
            connection.execute(athlete_upsert, athlete_rows)
            connection.execute(round_upsert, round_rows)

            last_round = connection.execute(
                text(
                    f"""
                    SELECT GREATEST(
                        COALESCE((
                            SELECT MAX(rodada) FROM {HISTORY_TABLE}
                            WHERE temporada = :temporada
                        ), 0),
                        COALESCE((
                            SELECT MAX(rodada) FROM {HISTORY_TABLE}
                            WHERE temporada IS NULL AND rodada <= :rodada_atual
                        ), 0)
                    )
                    """
                ),
                {"temporada": season, "rodada_atual": current_round},
            ).scalar() or 0
            new_history = [
                row
                for row in history_rows
                if row["rodada"] > int(last_round)
            ]
            if new_history:
                connection.execute(history_insert, new_history)

            connection.execute(text(f"DELETE FROM {FIXTURES_TABLE}"))
            connection.execute(fixtures_insert, upcoming_rows)
    finally:
        engine.dispose()

    return len(new_history), int(last_round)


def main():
    database_url = os.environ.get("CARTOLA_DATABASE_URL")
    if not database_url:
        raise RuntimeError(
            "Defina CARTOLA_DATABASE_URL para atualizar o PostgreSQL."
        )

    status = get_json("/mercado/status")
    round_number = int(status["rodada_atual"])
    season = int(status["temporada"])
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
    database_history_rows = []
    for round_data in player_rounds:
        played_round = int(round_data["rodada"])
        for athlete_id, athlete in round_data.get("atletas", {}).items():
            club_id = athlete.get("clube_id")
            fixture = fixture_by_club_round.get((played_round, club_id))
            if fixture is None:
                continue
            database_history_rows.append(
                build_history_row(
                    played_round, season, athlete_id, athlete, fixture, clubs, positions
                )
            )
            if not athlete.get("entrou_em_campo"):
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
    upcoming_rows = build_upcoming_rows(
        current_fixtures, clubs, season, round_number
    )
    club_rows, athlete_rows, round_rows = build_dimension_rows(
        market, clubs, positions, status, round_number
    )
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

    history_inserted, previous_history_round = persist_postgres_tables(
        database_url,
        season,
        round_number,
        club_rows,
        athlete_rows,
        round_rows,
        database_history_rows,
        upcoming_rows,
    )

    projected_total = sum(player["projecao"] for player in lineup)
    print(f"Temporada {season}, rodada {round_number}.")
    print(f"Dimensões atualizadas: {len(club_rows)} clubes, {len(athlete_rows)} atletas, {len(round_rows)} rodadas.")
    print(
        f"PostgreSQL: {history_inserted} registros novos em {HISTORY_TABLE} "
        f"(histórico anterior até a rodada {previous_history_round}); "
        f"{len(upcoming_rows)} linhas atualizadas em {FIXTURES_TABLE}."
    )
    print("Escalação sugerida:")
    for player in lineup:
        print(
            f"- {player['nome']} | {player['posicao']} | {player['time']} "
            f"| {player['mando']} vs {player['adversario']} "
            f"| projeção {player['projecao']:.2f}"
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


if __name__ == "__main__":
    main()
