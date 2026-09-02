// new_backend/utils/money.js
//
// HOW MONEY IS STORED IN THIS PROJECT - read this before touching any amount.
//
// Every `*_price` column in the database holds a whole number of the smallest
// currency unit, i.e. rupees x 100 (₹1 is stored as 100, ₹6000 as 600000).
// Nothing anywhere stores a decimal, so there is no floating-point rounding to
// get wrong. The old backend stored rupees as floats and patched the rounding
// afterwards with Math.round(x*100)/100 sprinkled through the controllers,
// which is exactly how small errors crept into invoices.
//
// The API, by contrast, speaks plain rupees (`rateRupees: 6000`) because that
// is what the app shows a human. These two functions are the ONLY place the
// two representations meet - convert at the edge, never mid-calculation.

const UNITS_PER_RUPEE = 100;

// ₹6000 -> 600000 (what goes into a *_price column)
function rupeesToPrice(rupees) {
  if (rupees === null || rupees === undefined) return null;
  return Math.round(Number(rupees) * UNITS_PER_RUPEE);
}

// 600000 (from a *_price column) -> ₹6000
function priceToRupees(price) {
  if (price === null || price === undefined) return null;
  return Number(price) / UNITS_PER_RUPEE;
}

module.exports = { rupeesToPrice, priceToRupees };
