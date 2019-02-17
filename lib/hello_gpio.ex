defmodule HelloGpio do
  use Application

  require Logger

  alias Circuits.GPIO

  @output_pin Application.get_env(:hello_gpio, :output_pin, 17)
  @input_pin Application.get_env(:hello_gpio, :input_pin, 26)

  def start(_type, _args) do
    Logger.info("Starting pin #{@output_pin} as output")
    {:ok, output_gpio} = GPIO.open(@output_pin, :output)

    Logger.info("Starting pin #{@input_pin} as input")
    {:ok, input_gpio} = GPIO.open(@input_pin, :input)
    spawn(fn -> listen_forever(input_gpio, output_gpio) end)
    {:ok, self()}
  end

  defp listen_forever(input_gpio, output_gpio) do
    # Start listening for interrupts on rising and falling edges
    GPIO.set_interrupts(input_gpio, :both)
    listen_loop(output_gpio)
  end

  defp listen_loop(output_gpio) do
    # Since we are using a pull up resistor we will receive a falling event when button is pushed
    # and a rising event when the button in released 

    receive do
      {:circuits_gpio, p, _timestamp, 1} ->
        Logger.debug("Received rising event on pin #{p}")
        GPIO.write(output_gpio, 0)

      {:circuits_gpio, p, _timestamp, 0} ->
        Logger.debug("Received falling event on pin #{p}")
        GPIO.write(output_gpio, 1)
    end

    listen_loop(output_gpio)
  end
end
