// new_backend/middleware/upload.js
//
// Image uploads go straight to Cloudinary; we never write files to the
// server's own disk (containers are disposable, so anything written inside
// one disappears on restart).
const multer = require('multer');
const { v2: cloudinary } = require('cloudinary');
const { loadConfig } = require('../utils/config');
const { ValidationError } = require('../errors/AppError');

const config = loadConfig();

cloudinary.config({
  cloud_name: config.cloudinary.cloudName,
  api_key: config.cloudinary.apiKey,
  api_secret: config.cloudinary.apiSecret,
});

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

const memoryUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      return callback(new ValidationError('Only JPEG, PNG or WebP images are allowed'));
    }
    return callback(null, true);
  },
});

function uploadBuffer(buffer, { folder, isPrivate }) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        // 'authenticated' assets are NOT reachable from a plain URL - you need
        // a signed link to view them. Payment proofs are bank/UPI screenshots,
        // so they must not sit on a public URL the way mess photos can.
        type: isPrivate ? 'authenticated' : 'upload',
      },
      (error, result) => (error ? reject(error) : resolve(result))
    );
    stream.end(buffer);
  });
}

// Builds a short-lived viewing link for a private (authenticated) image.
function buildSignedUrl(publicId, secondsValid = 600) {
  return cloudinary.url(publicId, {
    type: 'authenticated',
    sign_url: true,
    secure: true,
    expires_at: Math.floor(Date.now() / 1000) + secondsValid,
  });
}

// Factory: returns [multer parser, uploader] to drop into a route.
function uploadImage(fieldName, { folder, isPrivate = false }) {
  return [
    memoryUpload.single(fieldName),
    async (req, _res, next) => {
      try {
        if (!req.file) return next(); // field is optional on update routes
        const result = await uploadBuffer(req.file.buffer, { folder, isPrivate });
        req.uploadedImage = { url: result.secure_url, publicId: result.public_id };
        return next();
      } catch (error) {
        return next(error);
      }
    },
  ];
}

const uploadMessImage = uploadImage('messImage', { folder: 'messhub/mess-images' });
const uploadPaymentProof = uploadImage('paymentProof', {
  folder: 'messhub/payment-proofs',
  isPrivate: true,
});

module.exports = { uploadMessImage, uploadPaymentProof, buildSignedUrl };
