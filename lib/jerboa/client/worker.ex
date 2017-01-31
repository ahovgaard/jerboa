defmodule Jerboa.Client.Worker do
  @moduledoc false

  use GenServer

  alias :gen_udp, as: UDP

  defstruct [:server, :socket]

  def start_link(x) do
    GenServer.start_link(__MODULE__, x)
  end

  def init(address: a, port: p) do
    false = Process.flag(:trap_exit, true)
    {:ok, socket} = UDP.open(port(), [:binary, active: false])
    {:ok,
     %__MODULE__{server: {a, p}, socket: socket}}
  end

  def handle_call(:bind, _, state) do
    msg = Jerboa.Format.encode(Jerboa.Params.put_class(binding_(), :request))
    response = call(socket(state), server(state), msg)
    {:ok, params} = Jerboa.Format.decode(response)
    {:reply, reflexive_candidate(params), state}
  end
  def handle_call(:persist, _, state) do
    msg = Jerboa.Format.encode(Jerboa.Params.put_class(binding_(), :indication))
    {:reply, cast(socket(state), server(state), msg), state}
  end

  def terminate(_, state) do
    :ok = UDP.close(socket(state))
  end

  defp port do
    Enum.random(49_152..65_535)
  end

  defp server(%__MODULE__{server: s}) do
    s
  end

  defp socket(%__MODULE__{socket: s}) do
    s
  end

  defp binding_ do
    %Jerboa.Params{
      method: :binding,
      identifier: :crypto.strong_rand_bytes(div(96, 8)),
      body: <<>>
    }
  end

  defp reflexive_candidate(%Jerboa.Params{attributes: [%{value: a}]}) do
    alias Jerboa.Format.Body.Attribute.XORMappedAddress
    %XORMappedAddress{address: x, port: y} = a
    {x, y}
  end

  defp call(socket, {address, port}, request) do
    :ok = UDP.send(socket, address, port, request)
    {:ok, {^address, ^port, response}} = UDP.recv(socket, 0, timeout())
    response
  end

  defp cast(socket, {address, port}, indication) do
    :ok = UDP.send(socket, address, port, indication)
    {:error, :timeout} = UDP.recv(socket, 0, timeout())
    :ok
  end

  def timeout do
    Keyword.fetch!(Application.fetch_env!(:jerboa, :client), :timeout)
  end
end
