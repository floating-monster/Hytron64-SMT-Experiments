// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
package chipyard

import org.chipsalliance.cde.config.Config

/** B1: two Small Rocket cores with the shared Inclusive L2 from AbstractConfig. */
class Hytron64SmallSmpL2B1Config extends Config(
  new freechips.rocketchip.subsystem.WithoutTLMonitors ++
  new freechips.rocketchip.rocket.WithNSmallCores(2) ++
  new chipyard.config.AbstractConfig)
