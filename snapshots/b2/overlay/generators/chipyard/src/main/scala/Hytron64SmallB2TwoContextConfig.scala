// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
//+++ b/generators/rocket-chip/src/main/scala/rocket/RocketContextParams.scala

package chipyard

import org.chipsalliance.cde.config.Config

/** B2-2CTX parameter plumbing; execution logic is added in a later step. */

class Hytron64SmallB2TwoContextConfig extends Config(
  new freechips.rocketchip.rocket.WithRocketContext1BootPC(
    BigInt("80001000", 16)
  ) ++
  new freechips.rocketchip.rocket.WithRocketNContexts(2) ++
  new Hytron64SmallConfig
)
