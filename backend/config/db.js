// This file handles the connection logic to your MongoDB Atlas database.

// Import Mongoose, the library we use to interact with MongoDB.
const mongoose = require('mongoose');

// Define an asynchronous function to connect to the database.
const connectDB = async () => {
  try {
    // Attempt to connect to the database using the connection string from your .env file.
    // The options { useNewUrlParser: true, useUnifiedTopology: true } are good practice
    // but are now default in recent Mongoose versions.
    const conn = await mongoose.connect(process.env.MONGO_URI);

    // If the connection is successful, log a confirmation message to the console.
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    // If an error occurs during connection, log the error message.
    console.error(`Error connecting to MongoDB: ${error.message}`);
    // Exit the Node.js process with a failure code (1). This is important because
    // your application is useless without a database connection.
    process.exit(1);
  }
};

// Export the connectDB function so it can be used in your main index.js file.
module.exports = connectDB;