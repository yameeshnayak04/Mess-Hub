// new_backend/services/planService.js
//
// A plan is "Lunch Only, ₹2500/month". Which meals it covers lives in the
// plan_meals table as real rows, not as words inside the plan's name.
//
// The old backend worked out whether a plan included lunch by checking
// `planName.toLowerCase().includes('lunch')` — in nine separate places. A
// plan called "Deluxe" silently covered no meals, which broke attendance and
// produced a ₹0 bill with no error anywhere. Here it is a JOIN.

const knex = require('../db/knex');
const { NotFoundError, ValidationError } = require('../errors/AppError');
const { rupeesToPrice, priceToRupees } = require('../utils/money');

function toPublicPlan(plan, meals) {
  return {
    id: plan.id,
    messId: plan.mess_id,
    name: plan.name,
    rateRupees: priceToRupees(plan.rate_price),
    meals,
    isActive: plan.is_active,
  };
}

// Creating a plan and its meals must happen together — a plan with no meal
// rows is meaningless — so both callers pass in a transaction.
async function createPlan(trx, messId, { name, rateRupees, meals }) {
  const [plan] = await trx('plans')
    .insert({ mess_id: messId, name, rate_price: rupeesToPrice(rateRupees) })
    .returning('*');

  await trx('plan_meals').insert(meals.map((meal) => ({ plan_id: plan.id, meal })));

  return toPublicPlan(plan, meals);
}

async function listPlansForMess(messId, { includeInactive = false } = {}) {
  const plans = await knex('plans')
    .where('mess_id', messId)
    .modify((query) => {
      if (!includeInactive) query.andWhere('is_active', true);
    })
    .orderBy('rate_price', 'asc');

  if (plans.length === 0) return [];

  const mealRows = await knex('plan_meals').whereIn(
    'plan_id',
    plans.map((plan) => plan.id)
  );

  return plans.map((plan) =>
    toPublicPlan(
      plan,
      mealRows.filter((row) => row.plan_id === plan.id).map((row) => row.meal)
    )
  );
}

async function addPlanToMess(messId, input) {
  return knex.transaction((trx) => createPlan(trx, messId, input));
}

async function updatePlan(messId, planId, { name, rateRupees, meals }) {
  return knex.transaction(async (trx) => {
    const plan = await trx('plans').where({ id: planId, mess_id: messId }).first();
    if (!plan) throw new NotFoundError('Plan not found in your mess');

    const changes = {};
    if (name !== undefined) changes.name = name;
    if (rateRupees !== undefined) changes.rate_price = rupeesToPrice(rateRupees);
    if (Object.keys(changes).length > 0) {
      await trx('plans').where('id', planId).update(changes);
    }

    // Note: changing a plan's rate DOES change what existing members on it
    // pay, from their next bill onwards. Billing reads the rate live from this
    // row, so there is nothing else to update here.
    if (meals !== undefined) {
      await trx('plan_meals').where('plan_id', planId).del();
      await trx('plan_meals').insert(meals.map((meal) => ({ plan_id: planId, meal })));
    }

    const updated = await trx('plans').where('id', planId).first();
    const mealRows = await trx('plan_meals').where('plan_id', planId);
    return toPublicPlan(
      updated,
      mealRows.map((row) => row.meal)
    );
  });
}

// Plans are retired, never deleted: memberships point at them with a foreign
// key, and deleting one would either fail or orphan billing history.
async function deactivatePlan(messId, planId) {
  const plan = await knex('plans').where({ id: planId, mess_id: messId }).first();
  if (!plan) throw new NotFoundError('Plan not found in your mess');

  const activeMembers = await knex('memberships')
    .where({ plan_id: planId })
    .whereIn('status', ['Pending', 'Active'])
    .count('* as count')
    .first();

  if (Number(activeMembers.count) > 0) {
    throw new ValidationError(
      `Cannot retire this plan - ${activeMembers.count} member(s) are still on it`
    );
  }

  await knex('plans').where('id', planId).update({ is_active: false });
  return { id: planId, isActive: false };
}

module.exports = {
  createPlan,
  listPlansForMess,
  addPlanToMess,
  updatePlan,
  deactivatePlan,
};
