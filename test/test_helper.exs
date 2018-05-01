ExUnit.start()
ExUnit.configure(exclude: [:load_test])

defmodule TestHelper do
  def restart_application_if_not_started do
    unless List.keymember?(
             Application.started_applications(),
             :nine_digits,
             0
           ) do
      :ok = Application.start(:nine_digits)
    end
  end

  def clean_state do
    Application.stop(:nine_digits)
    Application.start(:nine_digits)
  end
end
