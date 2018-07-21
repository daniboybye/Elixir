defmodule Lambda.Application do
  use Application

  def start(_type, _args) do
    Lambda.Supervisor.start_link(name: Lambda)
  end
end
