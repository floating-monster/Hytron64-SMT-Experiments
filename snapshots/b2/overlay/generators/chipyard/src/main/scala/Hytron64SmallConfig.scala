// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
package chipyard

import org.chipsalliance.cde.config.Config

/** 010L baseline: standard Small Rocket, without TileLink monitors. */
class Hytron64SmallConfig extends Config(
  new freechips.rocketchip.subsystem.WithoutTLMonitors ++
  new freechips.rocketchip.rocket.WithNSmallCores(1) ++
  new chipyard.config.AbstractConfig)
