// jobs/billingJob.js
const mongoose = require('mongoose');
const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance');
const connectDB = require('../config/db');
const { getStartAndEndOfMonth, calculateMonthlyBillForMember } = require('../utils/billCalculation');

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
  // Previous month reference (day 0 of current month gives last day prev month)
  const prevMonthDate = new Date(now.getFullYear(), now.getMonth(), 0);
  const billingMonth = prevMonthDate.getMonth() + 1;
  const billingYear = prevMonthDate.getFullYear();
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
