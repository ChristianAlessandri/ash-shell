function getTrackName(player) {
  return (
    player.title ||
    (player.metadata && player.metadata["xesam:title"]) ||
    "Unknown Track"
  );
}

function getArtistName(player) {
  var metaArtist = player.metadata ? player.metadata["xesam:artist"] : null;
  if (!metaArtist)
    return player.artist ? String(player.artist) : "Unknown Artist";
  if (Array.isArray(metaArtist) || typeof metaArtist === "object") {
    return metaArtist.length > 0 ? String(metaArtist[0]) : "Unknown Artist";
  }
  return String(metaArtist);
}

function getCoverUrl(player) {
  return (
    player.artUrl || (player.metadata && player.metadata["mpris:artUrl"]) || ""
  );
}

function isPlaying(player) {
  var stateString = String(player.playbackState).toLowerCase();
  return stateString === "playing" || stateString === "1";
}
