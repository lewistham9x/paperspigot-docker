#!/bin/bash
set -e

setup_github() {
	# Start authentication agent
  eval $(ssh-agent -s) 
  
  # Create SSH Key with no prompts or overwrite
  echo n | ssh-keygen -t rsa -b 4096 -C "${GITHUB_TOKEN}" -f ${DATA_PATH}/id_rsa -N "" > /dev/null
  ssh-add ${DATA_PATH}/id_rsa

  # Send SSH Keys to GitHub for authentication - jeezus you gotta escape the "" if not it will cryyyy
  curl -u ${GITHUB_TOKEN}:"" https://api.github.com/user/keys -d "{\"title\": \"$KEY_NAME\", \"key\":\"$(cat ${DATA_PATH}/id_rsa.pub)\"}"

  cd ${MINECRAFT_PATH}

  # Clone repository
	GITHUB_TOKEN=${GITHUB_TOKEN} $HUB clone ${GITHUB_REPO_NAME}

  # If Repository exists, else
  if [ $? -eq 0 ]; then
    echo "Cloned Existing Repository"

	else
	  echo "Creating New Repository"
		# Create a Git Repository
		GITHUB_TOKEN=${GITHUB_TOKEN} $HUB init
		GITHUB_TOKEN=${GITHUB_TOKEN} $HUB create ${GITHUB_REPO_NAME} | tail -n 1 > ${CONFIG_PATH}/git_repo.txt

		# Setup .gitignore to ignore sensitive files/folders
		echo ".DS_Store" >> .gitignore
		echo "" >> .gitignore
		echo "Ignoring sensitive files and folders" >> .gitignore
		echo "/data" >> .gitignore
		echo "/logs" >> .gitignore
		echo "/worlds" >> .gitignore
		echo "*.db*" >> .gitignore
		echo "*.sql*" >> .gitignore

		# Setup README.md
		echo "# ${GITHUB_REPO_NAME}" >> README.md
		echo "* * *" >> README.md
		echo "## About" >> README.md
		echo "" >> README.md
		echo "This repository coexists together with the ${GITHUB_REPO_NAME} Paper Spigot server. " >> README.md
		echo "" >> README.md
		echo "All changes made to configurations stored on this repository will be reflected onto the server upon its next restart." >> README.md
		echo "## tl;dr" >> README.md
		echo "lekt8 is da best" >> README.md

		# Initial Commit
		git add .
		git commit -am "Initial Commit"
		GITHUB_TOKEN=${GITHUB_TOKEN} $HUB push origin master
	fi

	# Revert back to original working directory
	cd ${SERVER_PATH}
}

update_github() {
	GITHUB_TOKEN=${GITHUB_TOKEN} $HUB sync
}

run_paper() {
  # Start server
  bash start.sh
}

case "$1" in
    serve)
        shift 1
        #setup_github
        #update_github
        run_paper
        ;;
    reload)
        shift 1
        update_github
        ;;
    *)
        exec "$@"
esac

