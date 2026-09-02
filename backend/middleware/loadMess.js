// new_backend/middleware/loadMess.js
const knex = require('../db/knex');
const { NotFoundError } = require('../errors/AppError');

// Finds the mess owned by the logged-in manager and puts it on req.mess.
//
// In the old backend this exact lookup ("find the mess for this owner, 404 if
// there isn't one") was copy-pasted into 17 different controller functions.
// One middleware replaces all of them, so the rule lives in one place.
async function requireManagerMess(req, _res, next) {
  try {
    const mess = await knex('messes').where('owner_id', req.user.id).first();
    if (!mess) {
      return next(new NotFoundError('You have not set up a mess yet'));
    }
    req.mess = mess;
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = { requireManagerMess };
