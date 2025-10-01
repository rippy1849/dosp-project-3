import argv
import gleam/bit_array
import gleam/crypto
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/string

//Need internal state per node, id, predecessor, successor, finger table, successor list, data_store
//Dont forget map, whatever that means... it means (map of key to data)
//Needed to make predecessor and successor lists to avoid issue with not being able to make them nil
pub type State {
  State(
    internal: #(
      Int,
      List(process.Subject(Message)),
      List(process.Subject(Message)),
      List(process.Subject(Message)),
    ),
    stack: List(Int),
  )
}

pub type Message {
  Shutdown
  SetInternal(
    #(
      Int,
      List(process.Subject(Message)),
      List(process.Subject(Message)),
      List(process.Subject(Message)),
    ),
  )
  // Push(String)
  // PopGossip(process.Subject(Result(Int, Nil)))
}

fn handle_message(state: State, msg: Message) -> actor.Next(State, Message) {
  case msg {
    Shutdown -> actor.stop()

    SetInternal(#(v1, v2, v3, v4)) -> {
      actor.continue(State(#(v1, v2, v3, v4), state.stack))
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

  // echo number_of_nodes

  let number_of_nodes = case int.parse(number_of_nodes) {
    Ok(number_of_nodes) -> number_of_nodes
    Error(_) -> 0
  }

  let num_requests = case int.parse(num_requests) {
    Ok(number_of_nodes) -> number_of_nodes
    Error(_) -> 0
  }

  io.println("Hello from rippy!")

  let m = 8

  let assert Ok(default_actor) =
    actor.new(State(#(0, [], [], []), []))
    |> actor.on_message(handle_message)
    |> actor.start

  let output = chord_id("Hello", m)
  let output2 = chord_id("3", m)
  echo output2

  let random_max = int.bitwise_shift_left(1, m)
  echo random_max

  // echo number_of_nodes
  let unique_random_list = unique_random(number_of_nodes, random_max)
  echo unique_random_list

  let number_list = list.range(0, number_of_nodes - 1)

  echo number_list

  let actor_list =
    list.map(unique_random_list, fn(n) {
      let assert Ok(started) =
        actor.new(State(#(n, [], [], []), []))
        |> actor.on_message(handle_message)
        |> actor.start

      started.data
    })

  // list.each(number_list, fn(n) {
  //   let random_id = nth_int(unique_random_list, n)
  //   let random_id = case random_id {
  //     Ok(random_id) -> random_id
  //     Error(_) -> 0
  //   }

  //   let successor_index = { n + 1 } % number_of_nodes
  //   // echo successor_index
  //   let successor = nth_actor(actor_list, successor_index)

  //   let predecessor_index = { n - 1 } % number_of_nodes

  //   let predecessor_index = case predecessor_index {
  //     -1 -> {
  //       number_of_nodes - 1
  //     }
  //     _ -> {
  //       predecessor_index
  //     }
  //   }

  //   let predecessor = nth_actor(actor_list, predecessor_index)

  //   let successor = case successor {
  //     Ok(successor) -> successor
  //     Error(_) -> default_actor.data
  //   }
  //   let predecessor = case predecessor {
  //     Ok(predecessor) -> predecessor
  //     Error(_) -> default_actor.data
  //   }
  //   // echo random_id
  // })

  process.sleep(1000)
  // echo actor_list

  // let random_number_max = int.power(2, 8.0)
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

fn nth_int(xs: List(Int), i: Int) -> Result(Int, Nil) {
  case xs {
    [] -> Error(Nil)
    // list too short
    [x, ..rest] ->
      case i {
        0 -> Ok(x)
        // found the element
        _ -> nth_int(rest, i - 1)
        // keep searching
      }
  }
}

fn nth_actor(
  xs: List(process.Subject(Message)),
  i: Int,
) -> Result(process.Subject(Message), Nil) {
  case xs {
    [] -> Error(Nil)
    // list too short
    [x, ..rest] ->
      case i {
        0 -> Ok(x)
        // found the element
        _ -> nth_actor(rest, i - 1)
        // keep searching
      }
  }
}

pub fn chord_id(key: String, m: Int) -> Int {
  // Convert the key string to a BitArray
  let key_bits = bit_array.from_string(key)

  // Compute SHA-1 (returns a BitArray)
  let hash_bits = crypto.hash(crypto.Sha1, key_bits)

  // Turn the hash into hex, then parse as an Int base-16
  case int.base_parse(bit_array.base16_encode(hash_bits), 16) {
    Ok(n) -> {
      // ring_size = 2^m   (use bitwise shift)
      let ring_size = int.bitwise_shift_left(1, m)
      n % ring_size
    }
    Error(_) ->
      // fallback on parse failure (very unlikely)
      0
  }
}

pub fn unique_random(n: Int, k: Int) -> List(Int) {
  case n > k + 1 {
    True -> []
    False -> {
      let nums = loop([], n, k)
      list.sort(nums, int.compare)
    }
  }
}

fn loop(acc: List(Int), n: Int, k: Int) -> List(Int) {
  case list.length(acc) == n {
    True -> acc
    False -> {
      let r = int.random(k)
      case list.contains(acc, r) {
        True -> loop(acc, n, k)
        // duplicate → try again
        False -> loop([r, ..acc], n, k)
        // new → add
      }
    }
  }
}
// fn set_successors(actor_list){

// }
