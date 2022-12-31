defmodule Derailed.Crossway.User.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run Derailed.Crossway.User
end
