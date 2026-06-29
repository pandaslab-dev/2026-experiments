const ESPN_LEAGUES = [
  { sport: "basketball", league: "nba", label: "nba" },
  { sport: "baseball", league: "mlb", label: "mlb" },
  { sport: "hockey", league: "nhl", label: "nhl" },
  { sport: "football", league: "nfl", label: "nfl" },
  { sport: "basketball", league: "wnba", label: "wnba" },
  { sport: "football", league: "college-football", label: "college football" },
  { sport: "basketball", league: "mens-college-basketball", label: "college basketball" },
  { sport: "soccer", league: "eng.1", label: "premier league" },
  { sport: "soccer", league: "esp.1", label: "la liga" },
  { sport: "soccer", league: "ger.1", label: "bundesliga" },
  { sport: "soccer", league: "ita.1", label: "serie a" },
  { sport: "soccer", league: "fra.1", label: "ligue 1" },
  { sport: "soccer", league: "usa.1", label: "mls" },
];

const THE_SPORTS_DB_LEAGUES = [
  { sport: "baseball", leagueId: "4591", label: "nippon baseball league" },
  { sport: "basketball", leagueId: "5351", label: "nbl1 west" },
  { sport: "basketball", leagueId: "4734", label: "argentine lnb" },
  { sport: "basketball", leagueId: "4434", label: "australian nbl" },
  { sport: "soccer", leagueId: "4328", label: "premier league" },
];

const DEFAULT_AWAY_COLOR = "#111111";
const DEFAULT_HOME_COLOR = "#ffffff";
const MIN_TEXT_SIZE = 12;
const LAST_GAME_KEY = "paint-ball-xl-last-game";

const EMPTY_GAME = normalizeGame({
  source: "x",
  sport: "x",
  league: "x",
  status: "x",
  clock: "x",
  awayTeam: "x",
  homeTeam: "x",
  awayScore: null,
  homeScore: null,
  awayColor: DEFAULT_AWAY_COLOR,
  homeColor: DEFAULT_HOME_COLOR,
  extraInfo: "",
  state: "empty",
  date: null,
});

const state = {
  currentGame: EMPTY_GAME,
};

const elements = {
  awayTeam: document.getElementById("awayTeam"),
  homeTeam: document.getElementById("homeTeam"),
  awayScore: document.getElementById("awayScore"),
  homeScore: document.getElementById("homeScore"),
  statusText: document.getElementById("statusText"),
  gameClock: document.getElementById("gameClock"),
  sportText: document.getElementById("sportText"),
  metaText: document.getElementById("metaText"),
};

async function getAllGames() {
  const adapters = [getEspnGames, getTheSportsDbGames];
  const results = await Promise.allSettled(adapters.map((adapter) => adapter()));
  return dedupeGames(results.flatMap((result) => (result.status === "fulfilled" ? result.value : [])));
}

async function getEspnGames() {
  const results = await Promise.allSettled(ESPN_LEAGUES.map((leagueConfig) => getEspnLeagueGames(leagueConfig)));
  return results.flatMap((result) => (result.status === "fulfilled" ? result.value : []));
}

async function getEspnLeagueGames(leagueConfig) {
  const url = `https://site.api.espn.com/apis/site/v2/sports/${leagueConfig.sport}/${leagueConfig.league}/scoreboard`;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`could not load ${leagueConfig.label}`);
  }

  const data = await response.json();
  const events = Array.isArray(data.events) ? data.events : [];

  return events.map((event) => normalizeEspnGame(event, leagueConfig)).filter(Boolean);
}

async function getTheSportsDbGames() {
  const tasks = THE_SPORTS_DB_LEAGUES.flatMap((leagueConfig) => [
    getTheSportsDbLeagueGames(leagueConfig, "past"),
    getTheSportsDbLeagueGames(leagueConfig, "next"),
  ]);
  const results = await Promise.allSettled(tasks);
  return results.flatMap((result) => (result.status === "fulfilled" ? result.value : []));
}

async function getTheSportsDbLeagueGames(leagueConfig, phase) {
  const endpoint = phase === "past" ? "eventspastleague" : "eventsnextleague";
  const url = `https://www.thesportsdb.com/api/v1/json/123/${endpoint}.php?id=${leagueConfig.leagueId}`;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`could not load ${leagueConfig.label}`);
  }

  const data = await response.json();
  const events = Array.isArray(data.events) ? data.events : [];

  return events
    .map((event) => {
      const scoresKnown = hasValue(event.intHomeScore) || hasValue(event.intAwayScore);
      const status = phase === "past" || scoresKnown ? "final" : "scheduled";

      return normalizeGame({
        source: "the sports db",
        sport: leagueConfig.sport,
        league: leagueConfig.label,
        status,
        clock: phase === "next" ? formatDateForBoard(event.strTimestamp) : "final",
        awayTeam: event.strAwayTeam,
        homeTeam: event.strHomeTeam,
        awayScore: parseScore(event.intAwayScore),
        homeScore: parseScore(event.intHomeScore),
        awayColor: DEFAULT_AWAY_COLOR,
        homeColor: DEFAULT_HOME_COLOR,
        extraInfo: event.strVenue || event.strStatus || "",
        state: status === "final" ? "final" : "scheduled",
        date: event.strTimestamp || null,
      });
    })
    .filter(Boolean);
}

function normalizeEspnGame(event, leagueConfig) {
  const competition = event.competitions?.[0];

  if (!competition) {
    return null;
  }

  const competitors = competition.competitors || [];
  const home = competitors.find((team) => team.homeAway === "home");
  const away = competitors.find((team) => team.homeAway === "away");

  if (!home || !away) {
    return null;
  }

  const statusType = competition.status?.type || {};
  const stateName = getEspnState(statusType.state);
  const awayScore = stateName === "scheduled" ? null : parseScore(away.score);
  const homeScore = stateName === "scheduled" ? null : parseScore(home.score);

  return normalizeGame({
    source: "espn",
    sport: leagueConfig.sport,
    league: leagueConfig.label,
    status: getEspnStatusLabel(statusType),
    clock: getEspnClockLabel(competition.status, competition.date),
    awayTeam: getEspnTeamName(away),
    homeTeam: getEspnTeamName(home),
    awayScore,
    homeScore,
    awayColor: makeColor(away.team?.color, DEFAULT_AWAY_COLOR),
    homeColor: makeColor(home.team?.color || home.team?.alternateColor, DEFAULT_HOME_COLOR),
    extraInfo: competition.note?.headline || competition.venue?.fullName || "",
    state: stateName,
    date: competition.date || event.date || null,
  });
}

function normalizeGame(game) {
  if (!game) {
    return null;
  }

  const awayTeam = String(game.awayTeam || "").trim();
  const homeTeam = String(game.homeTeam || "").trim();

  if (!awayTeam || !homeTeam) {
    return null;
  }

  return {
    source: cleanLabel(game.source, "demo"),
    sport: cleanLabel(game.sport, "x"),
    league: cleanLabel(game.league, "x"),
    status: cleanLabel(game.status, "x"),
    clock: cleanLabel(game.clock, "x"),
    homeTeam,
    awayTeam,
    homeScore: toScoreOrNull(game.homeScore),
    awayScore: toScoreOrNull(game.awayScore),
    homeColor: makeColor(game.homeColor, DEFAULT_HOME_COLOR),
    awayColor: makeColor(game.awayColor, DEFAULT_AWAY_COLOR),
    extraInfo: cleanLabel(game.extraInfo, ""),
    state: cleanLabel(game.state, "scheduled"),
    date: game.date || null,
  };
}

function renderScoreboard(game) {
  state.currentGame = game;
  saveLastGameKey(game);

  elements.awayTeam.textContent = game.awayTeam;
  elements.homeTeam.textContent = game.homeTeam;
  elements.awayScore.textContent = formatScore(game.awayScore);
  elements.homeScore.textContent = formatScore(game.homeScore);
  elements.statusText.textContent = game.status;
  elements.gameClock.textContent = game.clock;
  elements.sportText.textContent = `${game.sport} / ${game.league}`;
  applyTeamColors(game);
  updateClock();
  fitTextToBox();
}

function applyTeamColors(game) {
  const awayColor = makeColor(game.awayColor, DEFAULT_AWAY_COLOR);
  const homeColor = makeColor(game.homeColor, DEFAULT_HOME_COLOR);

  document.documentElement.style.setProperty("--away-color", awayColor);
  document.documentElement.style.setProperty("--home-color", homeColor);
  document.documentElement.style.setProperty("--away-text", getReadableTextColor(awayColor));
  document.documentElement.style.setProperty("--home-text", getReadableTextColor(homeColor));
}

function updateClock() {
  if (state.currentGame.source === "x") {
    elements.metaText.textContent = "x";
    return;
  }

  const localTime = new Intl.DateTimeFormat([], {
    hour: "numeric",
    minute: "2-digit",
    timeZoneName: "short",
  }).format(new Date());

  elements.metaText.textContent = `${state.currentGame.source} / ${localTime}`.toLowerCase();
}

function getEspnTeamName(team) {
  return team.team?.shortDisplayName || team.team?.displayName || team.team?.name || "x";
}

function getEspnState(stateName) {
  if (stateName === "in") {
    return "live";
  }

  if (stateName === "post") {
    return "final";
  }

  return "scheduled";
}

function getEspnStatusLabel(statusType) {
  const detail = String(statusType.detail || statusType.shortDetail || "").toLowerCase();

  if (statusType.state === "in") {
    return "live";
  }

  if (statusType.completed || statusType.state === "post") {
    return "final";
  }

  if (detail.includes("postponed")) {
    return "postponed";
  }

  return "scheduled";
}

function getEspnClockLabel(status, date) {
  const statusType = status?.type || {};

  if (statusType.state === "in") {
    return cleanLabel(statusType.shortDetail || statusType.detail, "now");
  }

  if (statusType.completed || statusType.state === "post") {
    return "final";
  }

  return formatDateForBoard(date);
}

function formatDateForBoard(date) {
  if (!date) {
    return "tbd";
  }

  const value = new Date(date);

  if (Number.isNaN(value.getTime())) {
    return "tbd";
  }

  const sameDay = isToday(value);
  const timeText = new Intl.DateTimeFormat([], {
    hour: "numeric",
    minute: "2-digit",
  })
    .format(value)
    .toLowerCase();

  if (sameDay) {
    return timeText;
  }

  const dateText = new Intl.DateTimeFormat([], {
    month: "numeric",
    day: "numeric",
  }).format(value);

  return `${dateText} ${timeText}`.toLowerCase();
}

function cleanLabel(value, fallback) {
  const text = String(value || "").trim().toLowerCase();
  return text || fallback;
}

function makeColor(value, fallback) {
  const color = String(value || "").trim();

  if (!color) {
    return fallback;
  }

  return color.startsWith("#") ? color : `#${color.replace("#", "")}`;
}

function parseScore(score) {
  if (!hasValue(score)) {
    return null;
  }

  const value = Number(score);
  return Number.isFinite(value) ? value : null;
}

function toScoreOrNull(score) {
  return Number.isFinite(score) ? Number(score) : null;
}

function hasValue(value) {
  return value !== null && value !== undefined && value !== "";
}

function hasRealScore(game) {
  return Number.isFinite(game.homeScore) || Number.isFinite(game.awayScore);
}

function formatScore(score) {
  return Number.isFinite(score) ? String(score) : "x";
}

function isToday(date) {
  if (!date) {
    return false;
  }

  const value = new Date(date);

  if (Number.isNaN(value.getTime())) {
    return false;
  }

  const now = new Date();

  return value.getFullYear() === now.getFullYear()
    && value.getMonth() === now.getMonth()
    && value.getDate() === now.getDate();
}

function dedupeGames(games) {
  const seen = new Set();
  const uniqueGames = [];

  for (const game of games) {
    const key = buildGameKey(game);

    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    uniqueGames.push(game);
  }

  return uniqueGames;
}

function buildGameKey(game) {
  return [game.source, game.league, game.awayTeam, game.homeTeam, game.date].join("|").toLowerCase();
}

function pickRandomGame(games) {
  const lastGameKey = getLastGameKey();
  const liveGames = games.filter((game) => game.state === "live");
  const finalGames = games.filter((game) => game.state === "final" && isToday(game.date));
  const scoredGames = games.filter(hasRealScore);
  const scheduledGames = games.filter((game) => game.state === "scheduled");

  return (
    pickFrom(liveGames, lastGameKey)
    || pickFrom(finalGames, lastGameKey)
    || pickFrom(scoredGames, lastGameKey)
    || pickFrom(scheduledGames, lastGameKey)
    || EMPTY_GAME
  );
}

function pickFrom(games, lastGameKey) {
  if (!games.length) {
    return null;
  }

  const freshGames = games.filter((game) => buildGameKey(game) !== lastGameKey);
  const choices = freshGames.length ? freshGames : games;

  return choices[Math.floor(Math.random() * choices.length)];
}

function getLastGameKey() {
  try {
    return window.localStorage.getItem(LAST_GAME_KEY);
  } catch {
    return null;
  }
}

function saveLastGameKey(game) {
  try {
    window.localStorage.setItem(LAST_GAME_KEY, buildGameKey(game));
  } catch {
    return null;
  }
}

function fitTextToBox() {
  const boxes = document.querySelectorAll(".fit-text");

  boxes.forEach((box) => {
    const maxSize = Number(box.dataset.maxSize || 32);
    let size = maxSize;

    box.style.fontSize = `${size}px`;

    while ((box.scrollWidth > box.clientWidth || box.scrollHeight > box.clientHeight) && size > MIN_TEXT_SIZE) {
      size -= 1;
      box.style.fontSize = `${size}px`;
    }
  });
}

function getReadableTextColor(color) {
  const hex = color.replace("#", "").padStart(6, "0");
  const red = parseInt(hex.slice(0, 2), 16);
  const green = parseInt(hex.slice(2, 4), 16);
  const blue = parseInt(hex.slice(4, 6), 16);
  const brightness = (red * 299 + green * 587 + blue * 114) / 1000;

  return brightness > 160 ? "#111111" : "#ffffff";
}

async function showGame() {
  try {
    const games = await getAllGames();
    renderScoreboard(pickRandomGame(games));
  } catch {
    renderScoreboard(EMPTY_GAME);
  }
}

window.addEventListener("resize", fitTextToBox);
renderScoreboard(EMPTY_GAME);
window.setInterval(updateClock, 1000);
showGame();
