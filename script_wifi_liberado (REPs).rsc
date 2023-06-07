#SCRIPT ADAPTADO POR: DANIELSON - VERSÃO 2.1

#ONDE USAR? Nos REPs
#COMO USAR?
#1- Recomendação: Abrir esse scritp no editor de texto Sublime Text ou Notepad++
#2- Alterar os valores VARIAVEIS que estão entre aspas DUPLA ""
#3- Colar esse script no TERMINAL do Mikrotik e apertar ENTER

#Padrão rede wi-fi:
#REDE LAN---------REDE WIFI-LIBERADO
#172.16.xxx.xxx - 10.21.xxx.xxx 
#172.18.xxx.xxx - 10.23.xxx.xxx
#172.19.xxx.xxx - 10.24.xxx.xxx
#172.26.xxx.xxx - 10.31.xxx.xxx

#<INICIO DO SCRIPT>

#>>>>>>>> VARIAVEIS (ALTERAR VALORES) <<<<<<<<<<
global ssid "CSA-XXX"
global pool "10.24.XXX.5-10.24.XXX.15"
global networkwifi "10.24.XXX.0"
global ipaddress1 "10.24.XXX.1/26"
global ipaddress0 "10.24.XXX.0/26"
global gatewaywifi "10.24.XXX.1"
#Confira a subrede na RB EM: >IP > DHCP SERVER > NETWORK - LAN
global networklan "!172.19.XXX.0/24"
#Nome da interface ppoe, se for dhcp client, usar o gateway que é entregue pelo provedor. 
global nameinterfaceprovedor "pppoe-out-WAN-PROVEDOR"


#Excluir configurações da rede WIFI LIBERADO já criadas anteriormente
/interface bridge port remove [find interface="wlan2"]
/interface bridge port remove [find interface="vlan804"]
/ip address remove [find interface="bridge-vlan804"]
/interface bridge remove [find name="bridge-vlan804"]
/interface vlan remove [find name="vlan804"]
/interface wireless security-profiles remove [find name="profile-clientes"]
/interface wireless remove [find name="wlan2"]
/ip pool remove [find name="dhcp_pool_clientes"]
/ip dhcp-server remove [find name="dhcp-WIFI-LIBERADO"]
/ip dhcp-server network remove [find comment="WIFI-LIBERADO"]
/ip firewall address-list remove [find list="IPs-WIFI-LIBERADO"]
/ip firewall mangle remove [find comment="routing-WIFI-LIBERADO"]
/ip firewall nat remove [find comment="NAT-WIFI-LIBERADO"]
/ip route remove [find comment="DEFAULT-WIFI-LIBERADO"]


#Criar uma nova interface de bridge com o nome bridge-vlan804.
/interface bridge add name=bridge-vlan804

#Criar VLAN
/interface vlan add comment=WIFI-LIBERADO interface=bridge-Local name=vlan804 vlan-id=804

#Criar senha do WIFI CLIENTES
/interface wireless security-profiles add authentication-types=wpa2-psk eap-methods="" management-protection=allowed mode=dynamic-keys name=profile-clientes supplicant-identity="" wpa2-pre-shared-key=wfpb2k21

#Criar rede WIFI CLIENTES
/interface wireless
add disabled=no keepalive-frames=disabled master-interface=wlan1 multicast-buffering=disabled \
name=wlan2 security-profile=profile-clientes ssid=$ssid wds-cost-range=0 \
wds-default-cost=0 wps-mode=disabled

#Criar o pool da rede WIFI CLIENTES
/ip pool
add name=dhcp_pool_clientes ranges=$pool

#Criar o dhcp da rede WIFI CLIENTES
/ip dhcp-server
add address-pool=dhcp_pool_clientes disabled=no interface=bridge-vlan804 \
lease-time=2h name=dhcp-WIFI-LIBERADO

#Criar o bridge port da interface VLAN e WLAN2
/interface bridge port
add bridge=bridge-vlan804 interface=wlan2
add bridge=bridge-vlan804 interface=vlan804

#Criar endereço da interface bridge-vlan804
/ip address
add address=$ipaddress1 interface=bridge-vlan804 network=$networkwifi

#Criar dhcp-server da rede WIFI CLIENTES 
/ip dhcp-server network
add address=$ipaddress0 comment=WIFI-LIBERADO dns-server=8.8.8.8,8.8.4.4 \
gateway=$gatewaywifi

#Regras de FIREWALL 
#Regra 1 
/ip firewall address-list
add address=$ipaddress0 list=IPs-WIFI-LIBERADO
#Regra 2 
/ip firewall mangle
add action=mark-routing chain=prerouting comment=routing-WIFI-LIBERADO \
dst-address=$networklan new-routing-mark=routing_WIFI-LIBERADO \
passthrough=yes src-address=$ipaddress0
#Regra 2
/ip firewall nat
add action=masquerade chain=srcnat comment=NAT-WIFI-LIBERADO dst-address=\
$networklan src-address=$ipaddress0

#Criação de rota default WIFI-LIBERADO
/ip route
add check-gateway=ping comment=DEFAULT-WIFI-LIBERADO distance=2 gateway=\
$nameinterfaceprovedor routing-mark=routing_WIFI-LIBERADO

#<FIM DO SCRIPT>