import LodgeHouse.Share

/-!
# The Lodge House, constructed recursively

The static site is one recursive tree: a `Lodge` is a hall (the index) with a
list of rooms (pages), and every room is either a leaf page or a wing with
more rooms. Rendering walks the tree; nothing else is needed.
-/

namespace LodgeHouse

/-- One page of the site. -/
inductive Room where
  /-- A leaf page: filename (relative), title, body. -/
  | page (file : String) (title : String) (body : String)
  /-- A wing: a subdirectory of rooms. -/
  | wing (dir : String) (title : String) (rooms : List Room)
  deriving Inhabited

/-- The lodge: a root hall plus its rooms. -/
inductive Lodge where
  /-- The hall (index page) with the rooms it opens onto. -/
  | hall (title : String) (rooms : List Room)
  /-- The lodge inside a wing — same shape, one level down. -/
  | deeper (lodge : Lodge)
  deriving Inhabited

/-! ## HTML rendering -/

/-- Minimal HTML escaping. -/
def htmlEscape (s : String) : String :=
  s.foldl (fun acc c =>
    match c with
    | '<' => acc ++ "&lt;"
    | '>' => acc ++ "&gt;"
    | '&' => acc ++ "&amp;"
    | '"' => acc ++ "&quot;"
    | c => acc.push c) ""

/-- Wrap a page in the site's document shell. -/
def pageShell (title : String) (body : String) : String :=
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"UTF-8\">\n" ++
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" ++
  "<title>" ++ htmlEscape title ++ " — Lodge House</title>\n" ++
  "<link rel=\"stylesheet\" href=\"theme.css\">\n</head>\n" ++
  "<body>\n<main>\n" ++ body ++ "\n</main>\n" ++
  "<p><a href=\"index.html\">Back to the hall</a></p>\n" ++
  "</body>\n</html>\n"

/-- Concatenate a list of strings. -/
def join (xs : List String) : String :=
  xs.foldl (fun acc s => acc ++ s) ""

/-- Render a room's navigation list item. -/
def roomNavItem (depth : String) : Room → String
  | .page file title _ => "<li><a href=\"" ++ depth ++ htmlEscape file ++ "\">" ++ htmlEscape title ++ "</a></li>"
  | .wing dir title _ => "<li>" ++ htmlEscape title ++ " (<code>" ++ htmlEscape dir ++ "/</code>)</li>"

/-- Render a room to (path, contents) file pairs. -/
def renderRoom (depth : String) : Room → List (String × String)
  | .page file title body =>
    [(depth ++ file, pageShell title body)]
  | .wing dir _ rooms =>
    (rooms.flatMap (renderRoom (depth ++ dir ++ "/")))
    ++ [(depth ++ dir ++ "/index.html",
        pageShell dir ("<h1>" ++ dir ++ "</h1>" ++
          "<ul>" ++ join (rooms.map (roomNavItem "")) ++ "</ul>"))]

/-- Render the whole lodge to (path, contents) file pairs. -/
def renderLodge : Lodge → List (String × String)
  | .hall title rooms =>
    [("index.html",
      pageShell title ("<h1>" ++ htmlEscape title ++ "</h1>" ++
        "<p>The Lodge House: browser-local, link-shareable, now generated from recursive Lean.</p>" ++
        "<ul>" ++ join (rooms.map (roomNavItem "")) ++ "</ul>"))]
    ++ rooms.flatMap (renderRoom "")
  | .deeper lodge => renderLodge lodge

end LodgeHouse
