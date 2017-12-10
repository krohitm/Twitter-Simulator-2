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
        GenServer.call(:server, {:register, userName, socket})
        {:reply, :registered, socket}
    end

    #handle to subscribe clients
    def handle_in("subscribe", payload, socket) do
       userName = payload["username"]
       usersToSub = payload["usersToSub"] # A list of usernames
       IO.inspect ["subscribed", usersToSub]
       GenServer.call(:server, {:subscribe, usersToSub, userName})
       {:reply, :subscribed, socket}
    end

    def handle_in("tweet_subscribers", payload, socket) do
      tweetText = payload["tweetText"]
      userName = payload["username"]
      tweet_time =  payload["time"]
      event = "tweet_subscribers"
      # IO.inspect ["====== TWEET ACTR", self(), :ets.lookup(:users, self()), Engine.getPid(userName), userName]

      # userName
      # |> Engine.getPid() # userPid is a pid of socket channel
      # |> Engine.getFollowers()
      # |> Enum.filter(fn(pid) ->
      #     Engine.isLoggedIn(pid) == true
      #   end)
      # |> Enum.each(fn(pid) ->
      #   IO.inspect ["======PID TWEET ACTR", Process.alive?(pid)]
      #   send pid, %{"tweetText" => tweetText}
      # end)

      GenServer.cast(:server, {:tweet_subscribers, tweet_time, tweetText, userName, event})
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
    # def handle_in("register", %{"body" => body}, socket) do
    #
    #   GenServer.call(:server, {:register, userName, socket})
    #   {:noreply, socket}
    end

    def handle_in("new_msg",payload, socket) do
      #pass event as string to GenServer
      #tweet_time = 1
      #tweetText = %{"body" => body}
      #event = "new_msg"
      #userName = "aditya"
      #GenServer.cast(:server, {:tweet_subscribers, tweet_time, tweetText, userName, event})
        # Engine.register(socket, "user_name")
        # IO.inspect ["Inspecting db", socket, Engine.getFollowers(socket)]
        username = payload["username"]
        IO.inspect ["Inspecting body",  username]
        broadcast! socket, "new_msg", payload

        # IO.inspect[Engine.getFollowers(socket)>>>>>>> Stashed changes
        {:noreply, socket}
    end

    def handle_info(msg, socket) do
      broadcast socket, "tweet_sub", msg
      {:noreply, socket}
    end
end
