# Issue with Ubuntu

By default Ubuntu use port 53.  To free up port 53 so, we can use use bind:

```sh
# ls -la /etc/resolv.conf
lrwxrwxrwx 1 root root 39 Aug 10  2023 /etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
```
Remove the sym link and update to`/etc/resolv.conf` to:
```sh
nameserver 1.1.1.1

```

## ubuntu bind install issue:

This is an issue with dpkg, going to interactive mode and prompting a chose to overwrite configuration file.
To force dpkg to use the default option I usee this `-o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confnew'`

docker run error due to dpkg going into interactive mode:
```
dns-master  | 0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
dns-master  | 1 not fully installed or removed.
dns-master  | After this operation, 0 B of additional disk space will be used.
dns-master  | Setting up bind9 (1:9.18.30-0ubuntu0.24.04.2) ...
dns-master  |
dns-master  | Configuration file '/etc/bind/named.conf'
dns-master  |  ==> File on system created by you or by a script.
dns-master  |  ==> File also in package provided by package maintainer.
dns-master  |    What would you like to do about it ?  Your options are:
dns-master  |     Y or I  : install the package maintainer's version
dns-master  |     N or O  : keep your currently-installed version
dns-master  |       D     : show the differences between the versions
dns-master  |       Z     : start a shell to examine the situation
dns-master  |  The default action is to keep your current version.
dns-master  | *** named.conf (Y/I/N/O/D/Z) [default=N] ? dpkg: error processing package bind9 (--configure):
dns-master  |  end of file on stdin at conffile prompt
dns-master  | Errors were encountered while processing:
dns-master  |  bind9
dns-master  | E: Sub-process /usr/bin/dpkg returned an error code (1)
dns-master exited with code 100

```
