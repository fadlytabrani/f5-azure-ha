# F5 BIG-IP Azure High Availability & Failover Designs

## How is this design different?
 1. Much **simpler**, comparable to traditional on-premise setups.
 2. There is **no reliance on cloud APIs**.
 3. Failover is **quicker**, as fast as native cloud load balancer. 
 4. **No NAT needed** inbound from native cloud Public load balancer.
 5. One IP in the fabric for each interface, **no secondary IP** needed.
 6. **No single virtual server** listening on a range, multiple virtual servers can be created.
 7. Supports **manual configuration** from the Azure marketplace, example Terraform templates provided. 
 8. Deployed in **Active/Standby or Active/Active scalable up to 127 devices** based on [traffic groups](https://support.f5.com/csp/article/K41291441).
 9. Same design principles apply in a **standalone, 1-nic, 2-nic, 3-nic, n-nic** deployment.
 
The following manual deployment guides are published, and more is being planned. Get started with a progressive build:
 - [x] [Standalone Device 1 NIC](https://github.com/fadlytabrani/f5-azure-ha-fo/wiki/Standalone-Device-1-NIC)
- [x] [Active Standby HA FO 1 NIC](https://github.com/fadlytabrani/f5-azure-ha-fo/wiki/Active-Standby-HA-FO-1-NIC)
- [ ] Active Active HA FO 1 NIC
- [ ] Active Standby/Active HA FO MIRROR 2 NIC
- [ ] Active Standby/Active HA FO MIRROR N NIC 
- [ ] Routed/Floating  Virtual Servers & SNAT pools
- [ ] F5 BIG-IP DNS Integration

### Design 1: Native LB-attached Virtual Servers
![Native LB-attached Virtual Servers](https://github.com/fadlytabrani/f5-azure-ha-fo/raw/master/architecture-diagrams/f5-azure-ha-fo-lb-vs.png)

### Design 2: Routed Virtual Servers & SNATs
![Routed Virtual Servers & SNATs](https://github.com/fadlytabrani/f5-azure-ha-fo/raw/master/architecture-diagrams/f5-azure-ha-fo-routed-vs.png)
