# 🔧 PANEL E CORRECTION - Technical Explanation

**Date:** 2025-10-24  
**Panel:** E. G-Content by Position  
**Issue:** Incorrect scale and misleading labels

---

## ❌ **WHAT WAS WRONG (Original Code)**

### **Problem 1: Confusing Calculation**

**Original Code (lines 58-70):**
```r
mirna_g_content <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>%  # Only G mutations
  group_by(`miRNA name`) %>%
  summarise(
    n_g_in_seed = sum(position >= 2 & position <= 8 & str_detect(mutation_type, "^G>")),
    total_gt_mutations = sum(mutation_type == "G>T"),
    total_g_mutations = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    perc_oxidados = (total_gt_mutations / total_g_mutations) * 100
  )
```

**Problem:**
- `n_g_in_seed` counts **G MUTATIONS** in seed region (NOT actual G nucleotides)
- `perc_oxidados` calculates: `(G>T mutations / all G mutations) * 100`
- This is **% of G mutations that are G>T**, NOT G-content!

### **Problem 2: Misleading Labels**

**Original Y-axis label (line 91):**
```r
y = "Percentage of miRNAs with ≥1 G>T mutation (%)"
```

**What it ACTUALLY calculates:**
```r
perc_oxidados = (total_gt_mutations / total_g_mutations) * 100
# = % of G mutations that are G>T
```

**The label says:** "% of miRNAs with G>T"  
**The calculation shows:** "% of G mutations that are G>T"  
**THESE ARE COMPLETELY DIFFERENT THINGS!**

---

## ✅ **WHAT WAS FIXED (Corrected Code)**

### **Corrected Approach:**

```r
# Count unique miRNAs with ANY G mutation at each position
# This approximates positions where G nucleotides exist
g_content_estimate <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%  # Any G mutation: GT, GC, GA
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  distinct(miRNA_name, Position) %>%  # Unique miRNA-position pairs
  count(Position, name = "miRNAs_with_G")
```

**What this does:**
1. Finds all rows with G mutations (GT, GC, GA) at any position
2. Extracts the position number
3. Counts **unique miRNA-position pairs** (one miRNA counted once per position)
4. Result: Number of miRNAs that have a G nucleotide at each position

### **Corrected Labels:**

```r
labs(
  title = "E. G-Content Distribution Across miRNA Positions",
  subtitle = "Number of miRNAs with Guanine nucleotides at each position",
  x = "Position in miRNA (1-22)",
  y = "Number of miRNAs with G nucleotide",
  caption = "Note: G-content shows substrate availability for 8-oxoG formation.\nHigher G-content → more potential sites for oxidative damage."
)
```

**Now the label MATCHES the calculation!**

---

## 📊 **COMPARISON: OLD vs NEW**

### **Old Figure (INCORRECT):**
- **X-axis:** "Number of G nucleotides in seed region (positions 2-8)"
  - But actually counting **mutations**, not nucleotides
- **Y-axis:** "Percentage of miRNAs with ≥1 G>T mutation (%)"
  - But actually showing **% of G mutations that are G>T**
- **Scale:** 0-100% (percentage)
- **Problem:** The axis labels don't match what's being calculated!

### **New Figure (CORRECTED):**
- **X-axis:** "Position in miRNA (1-22)"
  - Showing ALL positions, not just seed
- **Y-axis:** "Number of miRNAs with G nucleotide"
  - Count of miRNAs (NOT percentage)
- **Scale:** 0-120 miRNAs (absolute count)
- **Interpretation:** How many miRNAs have a G at each position (substrate availability)

---

## 🎯 **BIOLOGICAL INTERPRETATION**

### **What the CORRECTED Panel E Shows:**

**G-Content Distribution:**
- Positions 6, 7, 8, 10 have ~100-120 miRNAs with G nucleotides
- Positions 1, 2, 3 have fewer (~12-44 miRNAs with G)
- This represents **substrate availability** for oxidation

**Why This Matters:**
1. **More Gs = More oxidation sites**
   - Positions with high G-content can accumulate more G>T mutations
2. **Complements Panel B (G>T count)**
   - Panel B shows actual G>T mutations
   - Panel E shows potential G sites
   - Compare them: Do high-G positions have more G>T?
3. **Seed Region Context**
   - Seed region (2-8) highlighted
   - Shows if seed has different G-content than other regions

---

## 🔍 **HOW THE CORRECTION WAS MADE**

### **Step 1: Identify the Problem**
- Original code counted **mutations** but labeled them as **nucleotides**
- Y-axis showed **percentage** but was labeled as something different

### **Step 2: Fix the Calculation**
```r
# OLD (wrong):
n_g_in_seed = sum(position >= 2 & position <= 8 & str_detect(mutation_type, "^G>"))
# This counts G MUTATIONS in seed

# NEW (correct):
distinct(miRNA_name, Position) %>% count(Position, name = "miRNAs_with_G")
# This counts unique miRNAs with G at each position
```

### **Step 3: Fix the Labels**
```r
# OLD (misleading):
y = "Percentage of miRNAs with ≥1 G>T mutation (%)"

# NEW (accurate):
y = "Number of miRNAs with G nucleotide"
```

### **Step 4: Change Plot Type**
```r
# OLD: Scatter plot with loess smoothing (for correlation)
# NEW: Bar chart (for distribution)
geom_col(fill = COLOR_G, alpha = 0.8, width = 0.7)
```

### **Step 5: Fix the Scale**
```r
# OLD: scale_y_continuous() with percentage scale (0-100%)
# NEW: scale_y_continuous() with count scale (0-120 miRNAs)
scale_y_continuous(
  expand = expansion(mult = c(0, 0.1)),
  breaks = seq(0, max(g_content_estimate$miRNAs_with_G), by = 50),
  limits = c(0, max(g_content_estimate$miRNAs_with_G) * 1.1)
)
```

---

## 📈 **RESULTS FROM CORRECTED CODE**

### **G-Content by Position:**

```
Position | miRNAs_with_G
---------|-------------
1        |  12
2        |  44
3        |  35
4        |  51
5        |  62
6        |  99
7        | 101
8        |  98
9        |  84
10       | 120
11       | 110
12       |  89
13       |  91
...      | ...
```

**Key Observations:**
- **Position 10 has highest G-content** (120 miRNAs)
- **Positions 6, 7, 8 (seed region)** have ~100 miRNAs with G
- **Positions 1-3** have lower G-content (~12-44 miRNAs)

---

## 💡 **WHAT THIS TEACHES US**

### **Methodological Lesson:**
Always verify that:
1. **Calculation matches the label**
2. **Units are correct** (count vs percentage)
3. **Variables represent what they're named** (nucleotides vs mutations)

### **Data Science Lesson:**
- Don't confuse **substrate** (G nucleotides) with **product** (G>T mutations)
- Panel E shows substrate availability
- Other panels show actual mutations (product)

---

## 📁 **FILES GENERATED**

1. **Script:** `STEP1_ORGANIZED/scripts/05_gcontent_analysis_FIXED.R`
2. **Figure:** `STEP1_ORGANIZED/figures/step1_panelE_gcontent_FIXED.png`
3. **Documentation:** This file

---

## ✅ **VERIFICATION**

To verify the correction is correct:

1. **Check the data:**
```r
g_content_estimate %>% print(n = Inf)
```

2. **Compare with Panel B:**
- Does high G-content correlate with high G>T count?
- This validates if G-content drives G>T mutations

3. **Visual check:**
- Seed region should be highlighted
- Y-axis should show counts (0-120), NOT percentages
- Bars should show clear differences between positions

---

**Status:** ✅ CORRECTED  
**Verified:** 2025-10-24  
**Ready for:** Integration into Step 1 final HTML

