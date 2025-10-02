ExUnit.start(exclude: [external: true, flaky: true])
Ecto.Adapters.SQL.Sandbox.mode(PhoenixApi.Repo, :manual)

# Setup Mimic for mocking
Mimic.copy(Req)
Mimic.copy(PhoenixApi.ApiClient)
