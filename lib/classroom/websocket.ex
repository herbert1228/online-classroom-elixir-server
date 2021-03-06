defmodule Classroom.Websocket do
  @behaviour :cowboy_websocket
  # @idle_timeout 60 * 60 * 1000
  @idle_timeout 5 * 1000
  require Logger

  def start(port, mod, args) do
    routes = [
      {:_,
       [
         {"/", __MODULE__, {mod, args}}
       ]}
    ]
    router = :cowboy_router.compile(routes)
    :cowboy.start_clear(:http, [port: port], %{env: %{dispatch: router}})
    # Application.ensure_all_started(:gun)
  end

  def init(req, params) do
    {:cowboy_websocket, req, params, %{idle_timeout: @idle_timeout}}
  end

  def websocket_init({mod, args}) do
    {:ok, state} = mod.init(args)
    {:ok, {mod, state}}
  end

  def websocket_handle({:binary, _}, state) do
    {:reply, {:close, 1003, "Unsupported Data"}, state}
  end

  def websocket_handle({:ping, _}, state) do
    {:ok, state}
  end

  def websocket_handle({:pong, _}, state) do
    {:ok, state}
  end

  def websocket_handle({:text, text}, s = {mod, state}) do
    case Poison.decode(text) do
      {:ok, ["cast", type, params]} ->
        mod.handle_cast(type, params, state) |> cast_result(mod)

      {:ok, ["call", id, type, params]} ->
        mod.handle_call(type, params, state) |> call_result(mod, id)

      {:ok, ["signal_cast", type, params]} ->
        Classroom.Signaling.handle_cast(type, params, state) |> cast_result(mod)

      {:ok, ["signal_call", id, type, params]} ->
        Classroom.Signaling.handle_cast(type, params, state) |> call_result(mod, id)

      {:ok, ["whiteboard_cast", type, params]} ->
        Classroom.Server.Whiteboard.handle_cast(type, params, state) |> cast_result(mod)

      {:ok, ["whiteboard_call", id, type, params]} ->
        Classroom.Server.Whiteboard.handle_call(type, params, state) |> call_result(mod, id)

      {:ok, ["group_whiteboard_cast", type, params]} ->
        Classroom.Server.GroupWhiteboard.handle_cast(type, params, state) |> cast_result(mod)

      {:ok, ["group_whiteboard_call", id, type, params]} ->
        Classroom.Server.GroupWhiteboard.handle_call(type, params, state) |> call_result(mod, id)

      {:ok, ["class_status_cast", type, params]} ->
        Classroom.Server.ClassStatus.handle_cast(type, params, state) |> cast_result(mod)

      {:ok, ["class_status_call", id, type, params]} ->
        Classroom.Server.ClassStatus.handle_call(type, params, state) |> call_result(mod, id)

      {:ok, "keep_alive"} ->
        {:ok, s}

      {:error, _} ->
        {:reply, {:close, 1003, "Unsupported Data"}, s}
    end
  end

  def websocket_info([:signaling, [term, params]], {mod, state}) do
    Classroom.Signaling.handle_info(term, params, state) |> info_result(mod)
  end

  def websocket_info([:signaling, [term | params]], {mod, state}) do
    Classroom.Signaling.handle_info(term, params, state) |> info_result(mod)
  end

  def websocket_info([:whiteboard_server, [term, params]], {mod, state}) do
    Classroom.Server.Whiteboard.handle_info(term, params, state) |> info_result(mod)
  end

  def websocket_info([:group_whiteboard_server, [term, params]], {mod, state}) do
    Classroom.Server.GroupWhiteboard.handle_info(term, params, state) |> info_result(mod)
  end

  def websocket_info([:class_status_server, [term, params]], {mod, state}) do
    Classroom.Server.ClassStatus.handle_info(term, params, state) |> info_result(mod)
  end

  def websocket_info(term, {mod, state}) do
    mod.handle_info(term, state) |> info_result(mod)
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  defp info_result(result, mod), do: cast_result(result, mod) # identical

  defp cast_result(result, mod) do
    case result do
      {:noreply, new_state} ->
        {:ok, {mod, new_state}}

      {:event, type, params, new_state} ->
        {:reply, {:text, Poison.encode!([:event, type, params])}, {mod, new_state}}

      {:stop, new_state} ->
        {:stop, {mod, new_state}}
    end
  end

  defp call_result(result, mod, id) do
    case result do
      {:reply, reply, new_state} ->
        {:reply, {:text, Poison.encode!([:reply, id, reply])}, {mod, new_state}}

      {:stop, reply, new_state} ->
        {:reply, [{:text, Poison.encode!([:reply, id, reply])}, :close], {mod, new_state}}
    end
  end

end
