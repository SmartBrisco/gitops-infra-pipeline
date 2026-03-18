package terraform.policies.compute

import rego.v1

# Only approved instance types permitted per cloud

approved_aws_instance_types := {
	"t2.micro",
	"t3.micro",
	"t3.small",
}

approved_gcp_machine_types := {
	"e2-micro",
	"e2-small",
	"e2-medium",
}

approved_azure_vm_sizes := {
	"Standard_B1s",
	"Standard_B1ms",
	"Standard_B2s",
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "aws_instance"
	instance_type := resource.change.after.instance_type
	not instance_type in approved_aws_instance_types
	msg := sprintf(
		"Resource '%s' uses unapproved AWS instance type '%s' — allowed: %v",
		[resource.address, instance_type, approved_aws_instance_types],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "google_compute_instance"
	machine_type := resource.change.after.machine_type
	not machine_type in approved_gcp_machine_types
	msg := sprintf(
		"Resource '%s' uses unapproved GCP machine type '%s' — allowed: %v",
		[resource.address, machine_type, approved_gcp_machine_types],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "azurerm_linux_virtual_machine"
	vm_size := resource.change.after.size
	not vm_size in approved_azure_vm_sizes
	msg := sprintf(
		"Resource '%s' uses unapproved Azure VM size '%s' — allowed: %v",
		[resource.address, vm_size, approved_azure_vm_sizes],
	)
}