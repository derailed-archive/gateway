{:ok, hostname} = :inet.gethostname()

pid = Node.spawn_link(
  :"guilds@#{hostname}}",
  fn ->
    guild = Guild.Registry.get_guild("23129417282")
    IO.puts('Got guild')

    Guild.subscribe(guild, "1398712847")
    IO.puts('subbed')
    Guild.unsubscribe(guild, "1398712847")
    IO.puts('unsubbed')
  end
)
IO.puts("#{inspect pid}")
Node.connect(:"guilds@#{hostname}}")
guild_pid = Guild.Registry.get_guild("2134982149")
IO.puts('Got Guild')
Guild.subscribe(guild_pid, "21397124")
IO.puts('Subscribed to Guild')
Guild.unsubscribe(guild_pid, "21397124")
IO.puts('Unsubscribed from Guild')
