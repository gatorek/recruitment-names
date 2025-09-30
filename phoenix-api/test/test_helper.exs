ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PhoenixApi.Repo, :manual)

# Setup Mimic for mocking
Mimic.copy(Req)
