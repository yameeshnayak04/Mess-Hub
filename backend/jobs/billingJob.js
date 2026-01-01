// jobs/billingJob.js
const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance');
const connectDB = require('../config/db');
const { getStartAndEndOfMonth, calculateMonthlyBillForMember } = require('../utils/billCalculation');

const TZ_OFFSET_MINUTES = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

function getLocalYearMonth(offsetMin = TZ_OFFSET_MINUTES, now = new Date()) {
  // Shift the current instant by offsetMin and read as UTC fields.
  // This yields a stable "local" year/month regardless of server timezone.
  const local = new Date(now.getTime() + offsetMin * 60 * 1000);
  return { year: local.getUTCFullYear(), monthIndex0: local.getUTCMonth() };
}

async function upsertBill({ member, mess, month, year, breakdown, session }) {
  const existing = await Bill.findOne({
    user: member.user,
    mess: mess._id,
    month,
    year,
  }).session(session);

  if (existing) {
    existing.baseAmount = breakdown.baseAmount;
    existing.rebateAmount = breakdown.rebateAmount;
    existing.totalAmount = breakdown.finalAmount; // totalAmount holds final payable
    // Preserve Paid / Pending
    if (!['Paid', 'Pending Approval'].includes(existing.status)) {
      existing.status = 'Due';
    }
    await existing.save({ session });
  } else {
    await Bill.create(
      [
        {
          user: member.user,
          mess: mess._id,
          month,
          year,
          baseAmount: breakdown.baseAmount,
            rebateAmount: breakdown.rebateAmount,
          totalAmount: breakdown.finalAmount,
          status: 'Due',
        },
      ],
      { session }
    );
  }
}

async function processMessForPeriod(mess, billingMonth, billingYear, startOfMonth, endOfMonth) {
  const session = await mongoose.startSession();
  try {
    let processed = 0;
    await session.withTransaction(async () => {
      const members = await Membership.find({
        mess: mess._id,
        status: 'Active',
      }).session(session);

      for (const member of members) {
        // Calculate attendance-based bill
        const breakdown = await calculateMonthlyBillForMember({
          member,
          mess,
          month: billingMonth,
          year: billingYear,
          AttendanceModel: Attendance,
        });

        // If baseAmount zero, skip (no plan rate)
        if (!breakdown.baseAmount) continue;

        // Persist membership.billingRate if just derived
        if (!member.billingRate && breakdown.baseAmount) {
          member.billingRate = breakdown.baseAmount;
          await member.save({ session });
        }

        await upsertBill({
          member,
          mess,
          month: billingMonth,
          year: billingYear,
          breakdown,
          session,
        });
        processed++;
      }
    });

    return {
      success: true,
      messId: mess._id,
      messName: mess.messName,
      membersProcessed: processed,
    };
  } catch (err) {
    return { success: false, messId: mess._id, messName: mess.messName, error: err.message };
  } finally {
    await session.endSession();
  }
}

/**
 * Monthly billing job: previous calendar month only.
 */
async function runBillingJob() {
  await connectDB();
  console.log('--- JOB: Monthly Billing (Attendance-Based) ---');

  const now = new Date();
  // Compute previous month using "local" calendar (IST by default), not server timezone.
  const { year: localYear, monthIndex0: localMonth0 } = getLocalYearMonth(TZ_OFFSET_MINUTES, now);
  const prevMonthDateLocal = new Date(Date.UTC(localYear, localMonth0, 0));
  const billingMonth = prevMonthDateLocal.getUTCMonth() + 1; // 1..12
  const billingYear = prevMonthDateLocal.getUTCFullYear();
  const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

  const messes = await Mess.find({});
  const results = [];

  for (const mess of messes) {
    const r = await processMessForPeriod(
      mess,
      billingMonth,
      billingYear,
      startOfMonth,
      endOfMonth
    );
    results.push(r);
  }

  const ok = results.filter((r) => r.success).length;
  const fail = results.length - ok;
  console.log(`[Billing Job] Completed. Success: ${ok}, Failed: ${fail}`);
  if (fail) console.error('[Billing Job] Failures:', results.filter((r) => !r.success));

  return results;
}

module.exports = { runBillingJob };
