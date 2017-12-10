defmodule HelloWeb.RoomChannel do
    use Phoenix.Channel

    def join("room:lobby", _message, socket) do
        {:ok, socket}
    end
    def join("room:"<> _private_room_id, _params, _socket) do
        {:error, %{reason: "unauthorized"}}
    end

    #handle to register clients
    def handle_in("register", userName, socket) do
        GenServer.call(:server, {:register, userName, socket})
        push socket, "registered",  %{"userName" => userName}
        {:reply, :registered, socket}
    end

    #handle to subscribe clients
    def handle_in("subscribe", payload, socket) do
       userName = payload["username"]
       usersToSub = payload["usersToSub"] # A list of usernames
       GenServer.call(:server, {:subscribe, usersToSub, userName})
       push socket, "subscribed",  %{"userName" => userName}
       {:reply, :subscribed, socket}
    end

    def handle_in("tweet_subscribers", payload, socket) do
      tweetText = payload["tweetText"]
      userName = payload["username"]
      tweet_time =  payload["time"]
      event = "tweet_subscribers"

      GenServer.cast(:server, {:tweet_subscribers, tweet_time, tweetText, userName, event})
      {:noreply, socket}
    end

    def handle_in("search", params, socket) do
        userName = params["username"]
        requestTime = params["time"]
        GenServer.cast(:server, {:search, userName, requestTime})
        {:noreply, socket}
    end

    def handle_in("search_hashtag", params, socket) do
      #{username: userNamesList[i], hashtagList: hashtagList, time: `${Date()}`}
      IO.inspect ["--------------------------------"]
      userName = params["username"]
      hashtagList = params["hashtagList"]
      time = params["time"]
      GenServer.cast(:server, {:search_hashtag, userName, hashtagList})
      {:noreply, socket}
    end

    def handle_in("search_mentions", params, socket) do
      userName = params["username"]
      time = params["time"]
      GenServer.cast(:server, {:search_mentions, userName})
      {:noreply, socket}
    end

    def handle_in("retweet", params, socket) do
      userName = params["username"]
      # hashtagList = params["hashtagList"]
      tweetText = params["tweetText"]
      tweet_time = ""
      event = "retweet"
      GenServer.cast(:server, {:tweet_subscribers, tweet_time, tweetText, userName, event})
      {:noreply, socket}
    end

    def handle_info({:search_result, tweetText}, socket) do
      push socket, "search_result", %{"searched_tweet" => tweetText}
      {:noreply, socket}
    end

    def handle_info({:search_result_ht, tweetText}, socket) do
      IO.inspect ["search hasth --------------", tweetText]
      push socket, "search_hashtag", %{"searched_tweet" => tweetText}
      {:noreply, socket}
    end

    def handle_info({:search_result_mn, tweetText}, socket) do
      IO.inspect ["search hast MN --------------", tweetText]
      push socket, "search_mentions", %{"searched_tweet" => tweetText}
      {:noreply, socket}
    end

    def handle_info({:retweet, userName, tweetText}, socket) do
      push socket, "search_retweet", %{"searched_tweet" => tweetText}
      {:noreply, socket}
    end

    # This is for sending normal tweets
    def handle_info(tweetText, socket) do
      push socket, "tweet_sub", tweetText
      {:noreply, socket}
    end
end
