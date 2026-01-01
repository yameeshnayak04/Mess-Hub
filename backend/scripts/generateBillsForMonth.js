/**
 * Generate (or regenerate) bills for a specific month/year.
 *
 * Usage:
 *   node scripts/generateBillsForMonth.js --month=12 --year=2025
 *   node scripts/generateBillsForMonth.js --onlyMissing=true
 *   node scripts/generateBillsForMonth.js                 (defaults to previous month in IST via TZ_OFFSET_MINUTES; onlyMissing=true)
 *
 * Notes:
 * - Create-only: does not update existing bills.
 */

require('dotenv').config();

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
  DEFAULT_TZ_OFFSET_MIN,
} = require('../utils/billCalculation');

const TZ_OFFSET_MINUTES = parseInt(process.env.TZ_OFFSET_MINUTES || String(DEFAULT_TZ_OFFSET_MIN), 10);

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (const a of args) {
    const m = a.match(/^--([^=]+)=(.+)$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

function parseBool(v, defaultValue = false) {
  if (v === undefined) return defaultValue;
  const s = String(v).trim().toLowerCase();
  if (['true', '1', 'yes', 'y'].includes(s)) return true;
  if (['false', '0', 'no', 'n'].includes(s)) return false;
  return defaultValue;
}

function round2(n) {
  return Math.round(Number(n) * 100) / 100;
}

function getLocalYearMonth(offsetMin = TZ_OFFSET_MINUTES, now = new Date()) {
  const local = new Date(now.getTime() + offsetMin * 60 * 1000);
  return { year: local.getUTCFullYear(), monthIndex0: local.getUTCMonth() };
}

function getTargetMonthYear(args) {
  if (args.month && args.year) {
    const month = Number(args.month);
    const year = Number(args.year);
    if (!Number.isInteger(month) || month < 1 || month > 12) {
      throw new Error('Invalid --month. Expected 1..12');
    }
    if (!Number.isInteger(year) || year < 1970 || year > 3000) {
      throw new Error('Invalid --year. Expected a valid year');
    }
    return { month, year };
  }

  // Default: previous month in IST (or configured TZ_OFFSET_MINUTES)
  const { year, monthIndex0 } = getLocalYearMonth(TZ_OFFSET_MINUTES, new Date());
  const prevMonthDateLocal = new Date(Date.UTC(year, monthIndex0, 0));
  return {
    month: prevMonthDateLocal.getUTCMonth() + 1,
    year: prevMonthDateLocal.getUTCFullYear(),
  };
}

async function createBillIfMissing({ membership, mess, month, year, breakdown }) {
  const existing = await Bill.findOne({ user: membership.user, mess: mess._id, month, year }).select('_id');
  if (existing) return { created: false };

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

async function generateForMess(mess, targetMonth, targetYear, startOfMonth, endOfMonth) {
  let created = 0;
  let skippedExisting = 0;
  let skippedNoBase = 0;

  // Keep this broad; getActiveWindowForMonth will decide if member intersects the month.
  const memberships = await Membership.find({
    mess: mess._id,
    status: { $in: ['Active', 'Inactive'] },
    createdAt: { $lte: endOfMonth },
  });

  for (const member of memberships) {
    const window = getActiveWindowForMonth(member, startOfMonth, endOfMonth);
    if (!window.activeStart || !window.activeEnd || window.activeDays <= 0) continue;

    const breakdown = await calculateMonthlyBillForMember({
      member,
      mess,
      month: targetMonth,
      year: targetYear,
      AttendanceModel: Attendance,
    });

    if (!breakdown.baseAmount) {
      skippedNoBase++;
      continue;
    }

    // Persist derived base into membership.billingRate when missing
    if (!member.billingRate && breakdown.baseAmount) {
      member.billingRate = breakdown.baseAmount;
      await member.save();
    }

    const res = await createBillIfMissing({
      membership: member,
      mess,
      month: targetMonth,
      year: targetYear,
      breakdown,
    });

    if (res.created) created++;
    else skippedExisting++;
  }

  return { messId: String(mess._id), name: mess.messName, created, skippedExisting, skippedNoBase };
}

async function main() {
  const args = parseArgs();
  const { month: targetMonth, year: targetYear } = getTargetMonthYear(args);

  const onlyMissing = parseBool(args.onlyMissing, true);
  if (!onlyMissing) {
    throw new Error('This script is create-only. Use --onlyMissing=true');
  }

  console.log(
    `Generating bills for month=${targetMonth}, year=${targetYear} (TZ_OFFSET_MINUTES=${TZ_OFFSET_MINUTES}, onlyMissing=true) ...`
  );

  await connectDB();

  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);
  console.log(`Period UTC: ${startOfMonth.toISOString()} - ${endOfMonth.toISOString()}`);

  const messes = await Mess.find({});
  console.log(`Found ${messes.length} mess(es).`);

  let totalUpdated = 0;
  let totalCreated = 0;
  let totalSkippedNoBase = 0;
  let totalSkippedExisting = 0;

  for (const mess of messes) {
    const res = await generateForMess(mess, targetMonth, targetYear, startOfMonth, endOfMonth);
    totalCreated += res.created;
    totalSkippedExisting += res.skippedExisting;
    totalSkippedNoBase += res.skippedNoBase;

    console.log(
      `Mess: ${res.name} (${res.messId}) -> created: ${res.created}, skipped(existing): ${res.skippedExisting}, skipped(no base): ${res.skippedNoBase}`
    );
  }

  console.log('--------------------------------------------------');
  console.log(
    `Finished. Bills created: ${totalCreated}, skipped(existing): ${totalSkippedExisting}, skipped(no base): ${totalSkippedNoBase}`
  );

  await mongoose.connection.close();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  mongoose.connection.close().then(() => process.exit(1));
});
