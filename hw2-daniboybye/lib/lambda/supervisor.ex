defmodule Lambda.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    [
      {Task.Supervisor, name: Lambda.TaskSupervisor, strategy: :one_for_one},
      {Lambda.Registry, name: Lambda.Registry}
    ]
    |> Supervisor.init(strategy: :one_for_all)
  end
end
