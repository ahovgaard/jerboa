defmodule Jerboa.Format.Body.Attribute.NatBindingInterval do
  @moduledoc """
  NAT-BINDING-INTERVAL attribute.
  """

  alias Jerboa.Format.Body.Attribute.{Decoder, Encoder}
  alias Jerboa.Format.Meta

  defstruct [:interval]

  @typedoc """
  Contains the number of the channel
  """
  @type t :: %__MODULE__{
               interval: pos_integer
             }

  defimpl Encoder do
    alias Jerboa.Format.Body.Attribute.NatBindingInterval
    @type_code 0xFF05

    @spec type_code(NatBindingInterval.t) :: integer
    def type_code(_), do: @type_code

    @spec encode(NatBindingInterval.t, Meta.t) :: {Meta.t, binary}
    def encode(attr, meta), do: {meta, NatBindingInterval.encode(attr)}
  end

  defimpl Decoder do
    alias Jerboa.Format.Body.Attribute.NatBindingInterval

    @spec decode(NatBindingInterval.t, value :: binary, meta :: Meta.t)
          :: {:ok, Meta.t, NatBindingInterval.t} | {:error, struct}
    def decode(_, value, meta), do: NatBindingInterval.decode(value, meta)
  end

  @doc false
  @spec encode(t) :: binary
  def encode(%__MODULE__{interval: interval}) do
    <<interval :: size(32)>>
  end

  @doc false
  @spec decode(binary, Meta.t) :: {:ok, Meta.t, t} | {:error, struct}
  def decode(<<interval :: size(32)>>, meta) do
    {:ok, meta, %__MODULE__{interval: interval}}
  end

end
