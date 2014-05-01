open Core.Std
open Ast

type t = decl with sexp,compare

type ring_decl = d1:Dim.t -> d2:Dim.t -> t
let is_real s = s, Ring (R,None)
let is_integer s = s, Ring (Z,None)
let is_complex s = s, Ring (C,None)

let ring s ~r ~d1 ~d2 = s, Ring(r,Some (d1,d2))
let real = ring ~r:R
let integer = ring ~r:Z
let complex = ring ~r:C


let kind s ~is = s, Kind is

let matrix s = kind s ~is:"matrix"
let vector s = kind s ~is:"vector"
let scalar s = kind s ~is:"scalar"

let assoc s = List.map ~f:(fun prop -> prop s)

let is_scalar (d1,d2) = Dim.(d1 = one && d2 = one)

let ppr_prop prop =
  let open Printer in
  let str = string in
  let ring s = s |> Ring.to_string |> str in
  let seq = list 1.0 space in
  match prop with
  | Ring (r,None) -> seq [str "in"; ring r]
  | Ring (r, Some ds) when is_scalar ds ->
    seq [str "scalar"; str "in"; ring r]
  | Ring (r, Some (d1,d2)) when Dim.(d2 = one) ->
    seq [str "in"; ring r;
         (str "[" ++ Dim.ppr d1 ++ str "]")]
  | Ring (r, Some (d1,d2)) ->
    seq [str "in"; ring r;
         (str "[" ++ Dim.ppr d1 ++ str "," ++ Dim.ppr d2 ++ str "]")]
  | Kind s -> seq [str s]

let ppr (s,prop) = Printer.(string s ++ space ++ ppr_prop prop)

let ppr_list (decls : t list) =
  let open Printer in
  let sorted =
    List.sort ~cmp:(fun (s1,_) (s2,_) -> Sym.ascending s1 s2) decls in
  let groups =
    List.group sorted ~break:(fun (s1,_) (s2,_) -> Sym.(s1 <> s2)) in
  let grouped =
    List.map groups ~f:(fun ds -> match ds with
        | [] -> assert false
        | (s,p)::ds ->
          let cmp = compare_property in
          let ps = List.sort ~cmp (p :: List.map ds ~f:snd) in
          s, List.dedup ~compare:cmp ps) in

  let ppr_group (s,props) =
    let sep = space ++ string "and" ++ space in
    string s ++ space ++ string "is" ++ space ++
    (List.map props ~f:ppr_prop |> list 0.5 sep) in

  let group_sep = flush ++ space ++ space in
  group_sep ++ (List.map grouped ~f:ppr_group |> Printer.(list 0.25 group_sep))
