# AI Prompt Document

This project was developed with a mix of direct implementation work and AI-assisted debugging support. The AI workflow focused on improving reliability in the app's state flow, keeping the architecture easy to reason about, and helping resolve issues without introducing unnecessary complexity.

## Main goals for AI assistance

- Debug the flow of state management between Riverpod providers, screens, and the local database.
- Keep the app architecture consistent by separating UI, providers, services, and persistence concerns.
- Help refine the local-first sync behavior so the app remains responsive even when connectivity changes.
- Suggest small, maintainable changes rather than large rewrites.

## Typical prompts used

Examples of prompts that were useful during development include:

- "Help me debug why a saved movie does not immediately reflect in the user list."
- "Explain how to make Riverpod listeners work safely inside a ConsumerStatefulWidget."
- "Review this state flow and suggest a cleaner way to keep providers and screens in sync."

## What AI helped with

- Troubleshooting Riverpod.
- Improving the flow between saving movies, refreshing local counts, and updating the UI.
- Clarifying the difference between local persistence and remote sync behavior.
- Supporting the design of a simple local-first architecture that remains understandable for future changes.

## Important exceptions and edge cases

Because this app mixes local persistence, async network calls, and UI state updates, a few issues can appear during normal use:

- A snackbar might be shown after the widget is already disposed if the async operation completes too late.
- Sync can fail if the device is offline or if the API request returns an unexpected response.
- A user may save the same movie twice if the save check is not completed before the UI triggers another action.
- The saved count may briefly appear stale if the local database refresh is delayed.
- Connectivity changes can cause sync to start unexpectedly, which may create a burst of background work.
- Providers may need invalidation after saves or removals to ensure downstream screens update correctly.

## Notes for future maintenance

When extending the app, keep the following in mind:

- Prefer small provider changes over broad state rewrites.
- Keep database writes and UI updates close to the feature that triggers them.
- Validate offline and retry behavior before shipping new sync-related features.
- If new screens depend on saved movie or user state, make sure the provider chain is still clear and testable.
