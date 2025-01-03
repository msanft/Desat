open Ast

let rec find_variable : cnf -> string option =
 fun (CNF clauses) ->
  let rec find_in_clause : clause -> string option =
   fun (Clause lits) ->
    match lits with
    | [] -> None
    | Pos v :: _ -> Some v
    | Neg v :: _ -> Some v
    | Bool _ :: rest -> find_in_clause (Clause rest)
  in
  match clauses with
  | [] -> None
  | Clause [] :: _ -> None
  | clause :: rest -> (
      match find_in_clause clause with
      | Some v -> Some v
      | None -> find_variable (CNF rest))

let substitute_literal : string -> bool -> literal -> literal =
 fun var value lit ->
  match lit with
  | Pos v when v = var -> Bool value
  | Neg v when v = var -> Bool (not value)
  | _ -> lit

let substitute_clause : string -> bool -> clause -> clause =
 fun var value (Clause lits) ->
  Clause (List.map (substitute_literal var value) lits)

let substitute_cnf : string -> bool -> cnf -> cnf =
 fun var value (CNF clauses) ->
  CNF (List.map (substitute_clause var value) clauses)

let evaluate_literal : literal -> bool option = function
  | Bool b -> Some b
  | _ -> None

let evaluate_clause : clause -> bool option =
 fun (Clause lits) ->
  let rec eval_lits : literal list -> bool option = function
    | [] -> Some false
    | lit :: rest -> (
        match evaluate_literal lit with
        | Some true -> Some true
        | Some false -> eval_lits rest
        | None -> None)
  in
  eval_lits lits

let evaluate_cnf : cnf -> bool option =
 fun (CNF clauses) ->
  let rec eval_clauses : clause list -> bool option = function
    | [] -> Some true
    | clause :: rest -> (
        match evaluate_clause clause with
        | Some false -> Some false
        | Some true -> eval_clauses rest
        | None -> None)
  in
  eval_clauses clauses

let rec dpll :
    cnf -> (string * bool) list -> (string * bool) list -> assignment option =
 fun formula fixed_assignments current_assignments ->
  let check_fixed_assignments : unit -> bool =
   fun () ->
    List.for_all
      (fun (var, value) ->
        let substituted = substitute_cnf var value formula in
        match evaluate_cnf substituted with Some false -> false | _ -> true)
      fixed_assignments
  in

  if not (check_fixed_assignments ()) then None
  else
    match evaluate_cnf formula with
    | Some true -> Some { assignments = current_assignments; formula }
    | Some false -> None
    | None -> (
        match find_variable formula with
        | None -> Some { assignments = current_assignments; formula }
        | Some var -> (
            match List.assoc_opt var fixed_assignments with
            | Some value ->
                let formula' = substitute_cnf var value formula in
                dpll formula' fixed_assignments
                  ((var, value) :: current_assignments)
            | None -> (
                let formula_true = substitute_cnf var true formula in
                match
                  dpll formula_true fixed_assignments
                    ((var, true) :: current_assignments)
                with
                | Some result -> Some result
                | None ->
                    let formula_false = substitute_cnf var false formula in
                    dpll formula_false fixed_assignments
                      ((var, false) :: current_assignments))))

let solve : assignment -> assignment option =
 fun assgn -> dpll assgn.formula assgn.assignments []
