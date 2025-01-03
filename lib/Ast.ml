type literal = Pos of string | Neg of string | Bool of bool
type clause = Clause of literal list
type cnf = CNF of clause list
type assignment = { assignments : (string * bool) list; formula : cnf }

let string_of_literal = function
  | Pos v -> v
  | Neg v -> "!" ^ v
  | Bool b -> string_of_bool b

let string_of_clause (Clause lits) =
  match lits with
  | [] -> "false"
  | [ lit ] -> string_of_literal lit
  | lits -> "(" ^ String.concat " || " (List.map string_of_literal lits) ^ ")"

let string_of_cnf (CNF clauses) =
  match clauses with
  | [] -> "true"
  | [ clause ] -> string_of_clause clause
  | clauses -> String.concat " && " (List.map string_of_clause clauses)

let string_of_assignment_pair (var, value) = var ^ " = " ^ string_of_bool value

let string_of_assignment assgn =
  let assignments_str =
    String.concat ", " (List.map string_of_assignment_pair assgn.assignments)
  in
  "{ " ^ assignments_str ^ " } " ^ string_of_cnf assgn.formula
