defmodule Labex.Instrument do
  defmacro __using__(opts) do
    module = Keyword.get(opts, :impl)

    quote do
      use GenServer

      def impl() do
        unquote(module)
      end

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts)
      end

      @impl GenServer
      def init(opts) do
        {:ok, impl().init(opts)}
      end

      @impl GenServer
      def handle_call({:query, message}, _from, state) do
        {:reply, impl().query(message, state)}
      end

      @impl GenServer
      def handle_call({:write, message}, _from, state) do
        {:reply, impl().write(message, state)}
      end

      def query(message) do
        GenServer.call(__MODULE__, {:query, message})
      end

      def write(message) do
        GenServer.call(__MODULE__, {:write, message})
      end
    end
  end
end
