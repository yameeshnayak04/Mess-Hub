const multer = require('multer');
const path = require('path');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

// --- 1. CONFIGURE CLOUDINARY ---
// You MUST set these environment variables in your .env file or on Render
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// --- 2. CREATE CLOUDINARY STORAGE ENGINES ---

// Storage configuration for mess images
const messImageStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'mess-images', // Folder in Cloudinary
    allowed_formats: ['jpg', 'png', 'jpeg'],
    public_id: (req, file) => `mess-${Date.now()}` // Unique file name
  }
});

// Storage configuration for payment proofs
const paymentProofStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'payment-proofs', // Folder in Cloudinary
    allowed_formats: ['jpg', 'png', 'jpeg'],
    public_id: (req, file) => `payment-${Date.now()}` // Unique file name
  }
});

// --- 3. RE-USE YOUR EXISTING IMAGE FILTER ---
const imageFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Only image files are allowed (jpeg, jpg, png, gif)'));
  }
};

// --- 4. EXPORT MULTER MIDDLEWARE WITH NEW STORAGE ---

// Upload middleware for mess images
exports.uploadMessImage = multer({
  storage: messImageStorage, // <-- UPDATED
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: imageFilter
});

// Upload middleware for payment proofs
exports.uploadPaymentProof = multer({
  storage: paymentProofStorage, // <-- UPDATED
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: imageFilter
});