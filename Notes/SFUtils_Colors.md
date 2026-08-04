````markdown
# Color Utilities

LibSFUtils provides a comprehensive set of functions for converting between RGB values, hexadecimal color strings, and ESO color tags. It also includes the lightweight **SF_Color** class for storing, manipulating, and displaying colors efficiently.

Unlike `ZO_ColorDef`, `SF_Color` caches its hexadecimal representation, reducing repeated formatting overhead when colors are used frequently.

---

# Features

- Convert RGB values to hexadecimal strings
- Convert hexadecimal strings to RGBA values
- Support for ESO color tags (`|cRRGGBB`)
- Support for alpha (`AARRGGBB`) hex strings
- Lightweight `SF_Color` class
- Cached hexadecimal values for improved performance
- Clone and compare colors
- Convert to `ZO_ColorDef`
- Colorize text for chat and UI

---

# Color Formats

The library recognizes several common color formats.

| Format | Example | Description |
|---------|---------|-------------|
| `RRGGBB` | `FF0000` | Standard RGB hexadecimal |
| `AARRGGBB` | `80FF0000` | RGB with alpha |
| `|cRRGGBB` | `|cFF0000` | ESO color tag |
| RGB floats | `1, 0, 0` | Values between 0 and 1 |
| RGB integers | `255, 0, 0` | Values between 0 and 255 (SF_Color only) |

---

# Conversion Functions

## colorRGBToHex()

Converts RGB float values into a six-character hexadecimal string.

```lua
local hex = SF.colorRGBToHex(1, 0, 0)
-- "FF0000"
```

### Syntax

```lua
SF.colorRGBToHex(r, g, b)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `r` | number | Red (0–1) |
| `g` | number | Green (0–1) |
| `b` | number | Blue (0–1) |

### Returns

A six-character hexadecimal string.

---

## colorHexToRGBA()

Converts a six-character hexadecimal string into RGBA floats.

```lua
local r, g, b, a = SF.colorHexToRGBA("00FF00")
```

### Syntax

```lua
SF.colorHexToRGBA(hex)
```

### Returns

```lua
r, g, b, a
```

Values range from `0` to `1`.

If the input is invalid or `nil`, white (`1,1,1,1`) is returned.

---

## ConvertRGBToHex()

Creates an ESO color tag.

```lua
local tag = SF.ConvertRGBToHex(1, 0, 0)

-- "|cFF0000"
```

### Syntax

```lua
SF.ConvertRGBToHex(r, g, b)
```

Unlike `colorRGBToHex()`, this function returns the complete ESO color prefix.

---

## ConvertHexToRGBA()

Converts several hexadecimal formats into RGBA values.

Supported inputs include:

- `RRGGBB`
- `AARRGGBB`
- `|cRRGGBB`

```lua
local r, g, b, a = SF.ConvertHexToRGBA("|c00FF00")
```

### Syntax

```lua
SF.ConvertHexToRGBA(hex)
```

### Returns

```lua
r, g, b, a
```

Invalid values return opaque white.

---

## ConvertHexToRGBAPacked()

Returns the converted values in a table.

```lua
local color = SF.ConvertHexToRGBAPacked("80FF0000")

d(color.r)
d(color.a)
```

### Syntax

```lua
SF.ConvertHexToRGBAPacked(hex)
```

### Returns

```lua
{
    r = ...,
    g = ...,
    b = ...,
    a = ...
}
```

---

# The SF_Color Class

`SF_Color` stores color information in both floating-point and cached hexadecimal form.

This minimizes repeated conversions when colors are used frequently for UI text.

---

## Creating Colors

### From RGB Floats

```lua
local color = SF_Color:New(1, 0, 0)
```

---

### From RGB Integers

```lua
local color = SF_Color:New(255, 0, 0)
```

---

### From Hexadecimal

```lua
local color = SF_Color:New("FF0000")
```

or

```lua
local color = SF_Color:New("80FF0000")
```

---

### From Another SF_Color

```lua
local copy = SF_Color:New(existingColor)
```

---

### From a ZO_ColorDef

```lua
local color = SF_Color:New(ZO_SELECTED_TEXT)
```

---

# Methods

## Initialize()

Reuses an existing color object.

```lua
color:Initialize(0, 1, 0)
```

Useful for reducing garbage collection.

---

## SetColor()

Changes the current color.

```lua
color:SetColor(1, 0, 0)

color:SetColor("00FF00")

color:SetColor(otherColor)
```

### Accepted Inputs

- RGB floats
- RGB integers
- Hex strings
- `SF_Color`
- `ZO_ColorDef`

Returns the color object for method chaining.

---

## SetAlpha()

Changes only the alpha value.

```lua
color:SetAlpha(0.5)
```

---

## UnpackRGB()

Returns RGB values.

```lua
local r, g, b = color:UnpackRGB()
```

---

## UnpackRGBA()

Returns RGBA values.

```lua
local r, g, b, a = color:UnpackRGBA()
```

Works for both `SF_Color` and `ZO_ColorDef`.

---

## ToHex()

Returns the cached hexadecimal string.

```lua
local hex = color:ToHex()
```

Returns:

```
FF0000
```

Alpha is not included.

---

## ToZO_ColorDef()

Creates a new `ZO_ColorDef`.

```lua
local zoColor = color:ToZO_ColorDef()
```

---

## Clone()

Creates an identical copy.

```lua
local duplicate = color:Clone()
```

---

## IsEqual()

Compares two colors.

```lua
if color:IsEqual(otherColor) then
    d("Same color")
end
```

Supports comparison with both `SF_Color` and `ZO_ColorDef`.

---

## Colorize()

Wraps text with ESO color tags.

```lua
local text = color:Colorize("Hello")
```

Produces:

```text
|cFF0000Hello|r
```

### Accepts

- strings
- numbers (localized string IDs)
- other values (converted using `tostring()`)

---

## Callable Objects

`SF_Color` implements Lua's `__call` metamethod.

Instead of

```lua
color:Colorize("Hello")
```

you can write

```lua
color("Hello")
```

Both produce identical results.

---

# Examples

## Create a Red Color

```lua
local red = SF_Color:New(1, 0, 0)
```

---

## Display Colored Text

```lua
d(red("Danger!"))
```

---

## Clone a Color

```lua
local copy = red:Clone()
```

---

## Convert to ZO_ColorDef

```lua
label:SetColor(red:ToZO_ColorDef():UnpackRGBA())
```

---

## Compare Colors

```lua
if red:IsEqual(copy) then
    d("Equal")
end
```

---

## Convert Hex to RGBA

```lua
local r, g, b, a =
    SF.ConvertHexToRGBA("80FF0000")
```

---

# Choosing the Right Function

| You have... | Use... |
|--------------|---------|
| RGB floats | `colorRGBToHex()` |
| RGB floats and need an ESO tag | `ConvertRGBToHex()` |
| Hex string | `ConvertHexToRGBA()` |
| Hex string as a table | `ConvertHexToRGBAPacked()` |
| Frequently reused colors | `SF_Color` |

---

# Technical Notes

## Cached Hexadecimal Values

`SF_Color` stores both RGBA values and a cached six-character hexadecimal string.

This avoids repeatedly formatting hexadecimal strings during rendering.

---

## Alpha Support

`SF_Color` stores alpha internally.

However, the cached hexadecimal string returned by `ToHex()` contains only RGB values.

This matches ESO's color tags (`|cRRGGBB`), which do not support alpha.

To display transparency, apply the alpha channel separately using UI controls such as:

```lua
control:SetColor(color:UnpackRGBA())
```

---

## Integer vs Float Input

`SetColor()` determines the input format by examining the first numeric parameter.

If the first value is greater than `1`, all numeric parameters are treated as integers (`0–255`).

Otherwise they are treated as floating-point values (`0–1`).

Mixing integer and floating-point values is not supported.

---

## Performance

`SF_Color` is intended as a lightweight alternative to `ZO_ColorDef`.

It avoids repeated conversions and only creates a `ZO_ColorDef` when explicitly requested via `ToZO_ColorDef()`.

For frequently reused colors—such as chat output, UI labels, and status indicators—`SF_Color` generally incurs less conversion overhead than repeatedly formatting hexadecimal strings or creating temporary `ZO_ColorDef` instances.
````
