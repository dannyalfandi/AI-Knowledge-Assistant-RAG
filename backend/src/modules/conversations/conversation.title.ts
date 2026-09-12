/**
 * Longest auto-generated title before it gets truncated. Kept well under the
 * 200-character limit `createConversationSchema` allows for a manual title —
 * this is a list label, not a heading.
 */
export const AUTO_TITLE_MAX_LENGTH = 50;

const ELLIPSIS = "...";

/**
 * Characters that read as dangling when a sentence is cut short, so they are
 * dropped before the ellipsis is appended ("refund," -> "refund...").
 */
const TRAILING_NOISE = /[\s.,;:!?\-–—/\\]+$/;

/**
 * Builds a conversation title from the first question asked in it.
 *
 * Whitespace is collapsed first, so a multi-line question still yields a
 * single-line label. A question that already fits is used verbatim — no
 * ellipsis is added to text that was not actually cut. Longer text is cut at
 * the last word boundary within the limit; a single word longer than the limit
 * (a URL, say) is cut hard rather than allowed to stretch the title.
 *
 * Returns null when the question has no usable text, so the caller leaves the
 * conversation untitled instead of storing an empty string.
 */
export function buildAutoTitle(question: string): string | null {
  const normalized = question.trim().replace(/\s+/g, " ");

  if (normalized.length === 0) {
    return null;
  }

  if (normalized.length <= AUTO_TITLE_MAX_LENGTH) {
    return normalized;
  }

  const head = normalized.slice(0, AUTO_TITLE_MAX_LENGTH);
  const lastSpace = head.lastIndexOf(" ");
  const cut = lastSpace > 0 ? head.slice(0, lastSpace) : head;
  const trimmed = cut.replace(TRAILING_NOISE, "");

  // Only punctuation before the cut: fall back to the hard cut so the title is
  // never just an ellipsis.
  if (trimmed.length === 0) {
    return `${head}${ELLIPSIS}`;
  }

  return `${trimmed}${ELLIPSIS}`;
}
