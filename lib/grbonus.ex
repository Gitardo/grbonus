# git clone && cd grbonus
# mix deps.get && mix deps.compile
# iex -S mix
# Grbonus.start_link

defmodule Grbonus do
  use GenServer

  @apis_url "https://apis.globalreader.eu/health" # endpoint to check
  @resptime_check 500 # check endpoint twice per minute, 500ms
  @resptime_trigger 0.4 # log error if response_time > 400ms

  defp check_status() do
    url = "#{@apis_url}"
    token = "some_token_from_another_request"
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json; Charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 500]

    HTTPoison.get(url, headers, options)
  end

  defp log_response() do
    start = System.monotonic_time(:millisecond)

    {:ok, grbonus_response} = check_status()
    grbonus_code = grbonus_response.status_code
    grbonus_body = grbonus_response.body

    stop = System.monotonic_time(:millisecond)
    grbonus_time = (stop - start) / 1000
    IO.puts("response_code: #{grbonus_code}\tresponse_body: #{grbonus_body}\tresponse_time: #{grbonus_time}s")
    if grbonus_time > @resptime_trigger do
      IO.puts("Error: response_time longer than 400ms")
    end
    
    {grbonus_code, grbonus_body, grbonus_time}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end
  
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    spawn_link(&do_work/0)
    schedule_work()
    {:noreply, state}
  end
  defp do_work() do
    log_response()
  end

  defp schedule_work() do
    Process.send_after(self(), :work, @resptime_check)
  end

end
