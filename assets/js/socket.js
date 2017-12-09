// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

//let socket = new Socket("/socket", {params: {token: window.userToken}})

var numClients
var channels = []
var sockets = []
let maxClients = 10
let userFollowers = {}
let userNames = []
let userName
for (numClients = 0; numClients < maxClients; numClients++){
  userName = "user_"+numClients
  let socket = new Socket("/socket", {params: {token: window.userToken, userName: userName}})
  userNames[numClients] = userName
  userFollowers[userName] = []
  socket.connect()
  sockets[numClients] = socket
  let channel = socket.channel("room:lobby", {})
  channels[numClients] = channel

  //join the new client
  channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

  //register the new client
  channel.push("register", userName)
  .receive("registered", resp => console.log("registered", resp))
}

//give subscribers to each client
var numSubscribers, subscribersList;
for (numClients = 0; numClients < maxClients; numClients++){
  numSubscribers = Math.floor((maxClients-2)/(numClients+1)) //following zipf distribution
  if (numSubscribers == 0){
    numSubscribers = 1
  }
  subscribersList = getRandom(userNames, numSubscribers)
  channels[numClients].push("subscribe", subscribersList)
  .receive("subscribed", resp => console.log("subscribed", resp))
}

/**function to send tweets */
function sendTweet(minInterval){
  console.log("sending tweets")
  var numUsers = userNames.length
  var mention, tweetText, numSubscribers

  for (var i = 0; i < numUsers; i++){
    mention = getRandom(userNames, 1)
    tweetText = "tweet@"+mention+getHashtag()
    numSubscribers = userFollowers[userNames[i]].len
    interval = Math.floor(maxClients/numSubscribers) * minInterval

    channels[numClients].push("tweet_subscribers", tweetText, )
  }
  
  //var interval = minumUsers/
}
/** @doc """
  If action is :tweet_subscribers, the clients send tweets
  If action is :complete_simulation, the clients send tweets,
  search for tweets, search for hashtags, and search for mentions, randomly
  """
  def sendTweet(actorsPid, minInterval, action) do
    IO.puts "sending tweets"
    numUsers = length(actorsPid)
    Enum.each(actorsPid, fn(client) ->
      mention = selectRandomMention(actorsPid, client)
                |> Simulator.getUsername
      tweetText = "tweet@"<>mention<>getHashtag()
      
      [{_, _, subscribers}] = :ets.lookup(:usersSimulator, client)
      numSubscribers = length(subscribers)
      interval = (numUsers/numSubscribers |> round) * minInterval

      userName = Simulator.getUsername(client)
      send client, {action, tweetText, userName, client, interval}
      #GenServer.cast(client, {:tweet_subscribers, tweetText, userName})
    end)
  end */


//////////////////////////////////////////////////////////////////////////////////////////////////////
/**All helper functions below this */


/** function to get random subscribers*/
function getRandom(arr, n) {
  var result = new Array(n),
  len = arr.length,
  taken = new Array(len);
  if (n > len)
    throw new RangeError("getRandom: more elements taken than available");
  while (n--) {
    var x = Math.floor(Math.random() * len);
    result[n] = arr[x in taken ? taken[x] : x];
    taken[x] = --len;
  }
  return result;
}

/**function to get random hashtag */
function getHashtag(){
  var hashList = ["#marketing", "#marketingtips", "#b2cmarketing",
  "#b2bmarketing", "#strategy", "#mktg", "#digitalmarketing",
  "#marketingstrategy", "#mobilemarketing", "#socialmediamarketing",
  "#promotion", "#food", "#yummy", "#nom", "#hungry", "#cleaneating",
  "#vegetarian", "#wine", "#sushi", "#birthday", "#red", "#workout",
  "#sweet",  "#wedding", "#blackandwhite"]
  return hashList[Math.floor(Math.random() * hashList.length)]
}

export default sockets