homedir="/home/shadowwalker"
echo "Enter the server you wish to secure(eg myserver.com):"
read servername
cd $homedir/cacerts
mkdir $servername && cd $servername
echo "Creating Valid SAN Parameters. You will have to train your PC to like the Cert Authority"
echo "
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 =${servername}
DNS.2 = *.${servername}
" > v3_ext.conf
echo "
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = MA
L = Cambridge
O = Cloudspace
OU = IT
CN = ${servername}
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${servername}
DNS.2 = *.${servername}
" > req.conf
echo "Generating private server key"
openssl req -new -nodes -out $homedir/cacerts/${servername}/server.csr -newkey rsa:2048 -keyout $homedir/cacerts/${servername}/server.key -config $homedir/cacerts/${servername}/req.conf -extensions 'v3_req'
openssl x509 -req -in $homedir/cacerts/${servername}/server.csr -CA $homedir/cacerts/root/rootCA.crt -CAkey $homedir/cacerts/root/rootCA.key -CAcreateserial -out $homedir/cacerts/${servername}/server.crt -days 500 -sha256 -extfile $homedir/cacerts/${servername}/v3_ext.conf
openssl pkcs12 -inkey server.key -in server.crt -export -out server.pem

echo "Configuring server to enforce https"
echo "Enter document root"
read documentroot
cd /etc/apache2/sites-available/

echo '
<VirtualHost *:443>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	ServerName '${servername}'
	SSLEngine on
        SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP

        SSLCertificateFile      "'${homedir}'/cacerts/'${servername}'/server.crt"
        SSLCertificateKeyFile  "'${homedir}'/cacerts/'${servername}'/server.key"
        SSLCACertificateFile    "'${homedir}'/cacerts/root/rootCA.crt"


	ServerAdmin info@'${servername}'
	DocumentRoot "'${documentroot}'/"

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn
	<Directory '${documentroot}'/>
                AllowOverride none
                Require all granted
        </Directory>

	ErrorLog '${homedir}'/cacerts/'${servername}'/error.log
	CustomLog '${homedir}'/cacerts/'${servername}'/access.log combined

</VirtualHost>
#cd to /etc/apache2/site-enabled/

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
' > ${servername}.conf
a2ensite ${servername}.conf
chmod -R a+rx ${documentroot}
certfile="${homedir}/cacerts/${servername}/server.pem"
certname=$servername"-Cert"



###
### For cert8 (legacy - DBM)
###

for certDB in $(find ~/ -name "cert8.db")
do
    certdir=$(dirname ${certDB});
    certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d dbm:${certdir}
done


###
### For cert9 (SQL)
###

for certDB in $(find ~/ -name "cert9.db")
do
    certdir=$(dirname ${certDB});
    certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d sql:${certdir}
done

service apache2 restart

