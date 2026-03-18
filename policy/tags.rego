package terraform.policies.tags

import rego.v1

# All resources must have managed-by and environment tags

deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	tags := resource.change.after.tags
	not tags["managed-by"]
	msg := sprintf("Resource '%s' is missing required tag: managed-by", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	tags := resource.change.after.tags
	not tags["environment"]
	msg := sprintf("Resource '%s' is missing required tag: environment", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	not resource.change.after.tags
	msg := sprintf("Resource '%s' has no tags block at all", [resource.address])
}