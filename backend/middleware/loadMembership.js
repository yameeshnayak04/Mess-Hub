// new_backend/middleware/loadMembership.js
const knex = require('../db/knex');
const { NotFoundError, ForbiddenError } = require('../errors/AppError');

// Loads the membership named in :membershipId and checks the caller is
// allowed to see it, then puts it on req.membership.
//
// The permission rule differs by role, which is why both live here together:
//   - a Customer may only touch their own membership
//   - a Manager may only touch memberships belonging to the mess they own
//
// This replaces roughly ten hand-written copies of the same check in the old
// backend, where any one of them could have been (and one was) subtly wrong.
async function loadMembership(req, _res, next) {
  try {
    const membership = await knex('memberships')
      .select('memberships.*', 'messes.owner_id as mess_owner_id')
      .join('messes', 'messes.id', 'memberships.mess_id')
      .where('memberships.id', req.params.membershipId)
      .first();

    if (!membership) {
      return next(new NotFoundError('Membership not found'));
    }

    const isOwnMembership = membership.user_id === req.user.id;
    const managesThisMess = membership.mess_owner_id === req.user.id;

    if (req.user.role === 'Customer' && !isOwnMembership) {
      return next(new ForbiddenError('This membership does not belong to you'));
    }
    if (req.user.role === 'Manager' && !managesThisMess) {
      return next(new ForbiddenError('This membership is not part of your mess'));
    }

    req.membership = membership;
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = { loadMembership };
