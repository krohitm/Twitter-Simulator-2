// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channelsList, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

<<<<<<< Updated upstream
//let socket = new Socket("/socket", {params: {token: window.userToken}})
=======
let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

//Project4.main("server")
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("room:lobby", {})
let chatInput = document.querySelector('#chat-input')
let messageContainer = document.querySelector('#messages')

chatInput.addEventListener("keypress", event => {
  if (event.keyCode === 13){
    channel.push("new_msg", {body: chatInput.value, username:"aditya"})
    chatInput.value = ""
  }
})
>>>>>>> Stashed changes

var numClients
var channelsList = []
var socketsList = []
let maxClients = 3
let userFollowers = {}
let userNamesList = []
let userName
for (numClients = 0; numClients < maxClients; numClients++){
  userName = "user_"+numClients
  let socket = new Socket("/socket", {params: {token: window.userToken, userName: userName}})
  userNamesList[numClients] = userName
  userFollowers[userName] = []
  socket.connect()
  socketsList[numClients] = socket
  let channel = socket.channel("room:lobby", {})
  channelsList[numClients] = channel

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
  subscribersList = getRandom(userNamesList, numSubscribers)
  channelsList[numClients].push("subscribe", subscribersList)
  .receive("subscribed", resp => console.log("subscribed", resp))
}

/**function to send tweets */
function sendTweet(minInterval){
  console.log("sending tweets")
  var numUsers = userNamesList.length
  var mention, tweetText, numSubscribers, interval

  for (var i = 0; i < numUsers; i++){
    mention = getRandom(userNamesList, 1)
    tweetText = "tweet@"+mention+getHashtag()
    console.log(tweetText)
    numSubscribers = userFollowers[userNamesList[i]].len
    interval = Math.floor(maxClients/numSubscribers) * minInterval

    channelsList[i].push("tweet_subscribers", {tweetText: tweetText, 
      username: userNamesList[i], time: `${Date()}`})
  }
}

//setInterval(sendTweet(10), 6000)
//sendTweet(10)

var check = 0
function simulation(){
  while (check <= 2){
    for (var i = 0; i < userNamesList.len; i++){
      setInterval(sendTweet(10), 2)
      var runBehavior = getRandom(["search", "search_hashtag", "search_mentions", "retweet"])
      switch (runBehavior){
        case("search"):
        console.log(searching)
        channelsList[i].push("search", {username: userNamesList[i], time: `${Date()}`})
        break
        case("search_hashtag"):
        console.log("searching for hashtag")
        hashtagList = [getHashtag]
        channelsList[i].push("search_hashtag", {username: userNamesList[i], hashtagList, time: `${Date()}`})
        break
        case("search_mentions"):
        console.log("searching for mentions")
        channelsList[i].push("search_mentions", {username: userNamesList[i], time: `${Date()}`})
        break
        case("retweet"):
        console.log("retweeting")
        hashtagList = [getHashtag]
        channelsList[i].push("retweet", {username: userNamesList[i], time: `${Date()}`})
        break
        default:
        break
      }
    }
    check += 1
  }
}

simulation()



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

export default socketsList