// new_backend/services/authService.js
const bcrypt = require('bcryptjs');
const knex = require('../db/knex');
const { ValidationError, NotFoundError, AppError } = require('../errors/AppError');

const BCRYPT_ROUNDS = 10;

// Never send password_hash / pin_hash back to the client.
function toPublicUser(user) {
  return {
    id: user.id,
    name: user.name,
    phone: user.phone,
    role: user.role,
  };
}

async function register({ name, phone, password, role, pin, location }) {
  const existing = await knex('users').where('phone', phone).first();
  if (existing) {
    throw new ValidationError('An account with this phone number already exists', 'PHONE_TAKEN');
  }

  const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
  // The kiosk PIN is a credential too - the old backend stored it as plain
  // text, so anyone who could read the users table could walk up to a kiosk
  // and mark attendance as somebody else.
  const pinHash = pin ? await bcrypt.hash(pin, BCRYPT_ROUNDS) : null;

  const [user] = await knex('users')
    .insert({
      name,
      phone,
      password_hash: passwordHash,
      pin_hash: pinHash,
      role,
      location: location
        ? knex.raw('ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography', [
            location.longitude,
            location.latitude,
          ])
        : null,
    })
    .returning('*');

  return toPublicUser(user);
}

async function login({ phone, password }) {
  const user = await knex('users').where('phone', phone).first();

  // Deliberately the same message whether the phone is unknown or the
  // password is wrong. Saying which one was wrong lets an attacker discover
  // who has an account (the old backend gave this away).
  const genericFailure = new AppError(
    'Phone number or password is incorrect',
    401,
    'BAD_CREDENTIALS'
  );
  if (!user) throw genericFailure;

  const passwordMatches = await bcrypt.compare(password, user.password_hash);
  if (!passwordMatches) throw genericFailure;

  return toPublicUser(user);
}

async function getProfile(userId) {
  const user = await knex('users').where('id', userId).first();
  if (!user) throw new NotFoundError('User not found');

  const profile = toPublicUser(user);

  // The mobile app uses this to decide whether to show a manager the
  // "create your mess" wizard or their dashboard.
  if (user.role === 'Manager') {
    const mess = await knex('messes').select('id').where('owner_id', user.id).first();
    profile.hasMess = Boolean(mess);
    profile.messId = mess ? mess.id : null;
  }

  return profile;
}

async function updateProfile(userId, { name, pin }) {
  const user = await knex('users').where('id', userId).first();
  if (!user) throw new NotFoundError('User not found');

  const changes = {};
  if (name !== undefined) changes.name = name;

  if (pin !== undefined) {
    if (user.role !== 'Customer') {
      throw new ValidationError('Only customers have a kiosk PIN');
    }
    changes.pin_hash = await bcrypt.hash(pin, BCRYPT_ROUNDS);
  }

  await knex('users').where('id', userId).update(changes);
  return getProfile(userId);
}

module.exports = { register, login, getProfile, updateProfile };
