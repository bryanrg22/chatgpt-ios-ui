# Explore, Sites, and project drafts

These surfaces follow the October 8, 2026 phone captures of ChatGPT for iOS 1.2026.267. Private captures are not distributed.

Explore expands inside the sidebar, replacing its row with Sites, Projects, Plugins, and Images while preserving the current destination and unsent draft. Apple's native [DisclosureGroup](https://developer.apple.com/documentation/swiftui/disclosuregroup) retains a disclosure label; this captured presentation replaces it, so ordinary native buttons and observable state reproduce the hierarchy.

Sites reproduces the empty directory, search field, and creation entry point. Create site opens a new Work draft containing `Create a website that ...` and a Sites prefix. It does not send a prompt. The context is included in `ChatAction.send` and the user message; edit cancellation restores the original draft context. `SitesDestinationView` accepts optional host-provided content rather than manufacturing an uncaptured loaded directory.

Projects reproduces the empty directory and New project sheet, including name, three confirmed suggestion labels, memory selection, and icon/color picker. Memory and icon choices are staged until Done; Cancel discards the staged choice. Writing replaces the name and assigns its purple nib. Create is disabled for whitespace-only names; submission emits a trimmed `ProjectsAction.create(ProjectDraft)` once and waits for the host. No real project is created by the demo. A resulting project page and failure/loading outcomes remain uncaptured.

`chat.explore` and `chat.projects` hold caller-owned presentation state. Search changes emit typed intents. `ProjectsDestinationView` accepts optional host-provided directory content. Neither state performs requests, account mutations, or persistence.

## Fidelity limits

- SF Symbols approximate most icons; smile-plus and nib use original outline drawings. Lotus, kettlebell, spiral notebook, and plant-pot remain approximate substitutes. None is claimed pixel-identical.
- Only Homework, Writing, and Health suggestion labels were readable. An additional clipped orange glyph has no verified label, so its destination is not invented.
- Native sheets and keyboard behavior supply motion; no transition duration or easing was measured.
- Loaded site/project directories and project creation outcomes remain outside this pass. Plugins reuses its separately captured catalog.
- Reference geometry is 393×852pt; simulator evidence uses a different viewport. This is not pixel-perfect certification.

Validation: 143 state tests in 20 suites pass. The combined Explore/Sites, Images/Work, and project-draft simulator checks pass (3 tests, 54.227s). After the final search-color and glyph corrections, Sites/draft routing passed again (14.788s), and project name/memory/icon/suggestion/cancel passed with a settled-sheet capture (35.433s). The final Images/Work rerun after correcting poster preview framing passed (23.703s). The ordinary compose/send/cancel regression also passed during the initial integration. The final generic simulator app plus widget-extension build succeeds. Screenshots were individually inspected; passing tests are not a claim of exact visual parity.


## Images

Images now includes the Library notice and dismissal, Templates/Trending categories, two-column cards, a template detail sheet with Share/Close/Try controls, and compact empty or expanded retained-draft composer. `chat.images` defaults to an empty host-owned catalog. `ChatGPTView(imagesArtwork:)` accepts each item's visual; metadata and prompts are supplied in `ImageTemplate`. Try emits the selected template and dismisses its detail. The demo explicitly starts a fictional Work fixture and clears the previous draft/context. Reusable state does not start a task or generate an image.

The selected Poster title/detail hierarchy and the first four labels in each category were captured. Other details/prompts in the demo are fictional samples. Gallery artwork uses original generated substitutes; see `GALLERY_ARTWORK.md`. Share, attachment, and dictation actions emit host intents, with subsequent destinations unverified. Work question presentation has its own host-data contract in `docs/features/WORK_TASK.md`.
