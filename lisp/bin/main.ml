type stream = 
  {mutable line_num: int; mutable chr: char list; chan: in_channel };;


let read_char stm = 
  match stm.chr with
    | [] -> 
            let c = input_char stm.chan in
            if c = '\n' then let _ = stm.line_num <- stm.line_num + 1 in c
            else c
    | c::rest ->
            let _ = stm.chr <- rest in c

let unread_char stm c = 
  stm.chr <- c :: stm.chr;;

let is_white c =
  c = ' ' || c = '\t' || c = '\n';;

let rec eat_whitespace stm = 
  let c = read_char stm in
  if is_white c then
    eat_whitespace stm
  else
    unread_char stm c;
    ();;

type lobject =
  | Fixnum of int
  | Boolean of bool
  | Symbol of string
  
exception SyntaxError of string;;

let stringOfChar c = 
    String.make 1 c;;

let rec read_sexp stm =
  let is_digit c =
    let code = Char.code c in
    code >= Char.code('0') && code <= Char.code('9')
  in
  let rec read_fixnum acc =
    let nc = read_char stm in
    if is_digit nc
    then read_fixnum (acc ^ (Char.escaped nc))
    else
      let _ = unread_char stm nc in
      Fixnum(int_of_string acc)
  in
  let is_symstartchar =
      let isalpha = function | 'A'..'Z'|'a'..'z' -> true
                             | _ -> false
      in
      function | '*'|'/'|'>'|'<'|'='|'?'|'!'|'-'|'+' -> true
               | c -> isalpha c
  in
  let rec read_symbol () =
      let literalQuote = String.get "\"" 0 in
      let is_delimiter = function | '('|')'|'{'|'}'|';' -> true
                                  | c when c=literalQuote -> true
                                  | c -> is_white c
      in
      let nc = read_char stm in
      if is_delimiter nc
      then let _ = unread_char stm nc in ""
      else stringOfChar nc ^ read_symbol ()
  in
  eat_whitespace stm;
  let c = read_char stm in
  if is_symstartchar c 
  then Symbol(stringOfChar c ^ read_symbol ())
  else if is_digit c || c='~'
  then read_fixnum (stringOfChar (if c='~' then '-' else c))
  else if c = '#' then
    match (read_char stm) with
    | 't' -> Boolean(true)
    | 'f' -> Boolean(false)
    | x -> raise (SyntaxError ("Invalid boolean literal " ^ (Char.escaped x)))
  else raise (SyntaxError ("Unexpected char " ^ (Char.escaped c)));;

let rec print_sexp e = 
  match e with
  | Fixnum(v) -> print_int v
  | Boolean(b) -> print_string (if b then "#t" else "#F")
  | Symbol(s) -> print_string s  

let rec repl stm =
  print_string "> ";
  flush stdout;
  let sexp = read_sexp stm in
  print_sexp sexp;
  print_newline ();
  repl stm;;let main = 
  let stm = {chr=[]; line_num=1; chan=stdin} in
  repl stm;;