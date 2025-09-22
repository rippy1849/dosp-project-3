import argv
import gleam/int
import gleam/io
import gleam/otp/actor

pub type State {
  State(internal: #(Int), stack: List(Int))
}

pub type Message {
  Shutdown
  SetInternal(#(Int))
  // Push(String)
  // PopGossip(process.Subject(Result(Int, Nil)))
}

fn handle_message(state: State, msg: Message) -> actor.Next(State, Message) {
  case msg {
    Shutdown -> actor.stop()

    SetInternal(#(v1)) -> {
      actor.continue(State(#(v1), state.stack))
    }
  }
}

pub fn main() {
  case argv.load().arguments {
    args -> handle_args(args)
  }
}

fn handle_args(args) {
  let number_of_nodes = case nth(args, 0) {
    Ok(arg) -> arg
    Error(_) -> "0"
  }

  let num_requests = case nth(args, 1) {
    Ok(arg) -> arg
    Error(_) -> "0"
  }

  let number_of_nodes = case int.parse(number_of_nodes) {
    Ok(number_of_nodes) -> number_of_nodes
    Error(_) -> 0
  }

  let num_requests = case int.parse(num_requests) {
    Ok(number_of_nodes) -> number_of_nodes
    Error(_) -> 0
  }

  io.println("Hello from rippy!")

  let assert Ok(default_actor) =
    actor.new(State(#(0), []))
    |> actor.on_message(handle_message)
    |> actor.start
}

fn nth(xs: List(String), i: Int) -> Result(String, Nil) {
  case xs {
    [] -> Error(Nil)
    // list too short
    [x, ..rest] ->
      case i {
        0 -> Ok(x)
        // found the element
        _ -> nth(rest, i - 1)
        // keep searching
      }
  }
}
