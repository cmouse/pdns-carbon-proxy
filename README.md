Carbon proxy for PowerDNS
=========================

This is used for PowerDNS carbon to HTTP server. Configuration is done
by changing the URL in file. Put this into /usr/local/sbin and use the
init scripts provided.

The software listens on 2003/tcp, takes in all key value pairs and
forwards them to specified URL.

Dependencies
------------

 * POE
 * POE::Component::Server::TCP
 * POE::Component::Client::HTTP
 * POE::Component::SSLify
 * Data::Dumper

Configuring PowerDNS
--------------------

carbon-ourname=whatever
carbon-server=127.0.0.1

Data format
-----------
Data is sent as key=value pairs. It includes stamp=timestamp-of-data. It is sent
to URL+carbon-ourname as POST request. If URL is http://foo/endpoint, target URL will be
http://foo/endpointwhatever. Add slash to URL if you need it. You can add GET variable(s)
and if you want, you can use http://foo/endpoint?server= to make server name appear as
GET variable.

