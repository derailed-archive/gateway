defmodule Derailed.Crossway.Proto.Message do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :event, 1, type: :string
  field :data, 2, type: :string
end

defmodule Derailed.Crossway.Guild.Proto.Publ do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :guild_id, 1, type: :string
  field :message, 2, type: Derailed.Crossway.Proto.Message
end

defmodule Derailed.Crossway.Guild.Proto.Publr do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :message, 1, type: :string
end

defmodule Derailed.Crossway.Guild.Proto.GetGuildInfo do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :guild_id, 1, type: :string
end

defmodule Derailed.Crossway.Guild.Proto.RepliedGuildInfo do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :presences, 1, type: :int32
  field :available, 2, type: :bool
end

defmodule Derailed.Crossway.Guild.Proto.Service do
  use GRPC.Service, name: "derailed.grpc.Guild", protoc_gen_elixir_version: "0.14.0"

  rpc :publish, Derailed.Crossway.Guild.Proto.Publ, Derailed.Crossway.Guild.Proto.Publr
  rpc :get_guild_info, Derailed.Crossway.Guild.Proto.GetGuildInfo, Derailed.Crossway.Guild.Proto.RepliedGuildInfo
end

defmodule Derailed.Crossway.Guild.Proto.Stub do
  use GRPC.Stub, service: Derailed.Crossway.Guild.Proto.Service
end
