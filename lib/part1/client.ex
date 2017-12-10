require Logger
defmodule Client do
  use GenServer
  @interval 1
  

  def retweet do
    # receive a tweet
    # send a tweet like the sendTweet function
  end

  def subscribeUsers(usernamesToSub) do
    GenServer.call({:server, :"server@127.0.0.1"}, {:subscribe, usernamesToSub}, :infinity)
  end

  def register(userName) do
    GenServer.call({:server, :"server@127.0.0.1"}, {:register, userName}, :infinity)
  end

#---------------------------------------------------------------------
#GenServer callbacks for the client from the simulator

  def handle_call({:register, userName}, _, state) do
    #IO.inspect self()
    Client.register(userName)
    {:reply, {:registered}, state}
  end

  #tell a client PID to subscribe to a list of users' PIDs
  def handle_cast({:subscribe, usernamesToSub}, state) do
    #IO.puts "subscribing"
    Client.subscribeUsers(usernamesToSub)
    {:noreply, state}
  end

  #def handle_cast({:tweet_subscribers, tweetText, userName}, state) do
  #  IO.puts "client tweeting"
  #  GenServer.cast({:server, :"server@127.0.0.1"}, {:tweet_subscribers, tweetText, userName})
  #  {:noreply, state}
  #end

  def handle_info({:tweet_subscribers, tweetText, userName, client, interval}, state) do
    #IO.puts "server receiving tweets"
    GenServer.cast({:server, :"server@127.0.0.1"}, {:tweet_subscribers, tweetText, userName})
    state = state + 1
    cond do 
      state <= 1000 ->
        Process.send_after(client, {:tweet_subscribers, tweetText, userName, client, interval}, interval)
      true ->
        true
    end
    {:noreply, state}
  end

  #GenServer callback to search for tweets of all users "userName" has subscribed to
  def handle_cast({:search, userName}, state) do
    IO.puts "client will ask server for tweets"
    requestTime = :os.system_time(:milli_seconds)
    GenServer.cast({:server, :"server@127.0.0.1"}, {:search, userName, requestTime})
    {:noreply, state}
  end

  #def handle_info({:search, userName, client}, state) do
  #  IO.puts "client will ask server regularly for tweets"
  #  GenServer.cast({:server, :"server@127.0.0.1"}, {:search, userName})
  #  Process.send_after(client, {:search, userName, client}, @interval)
  #  {:noreply, state}
  #end

#GenServer callback to query for tweets with given hashtags
  def handle_cast({:search_hashtag, userName, hashtag_list}, state) do
    #IO.puts "client will ask for hashtags"
    GenServer.cast({:server, :"server@127.0.0.1"}, {:search_hashtag, userName, hashtag_list})
    {:noreply, state}
  end

  #GenServer callback to search for tweets where user is mentioned
  def handle_cast({:search_mentions, userName}, state) do
    IO.puts "receiving tweets where client has been mentioned"
    GenServer.cast({:server, :"server@127.0.0.1"}, {:search_mentions, userName})
    {:noreply, state}
  end

  #handle by self to login again
  def handle_info({:login, tweetText, userName, client, interval}, state) do
    IO.puts "user #{userName} logging in again"
    GenServer.cast({:server, :"server@127.0.0.1"}, {:login, userName})
    requestTime = :os.system_time(:milli_seconds)
    GenServer.cast({:server, :"server@127.0.0.1"}, {:search, userName, requestTime})
    send client, {:complete_simulation, tweetText, userName, client, interval}
    {:noreply, state}
  end

  @doc """
  handle to run complete simulation. This includes sending tweets,
  randomly searching for mentions, tweets of users subscribed to, or
  mentions
  """
  def handle_info({:complete_simulation, tweetText, userName, client, interval}, state) do
    state = state + 1
    cond do 
      rem(state, 1000) == 0 ->
        runBehaviour = Enum.random([:search, :search_hashtag, :search_mentions, :retweet])
        case runBehaviour do
          :search ->
            IO.puts "user #{userName} querying for tweets"
            requestTime = :os.system_time(:milli_seconds)
            GenServer.cast({:server, :"server@127.0.0.1"}, {:search, userName, requestTime})
          :search_hashtag ->
            IO.puts "user #{userName} querying for hashtags"
            hashtag_list = [Simulator.getHashtag]
            GenServer.cast({:server, :"server@127.0.0.1"}, {:search_hashtag, userName, hashtag_list})
          :search_mentions ->
            "user #{userName} querying for mentions"
            GenServer.cast({:server, :"server@127.0.0.1"}, {:search_mentions, userName})
          :retweet ->
            IO.puts "user #{userName} retweeting"
            hashtag_list = [Simulator.getHashtag]
            GenServer.cast({:server, :"server@127.0.0.1"}, {:retweet, userName, hashtag_list})         
          _ ->
            true
        end
        Process.send_after(client, {:complete_simulation, tweetText, userName, client, interval}, interval)
      rem(state, 2100) == 0 ->
        #logging out for a while
        IO.puts "user #{userName} logging out"
        GenServer.cast({:server, :"server@127.0.0.1"}, {:logout, userName})
        Process.send_after(client, {:login, tweetText, userName, client, interval}, 5000)
      true ->
        GenServer.cast({:server, :"server@127.0.0.1"}, {:tweet_subscribers, :os.system_time(:milli_seconds), tweetText, userName})
        Process.send_after(client, {:complete_simulation, tweetText, userName, client, interval}, interval)
    end
    {:noreply, state}
  end

#---------------------------------------------------
#GenServer Callbacks from server below this

  #GenServer.callback to receive tweets, with tweet time, when users you have subscribed to tweets something
  def handle_cast({:receiveTweet, tweet_time, tweetText}, state) do
    #IO.puts "receiving tweets"
    #IO.puts tweetText
    #Logger.info ["tweet broadcast time", :os.system_time(:milli_seconds) - tweet_time]
    {:noreply, state}
  end

    #GenServer.callback to receive tweets when users you have subscribed to tweets something
    def handle_cast({:receiveTweet, tweetText}, state) do
      #IO.puts "receiving tweets"
      #IO.puts tweetText
      {:noreply, state}
    end

  #GenServer.callback to receive tweets queried for
  def handle_cast({:search_result, tweet_list}, state) do
    IO.puts "receiving tweets from users subscribed to"
    #IO.inspect tweet_list
    {:noreply, state}
  end

  #GenServer.callback to receive tweets with hashtags queried for
  def handle_cast({:search_result_ht, tweetText}, state) do
    IO.puts "receiving tweets with given hashtags"
    IO.puts tweetText
    {:noreply, state}
  end

  #GenServer.callback to receive tweets with hashtags queried for
  def handle_cast({:search_result_mention, tweetText}, state) do
    IO.puts "receiving tweets where client is mentioned"
    IO.puts tweetText
    {:noreply, state}
  end

  def handle_cast({:retweet, userName, tweet_list}, state) do
    cond do
      length(tweet_list) > 0 ->
        tweetText = Enum.random(tweet_list) |> Enum.at(1)
        GenServer.cast({:server, :"server@127.0.0.1"}, {:tweet_subscribers, :os.system_time(:milli_seconds), tweetText, userName})
      true ->
        true
    end
    {:noreply, state}
  end

  def init(state) do
    {:ok, state}
  end
end
