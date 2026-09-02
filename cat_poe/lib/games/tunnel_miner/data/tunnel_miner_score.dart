/// Pure score used for leaderboards and session submit.
/// [depthBlocks] is deepest row index reached (0 = surface).
int computeTunnelMinerScore({
  required int depthBlocks,
  required int shards,
  required bool extracted,
}) {
  var s = depthBlocks * 100 + shards * 50;
  if (extracted) s += 500;
  return s;
}
