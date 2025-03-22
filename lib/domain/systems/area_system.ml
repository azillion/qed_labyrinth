(* module Area_info_system = struct
  let handle_area_info state user_id character_id area_id =
    let* () = Lwt.catch
      (fun () -> Lwt.return_unit)
      (fun exn ->
        let* () = Lwt_io.printl (Printf.sprintf "Area info error for user %s: %s" user_id (Base.Exn.to_string exn)) in
        Lwt.return_unit)
  let priority = 100

  let execute () =
    Lwt.return_unit
end *)