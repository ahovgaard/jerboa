defmodule Jerboa.Format.Body.Attribute.ResponseAddress do
  @moduledoc """
  RESPONSE-ADDRESS attribute.
  """

  alias Jerboa.Format.Meta

  defstruct [:family, :address, :port]

  @type t :: %__MODULE__{
               family: :ipv4 | :ipv6,
               address: :inet.ip_address,
               port: :inet.port_number
             }

  @ipv4 <<0x01::8>>
  @ipv6 <<0x02::8>>


  defimpl Jerboa.Format.Body.Attribute.Encoder do
    @type_code 0xff06

    def type_code(_), do: @type_code

    def encode(attr, meta) do
      value =
        Jerboa.Format.Body.Attribute.ResponseAddress.encode(attr, meta.params)
      {meta, value}
    end
  end

  defimpl Jerboa.Format.Body.Attribute.Decoder do
    def decode(attr, value, meta) do
      Jerboa.Format.Body.Attribute.ResponseAddress.decode(attr, value, meta)
    end
  end

  @doc """
  Creates new address struct and fills address family
  based on passed IP address format
  """
  @spec new(address :: :inet.ip_address, port :: :inet.port_number) :: t
  def new({_, _, _, _} = addr, port) do
    %__MODULE__{family: :ipv4, address: addr, port: port}
  end
  def new({_, _, _, _, _, _, _, _} = addr, port) do
    %__MODULE__{family: :ipv6, address: addr, port: port}
  end

  @spec encode(t, Params.t) :: binary
  def encode(%{family: :ipv4, address: a, port: p}, _params) do
    encode(@ipv4, binerize(a), p)
  end
  def encode(%{family: :ipv6, address: a, port: p}, _params) do
    encode(@ipv6, binerize(a), p)
  end
  def encode(_), do: raise ArgumentError

  @spec decode(t, value :: binary, Meta.t)
        :: {:ok, Meta.t, t} | {:error, struct}
  def decode(attr, <<_::8, ip_version, port::16, addr::32-bits>>, meta) do
    {:ok, meta, attribute(attr, <<ip_version::8>>, addr, port)}
  end
  def decode(_, _, _) do
    {:error, :invalid_packet}
  end

  defp encode(family, addr, port) do
    <<0::8, family::8-bits, port::16, addr::binary>>
  end

  defp binerize({a, b, c, d}) do
    <<a, b, c, d>>
  end
  defp binerize({a, b, c, d, e, f, g, h}) do
    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>
  end

  defp attribute(attr, @ipv4, addr, port) do
    struct attr, %{
      family: :ipv4,
      address: ip_decode(addr),
      port: port
    }
  end
  defp attribute(attr, @ipv6, addr, port) do
    struct attr, %{
      family: :ipv6,
      address: ip_decode(addr),
      port: port
    }
  end

  defp ip_decode(<<a, b, c, d>>) do
    {a, b, c, d}
  end

  defp ip_decode(<<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>) do
    {a, b, c, d, e, f, g, h}
  end

end
