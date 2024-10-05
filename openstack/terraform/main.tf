# ----- Data
data "openstack_networking_network_v2" "ext_network" {
  name = "public"
}

# ----- Resource
# 1. Keypair 생성
resource "openstack_compute_keypair_v2" "opsathlan_keypair" {
  name       = "opsathlan-${var.name}-keypair"
  public_key = file(var.pubkey_file_path)
}

# 2. Security Group 생성
resource "openstack_networking_secgroup_v2" "opsathlan_secgroup" {
  name                 = "opsathlan-${var.name}-secgroup"
  description          = "OpsAthaln Security Group"
  delete_default_rules = false
}

# 2.1 Security Group Rule 생성
resource "openstack_networking_secgroup_rule_v2" "secgroup_rules" {
  count             = length(var.allowed_ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = lookup(var.allowed_ports[count.index], "protocol", "tcp")
  port_range_min    = lookup(var.allowed_ports[count.index], "port_range_min")
  port_range_max    = lookup(var.allowed_ports[count.index], "port_range_max")
  remote_ip_prefix  = lookup(var.allowed_ports[count.index], "remote_ip_prefix", "0.0.0.0/0")
  security_group_id = openstack_networking_secgroup_v2.opsathlan_secgroup.id
}

# 3. Network 생성
resource "openstack_networking_network_v2" "opsathlan_network" {
  name                  = "opsathlan-${var.name}-network"
  admin_state_up        = true
  port_security_enabled = var.port_security_enabled
}

# 3.1 Subnet 생성
resource "openstack_networking_subnet_v2" "opsathlan_subnet" {
  name            = "opsathlan-${var.name}-subnet"
  network_id      = openstack_networking_network_v2.opsathlan_network.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# 3.2 Router 생성
resource "openstack_networking_router_v2" "opsathlan_router" {
  name                = "opsathlan-${var.name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext_network.id
}

# 3.3 Router Interface 생성
resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.opsathlan_router.id
  subnet_id = openstack_networking_subnet_v2.opsathlan_subnet.id
}


# 5. Floating IP 생성 및 연결
resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = data.openstack_networking_network_v2.ext_network.name
}

# 4. Nova Instance 생성
resource "openstack_compute_instance_v2" "nova_instance" {
  name            = "opsathlan-${var.name}-instance"
  image_name      = var.image_name
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.opsathlan_keypair.name
  security_groups = [openstack_networking_secgroup_v2.opsathlan_secgroup.name]

  network {
    uuid = openstack_networking_network_v2.opsathlan_network.id
  }

  depends_on = [openstack_networking_subnet_v2.opsathlan_subnet]

}

resource "openstack_compute_floatingip_associate_v2" "floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.floating_ip.address
  instance_id = openstack_compute_instance_v2.nova_instance.id
}
