defmodule HelloWeb.RoomChannel do
    use Phoenix.Channel

    def join("room:lobby", _message, socket) do
        #IO.inspect ["joined", socket]
        #IO.inspect ["checking pid of room", self]
        {:ok, socket}
    end
    def join("room:"<> _private_room_id, _params, _socket) do
        {:error, %{reason: "unauthorized"}}
    end

    #handle to register clients
    def handle_in("register", userName, socket) do
        #IO.inspect ["subscribed", _message, socket]
        #push "user_socket:#{subscriber}", "new_message", %{id: 1, content: "hello"}
        #IO.inspect "user_socket:#{subscriber}"
        #HelloWeb.Endpoint.broadcast("user_socket:#{subscriber}", "new_message", %{})
        {:reply, :registered, socket} 
     end
    
    #handle to subscribe clients
    def handle_in("subscribe", subscribers, socket) do
       #IO.inspect ["subscribed", _message, socket]
       #push "user_socket:#{subscriber}", "new_message", %{id: 1, content: "hello"}
       #IO.inspect "user_socket:#{subscriber}"
       #HelloWeb.Endpoint.broadcast("user_socket:#{subscriber}", "new_message", %{})
       {:reply, :subscribed, socket} 
    end

    def handle_in("new_message", _payload, socket) do
        #IO.inspect ["subscribed", _message, socket]
        IO.puts "i subscribed"
        {:reply, :subscribed, socket} 
    end

    #def handle_in("new_msg", %{"body" => body}, socket) do
    #    broadcast! socket, "new_msg", %{body: body}
    #    {:noreply, socket}
    #end
end