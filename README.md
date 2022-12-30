# Derailed Gateway

Derailed's Gateway powered by Elixir.

## Main Detailing

The Gateway are the services which power
Derailed's real-time infrastructure.

It's done quite simple.

For Guilds it's like:

API -> gRPC -> Get Guild PID -> Publish if available

And for Users it's like:

API -> gRPC -> Get Session Registry -> Publish to all Sessions, if any

## Why Elixir?

We decided to pick elixir because:

- As it's based on the OTP and the BEAM VM it allowes for levels of
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
