#!/bin/bash

# Paths and variables
PROJECT_DIR="/root/personal-site"
VENV_DIR="/root/personal-site/.venv"
GUNICORN_SERVICE="gunicorn"

LOCKFILE="/tmp/deploy.lock"

# Check if the lock file exists
if [ -e $LOCKFILE ]; then
    echo "Deployment already in progress. Exiting."
    exit 1
fi

# Create the lock file
touch $LOCKFILE

# Ensure the lock file is removed when the script exits
trap "rm -f $LOCKFILE" EXIT

# Navigate to the project directory
cd $PROJECT_DIR || { echo "Failed to navigate to project directory."; exit 1; }

# Check for local changes
if ! git diff --quiet; then
    echo "Local changes detected. Stashing changes..."
    git stash save "Auto-stash before deployment"
fi

# Fetch the latest changes from the remote repository
git fetch origin

# Compare local and remote branches
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Changes detected on remote. Deploying updates..."
    
    # Reset local repository to match remote
    git reset --hard origin/main

    # Activate virtual environment
    source $VENV_DIR/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }

    # Install dependencies
    pip install -r requirements.txt

    # Apply database migrations
    python manage.py migrate

    # Collect static files
    python manage.py collectstatic --noinput

    # Reload Gunicorn
    sudo systemctl reload $GUNICORN_SERVICE || { echo "Failed to reload Gunicorn."; exit 1; }

    echo "Deployment complete."
else
    echo "No new changes detected. Skipping deployment."
fi

# Attempt to apply stashed changes back
if git stash list | grep -q "Auto-stash before deployment"; then
    echo "Re-applying stashed changes..."
    git stash pop || echo "Warning: Stashed changes could not be applied cleanly."
fi

