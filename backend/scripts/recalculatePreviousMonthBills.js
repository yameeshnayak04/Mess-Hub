/**
 * Recalculate (regenerate) bills for the previous month for all messes and memberships.
 * Attendance-only rules:
 *  - Base from membership.billingRate (fallback to mess.plan rate)
 *  - Present/Absent: no rebate
 *  - Leave: leaveCount * rebatePerThali
 *  - Skipped: skipCount * (skipPercent/100) * rebatePerThali
 *  - No-record meals: noRecordMeals * rebatePerThali
 *  - Final = max(minMonthlyCharge, base - rebate)
 *
 * Usage:
 *   node scripts/recalculatePreviousMonthBills.js
 *   node scripts/recalculatePreviousMonthBills.js --month=11 --year=2025   (override, month=1..12)
 */

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const connectDB = require('../config/db');
const Mess = require('../models/Mess');
const Membership = require('../models/Membership');
const Attendance = require('../models/Attendance');
const Bill = require('../models/Bill');

const {
  getStartAndEndOfMonth,
  getActiveWindowForMonth,
  calculateMonthlyBillForMember,
} = require('../utils/billCalculation');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  args.forEach((a) => {
    const m = a.match(/^--([^=]+)=(.+)$/);
    if (m) out[m[1]] = m[2];
  });
  return out;
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

async function upsertBill({ membership, mess, month, year, breakdown }) {
  let bill = await Bill.findOne({
    user: membership.user,
    mess: mess._id,
    month,
    year,
  });

  if (bill) {
    bill.baseAmount = round2(breakdown.baseAmount);
    bill.rebateAmount = round2(breakdown.rebateAmount);
    bill.totalAmount = round2(breakdown.finalAmount);
    // Preserve Paid / Pending statuses
    if (!['Paid', 'Pending', 'Pending Approval'].includes(bill.status)) {
      bill.status = 'Due';
    }
    await bill.save();
    return { created: false };
  } else {
    await Bill.create({
      user: membership.user,
      mess: mess._id,
      month,
      year,
      baseAmount: round2(breakdown.baseAmount),
      rebateAmount: round2(breakdown.rebateAmount),
      totalAmount: round2(breakdown.finalAmount),
      status: 'Due',
    });
    return { created: true };
  }
}

async function recalcForMess(mess, targetMonth, targetYear, startOfMonth, endOfMonth) {
  let updated = 0;
  let created = 0;

  // Memberships that intersect the month
  const memberships = await Membership.find({
    mess: mess._id,
    createdAt: { $lte: endOfMonth },
    $or: [
      { endDate: { $exists: false } },
      { endDate: null },
      { endDate: { $gte: startOfMonth } },
    ],
  });

  for (const member of memberships) {
    // Ensure member was active at least 1 day in the month
    const window = getActiveWindowForMonth(member, startOfMonth, endOfMonth);
    if (!window.activeStart || !window.activeEnd || window.activeDays <= 0) continue;

    // Attendance-only calculation
    const breakdown = await calculateMonthlyBillForMember({
      member,
      mess,
      month: targetMonth,
      year: targetYear,
      AttendanceModel: Attendance,
    });

    // Skip if we cannot determine base
    if (!breakdown.baseAmount) continue;

    // Persist billingRate if missing but derived from plan
    if (!member.billingRate && breakdown.baseAmount) {
      member.billingRate = breakdown.baseAmount;
      await member.save();
    }

    const res = await upsertBill({
      membership: member,
      mess,
      month: targetMonth,
      year: targetYear,
      breakdown,
    });

    if (res.created) created++;
    else updated++;
  }

  return { messId: mess._id.toString(), name: mess.messName, updated, created };
}

async function main() {
  const args = parseArgs();
  const now = new Date();
  let target;
  if (args.month && args.year) {
    target = new Date(Number(args.year), Number(args.month) - 1, 15);
  } else {
    // Previous month
    target = new Date(now.getFullYear(), now.getMonth() - 1, 15);
  }
  const targetMonth = target.getMonth() + 1; // 1..12
  const targetYear = target.getFullYear();

  console.log(`Recalculating bills for month=${targetMonth}, year=${targetYear} ...`);

  await connectDB();

  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);
  console.log(`Period UTC: ${startOfMonth.toISOString()} - ${endOfMonth.toISOString()}`);

  const messes = await Mess.find({});
  console.log(`Found ${messes.length} mess(es).`);

  let totalUpdated = 0;
  let totalCreated = 0;

  for (const mess of messes) {
    const res = await recalcForMess(mess, targetMonth, targetYear, startOfMonth, endOfMonth);
    totalUpdated += res.updated;
    totalCreated += res.created;
    console.log(
      `Mess: ${res.name} (${res.messId}) -> updated: ${res.updated}, created: ${res.created}`
    );
  }

  console.log('--------------------------------------------------');
  console.log(`Finished. Bills updated: ${totalUpdated}, bills created: ${totalCreated}`);
  console.log('Done.');
  await mongoose.connection.close();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  mongoose.connection.close().then(() => process.exit(1));
});