defmodule Jerboa.Format.Body.Attribute.StunId do
  @moduledoc """
  STUN-ID attribute.
  """

  alias Jerboa.Format.Body.Attribute.{Decoder, Encoder}
  alias Jerboa.Format.Meta

  defstruct [:stun_id]

  @typedoc """
  Contains the number of the channel
  """
  @type t :: %__MODULE__{
               stun_id: pos_integer
             }

  defimpl Encoder do
    alias Jerboa.Format.Body.Attribute.StunId
    @type_code 0xFF03

    @spec type_code(StunId.t) :: integer
    def type_code(_), do: @type_code

    @spec encode(StunId.t, Meta.t) :: {Meta.t, binary}
    def encode(attr, meta), do: {meta, StunId.encode(attr)}
  end

  defimpl Decoder do
    alias Jerboa.Format.Body.Attribute.StunId

    @spec decode(StunId.t, value :: binary, meta :: Meta.t)
          :: {:ok, Meta.t, StunId.t} | {:error, struct}
    def decode(_, value, meta), do: StunId.decode(value, meta)
  end

  @doc false
  @spec encode(t) :: binary
  def encode(%__MODULE__{stun_id: n}) do
    <<n :: size(32)>>
  end

  @doc false
  @spec decode(binary, Meta.t) :: {:ok, Meta.t, t} | {:error, struct}
  def decode(<<stun_id :: size(32)>>, meta) do
    {:ok, meta, %__MODULE__{stun_id: stun_id}}
  end

end
