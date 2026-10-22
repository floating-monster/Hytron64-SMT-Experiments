// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
/**
 * Experimental Rocket context-count configuration hook.
 * The default value of 1 preserves existing configurations.
 * WithRocketNContexts(n) lets an experiment opt in to another count.
 * This file declares the setting; RocketCore contains the hardware behavior.
 */
 /*(sample)
--- a/generators/rocket-chip/src/main/scala/rocket/RocketCore.scala
++ b/generators/rocket-chip/src/main/scala/rocket/RocketCore.scala
  // Consumes RocketNContextsKey declared in RocketContextParams.scala.
  // Existing configurations use the default value 1; B2-2CTX opts in to 2.
  // This check validates the configuration hook; context datapath support is separate.
  private val configuredNContexts = p(RocketNContextsKey)
  require(configuredNContexts == 1 || configuredNContexts == 2,
    "Rocket experiment supports 1 or 2 contexts")
 */
package freechips.rocketchip.rocket

import org.chipsalliance.cde.config.{Config, Field}

case object RocketNContextsKey extends Field[Int](1)

// Initial PC for experimental context 1; None keeps existing configurations unchanged.
case object RocketContext1BootPCKey extends Field[Option[BigInt]](None)

class WithRocketNContexts(n: Int) extends Config((site, here, up) => {
  case RocketNContextsKey => n
}) {
  require(n == 1 || n == 2, "Rocket experiment supports 1 or 2 contexts")
}

class WithRocketContext1BootPC(pc: BigInt) extends Config((site, here, up) => {
  case RocketContext1BootPCKey => Some(pc)
}) {
  require(pc >= 0 && (pc & 1) == 0, "Context 1 boot PC must be non-negative and 2-byte aligned")
}

// Default-off one-shot two-context integer execution experiment.
case object RocketDualAddExperimentKey extends Field[Boolean](false)
class WithRocketDualAddExperiment extends Config((site, here, up) => {
  case RocketDualAddExperimentKey => true
})
