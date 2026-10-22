// HYTRON64 research snapshot: locally modified from upstream Rocket/Chipyard.
// Publication copy: comments/path references and whitespace normalized; see PROVENANCE.json.
package chipyard

import org.chipsalliance.cde.config.Config

/** R1.1: preserve the normal Rocket frontend replay/exception path. */
class Hytron64SmallB3DualAddR1p1Config extends Config(
  new Hytron64SmallB3DualAddConfig
)
