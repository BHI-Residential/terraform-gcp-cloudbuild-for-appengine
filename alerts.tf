resource "google_monitoring_notification_channel" "email" {
  project      = local.project_name
  display_name = "GAE-${local.project_name}-${var.appengine_service_name}"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
  force_delete = false
}

locals {

  series_align_method = {
    mean       = "ALIGN_MEAN"
    count_true = "ALIGN_COUNT_TRUE"
    rate       = "ALIGN_RATE"
    sum        = "ALIGN_SUM"
  }
  alignment_period = "60s"

  reducer_method = {
    sum           = "REDUCE_SUM"
    none          = "REDUCE_NONE"
    count         = "REDUCE_COUNT"
    percentile_99 = "REDUCE_PERCENTILE_99"
  }

  group_by_labels = {
    response_code = "metric.label.response_code"
    module_id     = "resource.label.module_id"
  }

  threshold_comparison = {
    less_than    = "COMPARISON_LT"
    greater_than = "COMPARISON_GT"
  }

  resource_usage_threshold_duration = "0s"

  notification_channels = [google_monitoring_notification_channel.email.id]
}

resource "google_monitoring_alert_policy" "gae-resource-usage-alert" {
  project               = local.project_name
  display_name          = "${local.project_name}-${var.appengine_service_name}-gae-cpu-usage-alert"
  combiner              = "OR"
  enabled               = true
  notification_channels = local.notification_channels
  user_labels = {
    service = var.appengine_service_name
  }

  documentation {
    content   = "${local.project_name}-${var.appengine_service_name} app has been experiencing unusually high cpu utilization"
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "${local.project_name}-${var.appengine_service_name}-gae-cpu-usage"

    condition_threshold {
      threshold_value = var.alert_cpu_usage_threshold
      comparison      = local.threshold_comparison.greater_than
      duration        = local.resource_usage_threshold_duration

      filter = "resource.type = \"gae_app\" AND resource.labels.module_id = \"${var.appengine_service_name}\" AND metric.type = \"appengine.googleapis.com/flex/cpu/utilization\""

      aggregations {
        per_series_aligner   = local.series_align_method.mean
        alignment_period     = local.alignment_period
        cross_series_reducer = local.reducer_method.sum
        group_by_fields      = [local.group_by_labels.module_id]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }


}

resource "google_monitoring_alert_policy" "gae-response-latency-alert" {
  project               = local.project_name
  display_name          = "${local.project_name}-${var.appengine_service_name}-gae-response-latency-alert"
  combiner              = "OR"
  enabled               = true
  notification_channels = local.notification_channels
  user_labels = {
    service = var.appengine_service_name
  }

  documentation {
    content   = "the ${local.project_name}-${var.appengine_service_name} app has been experiencing high response latency"
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "${local.project_name}-${var.appengine_service_name}-gae-app-response-latency"

    condition_threshold {
      threshold_value         = var.alert_response_latency_threshold
      comparison              = local.threshold_comparison.greater_than
      duration                = "60s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = "resource.type = \"gae_app\" AND resource.labels.module_id = \"${var.appengine_service_name}\" AND metric.type = \"appengine.googleapis.com/http/server/response_latencies\""

      aggregations {
        per_series_aligner   = local.series_align_method.sum
        alignment_period     = local.alignment_period
        cross_series_reducer = local.reducer_method.percentile_99
        group_by_fields      = [local.group_by_labels.module_id]
      }

      trigger {
        count   = 1
        percent = 0
      }
    }
  }
}




resource "google_monitoring_alert_policy" "gae-response-code-alert" {
  project               = local.project_name
  display_name          = "${local.project_name}-${var.appengine_service_name}-gae-response-code-alert"
  combiner              = "OR"
  enabled               = true
  notification_channels = local.notification_channels
  user_labels = {
    service = var.appengine_service_name
  }

  documentation {
    content   = "the ${local.project_name}-${var.appengine_service_name} app has been responding with 500 internal server error status codes"
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "${local.project_name}-${var.appengine_service_name}-gae-app-500-response"

    condition_threshold {
      threshold_value         = var.alert_5xx_threshold
      comparison              = local.threshold_comparison.greater_than
      duration                = "60s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      filter = "resource.type = \"gae_app\" AND resource.labels.module_id = \"${var.appengine_service_name}\" AND metric.label.\"response_code\">=\"500\" AND metric.type = \"appengine.googleapis.com/http/server/response_count\""

      aggregations {
        per_series_aligner   = local.series_align_method.sum
        alignment_period     = local.alignment_period
        cross_series_reducer = local.reducer_method.sum
      }

      trigger {
        count   = 1
        percent = 0
      }

    }
  }
}