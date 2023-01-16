import Config
alias ExHashRing.Ring

Dotenv.load()

guild_nodes = System.get_env("GUILD_NODES")
session_nodes = System.get_env("SESSION_NODES")
ready_nodes = System.getenv("READY_NODES")

{:ok, guild_node_ring} = Ring.start_link()
Ring.add_nodes(guild_node_ring, String.split(guild_nodes, "/"))

{:ok, session_node_ring} = Ring.start_link()
Ring.add_nodes(session_node_ring, String.split(session_nodes, "/"))

{:ok, ready_node_ring} = Ring.start_link()
Ring.add_nodes(ready_node_ring, String.split(ready_nodes, "/"))

FastGlobal.put(:guild, guild_node_ring)
FastGlobal.put(:session, session_node_ring)
FastGlobal.put(:ready, ready_node_ring)
