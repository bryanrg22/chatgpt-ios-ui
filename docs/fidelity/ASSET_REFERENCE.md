# Official asset and typography reference

Reviewed October 7, 2026. Official resources can improve this reconstruction, but none of the sources reviewed supplies a complete native ChatGPT iOS app skeleton. That is a bounded search finding, not proof that no such resource exists.

| Resource | Confirmed available | What it does not establish |
|---|---|---|
| [OpenAI plugin UI guidelines](https://developers.openai.com/plugins/concepts/ui-guidelines) | General typography guidance explicitly identifies SF Pro on iOS; links the official Apps SDK UI component library and Figma components | Native per-screen font sizes, weights, tracking, custom icon mappings, or a SwiftUI copy of the app. The published component system uses Tailwind/CSS and serves plugin interfaces |
| [OpenAI brand guidelines](https://openai.com/brand/) | Official logo downloads, mark usage rules, and access to OpenAI Sans through the full brand guidelines | OpenAI Sans being the native iOS UI font, or permission to redistribute every brand asset under a project's code license |
| [Apple Design Resources](https://developer.apple.com/design/resources/) | Platform UI design resources | The vendor's complete app layouts or proprietary icons |
| [Apple fonts](https://developer.apple.com/fonts/) and [SF Symbols](https://developer.apple.com/sf-symbols/) | Platform fonts and configurable system icon library | That a visually similar system symbol is the exact icon used by a particular vendor screen |

Use system font APIs for the current implementation. The OpenAI statement supports that baseline in general design guidance; screenshot comparison must still establish each screen's metrics.

## Asset terms and distribution

OpenAI's published mark terms require appropriate context, unchanged supplied marks, ownership attribution, and no misleading endorsement; they do not grant an unrestricted sublicense to brand assets. The package bundles an existing knot vector in widget and About resource catalogs; its upstream attribution/redistribution provenance remains unresolved in `THIRD_PARTY_NOTICES.md`. No OpenAI font file is bundled. [OpenAI terms](https://openai.com/brand/)

Apple's downloadable font agreement restricts embedding and redistribution. Use the operating system's font rather than copying downloaded font binaries into this repository. SF Symbols also has usage restrictions, including restrictions on using symbols as app icons/logos and on particular symbols; inspect the symbol's restrictions before substituting it. [Font agreement](https://developer.apple.com/fonts/), [SF Symbols guidance](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)

For each future exact asset, record its official source, retrieval date, asset version, permitted use, and the actual app screen it matches. Keep private reference captures separate from distributable assets. No new third-party asset was downloaded or bundled during this research.
