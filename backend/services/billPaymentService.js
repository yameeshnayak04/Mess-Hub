// new_backend/services/billPaymentService.js
//
// Everything about *paying* a bill. Working out how much is owed lives in
// billingService; this file only moves a bill through its states:
//
//     Due  --submit proof-->  Pending Approval  --approve-->  Paid
//                                    |
//                                    +--reject--> back to Due
//
// Every one of those moves also writes a row to bill_events. That table is
// append-only history: who did what, when, and which proof image was attached
// at the time. The old backend just overwrote the bill row and blanked the
// proof URL on rejection, so there was no record a payment had ever been
// submitted at all.

const knex = require('../db/knex');
const { buildSignedUrl } = require('../middleware/upload');
const { NotFoundError, ValidationError } = require('../errors/AppError');
const { priceToRupees } = require('../utils/money');
const { buildPageMeta } = require('../utils/pagination');

function toPublicBill(row) {
  return {
    id: row.id,
    membershipId: row.membership_id,
    messId: row.mess_id,
    period: row.period,
    baseRupees: priceToRupees(row.base_price),
    rebateRupees: priceToRupees(row.rebate_price),
    totalRupees: priceToRupees(row.total_price),
    status: row.status,
    hasPaymentProof: Boolean(row.payment_proof_url),
    memberName: row.member_name,
    memberPhone: row.member_phone,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function findBillForMess(billId, messId) {
  const bill = await knex('bills')
    .select('bills.*', 'users.name as member_name', 'users.phone as member_phone')
    .join('memberships', 'memberships.id', 'bills.membership_id')
    .join('users', 'users.id', 'memberships.user_id')
    .where('bills.id', billId)
    .first();

  if (!bill || bill.mess_id !== messId) {
    throw new NotFoundError('Bill not found in your mess');
  }
  return bill;
}

// Customer uploads a screenshot of their UPI/bank transfer.
async function submitPaymentProof(billId, userId, uploadedImage) {
  if (!uploadedImage) throw new ValidationError('Please attach a payment proof image');

  return knex.transaction(async (trx) => {
    const bill = await trx('bills')
      .select('bills.*', 'memberships.user_id')
      .join('memberships', 'memberships.id', 'bills.membership_id')
      .where('bills.id', billId)
      .first();

    if (!bill || bill.user_id !== userId) throw new NotFoundError('Bill not found');
    if (bill.status === 'Paid') throw new ValidationError('This bill has already been paid');

    // We store Cloudinary's public_id here, not a public link. Payment proofs
    // are uploaded as private images, so they can only be viewed through a
    // short-lived signed URL we generate for an authorised caller.
    await trx('bills')
      .where('id', billId)
      .update({ status: 'Pending Approval', payment_proof_url: uploadedImage.publicId });

    await trx('bill_events').insert({
      bill_id: billId,
      event: 'ProofSubmitted',
      actor_id: userId,
      proof_url: uploadedImage.publicId,
    });

    const updated = await trx('bills').where('id', billId).first();
    return toPublicBill(updated);
  });
}

async function approvePayment(billId, messId, managerId) {
  return knex.transaction(async (trx) => {
    const bill = await trx('bills').where('id', billId).forUpdate().first();
    if (!bill || bill.mess_id !== messId) throw new NotFoundError('Bill not found in your mess');

    // A bill can only be approved from 'Pending Approval'. Jumping straight
    // from Due to Paid would mean marking something paid that nobody ever
    // submitted proof for — the old backend allowed exactly that.
    if (bill.status !== 'Pending Approval') {
      throw new ValidationError(
        `Only a bill awaiting approval can be approved (this one is ${bill.status})`
      );
    }

    await trx('bills').where('id', billId).update({ status: 'Paid' });
    await trx('bill_events').insert({
      bill_id: billId,
      event: 'Approved',
      actor_id: managerId,
      proof_url: bill.payment_proof_url,
    });

    const updated = await trx('bills').where('id', billId).first();
    return toPublicBill(updated);
  });
}

async function rejectPayment(billId, messId, managerId, note) {
  return knex.transaction(async (trx) => {
    const bill = await trx('bills').where('id', billId).forUpdate().first();
    if (!bill || bill.mess_id !== messId) throw new NotFoundError('Bill not found in your mess');
    if (bill.status !== 'Pending Approval') {
      throw new ValidationError(
        `Only a bill awaiting approval can be rejected (this one is ${bill.status})`
      );
    }

    // The rejected proof is recorded in bill_events before the bill goes back
    // to Due, so there is still a permanent record of what was submitted.
    await trx('bill_events').insert({
      bill_id: billId,
      event: 'Rejected',
      actor_id: managerId,
      proof_url: bill.payment_proof_url,
      note: note || null,
    });

    await trx('bills').where('id', billId).update({ status: 'Due', payment_proof_url: null });

    const updated = await trx('bills').where('id', billId).first();
    return toPublicBill(updated);
  });
}

// Generates a temporary link the manager can open to look at the proof image.
async function getPaymentProofUrl(billId, messId) {
  const bill = await findBillForMess(billId, messId);
  if (!bill.payment_proof_url) throw new NotFoundError('No payment proof has been submitted');

  return {
    billId: bill.id,
    // Expires after 10 minutes, so even if the link leaks it stops working.
    viewUrl: buildSignedUrl(bill.payment_proof_url, 600),
    expiresInSeconds: 600,
  };
}

async function listBillsForMembership(membershipId, { page, limit, offset }) {
  const totalRow = await knex('bills')
    .where('membership_id', membershipId)
    .count('* as count')
    .first();

  const rows = await knex('bills')
    .where('membership_id', membershipId)
    .orderBy('period', 'desc')
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map(toPublicBill),
    meta: buildPageMeta({ page, limit, total: Number(totalRow.count) }),
  };
}

async function listBillsForMess(messId, { status, month, year, page, limit, offset }) {
  const applyFilters = (query) => {
    query.where('bills.mess_id', messId);
    if (status) query.andWhere('bills.status', status);
    if (year) query.andWhereRaw('EXTRACT(YEAR FROM bills.period) = ?', [year]);
    if (month) query.andWhereRaw('EXTRACT(MONTH FROM bills.period) = ?', [month]);
    return query;
  };

  const totalRow = await applyFilters(knex('bills')).count('* as count').first();

  const rows = await applyFilters(
    knex('bills')
      .select('bills.*', 'users.name as member_name', 'users.phone as member_phone')
      .join('memberships', 'memberships.id', 'bills.membership_id')
      .join('users', 'users.id', 'memberships.user_id')
  )
    .orderBy([
      { column: 'bills.period', order: 'desc' },
      { column: 'bills.updated_at', order: 'desc' },
    ])
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map(toPublicBill),
    meta: buildPageMeta({ page, limit, total: Number(totalRow.count) }),
  };
}

async function getBillHistory(billId, messId) {
  const bill = await findBillForMess(billId, messId);
  const events = await knex('bill_events')
    .leftJoin('users', 'users.id', 'bill_events.actor_id')
    .select(
      'bill_events.id',
      'bill_events.event',
      'bill_events.note',
      'bill_events.created_at',
      'users.name as actor_name'
    )
    .where('bill_events.bill_id', billId)
    .orderBy('bill_events.created_at');

  return { bill: toPublicBill(bill), events };
}

module.exports = {
  toPublicBill,
  submitPaymentProof,
  approvePayment,
  rejectPayment,
  getPaymentProofUrl,
  listBillsForMembership,
  listBillsForMess,
  getBillHistory,
};
