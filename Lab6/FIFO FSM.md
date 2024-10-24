---

excalidraw-plugin: parsed
tags: [excalidraw]

---
==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠== You can decompress Drawing data with the command palette: 'Decompress current Excalidraw file'. For more info check in plugin settings under 'Saving'


# Excalidraw Data
## Text Elements
FSM1: Write Side
Inputs: 
-Physical
Reset_l    -> KEY(0)
Add       -> KEY(1)
Switches -> SW(9 downto 0)

Outputs:
-Physical
LEDs         -> LEDR(9 downto 0)
-Software
WriteEnable -> wr_en
WriteData   -> wr_data(9 downto 0)

Signals
Full        -> fifo_full (Used as input here and FSM2)

Current State                           Input                                  Next State                    Output
Clear                                      !KEY(0)                                Clear                            Remain in Clear on Reset
Clear                                      KEY(0)                                 Waiting                         Move to Waiting
Waiting                                   !KEY(0)                                 Clear                           Move to Clear
Waiting                                   KEY(0) & !KEY(1)                     Debounce                      Move to Debounce
Debounce                                KEY(1) & DELAY                      Waiting                         Return to Waiting if signal bounced
Debounce                                !KEY(1) & DELAY                     Pressed                        Moved to Pressed if still active after delay
Check                                     fifo_full                               Waiting                         FIFO full, can't add more
Check                                     !fifo_full                              Write                           Move to write to store SW value, set wr_data, set wr_en
Write                                     N/A                                     Waiting                         Clear wr_data and wr_enable, then move to waiting
 ^zgbqCHxJ

FSM2: Read Side
Inputs
ReadData     -> rd_data(23 downto 0)
Empty          -> fifo_empty

Outputs
-Physical
7-Segment     -> HEX(5 downto 0)
-Software
ReadEnable    -> rd_en

Signals
Full         -> fifo_full (Used as input here and FSM1)
Total      -> sum (Running total of accumulated value)

Current State                           Input                                  Next State                    Output
Clear                                      !KEY(0)                                Clear                            Remain in Clear, clear sum, clear HEX output
Clear                                      KEY(0)                                 Waiting                         Move to waiting
Waiting                                   !KEY(0)                                 Clear                            Move to clear on Reset
Waiting                                   KEY(0)&fifo_full                      Accumulate                     Move to Accumulate when FIFO full, set rd_en
Accumulate                              !fifo_empty                            Accumulate                     Remain in Accumulate until empty, adding data from rd_data to sum
Accumulate                              fifo_empty                             Display                         Move to display, reset rd_en
Display                                   N/A                                      Waiting                         Move to waiting, store sum in HEX output ^YQ1pLEDK

%%
## Drawing
```compressed-json
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
```
%%