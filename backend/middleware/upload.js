const multer = require('multer');
const path = require('path');

// Storage configuration for mess images
const messImageStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/mess-images/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'mess-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// Storage configuration for payment proofs
const paymentProofStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/payment-proofs/');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'payment-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// File filter for images
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

// Upload middleware for mess images
exports.uploadMessImage = multer({
  storage: messImageStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: imageFilter
});

// Upload middleware for payment proofs
exports.uploadPaymentProof = multer({
  storage: paymentProofStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: imageFilter
});
