// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
package chipyard

import org.chipsalliance.cde.config.Config
import freechips.rocketchip.rocket._

class Hytron64SmallSMP2BenchConfig extends Config(
  new Config((site, here, up) => {
    case RocketDualAddExperimentKey => false
    case RocketDualAddRepeatCountKey => 1
    case RocketNContextsKey => 1
    case RocketContext1BootPCKey => None
  }) ++
  new freechips.rocketchip.subsystem.WithoutTLMonitors ++
  new WithNSmallCores(2) ++
  new chipyard.config.AbstractConfig
)
