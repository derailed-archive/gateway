defmodule Derailed.GRPC.Auth.Proto.ValidateToken do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :user_id, :string
  field :password, :string
  field :token, :string
end

defmodule Derailed.GRPC.Auth.Proto.Valid do
  use Protobuf, protoc_gen_elixir_version: "1.14.0", syntax: :proto3

  field :valid, :bool
end

defmodule Derailed.Crossway.User.Proto.Service do
  use GRPC.Service, name: "derailed.grpc.auth.Authorization", protoc_gen_elixir_version: "0.14.0"

  rpc :validate, Derailed.GRPC.Auth.Proto.ValidateToken, Derailed.GRPC.Auth.Proto.Valid
end
