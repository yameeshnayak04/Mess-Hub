// upload.js (replace entire file)

// Dependencies
const multer = require('multer');
const { v2: cloudinary } = require('cloudinary');

// Configure Cloudinary via env (Render -> Environment)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Use in-memory storage; we’ll stream to Cloudinary
const memoryStorage = multer.memoryStorage();

// Basic image filter
const imageFilter = (req, file, cb) => {
  const allowed = /jpeg|jpg|png|gif/;
  const extOK = allowed.test((file.originalname || '').toLowerCase());
  const mimeOK = allowed.test(file.mimetype || '');
  if (extOK && mimeOK) return cb(null, true);
  cb(new Error('Only image files are allowed (jpeg, jpg, png, gif)'));
};

// Helper to stream to Cloudinary
const uploadToCloudinary = (buffer, folder) =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'image' },
      (err, result) => (err ? reject(err) : resolve(result))
    );
    stream.end(buffer);
  });

// Middleware factory: multer single + Cloudinary
const makeUploader = (folder) => [
  multer({
    storage: memoryStorage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: imageFilter
  }).single('file'), // expect field name 'file'
  async (req, res, next) => {
    try {
      if (!req.file) return next();
      const result = await uploadToCloudinary(req.file.buffer, folder);
      // expose Cloudinary URL(s) to controllers
      req.file.cloudinaryUrl = result.secure_url;
      req.file.publicId = result.public_id;
      next();
    } catch (e) {
      next(e);
    }
  }
];

exports.uploadMessImage = makeUploader('mess-images');
exports.uploadPaymentProof = makeUploader('payment-proofs');
