ExUnit.start()
ExUnit.configure(exclude: [:load_test])

defmodule TestHelper do
  import ExUnit.CaptureLog

  @doc """
  Restarts the application if it's not started, usefull for
  `on_exit` callbacks.
  """
  def restart_application_if_not_started do
    unless List.keymember?(
             Application.started_applications(),
             :nine_digits,
             0
           ) do
      :ok = Application.start(:nine_digits)
    end
  end

  @doc """
  Restarts the application to clear the state
  """
  def clean_state do
    capture_log(fn ->
      Application.stop(:nine_digits)
      Application.start(:nine_digits)
    end)
  end
end
