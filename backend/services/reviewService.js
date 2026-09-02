// new_backend/services/reviewService.js
const knex = require('../db/knex');
const { NotFoundError, ForbiddenError } = require('../errors/AppError');
const { buildPageMeta } = require('../utils/pagination');

function toPublicReview(row) {
  return {
    id: row.id,
    rating: row.rating,
    comment: row.comment,
    authorName: row.author_name,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// One review per person per mess. The old backend had two endpoints for this
// (an "add" and an "update") which could disagree; there is just one here and
// it does whichever is needed.
async function upsertReview(userId, messId, { rating, comment }) {
  const mess = await knex('messes').where('id', messId).first();
  if (!mess) throw new NotFoundError('Mess not found');

  // You can only review a mess you have actually been a member of.
  const membership = await knex('memberships')
    .where({ user_id: userId, mess_id: messId })
    .whereIn('status', ['Active', 'Inactive'])
    .first();
  if (!membership) {
    throw new ForbiddenError('You can only review a mess you have been a member of');
  }

  // The unique index on (user_id, mess_id) is what makes this safe to run
  // concurrently - no "check if it exists then insert" gap.
  //
  // We do not touch messes.rating_avg here: a trigger on this table keeps
  // that column in step automatically, however the row got written.
  const [review] = await knex('reviews')
    .insert({ user_id: userId, mess_id: messId, rating, comment: comment || null })
    .onConflict(['user_id', 'mess_id'])
    .merge({ rating, comment: comment || null, updated_at: knex.fn.now() })
    .returning('*');

  // Map it: every other review response is the public shape, and returning the
  // raw row here would leak column names and drop authorName. The author is
  // whoever called this, so their name comes from their own row.
  const author = await knex('users').select('name').where('id', userId).first();
  return toPublicReview({ ...review, author_name: author?.name ?? null });
}

async function listReviews(messId, { page, limit, offset }) {
  const mess = await knex('messes')
    .select('rating_avg', 'rating_count')
    .where('id', messId)
    .first();
  if (!mess) throw new NotFoundError('Mess not found');

  const rows = await knex('reviews')
    .join('users', 'users.id', 'reviews.user_id')
    .select('reviews.*', 'users.name as author_name')
    .where('reviews.mess_id', messId)
    .orderBy('reviews.created_at', 'desc')
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map(toPublicReview),
    meta: {
      ...buildPageMeta({ page, limit, total: mess.rating_count }),
      averageRating: Number(mess.rating_avg),
    },
  };
}

async function getMyReview(userId, messId) {
  const review = await knex('reviews')
    .join('users', 'users.id', 'reviews.user_id')
    .select('reviews.*', 'users.name as author_name')
    .where({ 'reviews.user_id': userId, 'reviews.mess_id': messId })
    .first();

  return review ? toPublicReview(review) : null;
}

module.exports = { upsertReview, listReviews, getMyReview };
