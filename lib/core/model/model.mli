module type S = sig
    module User : User.S
end
  
module Make(Db : Caqti_lwt.CONNECTION) : S