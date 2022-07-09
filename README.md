# Automatic FNA to WASM 

This project contains a simple "Blue Screen of Life" game built in FNA.

It also contains a Docker image that will automatically take the source code for the game, build it for WASM, and host it in a local server.

This takes the guess-work out of @TheSpyDog's excellent [FNA-to-WASM tutorial](https://gist.github.com/TheSpydog/e94c8c23c01615a5a3b2cc1a0857415c) so you can focus on your game and built it for the web when you're ready.

## Build steps

- From the project root, run `docker compose up` or right-click `docker-compose.yml` in VS Code 
  w/ the Docker extension installed, and click "Compose Up"

- Wait for the Docker container to finish building and boot up

- Navigate to `http://localhost:3030/index.html` to run your game!

![BSOL](/docs/bsol.png)
