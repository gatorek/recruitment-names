defmodule PhoenixApi.ApiClientTest do
  use ExUnit.Case, async: true
  import Mimic

  @real_data_url "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_m%C4%99skich_os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"

  describe "call/2" do
    test "successfully fetches and parses CSV data with valid URL and count" do
      csv_data = """
      IMIĘ_PIERWSZE,PŁEĆ,LICZBA_WYSTĄPIEŃ
      JAN,MĘŻCZYZNA,638369
      PIOTR,MĘŻCZYZNA,603682
      STANISŁAW,MĘŻCZYZNA,447671
      ANDRZEJ,MĘŻCZYZNA,406153
      PAWEŁ,MĘŻCZYZNA,399071
      """

      # Mock the HTTP request using Mimic
      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:ok, names} = PhoenixApi.ApiClient.call("https://example.com/names.csv", 3)
      assert names == ["JAN", "PIOTR", "STANISŁAW"]
    end

    test "handles CSV with extra whitespace in names" do
      csv_data = """
      IMIĘ_PIERWSZE,PŁEĆ,LICZBA_WYSTĄPIEŃ
      JAN ,MĘŻCZYZNA,638369
      PIOTR,MĘŻCZYZNA,603682
      STANISŁAW ,MĘŻCZYZNA,447671
      """

      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:ok, names} = PhoenixApi.ApiClient.call("https://example.com/names.csv", 3)
      assert names == ["JAN", "PIOTR", "STANISŁAW"]
    end

    test "returns error when HTTP request fails" do
      stub(Req, :get, fn "https://invalid-url.com/data.csv" ->
        {:error, %Req.TransportError{reason: :nxdomain}}
      end)

      assert {:error, {:connection_error, :nxdomain}} =
               PhoenixApi.ApiClient.call("https://invalid-url.com/data.csv", 3)
    end

    test "returns error when HTTP response is not 200" do
      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 404, body: "Not Found"}}
      end)

      assert {:error, {:http_error, 404}} =
               PhoenixApi.ApiClient.call("https://example.com/names.csv", 3)
    end

    test "returns error when CSV is empty" do
      stub(Req, :get, fn "https://example.com/empty.csv" ->
        {:ok, %Req.Response{status: 200, body: ""}}
      end)

      assert {:error, :empty_csv} =
               PhoenixApi.ApiClient.call("https://example.com/empty.csv", 3)
    end

    test "returns error when CSV has only header" do
      csv_data = "IMIĘ_PIERWSZE,PŁEĆ,LICZBA_WYSTĄPIEŃ"

      stub(Req, :get, fn "https://example.com/header-only.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:error, :insufficient_data} =
               PhoenixApi.ApiClient.call("https://example.com/header-only.csv", 3)
    end

    test "returns error when requesting more names than available" do
      csv_data = """
      IMIĘ_PIERWSZE,PŁEĆ,LICZBA_WYSTĄPIEŃ
      JAN,MĘŻCZYZNA,638369
      PIOTR,MĘŻCZYZNA,603682
      """

      stub(Req, :get, fn "https://example.com/short.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:error, :insufficient_data} =
               PhoenixApi.ApiClient.call("https://example.com/short.csv", 5)
    end

    test "returns error for invalid parameters" do
      assert {:error, :invalid_url} = PhoenixApi.ApiClient.call("", 3)
      assert {:error, :invalid_parameters} = PhoenixApi.ApiClient.call("https://example.com", 0)
      assert {:error, :invalid_parameters} = PhoenixApi.ApiClient.call("https://example.com", -1)
      assert {:error, :invalid_parameters} = PhoenixApi.ApiClient.call(nil, 3)
      assert {:error, :invalid_parameters} = PhoenixApi.ApiClient.call("https://example.com", nil)
      assert {:error, :invalid_url} = PhoenixApi.ApiClient.call("not-a-url", 3)
    end

    test "handles CSV with empty lines" do
      csv_data = """
      IMIĘ_DRUGIE,PŁEĆ,LICZBA_WYSTĄPIEŃ
      JAN,MĘŻCZYZNA,638369

      PIOTR,MĘŻCZYZNA,603682

      STANISŁAW,MĘŻCZYZNA,447671
      """

      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:ok, names} = PhoenixApi.ApiClient.call("https://example.com/names.csv", 3)
      assert names == ["JAN", "PIOTR", "STANISŁAW"]
    end

    test "handles CSV with trailing newlines" do
      csv_data = """
      IMIĘ_DRUGIE,PŁEĆ,LICZBA_WYSTĄPIEŃ
      JAN,MĘŻCZYZNA,638369
      PIOTR,MĘŻCZYZNA,603682
      STANISŁAW,MĘŻCZYZNA,447671

      """

      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:ok, names} = PhoenixApi.ApiClient.call("https://example.com/names.csv", 3)
      assert names == ["JAN", "PIOTR", "STANISŁAW"]
    end

    test "handles CSV with Windows line endings" do
      csv_data =
        "IMIĘ_DRUGIE,PŁEĆ,LICZBA_WYSTĄPIEŃ\r\nJAN,MĘŻCZYZNA,638369\r\nPIOTR,MĘŻCZYZNA,603682\r\n"

      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:ok, names} = PhoenixApi.ApiClient.call("https://example.com/names.csv", 2)
      assert names == ["JAN", "PIOTR"]
    end

    test "handles CSV with mixed line endings" do
      csv_data =
        "IMIĘ_DRUGIE,PŁEĆ,LICZBA_WYSTĄPIEŃ\nJAN,MĘŻCZYZNA,638369\r\nPIOTR,MĘŻCZYZNA,603682\n"

      stub(Req, :get, fn "https://example.com/names.csv" ->
        {:ok, %Req.Response{status: 200, body: csv_data}}
      end)

      assert {:ok, names} = PhoenixApi.ApiClient.call("https://example.com/names.csv", 2)
      assert names == ["JAN", "PIOTR"]
    end

    @tag :skip
    test "works with a real CSV endpoint" do
      assert {:ok, names} = PhoenixApi.ApiClient.call(@real_data_url, 3)
      assert names == ["PIOTR", "KRZYSZTOF", "TOMASZ"]
    end
  end
end
