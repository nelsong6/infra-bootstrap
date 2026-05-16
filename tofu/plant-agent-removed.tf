# ============================================================================
# plant-agent retirement
# ============================================================================
# plant-agent was retired on 2026-05-16. The per-app Azure resources were
# destroyed by plant-agent/tofu/* (see nelsong6/plant-agent#24). This file
# drops the remaining infra-bootstrap-managed pieces:
#
# - module.app["plant-agent"] was removed from the for_each set above. Tofu
#   would plan a destroy on every resource the module produced — most of
#   which we want destroyed (SP, KV role assignment, federated credentials,
#   github_actions variables). The exception is the github_repository: we
#   want to preserve it so we can `gh repo archive` it manually after this
#   PR lands (archival is reversible; destruction is not).
#
# Each `removed` block forgets a resource from state without destroying it.
# Everything else module.app produces for plant-agent gets destroyed in
# the normal way when its for_each entry disappears.
# ============================================================================

removed {
  from = module.app["plant-agent"].github_repository.repo

  lifecycle {
    destroy = false
  }
}
