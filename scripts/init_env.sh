ENV=$1
doppler secrets download --no-file --format env --project reddit-dataplateform --config $ENV | sed -E 's/="(.*)"/=\1/' > .env.$ENV
echo "HOST_IP=$(ipconfig getifaddr en0)" >> .env.$ENV