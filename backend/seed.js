const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');

// Load env vars
dotenv.config();

// Load models
const User = require('./models/User');
const Mess = require('./models/Mess');
const Membership = require('./models/Membership');
const Attendance = require('./models/Attendance');
const Leave = require('./models/Leave');
const Bill = require('./models/Bill');
const Menu = require('./models/Menu');
const Review = require('./models/Review');

// --- Configuration ---
const TEST_PASSWORD = 'password123'; // Common password for all seeded users
// --- End Configuration ---

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`MongoDB Connected for Seeding: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error connecting to MongoDB: ${error.message}`);
    process.exit(1);
  }
};

const destroyData = async () => {
  try {
    // Clear all existing data in order (child -> parent references)
    await Review.deleteMany();
    await Menu.deleteMany();
    await Bill.deleteMany();
    await Leave.deleteMany();
    await Attendance.deleteMany();
    await Membership.deleteMany();
    await Mess.deleteMany();
    await User.deleteMany();

    console.log('Data Destroyed!');
  } catch (error) {
    console.error(`Error destroying data: ${error.message}`);
    process.exit(1);
  }
};

// const importData = async () => {
//   try {
//     // --- 1. Create Users ---
//     const salt = await bcrypt.genSalt(10);
//     const hashedPassword = await bcrypt.hash(TEST_PASSWORD, salt);

//     const usersToCreate = [
//       // Manager 1
//       {
//         name: 'Manager Ramesh',
//         phone: '9876543210', // Unique phone
//         password: hashedPassword,
//         role: 'Manager',
//       },
//       // Manager 2
//       {
//         name: 'Manager Ram Sharma', // Changed name slightly for clarity
//         phone: '1234567890', // Unique phone
//         password: hashedPassword,
//         role: 'Manager',
//       },
//       // Customer 1 (Active member at Ramesh's Mess)
//       {
//         name: 'Customer Priya',
//         phone: '1111111111',
//         password: hashedPassword,
//         role: 'Customer',
//         pin: '1111',
//         location: { type: 'Point', coordinates: [77.3188, 24.6469] }, // Guna
//       },
//       // Customer 2 (Pending member at Ramesh's Mess)
//       {
//         name: 'Customer Amit',
//         phone: '2222222222',
//         password: hashedPassword,
//         role: 'Customer',
//         pin: '2222',
//         location: { type: 'Point', coordinates: [77.3200, 24.6500] },
//       },
//        // Customer 3 (Inactive member at Ramesh's Mess)
//       {
//         name: 'Customer Sunita',
//         phone: '3333333333',
//         password: hashedPassword,
//         role: 'Customer',
//         pin: '3333',
//         location: { type: 'Point', coordinates: [77.3150, 24.6400] },
//       },
//        // Customer 4 (Active member at Ram's Mess)
//       {
//         name: 'Customer Vikram',
//         phone: '4444444444',
//         password: hashedPassword,
//         role: 'Customer',
//         pin: '4444',
//         location: { type: 'Point', coordinates: [75.8577, 22.7196] }, // Indore
//       },
//     ];

//     const createdUsers = await User.insertMany(usersToCreate);

//     // **Find managers reliably by unique phone numbers**
//     const managerRamesh = createdUsers.find(u => u.phone === '9876543210');
//     const managerRam = createdUsers.find(u => u.phone === '1234567890');
//     if (!managerRamesh || !managerRam) throw new Error('Failed to find seeded managers!');

//     // Find customers
//     const customerPriya = createdUsers.find(u => u.phone === '1111111111');
//     const customerAmit = createdUsers.find(u => u.phone === '2222222222');
//     const customerSunita = createdUsers.find(u => u.phone === '3333333333');
//     const customerVikram = createdUsers.find(u => u.phone === '4444444444');
//     console.log('Users Created...');

//     // --- 2. Create Messes ---
//      const messesToCreate = [
//        // Mess 1 (Owned by Ramesh)
//        {
//          owner: managerRamesh._id, // Assign Ramesh
//          messName: 'Ramesh Tiffin Center',
//          location: { type: 'Point', coordinates: [77.3195, 24.6480] }, // Guna
//          address: 'Near Hanuman Chouraha, Guna',
//          city: 'Guna',
//          contactPhone: managerRamesh.phone,
//          serviceType: 'Both Daily & Monthly',
//          cuisine: 'Veg',
//          tiffinService: true,
//          basicThaliDetails: '4 Roti, Dal Fry, Seasonal Sabzi, Rice, Salad',
//          timings: {
//            lunch: { start: '12:00', end: '14:30' },
//            dinner: { start: '19:00', end: '21:30' },
//          },
//          plans: [
//            { name: 'Monthly (Both Meals)', rate: 2800 },
//            { name: 'Monthly (Lunch Only)', rate: 1500 },
//          ],
//          dailyThaliRate: 60,
//          rules: {
//            minLeaveDaysForRebate: 3,
//            rebatePerThali: 40,
//            skipAllowancePercent: 10,
//            securityDeposit: 500,
//            minMonthlyCharge: 1000,
//          },
//        },
//        // Mess 2 (Owned by Ram Sharma)
//         {
//          owner: managerRam._id, // Assign Ram
//          messName: 'Indore Food Junction',
//          location: { type: 'Point', coordinates: [75.8600, 22.7200] }, // Indore
//          address: 'Vijay Nagar Square, Indore',
//          city: 'Indore',
//          contactPhone: managerRam.phone, // Use Ram's phone
//          serviceType: 'Monthly Only',
//          cuisine: 'Non-Veg',
//          tiffinService: false,
//          basicThaliDetails: 'Chicken Curry, 3 Roti, Rice, Salad',
//          timings: {
//            lunch: { start: '13:00', end: '15:00' },
//            dinner: { start: '20:00', end: '22:00' },
//          },
//          plans: [
//            { name: 'Monthly Special Non-Veg', rate: 4000 },
//          ],
//          // dailyThaliRate: undefined, // Not needed for Monthly Only
//          rules: {
//            minLeaveDaysForRebate: 5,
//            rebatePerThali: 60,
//            skipAllowancePercent: 0,
//            securityDeposit: 1000,
//            minMonthlyCharge: 1500,
//          },
//        },
//      ];

//      const createdMesses = await Mess.insertMany(messesToCreate);
//      // Find messes reliably by owner ID or unique name
//      const messRamesh = createdMesses.find(m => m.owner.equals(managerRamesh._id));
//      const messRam = createdMesses.find(m => m.owner.equals(managerRam._id)); // Changed variable name
//      if (!messRamesh || !messRam) throw new Error('Failed to find seeded messes!');
//      console.log('Messes Created...');

//      // --- 3. Create Memberships ---
//      const membershipsToCreate = [
//        // Priya: Active at Ramesh Tiffin
//        {
//          user: customerPriya._id,
//          mess: messRamesh._id,
//          planName: 'Monthly (Both Meals)',
//          billingRate: messRamesh.plans.find(p => p.name === 'Monthly (Both Meals)').rate,
//          status: 'Active',
//          joinedDate: new Date(new Date().setMonth(new Date().getMonth() - 2)),
//          effectiveFrom: new Date(new Date().getFullYear(), new Date().getMonth() - 2, 1)
//        },
//        // Amit: Pending at Ramesh Tiffin
//        {
//          user: customerAmit._id,
//          mess: messRamesh._id,
//          planName: 'Monthly (Lunch Only)',
//          billingRate: messRamesh.plans.find(p => p.name === 'Monthly (Lunch Only)').rate,
//          status: 'Pending',
//        },
//        // Sunita: Inactive at Ramesh Tiffin
//         {
//          user: customerSunita._id,
//          mess: messRamesh._id,
//          planName: 'Monthly (Both Meals)',
//          billingRate: messRamesh.plans.find(p => p.name === 'Monthly (Both Meals)').rate,
//          status: 'Inactive',
//          joinedDate: new Date(new Date().setMonth(new Date().getMonth() - 4)),
//        },
//         // Vikram: Active at Ram's Mess (Indore)
//        {
//          user: customerVikram._id,
//          mess: messRam._id, // Use messRam
//          planName: 'Monthly Special Non-Veg',
//          billingRate: messRam.plans.find(p => p.name === 'Monthly Special Non-Veg').rate, // Use messRam
//          status: 'Active',
//          joinedDate: new Date(new Date().setDate(new Date().getDate() - 10)),
//          effectiveFrom: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
//        },
//      ];
//      // Add planId references (requires createdMesses to have subdocument IDs)
//      // Mongoose might add _id automatically, but let's be safe if needed later
//      membershipsToCreate[0].planId = messRamesh.plans.find(p => p.name === 'Monthly (Both Meals)')._id;
//      membershipsToCreate[1].planId = messRamesh.plans.find(p => p.name === 'Monthly (Lunch Only)')._id;
//      membershipsToCreate[2].planId = messRamesh.plans.find(p => p.name === 'Monthly (Both Meals)')._id;
//      membershipsToCreate[3].planId = messRam.plans.find(p => p.name === 'Monthly Special Non-Veg')._id;


//      const createdMemberships = await Membership.insertMany(membershipsToCreate);
//      const priyaMembership = createdMemberships.find(m => m.user.equals(customerPriya._id) && m.mess.equals(messRamesh._id));
//      const vikramMembership = createdMemberships.find(m => m.user.equals(customerVikram._id) && m.mess.equals(messRam._id));
//      console.log('Memberships Created...');

//      // --- 4. Create Attendance (for Active members) ---
//      const today = new Date(); today.setHours(0, 0, 0, 0);
//      const yesterday = new Date(today); yesterday.setDate(today.getDate() - 1);
//      const dayBefore = new Date(today); dayBefore.setDate(today.getDate() - 2);
//      const lastMonthDate = new Date(today); lastMonthDate.setMonth(today.getMonth() - 1); lastMonthDate.setDate(15); // Mid last month

//      const attendancesToCreate = [
//        // Priya at Ramesh Tiffin
//        { user: customerPriya._id, mess: messRamesh._id, date: today, mealType: 'Lunch', status: 'Present', memberType: 'Monthly', membership: priyaMembership._id, planNameSnapshot: priyaMembership.planName, rateSnapshot: priyaMembership.billingRate / 60, rebatePerThaliSnapshot: messRamesh.rules.rebatePerThali },
//        { user: customerPriya._id, mess: messRamesh._id, date: yesterday, mealType: 'Lunch', status: 'Present', memberType: 'Monthly', membership: priyaMembership._id, planNameSnapshot: priyaMembership.planName, rateSnapshot: priyaMembership.billingRate / 60, rebatePerThaliSnapshot: messRamesh.rules.rebatePerThali },
//        { user: customerPriya._id, mess: messRamesh._id, date: yesterday, mealType: 'Dinner', status: 'Skipped', memberType: 'Monthly', membership: priyaMembership._id, planNameSnapshot: priyaMembership.planName, rateSnapshot: priyaMembership.billingRate / 60, rebatePerThaliSnapshot: messRamesh.rules.rebatePerThali },
//        { user: customerPriya._id, mess: messRamesh._id, date: dayBefore, mealType: 'Lunch', status: 'Present', memberType: 'Monthly', membership: priyaMembership._id, planNameSnapshot: priyaMembership.planName, rateSnapshot: priyaMembership.billingRate / 60, rebatePerThaliSnapshot: messRamesh.rules.rebatePerThali },
//        { user: customerPriya._id, mess: messRamesh._id, date: dayBefore, mealType: 'Dinner', status: 'Present', memberType: 'Monthly', membership: priyaMembership._id, planNameSnapshot: priyaMembership.planName, rateSnapshot: priyaMembership.billingRate / 60, rebatePerThaliSnapshot: messRamesh.rules.rebatePerThali },
//        { user: customerPriya._id, mess: messRamesh._id, date: lastMonthDate, mealType: 'Lunch', status: 'Present', memberType: 'Monthly', membership: priyaMembership._id, planNameSnapshot: priyaMembership.planName, rateSnapshot: priyaMembership.billingRate / 60, rebatePerThaliSnapshot: messRamesh.rules.rebatePerThali },

//         // Vikram at Ram's Mess (Indore)
//        { user: customerVikram._id, mess: messRam._id, date: today, mealType: 'Dinner', status: 'Present', memberType: 'Monthly', membership: vikramMembership._id, planNameSnapshot: vikramMembership.planName, rateSnapshot: vikramMembership.billingRate / 30, rebatePerThaliSnapshot: messRam.rules.rebatePerThali },
//        { user: customerVikram._id, mess: messRam._id, date: yesterday, mealType: 'Dinner', status: 'Present', memberType: 'Monthly', membership: vikramMembership._id, planNameSnapshot: vikramMembership.planName, rateSnapshot: vikramMembership.billingRate / 30, rebatePerThaliSnapshot: messRam.rules.rebatePerThali },

//        // Daily walk-in at Ramesh Tiffin
//        { user: null, mess: messRamesh._id, date: today, mealType: 'Lunch', status: 'Present', memberType: 'Daily', rateSnapshot: messRamesh.dailyThaliRate },
//        { user: null, mess: messRamesh._id, date: yesterday, mealType: 'Lunch', status: 'Present', memberType: 'Daily', rateSnapshot: messRamesh.dailyThaliRate },
//        { user: null, mess: messRamesh._id, date: yesterday, mealType: 'Dinner', status: 'Present', memberType: 'Daily', rateSnapshot: messRamesh.dailyThaliRate },
//      ];
//      await Attendance.insertMany(attendancesToCreate);
//      console.log('Attendance Created...');

//      // --- 5. Create Leaves (for Active members) ---
//      // Reset today for date calculations
//      today.setHours(0,0,0,0);
//      const tomorrow = new Date(today); tomorrow.setDate(today.getDate() + 1);
//      const dayAfterTomorrow = new Date(today); dayAfterTomorrow.setDate(today.getDate() + 2); // 2 day leave (NOT eligible for rebate in Mess 1)
//      const dayAfter3 = new Date(today); dayAfter3.setDate(today.getDate() + 4); // 4 day leave (eligible for rebate in Mess 1)

//      const nextWeekStart = new Date(today); nextWeekStart.setDate(today.getDate() + 7);
//      const nextWeekEnd = new Date(today); nextWeekEnd.setDate(today.getDate() + 12); // 6 day leave (eligible in Mess 2)

//      const leavesToCreate = [
//        // Priya - eligible leave this month
//        { user: customerPriya._id, mess: messRamesh._id, startDate: tomorrow, endDate: dayAfter3 },
//        // Vikram - eligible leave this month
//        { user: customerVikram._id, mess: messRam._id, startDate: nextWeekStart, endDate: nextWeekEnd },
//         // Priya - Short leave (not eligible for rebate)
//        { user: customerPriya._id, mess: messRamesh._id, startDate: dayAfterTomorrow, endDate: dayAfterTomorrow },
//      ];
//      await Leave.insertMany(leavesToCreate);
//      console.log('Leaves Created...');

//      // --- 6. Create Bills (for Active members - last month) ---
//      const lastMonth = today.getMonth() === 0 ? 12 : today.getMonth(); // Month is 1-indexed for Bill schema
//      const yearOfLastMonth = today.getMonth() === 0 ? today.getFullYear() - 1 : today.getFullYear();

//      const billsToCreate = [
//        // Priya - Paid bill for last month at Ramesh's
//        { user: customerPriya._id, mess: messRamesh._id, month: lastMonth, year: yearOfLastMonth, baseAmount: priyaMembership.billingRate, rebateAmount: 200, totalAmount: priyaMembership.billingRate - 200, status: 'Paid'},
//        // Vikram - Joined this month, so no bill for last month usually, but adding one for testing Pending Approval at Ram's
//        { user: customerVikram._id, mess: messRam._id, month: lastMonth, year: yearOfLastMonth, baseAmount: vikramMembership.billingRate, rebateAmount: 0, totalAmount: vikramMembership.billingRate, status: 'Pending Approval', paymentProofUrl: '/uploads/payment-proofs/sample-proof.jpg' },
//        // Amit - Pending member, no bill. Sunita - Inactive, maybe a final bill? Adding one for Priya this month.
//        // Priya - Due bill for THIS month (simulate generation)
//        // Note: Bill generation logic should handle rebates, this is simplified
//         { user: customerPriya._id, mess: messRamesh._id, month: today.getMonth() + 1, year: today.getFullYear(), baseAmount: priyaMembership.billingRate, rebateAmount: 0, totalAmount: priyaMembership.billingRate, status: 'Due'},

//      ];
//      await Bill.insertMany(billsToCreate);
//      console.log('Bills Created...');

//       // --- 7. Create Menus ---
//        // Reset today for date calculations
//        today.setHours(0,0,0,0);
//        const tomorrowMenu = new Date(today); tomorrowMenu.setDate(today.getDate() + 1);

//       const menusToCreate = [
//         // Ramesh Tiffin - Today & Tomorrow
//         { mess: messRamesh._id, date: today, lunchItems: ['Dal Makhani', 'Shahi Paneer', 'Jeera Rice', '4 Butter Roti', 'Gulab Jamun'], dinnerItems: ['Chole Bhature', 'Veg Pulao', 'Raita', 'Salad'] },
//         { mess: messRamesh._id, date: tomorrowMenu, lunchItems: ['Rajma', 'Aloo Gobi', 'Rice', '4 Roti'], dinnerItems: ['Pav Bhaji', 'Onion Salad'] },
//         // Ram's Mess (Indore) - Today & Tomorrow
//         { mess: messRam._id, date: today, lunchItems: ['Egg Curry', 'Rice', '3 Roti'], dinnerItems: ['Butter Chicken', 'Naan', 'Rice', 'Salad'] },
//         { mess: messRam._id, date: tomorrowMenu, lunchItems: ['Fish Fry', 'Dal', 'Rice'], dinnerItems: ['Mutton Korma', 'Rumali Roti'] },
//       ];
//       await Menu.insertMany(menusToCreate);
//       console.log('Menus Created...');

//       // --- 8. Create Reviews ---
//       const reviewsToCreate = [
//         // Priya reviews Ramesh Tiffin
//         { user: customerPriya._id, mess: messRamesh._id, rating: 4, comment: 'Good quality veg food, reliable service.' },
//          // Sunita reviews Ramesh Tiffin (inactive member can review)
//         { user: customerSunita._id, mess: messRamesh._id, rating: 3, comment: 'Was okay, sometimes roti quality varied.' },
//          // Vikram reviews Ram's Mess (Indore)
//         { user: customerVikram._id, mess: messRam._id, rating: 5, comment: 'Excellent non-veg taste!' },
//          // Amit cannot review yet (pending member)
//       ];
//       await Review.insertMany(reviewsToCreate);
//       console.log('Reviews Created...');


//     console.log('Data Imported Successfully!');
//   } catch (error) {
//     console.error(`Error importing data: ${error.message}`);
//     console.error(error.stack); // Print stack trace for debugging
//     process.exit(1);
//   }
// };

// // --- Execution Logic ---
// const runSeed = async () => {
//   await connectDB();

//   if (process.argv[2] === '-d') {
//     await destroyData();
//   } else {
//     await destroyData();
//     await importData();
//   }

//   await mongoose.disconnect();
//   console.log('MongoDB Disconnected.');
//   process.exit();
// };

connectDB();
destroyData();