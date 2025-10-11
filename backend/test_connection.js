require('dotenv').config();
const mongoose = require('mongoose');

const mongoURI = process.env.MONGO_URI;

console.log("-----------------------------------------");
console.log("--- Starting MongoDB Connection Test ---");
console.log("-----------------------------------------");

// This is a critical check. It will print the exact URI your app is trying to use.
console.log("Attempting to connect with URI:", mongoURI);

if (!mongoURI) {
    console.error("\n❌ ERROR: MONGO_URI is not defined in your .env file!");
    process.exit(1);
}

mongoose.connect(mongoURI)
  .then(() => {
    console.log("\n✅ SUCCESS: MongoDB Connection was successful!");
    process.exit(0);
  })
  .catch(err => {
    console.error("\n❌ FAILED: MongoDB Connection failed.");
    console.error("--- Error Details ---");
    console.error(err);
    console.error("---------------------");
    console.log("\nTROUBLESHOOTING TIPS:");
    console.log("1. Double-check your password in the MONGO_URI.");
    console.log("2. Ensure your IP address is whitelisted in Atlas Network Access (0.0.0.0/0 for development).");
    console.log("3. Check for any typos in the connection string.");
    process.exit(1);
  });

