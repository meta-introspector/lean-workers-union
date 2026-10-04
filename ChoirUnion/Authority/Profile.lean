import Lean

namespace ChoirUnion.Authority

abbrev AxiomProfile := List Lean.Name

namespace AxiomProfile

def empty : AxiomProfile := []

def constructive : AxiomProfile := [``propext]

def classical : AxiomProfile := [``propext, ``Classical.choice]

end AxiomProfile

end ChoirUnion.Authority
