# Derailed Gateway

Derailed's Gateway powered by Elixir.

## How Does it work?

The Gateway feeds off and is powered by a consistent hashing algorithm. In this way, the Gateway can
locate and use the nodes for a Guild, or a User's Session.

## Why Elixir?

We decided to pick Elixir because:

- As it's based on the OTP and the BEAM VM it allows for levels of
scalability easier and promptly better than on platforms like Rust, JavaScript, or Python.
- It's fast and easy to learn
- Great Tools and Community
- And because it's honestly the only tool for the job.

## Running the Gateway

Currently there is no way to deploy the gateway on docker,
although, you can deploy it using `mix run` and in the future separately to support
a microservice-like architecture and design.

## Documentation

We don't currently have any documentation because of Derailed still being in a pre-alpha stage.
Just give us some time.. we need a complete API first!
