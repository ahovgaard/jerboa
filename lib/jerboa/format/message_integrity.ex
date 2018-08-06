defmodule Jerboa.Format.MessageIntegrity do
  @moduledoc false

  alias Jerboa.Format.Meta
  alias Jerboa.Params
  alias Jerboa.Format.Body.Attribute.Username
  alias Jerboa.Format.Body.Attribute.Realm
  alias Jerboa.Format.MessageIntegrity.FormatError

  @type_code 0x0008
  @hash_length 32
  @attr_length @hash_length + 4

  def type_code, do: @type_code

  @spec extract(Meta.t, binary) :: {:ok, Meta.t} | {:error, struct}
  def extract(meta, <<@type_code::16, @hash_length::16,
    hash::@hash_length-binary, _::binary>>) do
    new_meta =
      %{meta | message_integrity: hash,
               params: %{meta.params | signed?: true}}
    {:ok, new_meta}
  end
  def extract(_, _) do
    {:error, FormatError.exception()}
  end

  @spec apply(Meta.t) :: Meta.t
  def apply(meta) do
    if has_required_options?(meta) do
      apply_message_integrity(meta)
    else
      meta
    end
  end

  @spec verify(Meta.t) :: {:ok, Meta.t}
  def verify(meta) do
    verified? =
      with true <- signed?(meta),
           true <- has_required_options?(meta),
            :ok <- verify_message_integrity(meta) do
        true
      else
        _ -> false
      end
    {:ok, %{meta | params: %{meta.params | verified?: verified?}}}
  end

  @spec signed?(Meta.t) :: boolean
  defp signed?(meta), do: meta.params.signed?

  @spec has_required_options?(Meta.t) :: boolean
  defp has_required_options?(meta) do
    with {:ok, _} <- get_secret(meta) do
      true
    else
      _ -> false
    end
  end

  @spec get_username(Meta.t) :: {:ok, String.t} | :error
  defp get_username(meta) do
    from_attr = Params.get_attr(meta.params, Username)
    from_opts = meta.options[:username]
    cond do
      from_attr -> {:ok, from_attr.value}
      from_opts -> {:ok, from_opts}
      true      -> :error
    end
  end

  @spec get_secret(Meta.t) :: {:ok, String.t} | :error
  defp get_secret(meta) do
    case meta.options[:secret] do
      nil -> :error
      secret -> {:ok, secret}
    end
  end

  @spec get_realm(Meta.t) :: {:ok, String.t} | :error
  defp get_realm(meta) do
    from_attr = Params.get_attr(meta.params, Realm)
    from_opts = meta.options[:realm]
    cond do
      from_attr -> {:ok, from_attr.value}
      from_opts -> {:ok, from_opts}
      true      -> :error
    end
  end

  @spec apply_message_integrity(Meta.t) :: Meta.t
  defp apply_message_integrity(meta) do
    key = calculate_hash_key(meta)
    data = get_hash_subject(meta)
    hash = calculate_hash(key, data)
    %{meta | body: meta.body <> attribute(hash),
             header: modify_header_length(meta.header)}
  end

  @spec verify_message_integrity(Meta.t) :: :ok | :error
  defp verify_message_integrity(meta) do
    key = calculate_hash_key(meta)
    data = meta |> amend_header_and_body() |> get_hash_subject()
    hash = calculate_hash(key, data)
    if hash == meta.message_integrity do
      :ok
    else
      :error
    end
  end

  @spec calculate_hash_key(Meta.t) :: binary
  defp calculate_hash_key(meta) do
    {:ok, secret} = get_secret(meta)
    with {:ok, username} <- get_username(meta),
         {:ok, realm} <- get_realm(meta) do
      :crypto.hash :md5, [username, ":", realm, ":", secret]
    else
      _ -> secret
    end
  end

  @spec calculate_hash(binary, iodata) :: binary
  def calculate_hash(key, data) do
    :crypto.hmac(:sha256, key, data)
  end

  @spec get_hash_subject(Meta.t) :: iolist
  defp get_hash_subject(%Meta{header: header, body: body}) do
    [modify_header_length(header), body]
  end

  @spec modify_header_length(header :: <<_::32, _::_ * 8>>) :: <<_::32, _::_ * 8>>
  defp modify_header_length(<<0::2, type::14, length::16, rest::binary>>) do
    <<0::2, type::14, (length + @attr_length)::16, rest::binary>>
  end

  @spec attribute(hash :: binary) :: attribute :: <<_::32, _::_ * 8>>
  defp attribute(hash) do
    <<@type_code::16, @hash_length::16, hash::binary>>
  end

  @spec amend_header_and_body(Meta.t) :: Meta.t
  defp amend_header_and_body(meta) do
    length = meta.length_up_to_integrity

    <<0::2, type::14, _::16, header_rest::binary>> = meta.header
    amended_header = <<0::2, type::14, length::16, header_rest::binary>>

    <<amended_body::size(length)-bytes, _::binary>> = meta.body

    %{meta | body: amended_body, header: amended_header}
  end
end
