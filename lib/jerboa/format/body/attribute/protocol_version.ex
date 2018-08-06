defmodule Jerboa.Format.Body.Attribute.ProtocolVersion do
  @moduledoc """
  PROTOCOL-VERSION attribute.
  """

  alias Jerboa.Format.Body.Attribute.{Decoder, Encoder}
  alias Jerboa.Format.Meta

  defstruct [:version]

  @typedoc """
  Contains the number of the channel
  """
  @type t :: %__MODULE__{
               version: pos_integer
             }

  defimpl Encoder do
    alias Jerboa.Format.Body.Attribute.ProtocolVersion
    @type_code 0xFF04

    @spec type_code(ProtocolVersion.t) :: integer
    def type_code(_), do: @type_code

    @spec encode(ProtocolVersion.t, Meta.t) :: {Meta.t, binary}
    def encode(attr, meta), do: {meta, ProtocolVersion.encode(attr)}
  end

  defimpl Decoder do
    alias Jerboa.Format.Body.Attribute.ProtocolVersion

    @spec decode(ProtocolVersion.t, value :: binary, meta :: Meta.t)
          :: {:ok, Meta.t, ProtocolVersion.t} | {:error, struct}
    def decode(_, value, meta), do: ProtocolVersion.decode(value, meta)
  end

  @doc false
  @spec encode(t) :: binary
  def encode(%__MODULE__{version: n}) do
    <<n :: size(32)>>
  end

  @doc false
  @spec decode(binary, Meta.t) :: {:ok, Meta.t, t} | {:error, struct}
  def decode(<<version :: size(32)>>, meta) do
    {:ok, meta, %__MODULE__{version: version}}
  end

end
