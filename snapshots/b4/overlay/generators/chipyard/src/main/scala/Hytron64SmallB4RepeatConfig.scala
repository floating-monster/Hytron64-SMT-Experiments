// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
package chipyard

import org.chipsalliance.cde.config.Config

/** 1024 dependent integer operations per context; original B3 fetch/replay fix. */
class Hytron64SmallB4RepeatConfig extends Config(
  new freechips.rocketchip.rocket.WithRocketDualAddRepeatCount(1024) ++
  new Hytron64SmallB3DualAddR1p1Config
)
