#!/bin/bash
set -e

setup_github(){
	# Start authentication agent
  eval $(ssh-agent -s) 
  # Create SSH Key with no prompts or overwrite
  echo n | ssh-keygen -t rsa -b 4096 -C "${GITHUB_TOKEN}" -f ${DATA_PATH}/id_rsa -N "" > /dev/null
  ssh-add ${DATA_PATH}/id_rsa

  # Send SSH Keys to GitHub for authentication - jeezus you gotta escape the "" if not it will cryyyy
  curl -u ${GITHUB_TOKEN}:"" https://api.github.com/user/keys -d "{\"title\": \"$KEY_NAME\", \"key\":\"$(cat ${DATA_PATH}/id_rsa.pub)\"}"

  cd ${MINECRAFT_PATH}

  # Clone repository
	GITHUB_TOKEN=${GITHUB_TOKEN} hub clone ${GITHUB_REPO_NAME}

  # If Repository exists, else
  if [ $? -eq 0 ]; then
    echo "Cloned Existing Repository"

	else
	  echo "Creating New Repository"
	  curl -u ${GITHUB_TOKEN}:"" https://api.github.com/user/repos -d "{\"name\":\"${GITHUB_REPO_NAME}\"}"  
	fi


  # Create a GitHub Repository

  git init

}

run_paper() {
  # Start server
  bash start.sh
}

case "$1" in
    serve)
        shift 1
        run_paper
        ;;
    *)
        exec "$@"
esac

