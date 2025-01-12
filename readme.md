# Easy delopy for Caddy + Gunicorn
## Add the domain name to env variables
```
export DOMAIN_NAME=example.com
```
You can add this to your shell configuration (e.g., .bashrc or .zshrc) for persistence.
This is probably ~/.bashrc

## Add deploy to cron
Run every minute - the script prevents pull if no changes
```
crontab -e
* * * * * /root/gunicorn-caddy-deploy/deploy.sh >> /root/gunicorn-caddy-deploy/logs/deploy.log 2>&1
```

## Start Caddy
caddy run --config /path/to/Caddyfile

## Set logrotate

