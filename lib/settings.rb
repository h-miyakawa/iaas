class Settings
  USERS_FILEPATH = "./users.json"
  HOSTS_FILEPATH = "./hosts.json"
  DHCP_LEASES_FILEPATH = "/var/lib/dhcp/dhcpd.leases"
  DHCP_CONF_FILEPATH = "/etc/dhcp/dhcpd.conf"
  DHCP_BASECONF_FILEPATH = "./dhcp_base.txt"
  MY_DHCP_LEASES_FILEPATH = "./ip_leases.json"
  BASE_LEASE_IP = "192.168.1."
  MIN_LEASE_IP = 10
  MAX_LEASE_IP = 200
  WEB_SERVER_IP_ADDRESS = "127.0.0.1"
  WEB_SERVER_PORT = 44444
  HOST_PORT = 55555
  LISTENING_PORT = 55555
end
