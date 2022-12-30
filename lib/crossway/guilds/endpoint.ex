defmodule Derailed.Crossway.Guild.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run Derailed.Crossway.Guild
end
