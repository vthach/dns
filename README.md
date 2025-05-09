## Explanation:

Setup three containers to learn/test DNS setting.

1. `version: '3.8'`: Specifies the Docker Compose file format version. (deprecated)

2. `services:`: Defines the different containers (services) that will be run.

* `dns-master:`:
  * `image: ubuntu:latest`: Uses the latest Ubuntu image.
  * `container_name: dns-master`: Sets the container name.
  * `hostname: dns-master`: Sets the hostname within the container.
  * `networks:`: Connects this container to the `dns-net` network and assigns it a static IP address `172.28.1.10`.
  * `volumes:`: Mounts local files into the container:
        * `./named.conf.master:/etc/bind/named.conf`: Your BIND master configuration file.
        * `./db.example.com:/var/lib/bind/db.example.com`: Your forward zone file for `example.com.`
        * `./db.1.168.192.in-addr.arpa:/var/lib/bind/db.1.168.192.in-addr.arpa`: Your reverse zone file for the `172.28.1.0/24` subnet.
* `ports:`: Exposes the standard DNS ports (53 TCP and UDP) on the host machine.
* `command:`: Executes commands inside the container:
    * `apt-get update && apt-get install -y bind9 dnsutils`: Updates the package list and installs the BIND DNS server and DNS utilities.
    * `named -g -c /etc/bind/named.conf`: Starts the BIND DNS server in the foreground (-g) using the specified configuration file (`-c`).
* `dns-slave:`:

    * Similar to `dns-master`, but with the following differences:
        * `container_name: dns-slave` and hostname: `dns-slave`.
        * Static IP address `172.28.1.11`.
        * `volumes:`: Mounts your BIND slave configuration file (`./named.conf.slave`). You typically don't need zone files on the slave as it will transfer them from the master.
        * `ports:`: Exposes DNS ports on the host as 5353:53/tcp and 5353:53/udp. This is done to avoid port conflicts with the master on the host machine. Inside the container, BIND will still be listening on port 53.
        * `command:`: Installs BIND and starts named with the slave configuration.
        * `depends_on: - dns-master`: Ensures that the dns-master container is started before the dns-slave container.

* `dns-client:`:

    * `image: ubuntu:latest`.
    * `container_name: dns-client` and `hostname: dns-client`.
    * Static IP address `172.28.1.12`.
    * `depends_on: - dns-master - dns-slave`: Ensures that both DNS servers are running before the client.
    * `command: sleep infinity`: Keeps the container running indefinitely in the background so you can interact with it.
3. networks:: Defines the network for the containers.

* `dns-net:`:
    * `ipam:`: Configures IP address management.
    * `driver: default`: Uses the default Docker network driver.
    * `config:`: Defines the subnet for this network (`172.28.1.0/24`). Docker will automatically assign IP addresses from this subnet unless you specify them explicitly (as done in the `services` section).

## Before Running:

1. Create Configuration Files: You need to create the following files in the same directory as your `docker-compose.yml` file:
   * `named.conf.master`: Your BIND configuration file for the master server. It should define your zones (forward and reverse) and specify that this server is the master.
   * `db.example.com`: Your forward zone file for example.com. This file will contain the DNS records for your domain.
    * `db.1.168.192.in-addr.arpa`: Your reverse zone file for the `172.28.1.0/24` subnet. This file maps IP addresses back to hostnames.
    * `named.conf.slave`: Your BIND configuration file for the slave server. It should define the zones you want to replicate and specify the master server's IP address for zone transfers.
  
### Example `named.conf.master`:
```
options {
    directory "/var/lib/bind";
    allow-query { any; };
    forwarders { };
};

zone "example.com" IN {
    type master;
    file "/var/lib/bind/db.example.com";
    allow-transfer { 172.28.1.11; }; // Allow zone transfers to the slave
};

zone "1.168.192.in-addr.arpa" IN {
    type master;
    file "/var/lib/bind/db.1.168.192.in-addr.arpa";
    allow-transfer { 172.28.1.11; }; // Allow zone transfers to the slave
};
```

### Example `named.conf.slave`:
```
options {
    directory "/var/lib/bind";
    allow-query { any; };
    forwarders { };
};

zone "example.com" IN {
    type slave;
    masters { 172.28.1.10; }; // IP address of the master server
    file "/var/lib/bind/db.example.com";
};

zone "1.168.192.in-addr.arpa" IN {
    type slave;
    masters { 172.28.1.10; }; // IP address of the master server
    file "/var/lib/bind/db.1.168.192.in-addr.arpa";
};
```
### Example Zone file `db.example.com`:
```
$TTL    86400
@       IN      SOA     dns-master.example.com. admin.example.com. (
                                        2023050601     ; Serial
                                           1D          ; Refresh
                                           1H          ; Retry
                                           1W          ; Expire
                                           3H          ; Minimum TTL
                        )
;
@       IN      NS      dns-master.example.com.
@       IN      NS      dns-slave.example.com.
dns-master      IN      A       172.28.1.10
dns-slave       IN      A       172.28.1.11
client          IN      A       172.28.1.12
www             IN      A       172.28.1.10
pop             IN      CNAME   client
smtp            IN      CNAME   client
```
### Example `db.1.168.192.in-addr.arpa`:
```
$TTL    86400
@       IN      SOA     dns-master.example.com. admin.example.com. (
                                        2023050601     ; Serial
                                           1D          ; Refresh
                                           1H          ; Retry
                                           1W          ; Expire
                                           3H          ; Minimum TTL
                        )
;
@       IN      NS      dns-master.example.com.
@       IN      NS      dns-slave.example.com.
10      IN      PTR     dns-master.example.com.
11      IN      PTR     dns-slave.example.com.
12      IN      PTR     dns-client.example.com
```

2. Run Docker Compose: Navigate to the directory containing your `docker-compose.yml` file and the configuration files, and run:

```Bash
docker-compose up -d
```

## Testing:

1. Access the Client Container:

```Bash
docker exec -it dns-client bash
```

2. Use `nslookup` or `dig`: Inside the `dns-client` container, you can test the DNS resolution:

```Bash
nslookup www.example.com 172.28.1.10  # Query the master server
nslookup www.example.com 172.28.1.11  # Query the slave server

dig @172.28.1.10 www.example.com
dig @172.28.1.11 www.example.com
```

3.Verify Reverse Lookup:

```Bash
nslookup 172.28.1.12 172.28.1.10
nslookup 172.28.1.12 172.28.1.11

dig @172.28.1.10 -x 172.28.1.12
dig @172.28.1.11 -x 172.28.1.12
```
Remember to adjust the configuration files (`named.conf.*`, `db.*`) according to your specific DNS requirements. This `docker-compose.yml` provides a basic setup for a DNS master, slave, and client on the same Docker network.


# docker-compose CLI

To stop/start all containers:
 ```sh
 docker-compose down
 docker-compose up -d
 ```

 Startup a selected container to debug:`docker-compose up dns-master`
 
 To attach to the shell: `docker exec -it dns-master bash`

 To look at the run log:
 ```sh
 docker logs dns-master
 docker logs dns-slave

 ```
