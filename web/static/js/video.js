import Player from "./player"

let Video = {
  init(socket, element){ if(!element){ return }
    // setup the player and pluck the video ID from the element attributes
    let playerId = element.getAttribute("data-player-id")
    let videoId = element.getAttribute("data-id")
    // start the socket connection
    socket.connect()
    Player.init(element.id, playerId, () => {
      // initialize player with callback when player has loaded
      this.onReady(videoId, socket)
    })
  },

  onReady(videoId, socket){
    // container for annotations
    let msgContainer = document.getElementById("msg-container")
    // the input control
    let msgInput = document.getElementById("msg-input")
    // button for creating a new annotation
    let postButton = document.getElementById("msg-submit")
    // this will be used to connect ES6 client to Phoenix VideoChannel
    // convention for topic identifiers
    let vidChannel = socket.channel("videos:" + videoId)
    // TODO join the vidChannel
  }
}
export default Video
