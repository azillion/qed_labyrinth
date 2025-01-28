open Types

let estimate_tokens (messages : message list) =
  (* Simple estimation - can be made more sophisticated *)
  List.fold_left (fun acc msg ->
    acc + (String.length msg.content / 4)  (* rough estimate *)
  ) 0 messages