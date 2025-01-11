module type S = sig
    type t = private {
      id : string;
      username : string;
      email : string;
      created_at : Ptime.t;
    }
  
    type error =
      | UserNotFound
      | InvalidPassword
      | UsernameTaken
      | EmailTaken  
      | DatabaseError of string
    
    val register : 
      username:string -> 
      password:string -> 
      email:string -> 
      (t, error) result Lwt.t
  
    val authenticate : 
      username:string -> 
      password:string -> 
      (t, error) result Lwt.t
  
    val find_by_id : 
      string -> 
      (t option, error) result Lwt.t
  
    val find_by_username : 
      string -> 
      (t option, error) result Lwt.t
end
  
module Make : functor (Db : Caqti_lwt.CONNECTION) -> S