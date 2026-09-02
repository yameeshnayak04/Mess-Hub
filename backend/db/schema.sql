-- Mess Hub — PostgreSQL schema (Phase 0)
-- Money: every *_price column is a BIGINT holding a whole number of the
-- smallest currency unit (rupees x 100), so ₹6000 is stored as 600000 and no
-- amount is ever a decimal. See utils/money.js for the only two places that
-- convert between this and the rupees the API talks in.
-- Calendar-day concepts: DATE, never TIMESTAMPTZ.

CREATE EXTENSION IF NOT EXISTS postgis;      -- GEOGRAPHY(POINT) for geo discovery
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- lets GiST EXCLUDE mix equality + range/point

CREATE TYPE user_role         AS ENUM ('Customer', 'Manager');
CREATE TYPE mess_service_type AS ENUM ('Monthly Only', 'Both Daily & Monthly');
CREATE TYPE mess_cuisine      AS ENUM ('Veg', 'Non-Veg', 'Both');
CREATE TYPE meal_type         AS ENUM ('Lunch', 'Dinner');
CREATE TYPE membership_status AS ENUM ('Pending', 'Active', 'Inactive');
CREATE TYPE attendance_status AS ENUM ('Present', 'Skipped', 'Leave', 'Absent');
CREATE TYPE bill_status       AS ENUM ('Due', 'Pending Approval', 'Paid');
CREATE TYPE bill_event_type   AS ENUM ('ProofSubmitted', 'Approved', 'Rejected');

-- Reused by every table's updated_at column.
CREATE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- users
-- ============================================================
CREATE TABLE users (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name           TEXT NOT NULL,
  phone          VARCHAR(10) NOT NULL UNIQUE CHECK (phone ~ '^[0-9]{10}$'),
  password_hash  TEXT NOT NULL,
  pin_hash       TEXT,                       -- bcrypt; customers only (bug #24)
  role           user_role NOT NULL,
  location       GEOGRAPHY(POINT, 4326),     -- customers only
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- role-conditional requiredness the app used to enforce ad hoc in Mongoose validators
  CHECK (role <> 'Customer' OR (pin_hash IS NOT NULL AND location IS NOT NULL))
);
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- messes
-- ============================================================
CREATE TABLE messes (
  id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_id             BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  mess_name            TEXT NOT NULL,
  mess_image           TEXT,
  address              TEXT NOT NULL,
  city                 TEXT NOT NULL,
  contact_phone        VARCHAR(10) NOT NULL CHECK (contact_phone ~ '^[0-9]{10}$'),
  location             GEOGRAPHY(POINT, 4326) NOT NULL,
  service_type         mess_service_type NOT NULL,
  cuisine              mess_cuisine NOT NULL,
  max_capacity         INT CHECK (max_capacity IS NULL OR max_capacity > 0),
  tiffin_service       BOOLEAN NOT NULL DEFAULT false,
  basic_thali_details  TEXT NOT NULL,

  -- Timings drive meal-window logic directly — real TIME columns, not a JSONB blob,
  -- so window checks are a WHERE clause, not app-layer parsing (was billCalculation.js).
  lunch_start          TIME NOT NULL,
  lunch_end            TIME NOT NULL,
  dinner_start         TIME NOT NULL,
  dinner_end           TIME NOT NULL,

  daily_thali_rate_price BIGINT CHECK (daily_thali_rate_price IS NULL OR daily_thali_rate_price >= 0),

  -- Billing/rebate rules — flattened to real columns (not JSONB) because billing
  -- reads every one of these on every bill run; they need real types + CHECKs.
  rule_min_leave_days_for_rebate INT NOT NULL CHECK (rule_min_leave_days_for_rebate >= 1),
  rule_rebate_per_thali_price    BIGINT NOT NULL CHECK (rule_rebate_per_thali_price >= 0),
  rule_skip_allowance_percent    SMALLINT NOT NULL DEFAULT 0 CHECK (rule_skip_allowance_percent BETWEEN 0 AND 100),
  rule_allow_absent_rebate       BOOLEAN NOT NULL DEFAULT false,
  rule_min_monthly_charge_price  BIGINT CHECK (rule_min_monthly_charge_price IS NULL OR rule_min_monthly_charge_price >= 0),

  -- Informational only per product decision: shown to the customer as the advertised
  -- caution-money figure before joining. Not collected, tracked, or billed by this system.
  rule_security_deposit_price    BIGINT CHECK (rule_security_deposit_price IS NULL OR rule_security_deposit_price >= 0),

  -- Denormalized review aggregate (bug #23) — kept in sync by trg_reviews_* below.
  rating_avg    NUMERIC(2,1) NOT NULL DEFAULT 0,
  rating_count  INT NOT NULL DEFAULT 0,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CHECK (lunch_start < lunch_end),
  CHECK (dinner_start < dinner_end),
  CHECK (lunch_end <= dinner_start),                                   -- no lunch/dinner overlap
  CHECK (service_type <> 'Both Daily & Monthly' OR daily_thali_rate_price IS NOT NULL)
);
CREATE UNIQUE INDEX ux_messes_name_address ON messes (lower(mess_name), lower(address));
CREATE INDEX ix_messes_owner   ON messes (owner_id);
CREATE INDEX ix_messes_cuisine ON messes (cuisine);
CREATE INDEX ix_messes_location ON messes USING GIST (location);        -- discoverMesses geo sort
CREATE TRIGGER trg_messes_updated_at BEFORE UPDATE ON messes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- plans + plan_meals
-- ============================================================
CREATE TABLE plans (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mess_id    BIGINT NOT NULL REFERENCES messes(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  rate_price BIGINT NOT NULL CHECK (rate_price >= 0),
  is_active  BOOLEAN NOT NULL DEFAULT true,      -- retire instead of delete; memberships FK to this row
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_plans_mess_name ON plans (mess_id, lower(name));
CREATE TRIGGER trg_plans_updated_at BEFORE UPDATE ON plans
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- The relational fact that replaces every `.includes('lunch')` string parse (bug #13).
CREATE TABLE plan_meals (
  plan_id BIGINT NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  meal    meal_type NOT NULL,
  PRIMARY KEY (plan_id, meal)
  -- Invariant "every plan has >=1 row here" is enforced in the service layer
  -- (insert plan + plan_meals in one transaction) — not expressible as a single-table CHECK.
);

-- ============================================================
-- memberships
-- ============================================================
CREATE TABLE memberships (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id        BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  mess_id        BIGINT NOT NULL REFERENCES messes(id) ON DELETE RESTRICT,
  -- There is deliberately NO rate column here. Mess billing is live pricing:
  -- if a manager changes a plan's rate, every member on that plan is billed
  -- the new rate from the next bill onwards. The rate therefore always comes
  -- from a live JOIN to plans.rate_price - never snapshotted, never cached,
  -- so the two can never drift apart.
  plan_id        BIGINT NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,

  status         membership_status NOT NULL DEFAULT 'Pending',
  joined_date    DATE,
  effective_from DATE,                         -- billing-cycle anchor
  active_period  DATERANGE,                    -- set on approval, upper bound closed on discontinue

  -- Discontinue-membership flow (Correction 4) — deliberately NOT named "leave"
  -- anywhere in the schema, to keep it unconfused with vacation leave below.
  discontinuation_requested_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- A user can't have two simultaneously-Active memberships at the same mess.
  -- Rejoining after Inactive is fine — ranges don't overlap. This is what makes
  -- bug #7 (bill collision on rejoin) impossible: each stint is its own row.
  EXCLUDE USING gist (
    user_id WITH =,
    mess_id WITH =,
    active_period WITH &&
  ) WHERE (status = 'Active')
);
CREATE INDEX ix_memberships_mess_status ON memberships (mess_id, status);
CREATE INDEX ix_memberships_user_status ON memberships (user_id, status);
CREATE TRIGGER trg_memberships_updated_at BEFORE UPDATE ON memberships
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- attendance (ground truth + job-materialized Absent; see Correction 1)
-- ============================================================
CREATE TABLE attendance (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  membership_id  BIGINT NOT NULL REFERENCES memberships(id) ON DELETE RESTRICT,
  mess_id        BIGINT NOT NULL REFERENCES messes(id) ON DELETE RESTRICT, -- denormalized: dashboard hot path
  service_date   DATE NOT NULL,
  meal           meal_type NOT NULL,
  status         attendance_status NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- No rate/rebate snapshot columns here either: both the plan rate and the
  -- mess rebate rules are read live at bill-generation time.
  UNIQUE (membership_id, service_date, meal)
);
CREATE INDEX ix_attendance_dashboard ON attendance (mess_id, service_date, meal, status);
CREATE INDEX ix_attendance_calendar  ON attendance (membership_id, service_date);
CREATE TRIGGER trg_attendance_updated_at BEFORE UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- walkin_sales — daily/non-member sales; a sale, not a subscription attendance state (bug #15)
-- ============================================================
CREATE TABLE walkin_sales (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mess_id      BIGINT NOT NULL REFERENCES messes(id) ON DELETE RESTRICT,
  service_date DATE NOT NULL,
  meal         meal_type NOT NULL,
  rate_price   BIGINT NOT NULL CHECK (rate_price >= 0),   -- POS-style: the price AT sale time, correctly a snapshot
  recorded_by  BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_walkin_sales_mess_date ON walkin_sales (mess_id, service_date, meal);

-- ============================================================
-- leaves — vacation leave only. Auto-approved, no workflow (Correction 4).
-- ============================================================
CREATE TABLE leaves (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  membership_id BIGINT NOT NULL REFERENCES memberships(id) ON DELETE RESTRICT,
  period        DATERANGE NOT NULL,   -- inclusive both ends: daterange(start,end,'[]')
  reason        TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Replaces the hand-rolled $or overlap query (bug #17) with a real constraint.
  EXCLUDE USING gist (membership_id WITH =, period WITH &&)
);
CREATE INDEX ix_leaves_membership ON leaves (membership_id);

-- Every row in `leaves` must meet the mess's minimum-consecutive-days rule — enforced
-- here, not just in the service layer, so a short request is rejected at the DB and
-- every surviving leave row is rebate-eligible by construction (spec: leave only
-- qualifies for rebate once minLeaveDaysForRebate is met; old code enforced this by
-- rejecting the request outright, so there is no "leave but not rebate-eligible" state).
--
-- THIS TRIGGER IS THE SINGLE SOURCE OF TRUTH FOR THE MINIMUM-DAYS RULE. Final
-- decision — do not add a matching day-count check in leaveService or anywhere
-- else in application code. The service layer's only job is to catch this
-- trigger's raised exception (ERRCODE check_violation) and translate it into a
-- typed ValidationError carrying the trigger's own message text.
CREATE FUNCTION enforce_min_leave_days() RETURNS trigger AS $$
DECLARE
  min_days INT;
  requested_days INT;
BEGIN
  SELECT me.rule_min_leave_days_for_rebate INTO min_days
  FROM memberships mm JOIN messes me ON me.id = mm.mess_id
  WHERE mm.id = NEW.membership_id;

  requested_days := upper(NEW.period) - lower(NEW.period);  -- date ranges canonicalize to [), so this is an exact day count

  IF requested_days < min_days THEN
    RAISE EXCEPTION 'Leave must be at least % consecutive days (requested %)', min_days, requested_days
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_leaves_min_days
BEFORE INSERT OR UPDATE OF period ON leaves
FOR EACH ROW EXECUTE FUNCTION enforce_min_leave_days();

-- ============================================================
-- menus
-- ============================================================
CREATE TABLE menus (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  mess_id       BIGINT NOT NULL REFERENCES messes(id) ON DELETE CASCADE,
  service_date  DATE NOT NULL,
  lunch_items   TEXT[] NOT NULL DEFAULT '{}',
  dinner_items  TEXT[] NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (mess_id, service_date)
);
CREATE TRIGGER trg_menus_updated_at BEFORE UPDATE ON menus
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- bills + bill_events
-- ============================================================
CREATE TABLE bills (
  id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  membership_id  BIGINT NOT NULL REFERENCES memberships(id) ON DELETE RESTRICT,
  mess_id        BIGINT NOT NULL REFERENCES messes(id) ON DELETE RESTRICT,  -- denormalized: manager list/filter hot path
  period         DATE NOT NULL,          -- first day of the billed month
  base_price     BIGINT NOT NULL CHECK (base_price >= 0),
  rebate_price   BIGINT NOT NULL DEFAULT 0 CHECK (rebate_price >= 0),
  total_price    BIGINT NOT NULL CHECK (total_price >= 0),
  status         bill_status NOT NULL DEFAULT 'Due',
  payment_proof_url TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (membership_id, period),        -- bug #7: keyed by membership, not user
  CHECK (rebate_price <= base_price)
);
CREATE INDEX ix_bills_mess_status_period ON bills (mess_id, status, period DESC);
CREATE TRIGGER trg_bills_updated_at BEFORE UPDATE ON bills
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Append-only audit trail (bugs #18/#19) — proof/approval history is never overwritten in place.
CREATE TABLE bill_events (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  bill_id    BIGINT NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
  event      bill_event_type NOT NULL,
  actor_id   BIGINT REFERENCES users(id) ON DELETE SET NULL,
  proof_url  TEXT,           -- proof URL as it stood at this event; rejectPayment no longer destroys it
  note       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_bill_events_bill ON bill_events (bill_id, created_at);

-- ============================================================
-- reviews
-- ============================================================
CREATE TABLE reviews (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mess_id    BIGINT NOT NULL REFERENCES messes(id) ON DELETE CASCADE,
  rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment    TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, mess_id)
);
CREATE INDEX ix_reviews_mess ON reviews (mess_id, created_at DESC);
CREATE TRIGGER trg_reviews_updated_at BEFORE UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Keeps messes.rating_avg/rating_count in sync incrementally (bug #23) so
-- discoverMesses never recomputes review aggregates on every request.
CREATE FUNCTION refresh_mess_rating() RETURNS trigger AS $$
DECLARE
  target_mess_id BIGINT := COALESCE(NEW.mess_id, OLD.mess_id);
BEGIN
  UPDATE messes m
  SET rating_avg   = COALESCE(s.avg_rating, 0),
      rating_count = COALESCE(s.cnt, 0)
  FROM (
    SELECT AVG(rating)::NUMERIC(2,1) AS avg_rating, COUNT(*) AS cnt
    FROM reviews WHERE mess_id = target_mess_id
  ) s
  WHERE m.id = target_mess_id;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reviews_rating_sync
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION refresh_mess_rating();

-- ============================================================
-- job_runs — visibility for the absence-marking and billing jobs (Correction 1: a
-- missed run must be visible, not silent). Idempotency itself comes from the
-- attendance/bills UNIQUE constraints via upsert, not from this table.
-- ============================================================
CREATE TABLE job_runs (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  job_name      TEXT NOT NULL,           -- 'absent_marking' | 'billing'
  period_date   DATE,                    -- service_date for absence job; period for billing job
  status        TEXT NOT NULL,           -- 'running' | 'success' | 'failed'
  rows_affected INT,
  error         TEXT,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at   TIMESTAMPTZ
);
CREATE INDEX ix_job_runs_name_started ON job_runs (job_name, started_at DESC);
