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

    // Handle click event on the post button.
    // push function on vidChannel sends contents of message to server.
    // then clear the input control.
    postButton.addEventListener("click", e => {
      let payload = {body: msgInput.value, at: Player.getCurrentTime()}
      // when we push a message to the server, we can opt to receive a response
      vidChannel.push("new_annotation", payload)
                .receive("error", e => console.log(e) )
      msgInput.value = ""
    })

    // when users post new annotations, the server will broadcast the event to
    // the clients. This handles the event.
    vidChannel.on("new_annotation", (resp) => {
      this.renderAnnotation(msgContainer, resp)
    })

    // create a new channel object from our socket and give it a topic
    vidChannel.join()
      .receive("ok", resp => console.log("joined the video channel", resp) )
      .receive("error", reason => console.log("join failed", reason) )
  },

  // escape user input before injecting values into the page.
  esc(str){
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  renderAnnotation(msgContainer, {user, body, at}){
    // build a DOM node with the user's name and annotation body
    let template = document.createElement("div")
    template.innerHTML = `
    <a href="#" data-seek="${this.esc(at)}">
      <b>${this.esc(user.username)}</b>: ${this.esc(body)}
    </a>
     `
    // append it to the msgContainer list and scroll to the right point.
    msgContainer.appendChild(template)
    msgContainer.scrollTop = msgContainer.scrollHeight
  }
}
export default Video
