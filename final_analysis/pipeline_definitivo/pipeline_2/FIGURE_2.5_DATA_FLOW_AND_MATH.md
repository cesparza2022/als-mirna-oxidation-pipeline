# 📊 FIGURE 2.5: DATA FLOW AND MATHEMATICAL EXPLANATION

**Date:** 2025-10-24  
**Figure:** Differential Heatmap (ALS vs Control) - All 301 miRNAs

---

## 🎯 **OVERVIEW**

**Question answered:**
"Which miRNAs and positions show G>T differential burden between ALS and Control?"

**Method:**
Direct subtraction of mean VAF values between groups

---

## 📐 **COMPLETE DATA FLOW**

### **STEP 0: INPUT DATA**

```
┌─────────────────────────────────────────────────────────┐
│ INPUT FILE: final_processed_data_CLEAN.csv             │
├─────────────────────────────────────────────────────────┤
│ Structure:                                              │
│   • 5,448 rows (SNVs)                                  │
│   • Columns: miRNA_name, pos.mut, 415 sample columns  │
│   • Each cell = VAF of that SNV in that sample         │
│                                                         │
│ Example row:                                            │
│   miRNA_name: "hsa-let-7a-5p"                          │
│   pos.mut: "6:GT"                                       │
│   ALS1: 0.0200                                         │
│   ALS2: 0.0100                                         │
│   Control1: 0.0250                                     │
│   ... (415 samples total)                              │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 1: FILTER G>T IN SEED**

```
┌─────────────────────────────────────────────────────────┐
│ FILTER 1: Only G>T mutations                            │
├─────────────────────────────────────────────────────────┤
│ Code: filter(str_detect(pos.mut, ":GT$"))              │
│                                                         │
│ Keeps: "6:GT", "3:GT" ✅                               │
│ Removes: "6:GA", "7:AC" ❌                             │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ FILTER 2: Only SEED positions (2-8)                     │
├─────────────────────────────────────────────────────────┤
│ Code: filter(position >= 2, position <= 8)             │
│                                                         │
│ Result: 473 SNVs from 301 unique miRNAs                │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 2: EXPAND TO ALL POSITIONS (1-22)**

```
┌─────────────────────────────────────────────────────────┐
│ EXPAND: Include ALL G>T positions for these 301 miRNAs  │
├─────────────────────────────────────────────────────────┤
│ Logic: For the 301 miRNAs that have G>T in seed,       │
│        also include their G>T mutations outside seed    │
│                                                         │
│ Code: filter(miRNA_name %in% all_mirnas)               │
│       filter(position <= 22)                            │
│                                                         │
│ Result: More SNVs (includes positions 1, 9-22)         │
└─────────────────────────────────────────────────────────┘
                         ↓
```

**Why expand to all positions?**
- Shows complete picture (not just seed)
- Seed marked visually (dashed lines)
- Allows comparison of seed vs non-seed

---

### **STEP 3: TRANSFORM TO LONG FORMAT**

```
┌─────────────────────────────────────────────────────────┐
│ WIDE FORMAT (before):                                   │
├─────────────────────────────────────────────────────────┤
│   miRNA      pos.mut   ALS1    ALS2    Control1        │
│   let-7a     6:GT      0.020   0.010   0.025           │
└─────────────────────────────────────────────────────────┘
                         ↓ pivot_longer()
┌─────────────────────────────────────────────────────────┐
│ LONG FORMAT (after):                                    │
├─────────────────────────────────────────────────────────┤
│   miRNA      pos  Sample_ID    Group    VAF            │
│   let-7a     6    ALS1         ALS      0.020          │
│   let-7a     6    ALS2         ALS      0.010          │
│   let-7a     6    Control1     Control  0.025          │
│   ... (415 rows per SNV)                               │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 4: CALCULATE MEAN VAF PER (miRNA, POSITION, GROUP)**

```
┌─────────────────────────────────────────────────────────┐
│ AGGREGATION: group_by(miRNA, position, Group)          │
├─────────────────────────────────────────────────────────┤
│ Mathematical operation:                                 │
│                                                         │
│ For each combination:                                   │
│   Mean_VAF = Σ(VAF) / N                                │
│                                                         │
│ Example: let-7a, position 6, ALS                       │
│   VAF values from 313 ALS samples:                     │
│   [0.020, 0.010, 0.015, 0.000, 0.025, ...]            │
│                                                         │
│   Mean_VAF_ALS = (0.020 + 0.010 + ... + 0.025) / 313  │
│                = 0.0180                                 │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ OUTPUT: Summary table                                   │
├─────────────────────────────────────────────────────────┤
│   miRNA      position   Group     Mean_VAF             │
│   let-7a     6          ALS       0.0180               │
│   let-7a     6          Control   0.0220               │
│   let-7a     7          ALS       0.0150               │
│   let-7a     7          Control   0.0180               │
│   miR-9      3          ALS       0.0250               │
│   miR-9      3          Control   0.0300               │
│   ...                                                   │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 5: CALCULATE DIFFERENTIAL (ALS - CONTROL)**

```
┌─────────────────────────────────────────────────────────┐
│ MERGE AND SUBTRACT                                      │
├─────────────────────────────────────────────────────────┤
│ Code:                                                   │
│   vaf_als <- filter(Group == "ALS")                    │
│   vaf_ctrl <- filter(Group == "Control")               │
│   differential <- full_join(vaf_als, vaf_ctrl)         │
│   differential$Diff = VAF_ALS - VAF_Control            │
│                                                         │
│ Mathematical operation:                                 │
│   Δ = VAF_ALS - VAF_Control                            │
│                                                         │
│ Example: let-7a, position 6                            │
│   VAF_ALS = 0.0180                                     │
│   VAF_Control = 0.0220                                 │
│   Differential = 0.0180 - 0.0220 = -0.0040            │
│                                                         │
│ Interpretation:                                         │
│   Negative (-0.0040) → Control has MORE G>T            │
│   Magnitude: 0.004 difference in VAF                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ OUTPUT: Differential table                              │
├─────────────────────────────────────────────────────────┤
│   miRNA      position   VAF_ALS   VAF_Control   Diff   │
│   let-7a     6          0.0180    0.0220        -0.004 │
│   let-7a     7          0.0150    0.0180        -0.003 │
│   miR-9      3          0.0250    0.0300        -0.005 │
│   ...                                                   │
│                                                         │
│ Total rows: ~1,361 (miRNA-position combinations)       │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 6: CREATE HEATMAP MATRIX**

```
┌─────────────────────────────────────────────────────────┐
│ PIVOT TO MATRIX FORMAT                                  │
├─────────────────────────────────────────────────────────┤
│ Rows: 301 miRNAs (ranked by total G>T burden)          │
│ Columns: 22 positions                                   │
│ Values: Differential (ALS - Control)                    │
│                                                         │
│ Matrix structure:                                       │
│                                                         │
│         pos1   pos2   pos3  ...  pos6   ...  pos22     │
│   miR-1  0.00  +0.01  -0.02 ... -0.004 ... +0.001      │
│   miR-2  +0.01  0.00  -0.01 ... +0.002 ... -0.003      │
│   ...                                                   │
│   miR-301 0.00  0.00   0.00 ...  0.000 ...  0.000      │
│                                                         │
│ Dimensions: 301 × 22 = 6,622 cells                     │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 7: MAP TO COLORS**

```
┌─────────────────────────────────────────────────────────┐
│ COLOR SCALE (diverging)                                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   Blue ←───────── White ───────→ Red                   │
│   (Control)      (Equal)        (ALS)                   │
│                                                         │
│ Mathematical mapping:                                   │
│                                                         │
│   Diff = -0.110  →  Blue (darkest)   ← Max Control    │
│   Diff = -0.050  →  Blue (medium)                      │
│   Diff = -0.010  →  Blue (light)                       │
│   Diff =  0.000  →  White                              │
│   Diff = +0.005  →  Red (light)                        │
│   Diff = +0.010  →  Red (medium)                       │
│   Diff = +0.013  →  Red (darkest)    ← Max ALS         │
│                                                         │
│ Scale centered at 0 (symmetric)                         │
│ Limits: [-0.110, +0.013]                               │
└─────────────────────────────────────────────────────────┘
                         ↓
```

---

### **STEP 8: FINAL VISUALIZATION**

```
┌─────────────────────────────────────────────────────────┐
│ FINAL HEATMAP                                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   Y-axis: 301 miRNAs (no labels, too many)            │
│   X-axis: 22 positions (labeled 1-22)                  │
│   Colors: Blue-White-Red (differential scale)          │
│   Markers: Dashed lines at positions 2 and 8 (seed)    │
│                                                         │
│   Visual result:                                        │
│   ┌──────────────────────────────────┐                 │
│   │ ┊     SEED      ┊                │                 │
│   │ ┊ (marked)     ┊                │                 │
│   │█████████████████████████████████│ ← miRNA 1       │
│   │█████████████████████████████████│ ← miRNA 2       │
│   │█████████████████████████████████│                 │
│   │ ... (301 rows)                   │                 │
│   │█████████████████████████████████│ ← miRNA 301     │
│   └──────────────────────────────────┘                 │
│    1  2  3  4  5  6  7  8  9  ... 22                   │
│                                                         │
│ Color intensity = Magnitude of difference              │
└─────────────────────────────────────────────────────────┘
```

---

## 🔬 **MATHEMATICAL FORMULAS**

### **Formula 1: Mean VAF per group**

```
For each (miRNA i, position p, group g):

                    N_g
                    Σ   VAF_i,p,s
                   s=1
Mean_VAF_i,p,g = ─────────────────
                      N_g

Where:
   i = miRNA index (1 to 301)
   p = position (1 to 22)
   g = group (ALS or Control)
   s = sample index
   N_g = number of samples in group g
       N_ALS = 313
       N_Control = 102

Example:
   Mean_VAF_let-7a,6,ALS = (VAF_s1 + VAF_s2 + ... + VAF_s313) / 313
```

---

### **Formula 2: Differential**

```
For each (miRNA i, position p):

Δ_i,p = Mean_VAF_i,p,ALS - Mean_VAF_i,p,Control

Where:
   Δ > 0  →  ALS has more G>T (red)
   Δ = 0  →  No difference (white)
   Δ < 0  →  Control has more G>T (blue)

Example:
   Δ_let-7a,6 = 0.0180 - 0.0220 = -0.0040
   
   Interpretation: Control has 0.004 more VAF at this position
```

---

## 📊 **NUMERICAL EXAMPLE (COMPLETE WALKTHROUGH)**

### **Example: hsa-let-7a-5p, position 6**

#### **Step-by-step calculation:**

**1. Extract raw VAF values:**
```
SNV: "hsa-let-7a-5p 6:GT"

ALS samples (313 total):
   ALS-1: VAF = 0.0200
   ALS-2: VAF = 0.0100
   ALS-3: VAF = 0.0150
   ALS-4: VAF = 0.0000
   ...
   ALS-313: VAF = 0.0250
```

**2. Calculate mean for ALS:**
```
Mean_VAF_ALS = (0.0200 + 0.0100 + 0.0150 + 0.0000 + ... + 0.0250) / 313
             = 0.0180
```

**3. Extract Control values:**
```
Control samples (102 total):
   Control-1: VAF = 0.0250
   Control-2: VAF = 0.0200
   Control-3: VAF = 0.0180
   ...
   Control-102: VAF = 0.0300
```

**4. Calculate mean for Control:**
```
Mean_VAF_Control = (0.0250 + 0.0200 + 0.0180 + ... + 0.0300) / 102
                 = 0.0220
```

**5. Calculate differential:**
```
Differential = Mean_VAF_ALS - Mean_VAF_Control
             = 0.0180 - 0.0220
             = -0.0040
```

**6. Interpret:**
```
Δ = -0.0040  (negative)
   → Control > ALS
   → Difference magnitude: 0.004 (0.4%)
   → Color in heatmap: Light blue
```

---

## 🎨 **COLOR MAPPING SCALE**

### **Actual values from analysis:**

```
Range of differentials:
   Minimum: -0.110317  (most Control-elevated)
   Maximum: +0.012739  (most ALS-elevated)

Scale is ASYMMETRIC:
   Control side is LARGER (more negative values)
   Consistent with global finding: Control > ALS

Color mapping:
   ┌────────────────────────────────────────────┐
   │                                            │
   │  Diff = -0.110  [Blue darkest]  ← miR-6133│
   │  Diff = -0.050  [Blue dark]               │
   │  Diff = -0.020  [Blue medium]             │
   │  Diff = -0.005  [Blue light]              │
   │  Diff = -0.001  [Blue very light]         │
   │  Diff =  0.000  [White]         ← No diff │
   │  Diff = +0.001  [Red very light]          │
   │  Diff = +0.005  [Red light]               │
   │  Diff = +0.010  [Red medium]              │
   │  Diff = +0.013  [Red darkest]   ← Max ALS │
   │                                            │
   └────────────────────────────────────────────┘
```

---

## 🔍 **WHY MOST CELLS ARE NEAR WHITE (SMALL VALUES)?**

### **Explanation:**

**Actual differential values are VERY SMALL:**

```
Statistics:
   Mean differential: -0.000288  (very close to 0)
   Median: 0.00000669            (almost 0)
   SD: 0.004144                  (small variability)

Distribution:
   • Most cells: -0.005 to +0.005 (very light colors)
   • Few cells: < -0.01 or > +0.01 (darker colors)
   • Extreme: miR-6133 at -0.11 (dark blue)
```

---

### **Why are differences so small?**

**Reason 1: Low VAF values overall**
```
Typical VAF: 0.0001 to 0.01 (0.01% to 1%)
Difference: Even smaller (0.0001 range)

Example:
   ALS: 0.0015
   Control: 0.0020
   Diff: 0.0005 (tiny!)
```

**Reason 2: High within-group variability**
```
Within ALS samples:
   Some: VAF = 0.05
   Others: VAF = 0.00
   Mean: 0.015
   
Within Control samples:
   Similar spread
   
Mean difference is SMALL compared to variance
```

**Reason 3: Distributed effect**
```
From Fig 2.1-2.2: Control > ALS globally (p < 1e-12)

But this is from:
   • Many small differences across positions
   • Accumulated across all miRNAs
   
NOT from:
   • Large differences in specific positions
```

---

## 📊 **COMPARISON: OLD FIG 2.5 vs NEW FIG 2.5**

### **OLD (Z-score):**

```
┌───────────────────────────────────────────────────────┐
│ Z-SCORE HEATMAP (old)                                 │
├───────────────────────────────────────────────────────┤
│ Rows: 100 (50 miRNAs × 2 groups, DUPLICATED)        │
│ Values: Z-score normalized PER ROW                    │
│                                                       │
│ Calculation per cell:                                 │
│   For miRNA i in group g:                            │
│   Z_i,g,p = (VAF_i,g,p - μ_i,g) / σ_i,g             │
│                                                       │
│   Where μ and σ are FROM THAT ROW ONLY               │
│                                                       │
│ Result:                                               │
│   • Each row normalized independently                 │
│   • Cannot compare ALS vs Control                     │
│   • Shows "outlier positions" within each miRNA       │
│   • Lots of red/blue (normalized highlights)          │
└───────────────────────────────────────────────────────┘
```

---

### **NEW (Differential):**

```
┌───────────────────────────────────────────────────────┐
│ DIFFERENTIAL HEATMAP (new)                            │
├───────────────────────────────────────────────────────┤
│ Rows: 301 (ALL miRNAs, NO duplication)               │
│ Values: Direct subtraction (ALS - Control)            │
│                                                       │
│ Calculation per cell:                                 │
│   Δ_i,p = Mean_VAF_i,p,ALS - Mean_VAF_i,p,Control    │
│                                                       │
│ Result:                                               │
│   • Direct comparison ALS vs Control                  │
│   • Preserves absolute magnitude                      │
│   • Shows actual differences                          │
│   • Mostly white/light (small differences)            │
│   • Few dark cells (large differences)                │
└───────────────────────────────────────────────────────┘
```

---

## 🔥 **KEY DIFFERENCES EXPLAINED**

### **Why OLD had more colors?**

**Z-score normalization AMPLIFIES small variations:**

```
miRNA with uniform low VAF:
   [0.0001, 0.0001, 0.0001, 0.0002, 0.0001]
   Mean = 0.00012, SD = 0.00004
   
   Position 4 (0.0002):
   Z = (0.0002 - 0.00012) / 0.00004 = +2.0
   → Shows as RED (high Z-score)
   
But absolute difference is TINY (0.0002 vs 0.0001)!
```

**Result:**
- OLD: Many red/blue cells (normalized deviations)
- NEW: Mostly white (actual differences are small)

---

### **Why NEW is more accurate?**

**Shows REAL magnitude of differences:**

```
OLD (Z-score):
   Cell A: Red (+2 Z) → Could be 0.0002 difference
   Cell B: Red (+2 Z) → Could be 0.0200 difference
   → Can't distinguish magnitude

NEW (Differential):
   Cell A: Light red (+0.0002)
   Cell B: Dark red (+0.0200)
   → Clear magnitude difference
```

---

## 💡 **INTERPRETATION GUIDE**

### **What to look for in the heatmap:**

**1. Overall color:**
```
Predominantly blue → Control > ALS (majority)
Predominantly red → ALS > Control
Mixed → Heterogeneous
```

**2. Vertical patterns (columns):**
```
Entire column blue → That position elevated in Control across miRNAs
Entire column red → That position elevated in ALS
```

**3. Horizontal patterns (rows):**
```
Entire row blue → That miRNA elevated in Control across positions
Entire row red → That miRNA elevated in ALS
```

**4. Hotspots (dark colors):**
```
Dark blue cell → Large difference (Control >> ALS)
Dark red cell → Large difference (ALS >> Control)

Example: miR-6133 
   → Dark blue streak
   → Control much greater for this miRNA
```

---

## ✅ **SUMMARY**

### **Data used:**
- **All 301 miRNAs** with G>T in seed
- **All positions** 1-22 (not just seed)
- **All 415 samples** (313 ALS + 102 Control)

### **Calculation:**
```
Each cell = Mean_VAF_ALS - Mean_VAF_Control
```

### **Interpretation:**
- Mostly light colors → Small differences (consistent with distributed effect)
- Few dark cells → Specific hotspots (e.g., miR-6133)
- Overall blue tint → Control > ALS (consistent with Fig 2.1-2.2)

### **Why different from OLD:**
- OLD: Normalized per row (amplifies small variations)
- NEW: Direct differences (shows real magnitude)
- NEW is more biologically accurate

---

**This figure is now consistent with all other Step 2 figures:**
- Uses ALL available data (301 miRNAs)
- Compares ALS vs Control directly
- Professional English labels

---

**Created:** 2025-10-24  
**Status:** Ready for approval ✅

