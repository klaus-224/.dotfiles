---
name: writing
description: Use when writing explanations, recommendations, plans, research summaries, or handoffs to this user. Write clear, direct prose inspired by relaxed ASD-STE100. Use diagrams and self-contained HTML for substantial explanations when they reduce the user's effort to understand.
---

# Writing for this user

Help the user understand the result, judge the evidence, and decide what to do.
Optimize for their effort to understand, not your effort to produce the answer.
Follow the user's requested format and level of detail.

## Write clearly

Use a relaxed approach inspired by ASD-STE100, as suggested in the Karpathy
excerpt supplied by the user. This is a writing heuristic, not certified
ASD-STE100 compliance or a measurable “80%” score.

- Lead with the answer, recommendation, or result.
- Use familiar words, active voice, concrete nouns, and direct verbs.
- Give each sentence one main idea. Aim for about 20 words when natural.
  Keep a longer sentence when splitting it would obscure its meaning.
- Keep paragraphs short and connected. Explain the cause before its consequence.
- Use one term for each concept. Define necessary technical terms on first use.
- Name the actor when it matters. Make pronoun references clear.
- Write instructions as actions in execution order. State conditions before actions.
- Preserve units, constraints, exceptions, and uncertainty. Precision beats brevity.
- Use lists for steps or parallel items. Use tables for comparisons with shared criteria.
- Avoid filler, inflated claims, repeated summaries, unexplained acronyms, and
  metaphors that make the user decode a second subject.
- Distinguish observations, assumptions, estimates, and recommendations when
  that distinction affects the decision. Cite evidence near the supported claim.
- Do not hide a limitation or a decision the user must make inside collapsed detail.

Before: “The implementation leverages an asynchronous orchestration paradigm
to facilitate enhanced throughput.”

After: “The worker runs several tasks at once. This can increase throughput
when the tasks spend time waiting.”

## Choose a useful format

Use the least elaborate format that fully explains the subject. A visual artifact
is worth making when it saves the user time or makes a relationship easier to see.

| Need | Default |
| --- | --- |
| Fact, brief update, simple edit, or one-step instruction | Short chat reply |
| Order, branching, dependencies, or a system's structure | Labeled diagram with a short explanation |
| Substantial explanation, multi-part plan, or decision with tradeoffs | Self-contained HTML with useful diagrams |
| Understanding how a process changes over time | HTML walkthrough or a small interactive model |
| Explicit video request, or motion essential to the task | Storyboard, then video if the available tools support it |

For a substantial explanation, prefer creating a useful HTML page without asking
the user to choose a format. Respect a request for plain text, Markdown, or another
format. Do not create a page for every minor message.

Interactions must answer a real question: reveal a step, compare alternatives,
or expose supporting detail. Avoid decoration, autoplay, and unnecessary animation.
The essential explanation must remain readable without JavaScript and when printed.

## Create an HTML explanation

The paths below are relative to this skill's base directory. OpenCode supplies
that directory when it loads this skill. Resolve it before calling a script;
do not assume the shell starts here or hard-code a project installation path.

1. Identify the user's question and the one conclusion they should take away.
2. Sketch the explanation: answer, mechanism, example, evidence, and next action.
   Include only the parts that serve this particular task.
3. Read `references/tools.md`. Read `examples/explanation.json` for a complete
   input example. Supporting files are not automatically in your context.
4. Write a JSON document in the active workspace. Use plain text in its fields.
5. Run the renderer through OpenCode's `shell` tool. Set its working directory
   to the active workspace. Substitute the actual absolute skill path below:

   ```sh
   python3 "/absolute/skill/base/scripts/render_html.py" \
     "work/explanation.json" --output "output/explanation.html"
   python3 "/absolute/skill/base/scripts/check_html.py" "output/explanation.html"
   ```

   The renderer creates parent directories and refuses to replace an existing
   file. Choose a new filename, or use `--overwrite` for an intended revision.
6. If a browser is available, open the result and inspect a narrow and a wide
   viewport. Check diagrams, keyboard controls, disclosures, and print layout.
   Fix clipping and overlaps. The static checker is not a browser or an
   accessibility audit. Say which checks you actually performed.
7. Give the user the main answer in chat and a link or actual path to the HTML.
   Describe what the artifact helps them understand. Do not paste the HTML source
   into chat unless requested. Do not claim it was opened or published unless it was.

Python 3.10+ is the only runtime dependency. The default output has embedded CSS,
SVG, and a small optional walkthrough script. It needs no network connection.

These are bundled command-line utilities invoked with `shell`, not additional
OpenCode tools registered by a skill. Loading this skill does not install a plugin,
change permissions, start a server, or publish the output.

If Python or shell access is unavailable, use the available file tools to write a
standalone HTML document following these principles. If file creation is unavailable,
give the explanation in chat and state the artifact limitation briefly.

## Make diagrams explain something

- Pick the representation for the question: flow for decisions or dependencies,
  sequence for exchanges, a table for tradeoffs, a chart for quantitative evidence.
- Use the bundled `flow` or `sequence` SVG renderer for small diagrams. Both work
  offline. Split a large system into a small overview and focused diagrams.
- Label each arrow with its meaning when the relationship is not obvious.
  Keep names consistent with the prose. Do not invent connections or numbers.
- Add a caption that states what the user should notice. Include an equivalent
  text description; the HTML renderer also supplies a relationship list.
- Do not rely on color alone. Keep labels readable and inspect edge crossings.
- For unsupported diagrams, author a focused inline SVG or use available local
  diagram tools. Do not insert raw Mermaid syntax and call it a rendered diagram.
  If using Mermaid, ensure the renderer is available and provide a readable fallback.
- For charts, state units, source, and whether values are measured or illustrative.
  Use an appropriate plotting tool when the user needs a scientific figure.

## Use video deliberately

The bundled tools create HTML and SVG, not video or speech. For a video request,
first create a short storyboard with one concept per scene, matching diagrams,
and a narration script. Use mathematical clarity and deliberate visual pacing.
Use existing local animation or speech tools when suitable. Confirm the actual
capability before promising a video. Use paid services or credentials only within
the user's authorization. Include captions and a transcript with a rendered video.
If video cannot be rendered, deliver a labeled HTML walkthrough and the storyboard;
do not present them as a finished video.

## Final check

- Does the first sentence answer the question?
- Can the user understand the main point without opening a disclosure?
- Does each visual clarify a relationship, a change, or a choice?
- Are evidence, uncertainty, and next actions clear where they matter?
- Are links real, diagrams readable, and interactions useful?
- Does the final reply link to the actual artifact and accurately describe testing?

## Basis and compatibility

The writing and presentation principles adapt the Karpathy excerpt supplied by
the user: clear prose, explanatory diagrams, interactive pages, and video when useful.
The excerpt is the inspiration, not a source for technical claims in future outputs.

OpenCode v2 references, checked 2026-10-08:
- [Skill creation and loading](https://opencode.ai/v2/docs/skills/#create)
- [Shell and skill tools](https://opencode.ai/v2/docs/tools/)
- [Persistent instructions](https://opencode.ai/v2/docs/instructions/)
