# Origami Tactics Board Game – Rules v0.91

## Overview
Origami Tactics is a two‑player tactical battle game played on a 9×9 grid. Each player commands a small team of origami units – Cranes, Frogs, Boxes, Turtles and Shuriken – each with unique movement and combat abilities. Units take **Fold Damage (FD)** rather than hit points: folds represent the structural integrity of your origami. When a unit’s FD equals or exceeds its health, it tears and is removed from the board.

Your goal is to either occupy your opponent’s **Home Base** at the end of your turn or eliminate all enemy units. Manage your limited **Command Points (CP)** to move, attack, use abilities and defend.

## Components
- 9×9 grid board with coloured terrain (plain squares, water squares and shrines).
- Unit pieces: Crane, Frog, Box, Turtle, Shuriken. Each piece tracks its **MP (movement points)**, **ATK (attack value)**, **ARM (armor value)** and **FD taken**.
- Command Point tokens.
- Base markers and Shrine markers.
- Optional initiative marker and round tracker.

## Setup
1. Place the board between the players. Each player places their **Home Base** in the center of their back row.
2. Shuffle Shrine markers; place one on each of the designated shrine squares.
3. Each player takes one of each unit type and places them on their starting row as described in the scenario. All units start with 0 FD.
4. Set the Command Points pool to 5 CP per player per round. Determine first player randomly.

## Turn Structure
A round consists of two **small turns** (one for each player). During your small turn:
1. **Refresh**: You regain your CP up to 5, plus shrine bonuses (+1 CP for each shrine you control, up to +2 total). Leftover CP can be converted to a +1 ARM “Defensive Wait” bonus instead of being lost.
2. **Act**: Spend CP to move your units, attack or use special abilities. You may interleave actions among your units; when a unit has no MP remaining it cannot move further this turn.
3. **End**: If one of your units stands on the opponent’s Home Base, you immediately win. If no attack or base occupation has occurred in 50 consecutive small turns, the game ends in a draw.

## Unit Abilities
Every unit has base MP, ATK and ARM values. Damage is calculated as:

**FD = max(1, ATK - max(0, adjusted ARM))**

ARM never drops below 0. Each unit may perform one automatic **counter‑attack** per round when attacked in melee (still adjacent after the attack resolves).

### Crane
- **Move**: Flies up to 4 squares ignoring terrain and units. Cannot land on water voluntarily. Landing on water after being carried by another unit does not deal FD.
- **Carry**: Once per turn, may carry an adjacent friendly unit up to its move distance. The carried unit cannot act this turn.

### Frog
- **Move**: Jumps orthogonally up to 3 squares. May attempt to **push** an adjacent unit one square. If the destination square contains an obstacle, the pushed unit takes +1 FD and remains in place. If it is water, the pushed unit falls in (see Terrain).
- **Leap Attack**: A frog that moves at least 2 squares may attack a target it lands adjacent to.

### Box
- **Armor Aura**: Enemy units in any of the eight squares surrounding the box have their ARM reduced by 1 (to a minimum of 0) as long as they remain adjacent.
- **Move**: 1 square orthogonally.

### Turtle
- **Move**: 1 square orthogonally.
- **Shell Guard**: When a turtle is adjacent to a friendly unit that is attacked, it may swap places with that unit before damage is resolved (if the turtle’s original square is empty). This **intercept** triggers before damage and counts as the unit’s counter‑attack for the round.

### Shuriken
- **Move**: 3 squares in a straight line.
- **Piercing Charge**: Moves in a straight line through enemies. If the charge passes through two or more enemy units, the final target takes +1 FD. It cannot bend its path.
- **Fragile**: Low ARM but high ATK. Take care when exposing the Shuriken.

## Terrain
- **Plain**: Normal squares with no special rules.
- **Water**: A unit may not voluntarily end its movement on water. If a unit is pushed, shoved or falls into water, it takes +1 FD and is placed in the water. While on a water square it has **MP +1** until it moves off; leaving the water removes this bonus. Units carried by a crane can be set down safely on water without taking FD.
- **Shrine**: Occupying a shrine at the end of your small turn grants +1 CP next round, up to a maximum of +2 CP from shrines. Shrine control is updated at the end of each round.

## Movement and Actions
- Each unit has a pool of MP each turn. Spending 1 MP allows a move to an adjacent square according to its movement rules.
- Moving through friendly units is allowed (except for shuriken which cannot move through allies). Enemy units block movement unless an ability says otherwise.
- **Push** and **Shove**: When a unit pushes an enemy, resolve as follows:
  1. Determine the destination square in the push direction.
  2. If the destination is plain and empty, the pushed unit moves into it.
  3. If the destination contains an obstacle, the pushed unit takes +1 FD and stays where it is.
  4. If the destination is water, the unit falls in and resolves water effects.
  5. If the destination contains another unit, the push fails.

## Combat Resolution
When a unit attacks an enemy:
1. **Interception**: If a turtle is adjacent to the target and chooses to intercept, swap the turtle with the target before damage.
2. **Damage**: Attacker deals FD = max(1, ATK – effective ARM of the target). Apply FD; if the unit’s FD ≥ its health, it tears and is removed.
3. **Break**: Some abilities trigger on break (not detailed here).
4. **Push**: If the attack includes a push or knockback, resolve it now using the push rules.
5. **Position Update**: Move any pieces as required by push or ability.
6. **Counter‑Attack**: If the defender is still adjacent to the attacker and has not yet counter‑attacked this round, it may immediately inflict damage on the attacker with its ATK value.
7. **Final Break**: If either unit is at or above its FD threshold after counter‑attack, remove it.

Each unit may counter‑attack at most once per round.

## Undo and Command Points
- Actions are performed using CP. Moving one square or using an ability costs 1 CP; attacks cost CP as indicated on unit cards.
- You may undo freely while planning a move or path. Once you confirm an action (e.g. execute an attack), that action cannot be undone.
- Remaining CP at the end of your small turn may be converted into a **Defensive Wait**, granting +1 ARM until your next turn (multiple leftover CP cannot stack; any extra CP is lost).
- Heavy units (e.g. Turtle) cannot perform two attacks in the same round.

## Victory and Draw
- You win immediately if one of your units ends its small turn on the opponent’s Home Base.
- You win if your opponent has no units remaining.
- The game is a draw if 50 consecutive small turns pass with no unit being destroyed and no base captured.

---

This ruleset reflects version **v0.91** and incorporates recent clarifications:
- Water squares now allow forced stoppage: units cannot voluntarily end on water, but may end there when pushed or carried. Falling into water inflicts +1 FD; leaving water grants +1 MP until departure. Crane drops do not cause FD.
- Base occupation victory now triggers at the end of your small turn, not at round end.
- The attack resolution order has been unified to: interception → damage → break → push → position update → counter‑attack → final break.
- Counter‑attacks are limited to once per unit per round.
- Box aura applies continuously to any adjacent enemies (ARM –1, min 0).
- Shuriken’s piercing charge grants +1 FD to the final target if at least two enemies were passed through in a straight line.
- Push rules are consistent for frogs and other sources: obstacle = +1 FD and no movement; water = fall in; unit = no effect.
- Leftover CP can be used for a defensive wait (+1 ARM); shrine CP bonus is capped at +2.
- Draw is determined by 50 small turns without a kill or base occupation.

Enjoy commanding your paper warriors!
