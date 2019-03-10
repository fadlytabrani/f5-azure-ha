# F5 BIG-IP Azure High Availibility & Failover Designs

## How is this design different?
 1. Much **simpler**, comparable to traditional on-premise setups.
 2. There is **no reliance on cloud APIs**.
 3. Fail-over is **quicker**, as fast as native cloud load balancer. 
 4. **No NAT needed** inbound from native cloud Public load balancer.
 5. One IP in the fabric for each interface, **no secondary IP** needed.
 6. **No single virtual server** listening on a range, multiple virtual servers can be created.
 7. Supports **manual configuration** from the Azure marketplace, example Terraform templates provided. 
 8. Deployed in **Active/Standby or Active/Active scalable up to 127 devices** based on traffic groups.
 9. Same design principles apply in a **standalone, 1-nic, 2-nic, 3-nic, n-nic** deployment.

### Design 1: Native LB-attached Virtual Servers
![enter image description here](https://github.com/fadlytabrani/f5-azure-ha-fo/raw/master/architecture-diagrams/f5-azure-ha-fo-lb-vs.png)

### Design 2: Routed Virtual Servers & SNATs
![enter image description here](https://github.com/fadlytabrani/f5-azure-ha-fo/raw/master/architecture-diagrams/f5-azure-ha-fo-routed-vs.png)
