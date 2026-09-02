// new_backend/utils/pagination.js
//
// Every list endpoint in this API is paginated. The old backend returned
// unbounded lists, which quietly gets slower as a mess grows and eventually
// times out.

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

// Turns ?page=2&limit=50 into safe numbers we can hand straight to SQL.
//
// Routes that use validateQuery already reject a limit above MAX_LIMIT with a
// clear 400, which is the behaviour clients see. The clamp here is a safety
// net so that any route which forgets that validation still cannot be asked
// for a million rows.
function readPagination(query) {
  const page = Math.max(Number(query.page) || 1, 1);
  const requestedLimit = Number(query.limit) || DEFAULT_LIMIT;
  const limit = Math.min(Math.max(requestedLimit, 1), MAX_LIMIT);

  return { page, limit, offset: (page - 1) * limit };
}

// The `meta` block every paginated response returns, so the app always knows
// whether there is another page to fetch.
function buildPageMeta({ page, limit, total }) {
  return {
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit) || 0,
    hasNextPage: page * limit < total,
  };
}

module.exports = { readPagination, buildPageMeta };
