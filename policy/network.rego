package terraform.policies.network

import rego.v1

# No SSH (port 22) open to 0.0.0.0/0 or ::/0

# AWS - aws_security_group inline rules
deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "aws_security_group"
	rule := resource.change.after.ingress[_]
	rule.from_port <= 22
	rule.to_port >= 22
	cidr := rule.cidr_blocks[_]
	cidr in ["0.0.0.0/0", "::/0"]
	msg := sprintf("Resource '%s' allows SSH from %s — restrict to known CIDR ranges", [resource.address, cidr])
}

# AWS - standalone aws_security_group_rule
deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "aws_security_group_rule"
	resource.change.after.type == "ingress"
	resource.change.after.from_port <= 22
	resource.change.after.to_port >= 22
	cidr := resource.change.after.cidr_blocks[_]
	cidr in ["0.0.0.0/0", "::/0"]
	msg := sprintf("Resource '%s' allows SSH from %s — restrict to known CIDR ranges", [resource.address, cidr])
}

# GCP - google_compute_firewall
deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "google_compute_firewall"
	resource.change.after.direction == "INGRESS"
	allow := resource.change.after.allow[_]
	allow.protocol == "tcp"
	port := allow.ports[_]
	contains(port, "22")
	source := resource.change.after.source_ranges[_]
	source in ["0.0.0.0/0", "::/0"]
	msg := sprintf("Resource '%s' allows SSH from %s — restrict to known CIDR ranges", [resource.address, source])
}

# Azure - azurerm_network_security_group inline rules
deny contains msg if {
	resource := input.resource_changes[_]
	resource.change.actions[_] in ["create", "update"]
	resource.type == "azurerm_network_security_group"
	rule := resource.change.after.security_rule[_]
	rule.direction == "Inbound"
	rule.access == "Allow"
	rule.destination_port_range == "22"
	rule.source_address_prefix in ["*", "0.0.0.0/0", "::/0", "Internet"]
	msg := sprintf("Resource '%s' allows SSH from %s — restrict to known CIDR ranges", [resource.address, rule.source_address_prefix])
}
