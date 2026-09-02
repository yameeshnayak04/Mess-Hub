// new_backend/controllers/authController.js
//
// Controllers do three things and nothing else: read the request, call a
// service, send the response. No business rules, no SQL.
const authService = require('../services/authService');
const { signToken } = require('../middleware/auth');

async function register(req, res) {
  const user = await authService.register(req.body);
  res.status(201).json({
    success: true,
    data: { user, token: signToken(user) },
  });
}

async function login(req, res) {
  const user = await authService.login(req.body);
  res.json({
    success: true,
    data: { user, token: signToken(user) },
  });
}

async function getMyProfile(req, res) {
  const profile = await authService.getProfile(req.user.id);
  res.json({ success: true, data: profile });
}

async function updateMyProfile(req, res) {
  const profile = await authService.updateProfile(req.user.id, req.body);
  res.json({ success: true, data: profile });
}

// Tokens are stateless, so there is nothing to invalidate server-side. The
// app deletes its stored token when this returns. Kept as an endpoint so the
// client has one obvious "log out" call to make.
async function logout(_req, res) {
  res.json({ success: true, data: { message: 'Logged out' } });
}

module.exports = { register, login, getMyProfile, updateMyProfile, logout };
