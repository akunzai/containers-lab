echo "Creating the server certificate..."

keytool -genkeypair -alias cas -keyalg RSA -keypass changeit -storepass changeit -keystore ./etc/cas/config/server.keystore -dname "CN=cas,OU=cas,OU=cas,C=cas"  -ext SAN="dns:localhost,ip:127.0.0.1"

echo "Exporting the server certificate to /etc/cas/config/..."