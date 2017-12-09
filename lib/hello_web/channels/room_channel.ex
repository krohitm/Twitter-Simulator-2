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

    def handle_in("tweet_subscribers", tweet, socket) do
        #IO.inspect ["subscribed", _message, socket]
        #push "user_socket:#{subscriber}", "new_message", %{id: 1, content: "hello"}
        #IO.inspect "user_socket:#{subscriber}"
        #HelloWeb.Endpoint.broadcast("user_socket:#{subscriber}", "new_message", %{})
        IO.inspect tweet
        {:noreply, socket}
    end

    def handle_in("search", params, socket) do
        {:noreply, socket}
    end

    def handle_in("search_hashtag", params, socket) do
        {:noreply, socket}
    end

    def handle_in("search_mentions", params, socket) do
        {:noreply, socket}
    end

    def handle_in("retweet", params, socket) do
        {:noreply, socket}
    end
end