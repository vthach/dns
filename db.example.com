$TTL    86400
@       IN      SOA     dns-master.example.com. admin.example.com. (
                                       2023050601      ; Serial
                                       12h             ; Refresh
                                       15m             ; Retry
                                       52w             ; Expire
                                       3600            ; Minimum TTL
                        )
;
@       IN      NS      dns-master.example.com.
@       IN      NS      dns-slave.example.com.
dns-master      IN      A       172.28.1.10
dns-slave       IN      A       172.28.1.11
client          IN      A       172.28.1.12
www             IN      A       172.28.1.10
