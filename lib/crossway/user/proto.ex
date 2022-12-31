defmodule Derailed.Crossway.User.Proto.UPubl do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :user_id, 1, type: :string
  field :message, 2, type: Derailed.Crossway.Proto.Message
end

defmodule Derailed.Crossway.User.Proto.UPublr do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :message, 1, type: :string
end

defmodule Derailed.Crossway.User.Proto.Service do
  use GRPC.Service, name: "derailed.grpc.User", protoc_gen_elixir_version: "0.14.0"

  rpc :publish, Derailed.Crossway.User.Proto.UPubl, Derailed.Crossway.User.Proto.UPublr
end

defmodule Derailed.Crossway.User.Proto.Stub do
  use GRPC.Stub, service: Derailed.Crossway.User.Proto.Service
end
