output "state_machine_arn" {
  description = "The ARN of the Step Function State Machine"
  value       = aws_sfn_state_machine.sfn_state_machine.arn
}
