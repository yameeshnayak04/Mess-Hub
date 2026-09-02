// new_backend/services/messService.js
const knex = require('../db/knex');
const planService = require('./planService');
const { getMessClock } = require('./messClock');
const { NotFoundError, ValidationError } = require('../errors/AppError');
const { rupeesToPrice, priceToRupees } = require('../utils/money');
const { buildPageMeta } = require('../utils/pagination');

function toPublicMess(mess, extras = {}) {
  return {
    id: mess.id,
    ownerId: mess.owner_id,
    messName: mess.mess_name,
    messImage: mess.mess_image,
    address: mess.address,
    city: mess.city,
    contactPhone: mess.contact_phone,
    location: { longitude: mess.longitude, latitude: mess.latitude },
    serviceType: mess.service_type,
    cuisine: mess.cuisine,
    maxCapacity: mess.max_capacity,
    tiffinService: mess.tiffin_service,
    basicThaliDetails: mess.basic_thali_details,
    timings: {
      lunchStart: mess.lunch_start,
      lunchEnd: mess.lunch_end,
      dinnerStart: mess.dinner_start,
      dinnerEnd: mess.dinner_end,
    },
    dailyThaliRateRupees: priceToRupees(mess.daily_thali_rate_price),
    rules: {
      minLeaveDaysForRebate: mess.rule_min_leave_days_for_rebate,
      rebatePerThaliRupees: priceToRupees(mess.rule_rebate_per_thali_price),
      skipAllowancePercent: mess.rule_skip_allowance_percent,
      allowAbsentRebate: mess.rule_allow_absent_rebate,
      minMonthlyChargeRupees: priceToRupees(mess.rule_min_monthly_charge_price),
      // Shown to customers before they join so they know what caution money
      // to expect. The app does not collect or track it - that stays an
      // offline arrangement between the member and the mess.
      securityDepositRupees: priceToRupees(mess.rule_security_deposit_price),
    },
    rating: { average: Number(mess.rating_avg), count: mess.rating_count },
    ...extras,
  };
}

// Timings and location need SQL functions to read back in a usable shape, so
// every "read a mess" path goes through this instead of `select *`.
function selectMessColumns(query) {
  return query.select(
    'messes.*',
    knex.raw("to_char(lunch_start,  'HH24:MI') AS lunch_start"),
    knex.raw("to_char(lunch_end,    'HH24:MI') AS lunch_end"),
    knex.raw("to_char(dinner_start, 'HH24:MI') AS dinner_start"),
    knex.raw("to_char(dinner_end,   'HH24:MI') AS dinner_end"),
    knex.raw('ST_X(location::geometry) AS longitude'),
    knex.raw('ST_Y(location::geometry) AS latitude')
  );
}

async function createMess(ownerId, input) {
  const existing = await knex('messes').where('owner_id', ownerId).first();
  if (existing) {
    throw new ValidationError('You already have a mess. Edit it instead of creating another.');
  }

  if (input.serviceType === 'Both Daily & Monthly' && input.dailyThaliRateRupees == null) {
    throw new ValidationError('A daily thali rate is required when you offer daily service');
  }

  // Mess + its plans + each plan's meals are created together, so a mess can
  // never exist in a half-set-up state with no plans to join.
  return knex.transaction(async (trx) => {
    const [mess] = await trx('messes')
      .insert({
        owner_id: ownerId,
        mess_name: input.messName,
        mess_image: input.messImage || null,
        address: input.address,
        city: input.city,
        contact_phone: input.contactPhone,
        location: trx.raw('ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography', [
          input.location.longitude,
          input.location.latitude,
        ]),
        service_type: input.serviceType,
        cuisine: input.cuisine,
        max_capacity: input.maxCapacity ?? null,
        tiffin_service: input.tiffinService,
        basic_thali_details: input.basicThaliDetails,
        lunch_start: input.lunchStart,
        lunch_end: input.lunchEnd,
        dinner_start: input.dinnerStart,
        dinner_end: input.dinnerEnd,
        daily_thali_rate_price: rupeesToPrice(input.dailyThaliRateRupees),
        rule_min_leave_days_for_rebate: input.rules.minLeaveDaysForRebate,
        rule_rebate_per_thali_price: rupeesToPrice(input.rules.rebatePerThaliRupees),
        rule_skip_allowance_percent: input.rules.skipAllowancePercent,
        rule_allow_absent_rebate: input.rules.allowAbsentRebate,
        rule_min_monthly_charge_price: rupeesToPrice(input.rules.minMonthlyChargeRupees),
        rule_security_deposit_price: rupeesToPrice(input.rules.securityDepositRupees),
      })
      .returning('*');

    const plans = [];
    for (const plan of input.plans) {
      plans.push(await planService.createPlan(trx, mess.id, plan));
    }

    return { messId: mess.id, plans };
  });
}

async function getMessById(messId) {
  const mess = await selectMessColumns(knex('messes')).where('messes.id', messId).first();
  if (!mess) throw new NotFoundError('Mess not found');

  const plans = await planService.listPlansForMess(messId);
  const clock = await getMessClock(messId);

  return toPublicMess(mess, {
    plans,
    liveStatus: clock.current_meal ? 'Open' : 'Closed',
    currentMeal: clock.current_meal,
  });
}

async function getMessForOwner(ownerId) {
  const mess = await selectMessColumns(knex('messes')).where('owner_id', ownerId).first();
  if (!mess) throw new NotFoundError('You have not set up a mess yet');
  const plans = await planService.listPlansForMess(mess.id, { includeInactive: true });
  return toPublicMess(mess, { plans });
}

async function updateMess(messId, input) {
  const changes = {};
  const fieldMap = {
    messName: 'mess_name',
    messImage: 'mess_image',
    address: 'address',
    city: 'city',
    contactPhone: 'contact_phone',
    serviceType: 'service_type',
    cuisine: 'cuisine',
    maxCapacity: 'max_capacity',
    tiffinService: 'tiffin_service',
    basicThaliDetails: 'basic_thali_details',
    lunchStart: 'lunch_start',
    lunchEnd: 'lunch_end',
    dinnerStart: 'dinner_start',
    dinnerEnd: 'dinner_end',
  };

  for (const [inputName, columnName] of Object.entries(fieldMap)) {
    if (input[inputName] !== undefined) changes[columnName] = input[inputName];
  }
  if (input.dailyThaliRateRupees !== undefined) {
    changes.daily_thali_rate_price = rupeesToPrice(input.dailyThaliRateRupees);
  }

  if (input.rules) {
    const ruleMap = {
      minLeaveDaysForRebate: ['rule_min_leave_days_for_rebate', false],
      rebatePerThaliRupees: ['rule_rebate_per_thali_price', true],
      skipAllowancePercent: ['rule_skip_allowance_percent', false],
      allowAbsentRebate: ['rule_allow_absent_rebate', false],
      minMonthlyChargeRupees: ['rule_min_monthly_charge_price', true],
      securityDepositRupees: ['rule_security_deposit_price', true],
    };
    for (const [inputName, [columnName, isMoney]] of Object.entries(ruleMap)) {
      if (input.rules[inputName] !== undefined) {
        changes[columnName] = isMoney
          ? rupeesToPrice(input.rules[inputName])
          : input.rules[inputName];
      }
    }
  }

  if (Object.keys(changes).length === 0) {
    throw new ValidationError('Nothing to update');
  }

  // The schema itself enforces that lunch ends before dinner starts and that
  // each window's start is before its end, so an invalid combination is
  // rejected by Postgres here rather than needing checks in this function.
  await knex('messes').where('id', messId).update(changes);
  const mess = await selectMessColumns(knex('messes')).where('messes.id', messId).first();
  return toPublicMess(mess);
}

// "Messes near me", ordered by real distance.
async function discoverMesses({
  longitude,
  latitude,
  cuisine,
  serviceType,
  search,
  page,
  limit,
  offset,
}) {
  const point = knex.raw('ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography', [longitude, latitude]);

  const applyFilters = (query) => {
    if (cuisine) query.andWhere('cuisine', cuisine);
    if (serviceType) query.andWhere('service_type', serviceType);
    if (search) query.andWhere('mess_name', 'ilike', `%${search}%`);
    return query;
  };

  const totalRow = await applyFilters(knex('messes').count('* as count')).first();

  // rating_avg / rating_count are kept up to date by a trigger on the reviews
  // table, so listing messes needs no join or sub-query for ratings. The old
  // backend recomputed review averages for EVERY mess on every search, then
  // threw most of the work away when it paginated.
  const rows = await applyFilters(
    selectMessColumns(knex('messes')).select(
      knex.raw('ROUND(ST_Distance(location, ?)::numeric) AS distance_metres', [point])
    )
  )
    .orderByRaw('location <-> ?', [point]) // <-> is PostGIS's index-backed nearest-neighbour operator
    .limit(limit)
    .offset(offset);

  return {
    data: rows.map((mess) => toPublicMess(mess, { distanceMetres: Number(mess.distance_metres) })),
    meta: buildPageMeta({ page, limit, total: Number(totalRow.count) }),
  };
}

module.exports = {
  createMess,
  getMessById,
  getMessForOwner,
  updateMess,
  discoverMesses,
};
