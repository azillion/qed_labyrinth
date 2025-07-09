open Lwt.Infix
open Base
open Qed_error

(* Helper to wrap a unit Lwt.t into (unit, Qed_error.t) Lwt_result.t *)
let wrap_ok (op : unit Lwt.t) : (unit, Qed_error.t) Lwt_result.t =
  Lwt.catch
    (fun () -> op >|= fun () -> Ok ())
    (fun exn -> Lwt.return (Error (UnknownError (Exn.to_string exn))))

(* Helper to wrap a value returning Lwt.t into ('a, Qed_error.t) Lwt_result.t *)
let wrap_val (op : 'a Lwt.t) : ('a, Qed_error.t) Lwt_result.t =
  Lwt.catch
    (fun () -> op >|= fun v -> Ok v)
    (fun exn -> Lwt.return (Error (UnknownError (Exn.to_string exn)))) 