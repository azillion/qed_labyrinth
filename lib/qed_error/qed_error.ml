type auth_error =
  | InvalidCredentials
  | RegistrationFailed
  | InvalidMessageFormat

let auth_error_to_string = function
  | InvalidCredentials -> "Invalid credentials"
  | RegistrationFailed -> "Registration failed"
  | InvalidMessageFormat -> "Invalid message format"
