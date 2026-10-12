# Storage room: wall elements

Reference: `storage_modern_reference.png`. Studio build script: `studio/BuildStorageWalls.lua`.
Room coordinates: X left→right (0–45), Z back wall→front (0–52.5), Y up (wall height 14).

## Every wall (layered bottom → top)

| Layer | Height | Material | Colour |
|---|---|---|---|
| Stainless kick band | 0 – 2.5 | Metal | `#B9C2C8` |
| Teal stripe (= kitchen tile) | 2.5 – 3 | SmoothPlastic | `#2F6F6A` |
| FRP wall panels | 0 – 14 | SmoothPlastic | `#F4F1EA` |
| Top trim | 13.6 – 14 | Metal | `#5C6670` |

## Back wall

| Element | Position (X / Y) | Material / colour |
|---|---|---|
| Roll-up door 12 | X 17–29, Y 0–10 | CorrugatedMetal `#3E6E9C`, bottom bar Metal `#5C6670` |
| Door hood (coil box) | X 16.2–29.8, Y 10–11.4 | Metal `#5C6670` |
| Guard posts both sides | 0.8 wide, Y 0–10 | 1-stud yellow `#F2C230` / black `#2B2B2B` bands |
| RECEIVING sign | X 19–27, Y 11.7–13.3 | Teal, white text |
| "Truck here" lamp + label | X 30.5–34.5, Y ~7 | Neon green `#2ECC71` |
| Order tablet | X 35–38.5, Y 4.5–7 | Black bezel, Neon screen `#5FE8C4` |

## Walk-in cooler (back-left corner, X 0–12.5, Z 0–15, height 10)

* Panels: SmoothPlastic `#F7FAFB`, ice-blue `#BFE3F2` top/corner frame (ice-blue = cold).
* Doorway X 4.5–9, height 8, with a walk-through PVC strip curtain (Glass, 45% transparent, no collision).
* Frosted window (Glass `#BFE3F2`) and a "❄ COLD" sign above the door.
* Kick band and teal stripe continue around the cooler.

## Right wall: kitchen partition

* Door 7: Z 3–10, height 9, with yellow/black guard posts and a "KITCHEN →" sign.
* Crate slots, Y 3–6.5, with a chrome frame and label: Falafel Z 16.5–20.5, Bread 25–29, Salad 33.5–37.5, Tahini 41.8–45.8.

## Floor (safety yellow on the floor only)

* Epoxy floor: Granite `#CFC9BD` (applied to the selected floor part).
* Receiving zone border X 14–31, Z 0–12.5; yellow/black threshold under the roll-up door; dashed walk lane at X 27.
