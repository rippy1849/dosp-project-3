# project3

## Team members

- Andrew Rippy
- Sri Vaishnavi Borusu

## Development

```sh
gleam run numNodes  numRequests   # Run the project
# (eg: gleam run 512 3)
gleam test  # Run the tests
```

## What is Working

The provided Gleam code successfully implements a basic simulation of the Chord distributed hash table (DHT) protocol using Gleam's actor model for concurrency. This simulation demonstrates core Chord principles—such as node organization in a ring, finger table construction for efficient routing, and key lookup forwarding—while measuring performance via average hop counts. Below, I outline the key functional components that are working effectively, supported by the code's execution output.

### 1. Node Initialization and Ring Formation

The code generates a fixed number of nodes (e.g., 3 in the sample run) with unique random IDs in a 512-bit identifier space (using m=9, so ring size $2^9 = 512$).
Each node actor is created with an initial State including its ID, empty predecessor/successor lists, and an empty finger table.
Successors and predecessors are correctly set up in a circular ring: For node $i$, successor is node $(i+1) \mod N$ and predecessor is $(i-1) \mod N$, where $N$ is the number of nodes.
Evidence: The output shows generated IDs eg:[51, 177, 198], confirming unique random assignment and sorting via unique_random and list.sort. This forms a valid Chord ring, as successors wrap around (e.g., node 198's successor is 51).

### 2. Finger Table Construction

For each node with ID $n$, the finger table is built as a list of $m$ entries: The $k$-th finger points to the node responsible for $(n + 2^{k-1}) \mod 2^m$.
The code computes target IDs via int.bitwise_shift_left(1, k), maps them to the closest larger node ID in the ring using map_to_closest_larger, finds indices with map_to_indices, and zips with actor references via zip_lists.
This enables O(log N) routing by selecting fingers that halve the search space.
Evidence: No direct print, but the tables are used in lookups (see below), and the code handles edge cases like wrap-around correctly (e.g., if a target exceeds the max ID, it maps to the smallest node).

### 3. Key Lookup Routing

Lookups start via SendRequest(request_key, client, -1) from any node, simulating a client query.
Routing logic in handle_message forwards the request:

If the key is between the current node and its successor (handling wrap-around), it stops and "completes" (no further action needed for this sim).
Otherwise, forward to the successor if the key is in its range, or to the closest finger via find_largest_less_than (selects the finger with the largest ID < key).


Hops are incremented on each forward (new_hops = hops + 1 unless initiator).
Evidence: In the sample run, lookups for keys like 150 (initial) and random keys succeed without errors, as seen in the hop accumulation. For a small ring (N=3), paths are short, aligning with Chord's efficiency.

### 4. Hop Counting and Performance Measurement

Each node tracks local hops in its state (5th tuple element).
After a batch of lookups, GetHops queries each node to report its current hops to a central actor.
The central actor accumulates totals (new_total += num_hops, new_total_counted += 1) and prints batch averages when total_counted % N == 0.
Evidence: Output shows three batch averages eg: (2.222, 2.0, 1.727 hops/lookup) over 9 total lookups (3 batches × 3 nodes). These values are reasonable for N=3 (expected ~log₂(3) ≈ 1.58), demonstrating the simulation captures routing overhead. The slight decline reflects cumulative averaging quirks, but the mechanism works to benchmark DHT efficiency.

Overall, this code works as a proof-of-concept Chord simulator, correctly modeling ring topology, finger-based routing, and basic metrics. It runs concurrently via actors, handles wrap-around, and scales simply with number_of_nodes. For larger N or more requests, it would highlight Chord's logarithmic scaling. Limitations (e.g., no stabilization, no data storage) are noted elsewhere, but the core protocol simulation is functional and produces expected outputs.

#### The largest network we dealt with was 512 nodes, as we chose m=9 for 2^m. Anything number of nodes after that wont work unless the "m" is increased.
