CREATE TABLE IF NOT EXISTS dim_clubes (
    clube_id INTEGER PRIMARY KEY,
    nome TEXT,
    apelido TEXT,
    abreviacao TEXT,
    slug TEXT,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dim_atletas (
    atleta_id INTEGER PRIMARY KEY,
    nome TEXT,
    apelido TEXT,
    clube_id INTEGER REFERENCES dim_clubes (clube_id),
    posicao_id INTEGER,
    posicao TEXT,
    status_id INTEGER,
    status TEXT,
    media_num DOUBLE PRECISION,
    pontos_num DOUBLE PRECISION,
    jogos_num INTEGER,
    preco_num DOUBLE PRECISION,
    variacao_num DOUBLE PRECISION,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dim_rodadas (
    temporada INTEGER NOT NULL,
    rodada INTEGER NOT NULL,
    status TEXT,
    status_mercado INTEGER,
    fechamento TIMESTAMPTZ,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (temporada, rodada)
);

-- Mantém os nomes e campos gerados pelos scripts originais via DataFrame.to_sql.
CREATE TABLE IF NOT EXISTS estatisticas_jogadores (
    rodada BIGINT,
    nome TEXT,
    posicao TEXT,
    status TEXT,
    "time" TEXT,
    jogo TEXT,
    adversario TEXT,
    pontuacao DOUBLE PRECISION,
    ds DOUBLE PRECISION,
    g DOUBLE PRECISION,
    fs DOUBLE PRECISION,
    fc DOUBLE PRECISION,
    sg DOUBLE PRECISION,
    cv DOUBLE PRECISION,
    ca DOUBLE PRECISION,
    fd DOUBLE PRECISION,
    ff DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS proximos_confrontos (
    meu_time TEXT,
    adversario TEXT,
    condicao TEXT
);

CREATE TABLE IF NOT EXISTS cartola_carga_controle (
    fonte TEXT PRIMARY KEY,
    temporada INTEGER NOT NULL,
    ultima_rodada INTEGER NOT NULL DEFAULT 0,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
