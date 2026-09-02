// new_backend/jobs/jobRunner.js
//
// Wraps a background job so that every run is recorded in the job_runs table.
//
// Why bother: the absence-marking job is what turns "no record" into a real
// Absent row, and billing refuses to run on a month with missing records. So
// a job that quietly fails is not a small problem - it blocks billing. Having
// every run logged means a missed run is something you can see in a table,
// not something you find out about weeks later.
const knex = require('../db/knex');

async function runTrackedJob(jobName, periodDate, work) {
  const [run] = await knex('job_runs')
    .insert({ job_name: jobName, period_date: periodDate, status: 'running' })
    .returning('*');

  try {
    const result = await work();
    await knex('job_runs')
      .where('id', run.id)
      .update({
        status: 'success',
        rows_affected: result.rowsAffected ?? 0,
        finished_at: knex.fn.now(),
      });
    return { jobRunId: run.id, status: 'success', ...result };
  } catch (error) {
    await knex('job_runs').where('id', run.id).update({
      status: 'failed',
      error: error.message,
      finished_at: knex.fn.now(),
    });
    throw error;
  }
}

module.exports = { runTrackedJob };
