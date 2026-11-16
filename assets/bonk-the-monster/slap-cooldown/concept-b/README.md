# Concept B production assets

All coordinates in layout.json are relative to the 1024×256 Composite.png. All PNGs are RGBA. Only Composite.png has text.

| Piece | Export size | Composite x,y,w,h |
|---|---|---|
| Frame |1024×256|104,36,912,184|
| Icon |512×512|34,34,188,188|
| RadialTrack / RadialRing |512×512|8,8,240,240|
| Timer text area |live text|280,54,690,148|
| BarTrack / BarFill (optional) |1024×128|300,180,640,24; hidden in radial reference|
| ReadyGlow |1024×256|0,0,1024,256; hidden during cooldown|

Text color #F4E8D6, outline #1A0C22, 8 px at reference resolution (2 px at 256×64). Reference uses DejaVu Sans Bold; use your existing chunky Roblox font in game.

## Roblox slicing
Set ScaleType = Slice. Frame SliceCenter = Rect.new(96,64,928,192). BarTrack and BarFill SliceCenter = Rect.new(64,32,960,96). SliceScale should match UI display scale, e.g. 0.25 at quarter size. Preserve square aspect for both radial textures. Ring center is (256,256); outer radius 241, inner radius 199.

Concept B uses radial progress, so the horizontal bar is supplied as an optional alternative and is not rendered in Composite.png. Ring is clipped to 216 degrees clockwise from twelve o'clock (60%). The timer reads 6.1s as requested; exact 6.1/10 runtime progress would be 61%. Use code-driven masking for progress. For the optional horizontal bar, crop the full-sized fill with a clipping parent rather than squeezing the endcap at low values.

ReadyGlow is the only asset with soft exterior alpha. At READY, hide progress, briefly show the glow behind the frame and set your live label to READY!.
