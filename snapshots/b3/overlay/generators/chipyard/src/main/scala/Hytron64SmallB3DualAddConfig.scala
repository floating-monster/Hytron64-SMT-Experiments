// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
package chipyard

import org.chipsalliance.cde.config.Config

/** One fetched 32-bit ADD/ADDI per context; paired issue/execute, scalar retire. */
class Hytron64SmallB3DualAddConfig extends Config(
  new freechips.rocketchip.rocket.WithRocketDualAddExperiment ++
  new Hytron64SmallB2TwoContextConfig
)
