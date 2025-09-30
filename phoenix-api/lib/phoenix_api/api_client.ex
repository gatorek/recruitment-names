defmodule PhoenixApi.ApiClient do
  @moduledoc """
  Client for fetching and parsing CSV data from external APIs.

  Provides functionality to fetch CSV data from a URL and extract
  a specified number of names from the first column (excluding header).
  """

  @doc """
  Fetches CSV data from the given URL and returns the specified number of names.

  ## Parameters
  - `url` - The URL to fetch CSV data from
  - `count` - The number of names to return from the first column

  ## Returns
  - `{:ok, names}` - List of names extracted from the CSV
  - `{:error, reason}` - Error tuple with reason for failure

  ## Examples

      iex> PhoenixApi.ApiClient.call("https://example.com/names.csv", 3)
      {:ok, ["JAN", "PIOTR", "STANISŁAW"]}

      iex> PhoenixApi.ApiClient.call("invalid-url", 5)
      {:error, :invalid_url}
  """
  @type url :: binary()
  @type count :: pos_integer()
  @type name :: binary()
  @type error_details :: atom() | {atom(), any()}

  @separator ","

  @spec call(url, count) :: {:ok, [name]} | {:error, error_details}
  def call(url, count) when is_binary(url) and is_integer(count) and count > 0 do
    # Validate URL format
    case URI.parse(url) do
      %URI{scheme: nil} -> {:error, :invalid_url}
      %URI{host: nil} -> {:error, :invalid_url}
      _ -> fetch_and_process(url, count)
    end
  end

  def call(_url, _count), do: {:error, :invalid_parameters}

  # Private functions

  defp fetch_and_process(url, count) do
    with {:ok, response} <- fetch_data(url),
         {:ok, csv_data} <- parse_csv(response),
         {:ok, names} <- extract_names(csv_data, count) do
      {:ok, names}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_data(url) do
    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, {:connection_error, reason}}

      {:error, %Req.HTTPError{reason: reason}} ->
        {:error, {:http_protocol_error, reason}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  defp parse_csv(csv_string) when is_binary(csv_string) do
    lines = String.split(csv_string, "\n", trim: true)

    if length(lines) > 0 do
      {:ok, lines}
    else
      {:error, :empty_csv}
    end
  end

  defp parse_csv(_), do: {:error, :invalid_csv_format}

  defp extract_names(lines, count) do
    # Skip header row and extract names from first column
    data_lines = Enum.drop(lines, 1)

    names =
      data_lines
      |> Enum.take(count)
      |> Enum.map(fn line ->
        case String.split(line, @separator) do
          [name | _] -> String.trim(name)
          [] -> ""
        end
      end)
      |> Enum.reject(&(&1 == ""))

    if length(names) == count do
      {:ok, names}
    else
      {:error, :insufficient_data}
    end
  end
end
