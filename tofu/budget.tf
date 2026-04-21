# ============================================================================
# Cosmos DB cost guardrail
# ============================================================================
# Filtered to Azure Cosmos DB spend only. Covers the current provisioned
# account and the serverless account it is being migrated to — filtering by
# service category rather than resource ID means both are in scope.
#
# Alerts fire at 75% forecast and 100% actual of the monthly threshold.
# Start date must be the first of a month and cannot be backdated; kept as a
# static 2026-04-01 so plans are deterministic across runs.

resource "azurerm_consumption_budget_subscription" "cosmos" {
  name            = "cosmos-db-monthly"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 20
  time_grain = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z"
  }

  filter {
    dimension {
      name   = "MeterCategory"
      values = ["Azure Cosmos DB"]
    }
  }

  notification {
    enabled        = true
    threshold      = 75
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = ["fullnelsongrip@gmail.com"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = ["fullnelsongrip@gmail.com"]
  }
}

data "azurerm_subscription" "current" {}
