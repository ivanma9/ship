# Contract: SelectableList ARIA Grid

## Required attributes on container
- `role="grid"`
- `aria-label` — human-readable name of the list
- `aria-rowcount` — total row count (including header row)
- `aria-colcount` — total column count

## Required attributes on header row
- `role="row"`
- `aria-rowindex="1"`

## Required attributes on header cells
- `role="columnheader"`
- `id="col-<columnKey>"` — for headers association (optional if aria-label used on cells)
- `aria-sort="ascending"|"descending"|"none"` — on sortable columns

## Required attributes on data rows
- `role="row"`
- `aria-rowindex` — 1-based, starting at 2 (row 1 is header)
- `aria-selected` — reflects selection state

## Required attributes on data cells
- `role="gridcell"`
- `aria-colindex` — 1-based column position
- `aria-label="<Column Header>: <Cell Value>"` — enables SR announcement without headers/id association

## Keyboard contract
- Arrow keys: move focus between cells within the grid
- Tab: exit grid to next focusable element outside grid
- Enter / Space: activate the primary action of the focused cell
- Escape: deselect / close any open menu within the cell

## Invariants
- Every interactive child element inside a gridcell MUST be reachable by Tab once the cell has focus
- Focus MUST be visible (CSS :focus-visible) on both the gridcell and any active child
- Grid MUST NOT trap focus (Tab must exit)
