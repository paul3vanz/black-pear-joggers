// Power of 10 locked their site down further and the scraper that fed the
// 'auto' award-build path is no longer reliable. Manual claiming is the
// default while that's the case; flip back to 'auto' if PO10 access is
// restored, or keep both live by leaving this a straight one-line change.
export const CLAIM_MODE: 'manual' | 'auto' = 'manual';
