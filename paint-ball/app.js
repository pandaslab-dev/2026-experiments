const gameUrls = {
  nba: "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard",
  mlb: "https://site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard",
  soccer: [
    {
      url: "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.1/scoreboard",
      sport: "soccer",
      league: "MLS",
    },
    {
      url: "https://site.api.espn.com/apis/site/v2/sports/soccer/usa.nwsl/scoreboard",
      sport: "soccer",
      league: "NWSL",
    },
    {
      url: "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/scoreboard",
      sport: "soccer",
      league: "Premier League",
    },
  ],
};

const demoGames = [
  {
    sport: "baseball",
    league: "made up mlb-ish thing",
    status: "painted live",
    clock: "bottom 8th",
    homeTeam: "toledo mud puddles",
    awayTeam: "reno dust",
    homeScore: 6,
    awayScore: 4,
    homeColor: "#1d65c1",
    awayColor: "#f15a29",
    extraInfo: "windy night in ohio",
    isDemo: true,
    state: "in",
    date: new Date().toISOString(),
  },
  {
    sport: "basketball",
    league: "weird summer run",
    status: "final-ish",
    clock: "paint dried",
    homeTeam: "saturn hoops",
    awayTeam: "des moines lasers",
    homeScore: 112,
    awayScore: 109,
    homeColor: "#0f7b6c",
    awayColor: "#d91e63",
    extraInfo: "mystery gym somewhere",
    isDemo: true,
    state: "post",
    date: new Date().toISOString(),
  },
  {
    sport: "soccer",
    league: "tiny moon cup",
    status: "74th minute",
    clock: "2nd half",
    homeTeam: "club sandwich",
    awayTeam: "real puddle",
    homeScore: 2,
    awayScore: 1,
    homeColor: "#ffc400",
    awayColor: "#222222",
    extraInfo: "very fake but alive",
    isDemo: true,
    state: "in",
    date: new Date().toISOString(),
  },
];

const state = {
  games: [],
  currentGame: null,
  clockTimer: null,
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

// data stuff

async function getLiveGames() {
  const results = await Promise.allSettled([
    getNbaGames(),
    getMlbGames(),
    getSoccerGames(),
  ]);

  const games = results.flatMap((result) => {
    if (result.status === "fulfilled") {
      return result.value;
    }

    return [];
  });

  return games.filter(isRelevantGame);
}

function getDemoGames() {
  return demoGames.map((game) => ({ ...game }));
}

async function getNbaGames() {
  return getEspnLeagueGames(gameUrls.nba, { sport: "basketball", league: "NBA" });
}

async function getMlbGames() {
  return getEspnLeagueGames(gameUrls.mlb, { sport: "baseball", league: "MLB" });
}

async function getSoccerGames() {
  const results = await Promise.allSettled(
    gameUrls.soccer.map((item) => getEspnLeagueGames(item.url, item))
  );

  return results.flatMap((result) => {
    if (result.status === "fulfilled") {
      return result.value;
    }

    return [];
  });
}

async function getEspnLeagueGames(url, info) {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`could not load ${info.league}`);
  }

  const data = await response.json();
  const events = data.events || [];

  return events
    .map((event) => normalizeGame(event, info))
    .filter(Boolean);
}

function normalizeGame(event, info) {
  const competition = event.competitions && event.competitions[0];

  if (!competition) {
    return null;
  }

  const home = competition.competitors.find((team) => team.homeAway === "home");
  const away = competition.competitors.find((team) => team.homeAway === "away");

  if (!home || !away) {
    return null;
  }

  const statusType = competition.status?.type?.state || "pre";
  const detail = competition.status?.type?.shortDetail || competition.status?.type?.detail || "";
  const note = competition.notes?.[0]?.headline || "";
  const venue = competition.venue?.address?.city || competition.venue?.fullName || "";

  return {
    sport: info.sport,
    league: info.league,
    status: cleanStatusText(competition.status?.type?.description || "scheduled", detail),
    clock: cleanClockText(detail, competition.status?.displayClock),
    homeTeam: home.team.shortDisplayName || home.team.displayName || home.team.name,
    awayTeam: away.team.shortDisplayName || away.team.displayName || away.team.name,
    homeScore: Number(home.score || 0),
    awayScore: Number(away.score || 0),
    homeColor: makeColor(home.team.color, home.team.alternateColor),
    awayColor: makeColor(away.team.color, away.team.alternateColor),
    extraInfo: note || venue || event.shortName || "espn scoreboard",
    state: statusType,
    date: competition.date || event.date,
    isDemo: false,
  };
}

function pickRandomGame(games) {
  const liveGames = games.filter((game) => game.state === "in");
  const recentGames = games.filter((game) => game.state === "post");
  const soonGames = games.filter((game) => game.state === "pre");
  const bucket = liveGames.length ? liveGames : recentGames.length ? recentGames : soonGames;

  return bucket[Math.floor(Math.random() * bucket.length)];
}

function isRelevantGame(game) {
  if (!game.date) {
    return false;
  }

  const gameTime = new Date(game.date).getTime();
  const now = Date.now();
  const hoursAway = (gameTime - now) / (1000 * 60 * 60);

  if (game.state === "in") {
    return true;
  }

  if (game.state === "post") {
    return hoursAway > -30;
  }

  if (game.state === "pre") {
    return hoursAway > -2 && hoursAway < 12;
  }

  return false;
}

function cleanStatusText(description, detail) {
  const simple = description.toLowerCase();

  if (simple === "in progress" || simple === "status in progress") {
    return "live";
  }

  if (simple === "final") {
    return "final";
  }

  if (simple === "scheduled") {
    return "soon";
  }

  return detail ? detail.toLowerCase() : simple;
}

function cleanClockText(detail, displayClock) {
  if (detail) {
    return detail.toLowerCase();
  }

  if (displayClock) {
    return displayClock.toLowerCase();
  }

  return "waiting";
}

function makeColor(mainColor, backupColor) {
  const color = mainColor || backupColor;

  if (!color) {
    return "#111111";
  }

  return `#${color.replace("#", "")}`;
}

// rendering stuff

function numberToWords(number) {
  const ones = [
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "ten",
    "eleven",
    "twelve",
    "thirteen",
    "fourteen",
    "fifteen",
    "sixteen",
    "seventeen",
    "eighteen",
    "nineteen",
  ];

  const tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"];

  if (number < 20) {
    return ones[number];
  }

  if (number < 100) {
    const tenWord = tens[Math.floor(number / 10)];
    const rest = number % 10;
    return rest ? `${tenWord} ${ones[rest]}` : tenWord;
  }

  if (number < 1000) {
    const hundredWord = `${ones[Math.floor(number / 100)]} hundred`;
    const rest = number % 100;
    return rest ? `${hundredWord} ${numberToWords(rest)}` : hundredWord;
  }

  return String(number);
}

function renderScoreboard(game) {
  state.currentGame = game;

  const awayScoreText = formatScore(game.awayScore);
  const homeScoreText = formatScore(game.homeScore);
  const sportLabel = `${game.sport} / ${game.league}`;

  elements.awayTeam.textContent = game.awayTeam;
  elements.homeTeam.textContent = game.homeTeam;
  elements.awayScore.textContent = awayScoreText;
  elements.homeScore.textContent = homeScoreText;
  elements.statusText.textContent = game.status;
  elements.gameClock.textContent = game.clock;
  elements.sportText.textContent = sportLabel;

  applyTeamColors(game);
  updateClock();
  fitTextToBox();
}

function applyTeamColors(game) {
  const awayColor = game.awayColor || "#111111";
  const homeColor = game.homeColor || "#111111";

  document.documentElement.style.setProperty("--away-color", awayColor);
  document.documentElement.style.setProperty("--home-color", homeColor);
  document.documentElement.style.setProperty("--away-text", getReadableTextColor(awayColor));
  document.documentElement.style.setProperty("--home-text", getReadableTextColor(homeColor));
}

function updateClock() {
  const now = new Date();
  const shortTime = new Intl.DateTimeFormat([], {
    hour: "numeric",
    minute: "2-digit",
  }).format(now);

  if (!state.currentGame) {
    elements.metaText.textContent = shortTime;
    return;
  }

  elements.metaText.textContent = formatMetaLine(state.currentGame, shortTime);
}

function fitTextToBox() {
  const boxes = document.querySelectorAll(".fit-text");

  boxes.forEach((box) => {
    const maxSize = Number(box.dataset.maxSize || 32);
    let size = maxSize;

    box.style.fontSize = `${size}px`;

    while ((box.scrollWidth > box.clientWidth || box.scrollHeight > box.clientHeight) && size > 12) {
      size -= 1;
      box.style.fontSize = `${size}px`;
    }
  });
}

function formatScore(score) {
  const wordScore = numberToWords(score);

  if (wordScore.length <= 19) {
    return wordScore;
  }

  return String(score);
}

function formatMetaLine(game, timeText) {
  const parts = [];

  if (game.status) {
    parts.push(game.status);
  }

  if (game.extraInfo) {
    parts.push(game.extraInfo.toLowerCase());
  }

  parts.push(timeText.toLowerCase());

  return parts.join(" / ");
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
    const liveGames = await getLiveGames();
    const games = liveGames.length ? liveGames : getDemoGames();
    const game = pickRandomGame(games);

    state.games = games;
    renderScoreboard(game);
  } catch (error) {
    state.games = getDemoGames();
    renderScoreboard(pickRandomGame(state.games));
  }
}

window.addEventListener("resize", fitTextToBox);

updateClock();
state.clockTimer = window.setInterval(updateClock, 1000);
showAnotherGame();
