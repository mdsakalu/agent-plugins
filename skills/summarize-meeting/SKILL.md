---
name: summarize-meeting
description: Generates comprehensive meeting summaries from Zoom recordings. Extracts frames, processes transcripts, analyzes chat logs, and creates detailed documentation. Use when the user wants to summarize a meeting, process Zoom recordings, or create meeting notes from video files.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
license: MIT
metadata:
  version: 2.2.0
  updated: 2026-01-09
  spec-version: agentskills.io/2026
compatibility: |
  Requires: ffmpeg (frame extraction), Python 3.10+.
  Optional: whisper.cpp (transcription if no VTT), steipete/summarize (comparison).
  Claude Code only - requires local filesystem access and Bash execution.
---

# Summarize Meeting

## Quick Start

```bash
# Basic usage - summarize a Zoom recording
/summarize-meeting /path/to/zoom-recording/

# Or specify a video file directly
/summarize-meeting /path/to/meeting.mp4
```

The skill will locate video, transcript (.vtt), and chat files, extract frames, and generate a comprehensive `<video-name> - Summary/README.md`.

## Core Principle

When in doubt, include more detail. A 500-line document that captures everything is better than a 100-line summary that loses nuance.

---

## Processing Pipeline

### Step 1: Locate Meeting Files

Search the given path for:
- **Video:** `.mp4`, `.m4a`
- **Transcript:** `.vtt`, `.srt` (required, or generate with whisper.cpp)
- **Chat:** `*Chat.txt`, `*chat.txt` (optional but valuable)

### Step 2: Check/Install Dependencies

Verify and install if missing:

```bash
# ffmpeg - frame extraction
brew install ffmpeg

# whisper.cpp - transcription (if no VTT)
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp && cmake -B build && cmake --build build --config Release
./models/download-ggml-model.sh base.en

# steipete/summarize - comparison analysis
git clone https://github.com/steipete/summarize.git
cd summarize && pnpm install
```

### Step 3: Extract Frames

Choose extraction settings based on **video type and duration**:

#### For UI Demonstrations / Training Videos (under 15 minutes)

UI demos require **high-frequency capture** because subtle interactions (clicking menus, selecting options, scrolling) don't trigger scene detection:

```bash
# Primary: Fixed interval every 5 seconds (REQUIRED for UI demos)
ffmpeg -i <video> -vf "fps=1/5,scale=1280:-1" -q:v 2 frames/frame_%04d.jpg

# Secondary: Low-threshold scene detection (catches major transitions)
ffmpeg -i <video> -vf "select='gt(scene,0.1)',scale=1280:-1" -vsync vfr frames_scene/frame_%04d.jpg
```

**Expected frame counts for UI demos:**
- 2-minute video: ~24 frames
- 5-minute video: ~60 frames
- 10-minute video: ~120 frames

#### For Meetings / Presentations (15+ minutes)

Longer meetings with less UI interaction can use sparser extraction:

```bash
# Primary: Scene detection with moderate threshold
ffmpeg -i <video> -vf "select='gt(scene,0.2)',scale=1280:-1" -vsync vfr frames_scene/frame_%04d.jpg

# Secondary: Fixed interval every 30 seconds
ffmpeg -i <video> -vf "fps=1/30,scale=1280:-1" -q:v 2 frames/frame_%04d.jpg
```

#### Frame Extraction Decision Table

| Video Type | Duration | Fixed Interval | Scene Threshold | Expected Frames |
|------------|----------|----------------|-----------------|-----------------|
| UI demo/training | < 5 min | 5 seconds | 0.1 | 12 per minute |
| UI demo/training | 5-15 min | 5 seconds | 0.1 | 12 per minute |
| Presentation | 15-30 min | 15 seconds | 0.2 | 4 per minute |
| Meeting | 30-60 min | 30 seconds | 0.2 | 2 per minute |
| Long meeting | 60+ min | 60 seconds | 0.3 | 1 per minute |

**Important:** When in doubt, extract MORE frames. It's better to have 100 frames and select the best 20 for the visual timeline than to miss key UI interactions.

---

## Parallelization Strategy

To maximize efficiency, parallelize operations that don't depend on each other.

### Single Video Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: Extraction (3 parallel Bash calls)                 │
├─────────────────────────────────────────────────────────────┤
│  ffmpeg -i video.mp4 audio.wav           ─┐                 │
│  ffmpeg -i video.mp4 -vf "fps=1/5" ...    ├── simultaneous  │
│  ffmpeg -i video.mp4 -vf "select=..." ... ─┘                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: Processing (parallel transcription + frame reads)  │
├─────────────────────────────────────────────────────────────┤
│  whisper-cli transcribe    ─┐                               │
│  Read frames 1-8            │                               │
│  Read frames 9-16           ├── simultaneous                │
│  Read frames 17-24          │                               │
│  Read frames 25-32         ─┘                               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: Write summary (sequential - needs all context)     │
└─────────────────────────────────────────────────────────────┘
```

#### Phase 1: Parallel Extraction

Run these three ffmpeg commands in parallel (single message with 3 Bash tool calls):

```bash
# Call 1: Extract audio
ffmpeg -y -i <video> -ar 16000 -ac 1 -c:a pcm_s16le audio.wav

# Call 2: Extract frames at fixed intervals (5 sec for UI demos)
ffmpeg -y -i <video> -vf "fps=1/5,scale=1280:-1" -q:v 2 frames/frame_%04d.jpg

# Call 3: Extract scene-detection frames
ffmpeg -y -i <video> -vf "select='gt(scene,0.1)',scale=1280:-1" -vsync vfr frames_scene/frame_%04d.jpg
```

#### Phase 2: Parallel Transcription + Frame Analysis

Once Phase 1 completes, run transcription and frame reading in parallel:

```
# Single message with multiple tool calls:
- Bash: whisper-cli transcribe audio.wav
- Read: frames/frame_0001.jpg
- Read: frames/frame_0002.jpg
- Read: frames/frame_0003.jpg
- Read: frames/frame_0004.jpg
- Read: frames/frame_0005.jpg
- Read: frames/frame_0006.jpg
- Read: frames/frame_0007.jpg
- Read: frames/frame_0008.jpg
```

**Batch size:** 8 frames per parallel batch works well. Continue with additional batches until all frames are read.

#### Phase 3: Write Summary

Sequential - requires all transcript and frame data to be collected first.

### Multiple Videos Pipeline

When processing multiple videos in a folder, use **parallel Task agents**:

```bash
# Instead of processing sequentially:
# Video 1 → Summary 1 → Video 2 → Summary 2 → Video 3 → Summary 3

# Process in parallel with Task agents:
Task (Video 1) ──→ Summary 1 ─┐
Task (Video 2) ──→ Summary 2 ─├── All complete simultaneously
Task (Video 3) ──→ Summary 3 ─┘
```

Launch parallel agents with:
```
Task (subagent_type: general-purpose):
  "Process video: /path/to/video1.mp4
   1. Create output folder '<video-name> - Summary/'
   2. Extract audio + frames (parallel ffmpeg calls)
   3. Transcribe with whisper.cpp
   4. Analyze all frames
   5. Write comprehensive README.md following the summarize-meeting skill format"
```

**Note:** Each agent runs the full single-video pipeline independently.

### Parallelization Checklist

| Operation | Parallelize With | Notes |
|-----------|------------------|-------|
| Audio extraction | Frame extraction | Both read from video |
| Fixed-interval frames | Scene-detection frames | Independent ffmpeg calls |
| Whisper transcription | Frame reading | Transcription is CPU-bound |
| Reading frame batch 1 | Reading frame batch 2 | Up to 8 frames per batch |
| Video 1 processing | Video 2 processing | Use separate Task agents |

### What NOT to Parallelize

- **Writing summary** - needs all context first
- **Frame reading within same batch** - already parallelized by batch
- **Dependent operations** - e.g., transcription needs audio first

---

### Step 4: Read All Source Material

Read the **entire transcript** - do not skip or sample. For long transcripts:
- Read in chunks (500 lines at a time)
- Take notes on each chunk
- Build comprehensive understanding before writing

Read the **complete chat file** - every message may contain important context.

### Step 5: Analyze All Frames

Review **every extracted frame** with Claude vision:
1. Identify what's being shown (UI, diagram, code, person speaking, etc.)
2. Note timestamp association
3. Rate importance (1-5) for inclusion in visual timeline
4. Capture any visible text, labels, or data

**Do not skip frames.** Create a complete catalogue.

### Step 6: Run Comparison Tool

```bash
pnpm summarize --cli claude <transcript.vtt>
```

Compare results and **add any details** the tool caught that you missed.

### Step 7: Generate Output

Create `<path>/<video-name> - Summary/` (e.g., `Building a Q - Summary/` for `Building a Q.mp4`):
- `README.md` - comprehensive summary (expect 400-600+ lines for a 1-hour meeting)
- `frames/` - ALL extracted frames, not just highlights

---

## Required Document Structure

The output document MUST include ALL of the following sections. Do not omit or combine sections.

### 1. Header Block

```markdown
# [Meeting Title]

**Date:** [Full date]
**Duration:** [X minutes]
**Presenter:** [Primary speaker]
**Topic:** [Descriptive topic]

**Attendees:** [List ALL participants visible/audible in recording]
- Name 1 (role if known)
- Name 2 (role if known)
- ...

---
```

### 2. Executive Summary

A comprehensive overview (not a brief paragraph). Include:
- **Context:** Why this meeting happened
- **Key Points:** 5-10 bullet points covering main topics
- **Decisions Made:** Any conclusions reached
- **Outcomes:** What changed as a result

### 3. Background/Problem Statement (if applicable)

If the meeting discusses a problem or migration:
- **What was the old system/situation?**
- **What were the problems?** (detailed list with specific examples)
- **Why did it need to change?**

Use narrative format with subsections, not just tables.

### 4. Solution/Architecture (if applicable)

For technical meetings:
- **Overview diagram** (reference frame)
- **Component-by-component walkthrough** with numbered steps
- **Each component should have:**
  - Name and technology
  - What it does (in detail)
  - Why it was designed this way
  - Notable quotes from presenter

Example structure:
```markdown
#### Step 1: [Component Name]

- **Technology:** [Stack details]
- **Function:** [What it does]
- **Design rationale:** [Why this approach]

> "[Relevant quote from presenter]" - [Name]
```

### 5. Visual Timeline

**Detailed, timestamped walkthrough** of what was shown. For EACH significant frame:

```markdown
### [Timestamp] - [Descriptive Title]

![Description](frames/frame_XXXX.jpg)

**What's shown:** [Detailed description of the visual]

**Context:** [What was being discussed at this time]

**Key details visible:**
- [Specific item 1]
- [Specific item 2]
- [Data/text visible in screenshot]

**Relevance:** [Why this matters]

---
```

Include **10-20 detailed frame analyses** for a 1-hour meeting, not 5-7.

#### Image Embedding Guidelines

**Embed important frames inline** in the narrative using markdown syntax:

```markdown
![Descriptive alt text](frames/frame_0015.jpg)
```

**How many frames to embed inline:**

| Video Duration | Total Frames | Embed Inline | Link in Reference |
|----------------|--------------|--------------|-------------------|
| < 3 min | ~30 | 8-12 key frames | All 30 |
| 3-10 min | 30-120 | 15-25 key frames | All frames |
| 10-15 min | 120-180 | 25-40 key frames | All frames |
| 15+ min | 180+ | 30-50 key frames | All frames |

**What to embed inline:**
- Key UI states (dialogs opening, dropdowns expanded)
- Important workflow steps (before/after actions)
- Results and confirmations (success messages, search results)
- Diagrams and reference materials
- Transitions between major sections

**What NOT to embed inline:**
- Redundant frames showing same/similar content
- Transitional frames with no new information
- Every frame in a sequence (pick representative ones)

**Complete Frame Reference table** at the end of the document should list ALL frames as **clickable links**, not embedded images:

```markdown
## Complete Frame Reference

<details>
<summary>Click to see all N frames</summary>

| Frame | Time | Description |
|-------|------|-------------|
| [frame_0001.jpg](frames/frame_0001.jpg) | 0:00 | Initial view |
| [frame_0002.jpg](frames/frame_0002.jpg) | 0:05 | Menu opening |
| ... | ... | ... |

</details>
```

**Key principles:**
1. Each frame appears **once** as an embedded image (in narrative context)
2. **All frames** appear as clickable links in the reference table
3. No redundant "frame gallery" sections embedding every frame
4. Inline embeds show the image where it's being discussed
5. Reference table provides access to complete frame set

### 6. Process/Migration Story (if applicable)

If the meeting covers a process or migration:
- **The Challenge:** What needed to happen
- **Initial Approach:** What was tried first
- **Final Solution:** What actually worked
- **Verification:** How success was measured
- **Edge Cases/Bugs:** Problems encountered and how they were solved

Include **specific numbers, dates, and details**.

### 7. Technical Details

Multiple tables covering:

```markdown
### Database Tables
| Table | Purpose | Key Fields |
|-------|---------|------------|
| ... | ... | ... |

### System Components
| Component | Technology | Replicas/Scale | Notes |
|-----------|------------|----------------|-------|
| ... | ... | ... | ... |

### Configuration
| Setting | Value | Why |
|---------|-------|-----|
| ... | ... | ... |

### Retention Policies
| Location | Retention | Notes |
|----------|-----------|-------|
| ... | ... | ... |
```

### 8. Testing & Development

- **Test environments** (with specific names/IDs)
- **How to test locally**
- **Integration test coverage**
- **Test data/accounts available**

### 9. Debugging & Monitoring

- **Dashboards:** Names and what they show
- **Key metrics:** What to watch
- **Log queries:** How to find issues
- **Tools:** What utilities exist

### 10. Chat Highlights

**Full table format** with timestamps:

```markdown
| Time | Participant | Message/Context |
|------|-------------|-----------------|
| 28:57 | Name | "Exact quote or paraphrase" |
| ... | ... | ... |
```

Include ALL substantive chat messages, not just a few highlights.

### 11. Action Items

Comprehensive list with assignees if mentioned:

```markdown
- [ ] **[Task]** - [Details] (Owner: [Name] if known)
- [ ] **[Task]** - [Details]
```

### 12. Key Contacts

```markdown
| Role | Person | Notes |
|------|--------|-------|
| ... | ... | ... |
```

### 13. Quotes Worth Remembering

Extract 5-10 memorable/important quotes:

```markdown
> "[Quote]" - [Speaker], on [context]

> "[Quote]" - [Speaker]
```

### 14. Technical References

Comprehensive list of everything mentioned:
- Database tables
- APIs/endpoints
- Repositories/PRs
- Documentation links
- Tools/utilities
- Related systems

### 15. Complete Frame Reference

**Catalogue ALL frames**, not just key ones:

```markdown
<details>
<summary>Click to see all [N] frames</summary>

| Time | Frame | Description |
|------|-------|-------------|
| 0:00 | [frame_0001.jpg](frames/frame_0001.jpg) | [What's shown] |
| 1:00 | [frame_0002.jpg](frames/frame_0002.jpg) | [What's shown] |
| ... | ... | ... |

</details>
```

### 16. Full Transcript

```markdown
<details>
<summary>Click to expand full transcript</summary>

See: [transcript_filename.vtt](transcript_filename.vtt)

</details>
```

---

## Quality Standards

### Detail Requirements

- **Minimum document length:** 400 lines for a 30-min meeting, 600+ lines for 1-hour
- **Frame coverage:** Catalogue 100% of fixed-interval frames, analyze 100% of scene-detection frames
- **Chat coverage:** Include every substantive message
- **Quote extraction:** Minimum 5 memorable quotes
- **Attendee identification:** List everyone who speaks or is mentioned

### Accuracy Requirements

- **Verify names:** Cross-reference chat and transcript for correct spellings
- **Verify numbers:** Double-check statistics, counts, percentages mentioned
- **Verify technical terms:** Ensure correct spelling of tools, services, table names
- **Cross-reference:** Use steipete/summarize output to catch missed details

### Organization Requirements

- **Use headings liberally:** H2 for major sections, H3 for subsections, H4 for components
- **Use horizontal rules:** Separate major sections with `---`
- **Use collapsible sections:** For very long content (frame lists, transcripts)
- **Use tables:** For structured data, but NOT as a substitute for narrative
- **Use blockquotes:** For direct quotes from speakers

### What NOT to Do

- Do NOT summarize when you can be specific
- Do NOT use "various" or "several" when you can list items
- Do NOT combine sections to save space
- Do NOT skip frames because they "look similar"
- Do NOT paraphrase when exact quotes are available
- Do NOT omit technical details because they seem minor
- Do NOT truncate chat highlights to "key messages only"

---

## Example: Good vs Bad

### Bad (too condensed):

```markdown
## Architecture

The new system uses cloud services to process documents more reliably than the old approach.
```

### Good (appropriately detailed):

```markdown
## The New System Architecture

### Design Philosophy

The presenter explained the core design principles that guided the architecture:

1. **Never lose data:** Raw files stored in object storage for 30 days enables recovery from any bug
2. **Database independence:** The worker service operates without database connectivity
3. **Scalable processing:** Cloud infrastructure can scale; the vendor API cannot

> "I want this to work without the database." - [Presenter], explaining the resilience design

### Component-by-Component Flow

#### Step 1: Input Source → Vendor API

Documents arrive via the vendor's managed service. Processing typically takes 2-5 minutes per document.

#### Step 2: Polling Service

- **Deployment:** `document-poller` (Kubernetes)
- **Replicas:** 2-3 (limited by vendor rate limiting)
- **Technology:** Python with cloud SDK
- **Function:** Continuously polls vendor REST API for new documents

The poller receives a JSON payload containing:
- Document metadata (sender, receiver, timestamp)
- Base64-encoded file content
- Routing code (critical for downstream processing)

> "If it's valid JSON with the required attributes, store it immediately." - [Presenter]

[continues for each component...]
```

---

## Error Handling

- **Missing video:** Error with clear message
- **Missing transcript + no whisper.cpp:** Error with installation instructions
- **ffmpeg not found:** Prompt to install via `brew install ffmpeg`
- **Frame extraction fails:** Fall back to fixed 60-second interval
- **Transcript too large:** Read in chunks, do not skip content

---

## Limitations

- Zoom recordings only (optimized for Zoom file naming)
- Single meeting at a time (no batch processing)
- English transcription only (whisper base.en model)
- Requires local processing power for frame analysis

---

## Output Verification Checklist

Before completing, verify:

- [ ] All attendees listed
- [ ] Executive summary covers all major topics
- [ ] Every significant frame analyzed
- [ ] Complete frame catalogue in appendix
- [ ] All chat messages included
- [ ] At least 5 quotes extracted
- [ ] All action items captured
- [ ] Technical references complete
- [ ] Document is 400+ lines (30 min) or 600+ lines (1 hour)
- [ ] steipete/summarize output compared and merged
- [ ] No "[various]" or "[several]" placeholders remain
- [ ] All names spelled correctly
- [ ] All technical terms verified
