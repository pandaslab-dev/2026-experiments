const LEAGUES = [
  {
    sport: "basketball",
    league: "NBA",
    url: "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard",
  },
  {
    sport: "basketball",
    league: "WNBA",
    url: "https://site.api.espn.com/apis/site/v2/sports/basketball/wnba/scoreboard",
  },
  {
    sport: "baseball",
    league: "MLB",
    url: "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard",
  },
  {
    sport: "hockey",
    league: "NHL",
    url: "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/scoreboard",
  },
  {
    sport: "football",
    league: "NFL",
    url: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard",
  },
  {
    sport: "soccer",
    league: "MLS",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.1/scoreboard",
  },
  {
    sport: "soccer",
    league: "NWSL",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.nwsl/scoreboard",
  },
  {
    sport: "soccer",
    league: "Premier League",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard",
    defaultTimeZone: "Europe/London",
  },
  {
    sport: "soccer",
    league: "La Liga",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/scoreboard",
    defaultTimeZone: "Europe/Madrid",
  },
  {
    sport: "soccer",
    league: "Bundesliga",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/ger.1/scoreboard",
    defaultTimeZone: "Europe/Berlin",
  },
  {
    sport: "soccer",
    league: "Serie A",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/scoreboard",
    defaultTimeZone: "Europe/Rome",
  },
  {
    sport: "soccer",
    league: "Ligue 1",
    url: "https://site.api.espn.com/apis/site/v2/sports/soccer/fra.1/scoreboard",
    defaultTimeZone: "Europe/Paris",
  },
];

const DEFAULT_COLOR = "#111111";
const MIN_TEXT_SIZE = 12;
const RECENT_FINISHED_GAME_LIMIT = 10;

const TIME_ZONES_BY_STATE = {
  al: "America/Chicago",
  ar: "America/Chicago",
  az: "America/Phoenix",
  ca: "America/Los_Angeles",
  co: "America/Denver",
  ct: "America/New_York",
  dc: "America/New_York",
  de: "America/New_York",
  ga: "America/New_York",
  hi: "Pacific/Honolulu",
  ia: "America/Chicago",
  id: "America/Denver",
  il: "America/Chicago",
  in: "America/Indiana/Indianapolis",
  ks: "America/Chicago",
  ky: "America/New_York",
  la: "America/Chicago",
  ma: "America/New_York",
  md: "America/New_York",
  me: "America/New_York",
  mi: "America/Detroit",
  mn: "America/Chicago",
  mo: "America/Chicago",
  ms: "America/Chicago",
  mt: "America/Denver",
  nc: "America/New_York",
  nd: "America/Chicago",
  ne: "America/Chicago",
  nh: "America/New_York",
  nj: "America/New_York",
  nm: "America/Denver",
  nv: "America/Los_Angeles",
  ny: "America/New_York",
  oh: "America/New_York",
  ok: "America/Chicago",
  or: "America/Los_Angeles",
  pa: "America/New_York",
  ri: "America/New_York",
  sc: "America/New_York",
  sd: "America/Chicago",
  tn: "America/Chicago",
  tx: "America/Chicago",
  ut: "America/Denver",
  va: "America/New_York",
  vt: "America/New_York",
  wa: "America/Los_Angeles",
  wi: "America/Chicago",
  wv: "America/New_York",
  wy: "America/Denver",
  alberta: "America/Edmonton",
  "british columbia": "America/Vancouver",
  manitoba: "America/Winnipeg",
  ontario: "America/Toronto",
  quebec: "America/Toronto",
};

const TIME_ZONES_BY_CITY = {
  calgary: "America/Edmonton",
  edmonton: "America/Edmonton",
  indianapolis: "America/Indiana/Indianapolis",
  miami: "America/New_York",
  montreal: "America/Toronto",
  nashville: "America/Chicago",
  orlando: "America/New_York",
  ottawa: "America/Toronto",
  tampa: "America/New_York",
  toronto: "America/Toronto",
  vancouver: "America/Vancouver",
  winnipeg: "America/Winnipeg",
};

const TIME_ZONES_BY_COUNTRY = {
  england: "Europe/London",
  france: "Europe/Paris",
  germany: "Europe/Berlin",
  italy: "Europe/Rome",
  scotland: "Europe/London",
  spain: "Europe/Madrid",
  uk: "Europe/London",
  "united kingdom": "Europe/London",
};

const EMPTY_GAME = {
  sport: "x",
  league: "x",
  status: "x",
  clock: "x",
  homeTeam: "x",
  awayTeam: "x",
  homeScore: "x",
  awayScore: "x",
  homeColor: DEFAULT_COLOR,
  awayColor: DEFAULT_COLOR,
  location: "x",
  venueTimeZone: null,
  state: "empty",
  date: null,
};

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
  const results = await Promise.allSettled(LEAGUES.map((league) => getLeagueGames(league)));

  return results
    .flatMap((result) => (result.status === "fulfilled" ? result.value : []))
    .filter(isDisplayableGame);
}

async function getLeagueGames(league) {
  const response = await fetch(league.url);

  if (!response.ok) {
    throw new Error(`could not load ${league.league}`);
  }

  const data = await response.json();
  const events = data.events || [];

  return events.map((event) => normalizeGame(event, league)).filter(Boolean);
}

function normalizeGame(event, league) {
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

  const status = competition.status || {};
  const statusType = status.type || {};

  return {
    sport: league.sport,
    league: league.league,
    status: cleanStatusText(statusType.description),
    clock: cleanClockText(status),
    homeTeam: getTeamName(home),
    awayTeam: getTeamName(away),
    homeScore: getScore(home.score),
    awayScore: getScore(away.score),
    homeColor: makeColor(home.team?.color, home.team?.alternateColor),
    awayColor: makeColor(away.team?.color, away.team?.alternateColor),
    location: buildLocationLabel(competition.venue),
    venueTimeZone: resolveVenueTimeZone(competition.venue, league.defaultTimeZone),
    state: statusType.state || "pre",
    date: competition.date || event.date || null,
  };
}

function getTeamName(team) {
  return team.team?.shortDisplayName || team.team?.displayName || team.team?.name || "x";
}

function getScore(score) {
  const value = Number(score);
  return Number.isFinite(value) ? value : 0;
}

function isDisplayableGame(game) {
  if (!game.date) {
    return false;
  }

  const gameTime = new Date(game.date).getTime();

  if (Number.isNaN(gameTime)) {
    return false;
  }

  if (game.state === "in") {
    return true;
  }

  if (game.state === "post") {
    return true;
  }

  return false;
}

function pickDisplayGame(games) {
  const liveGames = games.filter((game) => game.state === "in");

  if (liveGames.length) {
    return liveGames[Math.floor(Math.random() * liveGames.length)];
  }

  const finishedGames = games
    .filter((game) => game.state === "post")
    .sort((left, right) => new Date(right.date) - new Date(left.date));

  if (finishedGames.length) {
    const recentFinishedGames = finishedGames.slice(0, RECENT_FINISHED_GAME_LIMIT);
    return recentFinishedGames[Math.floor(Math.random() * recentFinishedGames.length)];
  }

  return EMPTY_GAME;
}

function cleanStatusText(description) {
  const simple = (description || "").toLowerCase();

  if (simple === "in progress" || simple === "status in progress") {
    return "live";
  }

  if (simple === "final") {
    return "final";
  }

  if (simple) {
    return simple;
  }

  return "x";
}

function cleanClockText(status) {
  const detail = status.type?.shortDetail || status.type?.detail || status.displayClock || "";
  return detail ? detail.toLowerCase() : "x";
}

function buildLocationLabel(venue) {
  const city = venue?.address?.city;
  const region = venue?.address?.state || venue?.address?.country;

  if (city && region) {
    return `${city}, ${region}`;
  }

  if (city) {
    return city;
  }

  if (venue?.fullName) {
    return venue.fullName;
  }

  return "x";
}

function resolveVenueTimeZone(venue, defaultTimeZone) {
  const cityKey = normalizeKey(venue?.address?.city);
  const stateKey = normalizeKey(venue?.address?.state);
  const countryKey = normalizeKey(venue?.address?.country);

  if (cityKey && TIME_ZONES_BY_CITY[cityKey]) {
    return TIME_ZONES_BY_CITY[cityKey];
  }

  if (stateKey && TIME_ZONES_BY_STATE[stateKey]) {
    return TIME_ZONES_BY_STATE[stateKey];
  }

  if (countryKey && TIME_ZONES_BY_COUNTRY[countryKey]) {
    return TIME_ZONES_BY_COUNTRY[countryKey];
  }

  return defaultTimeZone || null;
}

function normalizeKey(value) {
  return String(value || "").trim().toLowerCase();
}

function makeColor(mainColor, backupColor) {
  const color = mainColor || backupColor;

  if (!color) {
    return DEFAULT_COLOR;
  }

  return `#${color.replace("#", "")}`;
}

function renderScoreboard(game) {
  state.currentGame = game;

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

function formatScore(score) {
  if (typeof score !== "number" || Number.isNaN(score)) {
    return "x";
  }

  return String(score);
}

function applyTeamColors(game) {
  const awayColor = game.awayColor || DEFAULT_COLOR;
  const homeColor = game.homeColor || DEFAULT_COLOR;

  document.documentElement.style.setProperty("--away-color", awayColor);
  document.documentElement.style.setProperty("--home-color", homeColor);
  document.documentElement.style.setProperty("--away-text", getReadableTextColor(awayColor));
  document.documentElement.style.setProperty("--home-text", getReadableTextColor(homeColor));
}

function updateClock() {
  elements.metaText.textContent = formatMetaLine(state.currentGame);
}

function formatMetaLine(game) {
  const venueTime = formatVenueTime(game.venueTimeZone);
  return [game.status || "x", game.location || "x", venueTime].join(" / ");
}

function formatVenueTime(timeZone) {
  if (!timeZone) {
    return "x";
  }

  try {
    return new Intl.DateTimeFormat([], {
      hour: "numeric",
      minute: "2-digit",
      timeZone,
      timeZoneName: "short",
    }).format(new Date());
  } catch {
    return "x";
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
  const hex = color.replace("#", "");
  const red = parseInt(hex.slice(0, 2), 16);
  const green = parseInt(hex.slice(2, 4), 16);
  const blue = parseInt(hex.slice(4, 6), 16);
  const brightness = (red * 299 + green * 587 + blue * 114) / 1000;

  return brightness > 150 ? "#111111" : "#ffffff";
}

async function showAnotherGame() {
  try {
    const games = await getAllGames();
    renderScoreboard(pickDisplayGame(games));
  } catch {
    renderScoreboard(EMPTY_GAME);
  }
}

window.addEventListener("resize", fitTextToBox);

renderScoreboard(EMPTY_GAME);
window.setInterval(updateClock, 1000);
showAnotherGame();
