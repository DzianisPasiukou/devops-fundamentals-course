CLIENT_BUILD_DIR=dist
CLIENT_BUILD_FILE=dist/client-app.zip

if [ -e $CLIENT_BUILD_FILE ]; then
	rm "$CLIENT_BUILD_FILE"
	echo "$CLIENT_BUILD_FILE was removed"
fi

npm install
npm run build --configuration=$ENV_CONFIGURATION --output-path=$CLIENT_BUILD_DIR

echo "Client was built with $ENV_CONFIGURATION configuration"

zip -r  $CLIENT_BUILD_FILE $CLIENT_BUILD_DIR/


