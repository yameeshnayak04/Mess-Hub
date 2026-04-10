/*
  One-time manual script.

  Usage (PowerShell):
    cd backend
    node scripts/backfillAttendancePresentOnce.js

  Notes:
  - Requires MONGO_URI in environment (.env supported by server, but this script does not auto-load it).
  - Script is idempotent: it only inserts missing rows and never overwrites existing attendance.
*/

const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const connectDB = require('../config/db');
const { backfillMissingAttendanceAsPresent } = require('../services/attendanceBackfillService');

async function main() {
  await connectDB();
  const offsetMinutes = parseInt(process.env.TZ_OFFSET_MINUTES || '330', 10);

  console.log('--- SCRIPT: Attendance Backfill (Present) ---');
  const result = await backfillMissingAttendanceAsPresent({
    includeToday: false,
    offsetMinutes,
  });
  console.log('--- SCRIPT: Completed ---');
  console.log(JSON.stringify(result, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('--- SCRIPT ERROR (Attendance Backfill):', err);
    process.exit(1);
  });
