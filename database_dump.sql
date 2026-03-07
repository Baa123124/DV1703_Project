--
-- PostgreSQL database dump
--

\restrict l1QlVMgW1qDCcfktlvozg9hOY1e5B8sgZVIDJWEOSq0IiypqgGuVZFhnrQBZuuL

-- Dumped from database version 17.9
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: add_furnishing_item(character varying, character varying, numeric, character varying, numeric, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_furnishing_item(p_sku character varying, p_display_name character varying, p_daily_rate numeric, p_furnishing_kind character varying, p_weight_kg numeric DEFAULT NULL::numeric, p_notes text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_category_id INT;
DECLARE v_item_id INT;
BEGIN
  INSERT INTO categories (display_name, daily_rate)
  VALUES (p_display_name, p_daily_rate)
  ON CONFLICT (display_name)
  DO UPDATE SET daily_rate = EXCLUDED.daily_rate
  RETURNING id INTO v_category_id;

  INSERT INTO furnishing_categories (category_id, furnishing_kind, weight_kg, notes)
  VALUES (v_category_id, p_furnishing_kind, p_weight_kg, p_notes)
  ON CONFLICT (category_id)
  DO UPDATE SET
    furnishing_kind = EXCLUDED.furnishing_kind,
    weight_kg = EXCLUDED.weight_kg,
    notes = EXCLUDED.notes;

  INSERT INTO items (category_id, sku, is_active)
  VALUES (v_category_id, p_sku, TRUE)
  ON CONFLICT (sku)
  DO UPDATE SET
    category_id = EXCLUDED.category_id,
    is_active = TRUE
  RETURNING id INTO v_item_id;

  RETURN v_item_id;
END$$;


ALTER FUNCTION public.add_furnishing_item(p_sku character varying, p_display_name character varying, p_daily_rate numeric, p_furnishing_kind character varying, p_weight_kg numeric, p_notes text) OWNER TO postgres;

--
-- Name: add_furnishing_item(character varying, character varying, numeric, character varying, numeric, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_furnishing_item(p_sku character varying, p_display_name character varying, p_daily_rate numeric, p_furnishing_kind character varying, p_weight_kg numeric DEFAULT NULL::numeric, p_power_watts integer DEFAULT NULL::integer, p_notes text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_item_id INT;
BEGIN
  INSERT INTO items (sku, display_name, daily_rate)
  VALUES (p_sku, p_display_name, p_daily_rate)
  RETURNING id INTO v_item_id;

  INSERT INTO furnishings (item_id, furnishing_kind, weight_kg, power_watts, notes)
  VALUES (v_item_id, p_furnishing_kind, p_weight_kg, p_power_watts, p_notes);

  RETURN v_item_id;
END$$;


ALTER FUNCTION public.add_furnishing_item(p_sku character varying, p_display_name character varying, p_daily_rate numeric, p_furnishing_kind character varying, p_weight_kg numeric, p_power_watts integer, p_notes text) OWNER TO postgres;

--
-- Name: add_item_unit(integer, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_item_unit(p_category_id integer, p_sku character varying, p_is_active boolean DEFAULT true) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_item_id INT;
BEGIN
  -- Ensure category exists
  IF NOT EXISTS (SELECT 1 FROM categories c WHERE c.id = p_category_id) THEN
    RAISE EXCEPTION 'Category % does not exist', p_category_id;
  END IF;

  INSERT INTO items (category_id, sku, is_active)
  VALUES (p_category_id, p_sku, p_is_active)
  RETURNING id INTO v_item_id;

  RETURN v_item_id;
END$$;


ALTER FUNCTION public.add_item_unit(p_category_id integer, p_sku character varying, p_is_active boolean) OWNER TO postgres;

--
-- Name: add_tent_item(character varying, character varying, numeric, integer, integer, integer, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_tent_item(p_sku character varying, p_display_name character varying, p_daily_rate numeric, p_capacity integer, p_season_rating integer, p_estimated_build_time_minutes integer, p_construction_cost numeric, p_deconstruction_cost numeric, p_packed_weight_kg numeric DEFAULT NULL::numeric, p_floor_area_m2 numeric DEFAULT NULL::numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_category_id INT;
DECLARE v_item_id INT;
BEGIN
  INSERT INTO categories (display_name, daily_rate)
  VALUES (p_display_name, p_daily_rate)
  ON CONFLICT (display_name)
  DO UPDATE SET daily_rate = EXCLUDED.daily_rate
  RETURNING id INTO v_category_id;

  INSERT INTO tent_categories (
    category_id, capacity, season_rating, estimated_build_time_minutes,
    construction_cost, deconstruction_cost, packed_weight_kg, floor_area_m2
  )
  VALUES (
    v_category_id, p_capacity, p_season_rating, p_estimated_build_time_minutes,
    p_construction_cost, p_deconstruction_cost, p_packed_weight_kg, p_floor_area_m2
  )
  ON CONFLICT (category_id)
  DO UPDATE SET
    capacity = EXCLUDED.capacity,
    season_rating = EXCLUDED.season_rating,
    estimated_build_time_minutes = EXCLUDED.estimated_build_time_minutes,
    construction_cost = EXCLUDED.construction_cost,
    deconstruction_cost = EXCLUDED.deconstruction_cost,
    packed_weight_kg = EXCLUDED.packed_weight_kg,
    floor_area_m2 = EXCLUDED.floor_area_m2;

  INSERT INTO items (category_id, sku, is_active)
  VALUES (v_category_id, p_sku, TRUE)
  ON CONFLICT (sku)
  DO UPDATE SET
    category_id = EXCLUDED.category_id,
    is_active = TRUE
  RETURNING id INTO v_item_id;

  RETURN v_item_id;
END$$;


ALTER FUNCTION public.add_tent_item(p_sku character varying, p_display_name character varying, p_daily_rate numeric, p_capacity integer, p_season_rating integer, p_estimated_build_time_minutes integer, p_construction_cost numeric, p_deconstruction_cost numeric, p_packed_weight_kg numeric, p_floor_area_m2 numeric) OWNER TO postgres;

--
-- Name: create_booking_with_allocations(integer, date, date, integer[], integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_booking_with_allocations(p_customer_id integer, p_start date, p_end date, p_category_ids integer[], p_qtys integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_booking_id INT;
  v_i INT;
  v_cat INT;
  v_qty INT;
  v_picked_count INT;
BEGIN
  IF array_length(p_category_ids, 1) IS NULL
     OR array_length(p_qtys, 1) IS NULL
     OR array_length(p_category_ids, 1) <> array_length(p_qtys, 1) THEN
    RAISE EXCEPTION 'category_ids and qtys must have same length';
  END IF;

  IF p_end <= p_start THEN
    RAISE EXCEPTION 'Invalid dates: end_date must be after start_date';
  END IF;

  -- Create booking header
  INSERT INTO bookings (customer_id, start_date, end_date, status)
  VALUES (p_customer_id, p_start, p_end, 'pending')
  RETURNING id INTO v_booking_id;

  -- Allocate items per category
  FOR v_i IN 1..array_length(p_category_ids, 1) LOOP
    v_cat := p_category_ids[v_i];
    v_qty := p_qtys[v_i];

    IF v_qty IS NULL OR v_qty <= 0 THEN
      RAISE EXCEPTION 'Invalid qty % for category %', v_qty, v_cat;
    END IF;

    WITH picked AS (
      SELECT i.id
      FROM items i
      WHERE i.category_id = v_cat
        AND i.is_active = TRUE
        AND NOT EXISTS (
          SELECT 1
          FROM booking_items bi
          JOIN bookings b ON b.id = bi.booking_id
          WHERE bi.item_id = i.id
            AND b.status <> 'cancelled'
            AND p_start < b.end_date
            AND p_end > b.start_date
        )
      ORDER BY i.id
      FOR UPDATE SKIP LOCKED
      LIMIT v_qty
    ),
    ins AS (
      INSERT INTO booking_items (booking_id, item_id, price_per_day)
      SELECT v_booking_id, p.id, c.daily_rate
      FROM picked p
      JOIN items i ON i.id = p.id
      JOIN categories c ON c.id = i.category_id
      RETURNING 1
    )
    SELECT COUNT(*) INTO v_picked_count FROM ins;

    IF v_picked_count <> v_qty THEN
      RAISE EXCEPTION
        'Not enough available units for category %: requested %, got %',
        v_cat, v_qty, v_picked_count;
    END IF;
  END LOOP;

  RETURN v_booking_id;
END$$;


ALTER FUNCTION public.create_booking_with_allocations(p_customer_id integer, p_start date, p_end date, p_category_ids integer[], p_qtys integer[]) OWNER TO postgres;

--
-- Name: trg_category_must_have_exactly_one_subtype(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_category_must_have_exactly_one_subtype() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT
    (CASE WHEN EXISTS (SELECT 1 FROM tent_categories t WHERE t.category_id = NEW.id) THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM furnishing_categories f WHERE f.category_id = NEW.id) THEN 1 ELSE 0 END)
  INTO v_count;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Category % must have exactly one subtype row (tent_categories XOR furnishing_categories)', NEW.id;
  END IF;

  RETURN NULL;
END$$;


ALTER FUNCTION public.trg_category_must_have_exactly_one_subtype() OWNER TO postgres;

--
-- Name: trg_item_must_have_exactly_one_subtype(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_item_must_have_exactly_one_subtype() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT
    (CASE WHEN EXISTS (SELECT 1 FROM tents t WHERE t.item_id = NEW.id) THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM furnishings f WHERE f.item_id = NEW.id) THEN 1 ELSE 0 END)
  INTO v_count;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Item % must have exactly one subtype row (tents XOR furnishings)', NEW.id;
  END IF;
  RETURN NULL;
END$$;


ALTER FUNCTION public.trg_item_must_have_exactly_one_subtype() OWNER TO postgres;

--
-- Name: trg_prevent_overlapping_item_booking(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_prevent_overlapping_item_booking() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_start DATE;
DECLARE v_end DATE;
BEGIN
  SELECT b.start_date, b.end_date INTO v_start, v_end
  FROM bookings b WHERE b.id = NEW.booking_id;

  IF EXISTS (
    SELECT 1
    FROM booking_items bi
    JOIN bookings b2 ON b2.id = bi.booking_id
    WHERE bi.item_id = NEW.item_id
      AND b2.status <> 'cancelled'
      AND bi.booking_id <> NEW.booking_id
      AND v_start < b2.end_date
      AND v_end > b2.start_date
  ) THEN
    RAISE EXCEPTION 'Item % is already booked for an overlapping period', NEW.item_id;
  END IF;

  RETURN NEW;
END$$;


ALTER FUNCTION public.trg_prevent_overlapping_item_booking() OWNER TO postgres;

--
-- Name: trg_prevent_two_category_subtypes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_prevent_two_category_subtypes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_TABLE_NAME = 'tent_categories' THEN
    IF EXISTS (SELECT 1 FROM furnishing_categories f WHERE f.category_id = NEW.category_id) THEN
      RAISE EXCEPTION 'Category % cannot be both tent and furnishing', NEW.category_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'furnishing_categories' THEN
    IF EXISTS (SELECT 1 FROM tent_categories t WHERE t.category_id = NEW.category_id) THEN
      RAISE EXCEPTION 'Category % cannot be both tent and furnishing', NEW.category_id;
    END IF;
  END IF;
  RETURN NEW;
END$$;


ALTER FUNCTION public.trg_prevent_two_category_subtypes() OWNER TO postgres;

--
-- Name: trg_prevent_two_subtypes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_prevent_two_subtypes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_TABLE_NAME = 'tents' THEN
    IF EXISTS (SELECT 1 FROM furnishings f WHERE f.item_id = NEW.item_id) THEN
      RAISE EXCEPTION 'Item % cannot be both tent and furnishing', NEW.item_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'furnishings' THEN
    IF EXISTS (SELECT 1 FROM tents t WHERE t.item_id = NEW.item_id) THEN
      RAISE EXCEPTION 'Item % cannot be both tent and furnishing', NEW.item_id;
    END IF;
  END IF;
  RETURN NEW;
END$$;


ALTER FUNCTION public.trg_prevent_two_subtypes() OWNER TO postgres;

--
-- Name: trg_users_disjoint_customer_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_users_disjoint_customer_admin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_TABLE_NAME = 'admins' THEN
    IF EXISTS (SELECT 1 FROM customers c WHERE c.user_id = NEW.user_id) THEN
      RAISE EXCEPTION 'User % cannot be both admin and customer', NEW.user_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'customers' THEN
    IF NEW.user_id IS NOT NULL AND EXISTS (SELECT 1 FROM admins a WHERE a.user_id = NEW.user_id) THEN
      RAISE EXCEPTION 'User % cannot be both customer and admin', NEW.user_id;
    END IF;
  END IF;

  RETURN NEW;
END$$;


ALTER FUNCTION public.trg_users_disjoint_customer_admin() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: booking_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking_items (
    booking_id integer NOT NULL,
    item_id integer NOT NULL,
    price_per_day numeric(10,2),
    line_note character varying(255),
    CONSTRAINT chk_line_price CHECK (((price_per_day IS NULL) OR (price_per_day >= (0)::numeric)))
);


ALTER TABLE public.booking_items OWNER TO postgres;

--
-- Name: bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookings (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_booking_dates CHECK ((end_date > start_date)),
    CONSTRAINT chk_booking_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.bookings OWNER TO postgres;

--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bookings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bookings_id_seq OWNER TO postgres;

--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    display_name character varying(200) NOT NULL,
    daily_rate numeric(10,2) DEFAULT 0.00 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_category_daily_rate CHECK ((daily_rate >= (0)::numeric))
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    full_name character varying(200) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(50),
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_id_seq OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: furnishing_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.furnishing_categories (
    category_id integer NOT NULL,
    furnishing_kind character varying(100) NOT NULL,
    weight_kg numeric(5,2),
    notes text,
    CONSTRAINT chk_furncat_weight CHECK (((weight_kg IS NULL) OR (weight_kg >= (0)::numeric)))
);


ALTER TABLE public.furnishing_categories OWNER TO postgres;

--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items (
    id integer NOT NULL,
    category_id integer NOT NULL,
    sku character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_id_seq OWNER TO postgres;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: tent_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tent_categories (
    category_id integer NOT NULL,
    capacity integer NOT NULL,
    season_rating integer NOT NULL,
    packed_weight_kg numeric(5,2),
    floor_area_m2 numeric(5,2),
    estimated_build_time_minutes integer DEFAULT 10 NOT NULL,
    construction_cost numeric(10,2) DEFAULT 0.00 NOT NULL,
    deconstruction_cost numeric(10,2) DEFAULT 0.00 NOT NULL,
    CONSTRAINT chk_tentcap_area CHECK (((floor_area_m2 IS NULL) OR (floor_area_m2 >= (0)::numeric))),
    CONSTRAINT chk_tentcap_build_time CHECK ((estimated_build_time_minutes >= 0)),
    CONSTRAINT chk_tentcap_capacity CHECK ((capacity > 0)),
    CONSTRAINT chk_tentcap_construction_cost CHECK ((construction_cost >= (0)::numeric)),
    CONSTRAINT chk_tentcap_deconstruction_cost CHECK ((deconstruction_cost >= (0)::numeric)),
    CONSTRAINT chk_tentcap_season CHECK (((season_rating >= 1) AND (season_rating <= 5))),
    CONSTRAINT chk_tentcap_weight CHECK (((packed_weight_kg IS NULL) OR (packed_weight_kg >= (0)::numeric)))
);


ALTER TABLE public.tent_categories OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) DEFAULT 'customer'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_user_role CHECK (((role)::text = ANY ((ARRAY['customer'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: booking_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking_items (booking_id, item_id, price_per_day, line_note) FROM stdin;
1	14	299.00	\N
1	9	249.00	\N
2	12	1099.00	\N
2	3	20.00	\N
2	4	20.00	\N
2	5	20.00	\N
2	6	20.00	\N
2	7	20.00	\N
2	8	20.00	\N
2	9	249.00	\N
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (id, customer_id, start_date, end_date, status, created_at) FROM stdin;
2	1	2026-03-06	2026-03-13	confirmed	2026-03-04 00:27:05.791714
1	1	2026-03-04	2026-03-06	confirmed	2026-03-04 00:04:33.846617
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, display_name, daily_rate, created_at) FROM stdin;
1	Table	80.00	2026-03-03 23:57:26.921675
2	Chair	20.00	2026-03-03 23:57:26.921675
3	Bench set	249.00	2026-03-03 23:57:26.921675
4	Tält 6×6 m	1399.00	2026-03-03 23:57:26.921675
5	Tält 8×4 m	1099.00	2026-03-03 23:57:26.921675
6	Tält 6×10 m	2099.00	2026-03-03 23:57:26.921675
7	3x3	299.00	2026-03-03 23:58:32.113622
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (id, full_name, email, phone, user_id, created_at) FROM stdin;
1	Temp Customer	hej.hej@hej.hej	\N	2	2026-03-03 23:57:26.921675
\.


--
-- Data for Name: furnishing_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.furnishing_categories (category_id, furnishing_kind, weight_kg, notes) FROM stdin;
1	table	\N	Table for about 6 people
2	chair	\N	\N
3	bench_set	\N	Good for large events
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, category_id, sku, is_active, created_at) FROM stdin;
1	1	FURN-TABLE-01	t	2026-03-03 23:57:26.921675
2	1	FURN-TABLE-02	t	2026-03-03 23:57:26.921675
3	2	FURN-CHAIR-01	t	2026-03-03 23:57:26.921675
4	2	FURN-CHAIR-02	t	2026-03-03 23:57:26.921675
5	2	FURN-CHAIR-03	t	2026-03-03 23:57:26.921675
6	2	FURN-CHAIR-04	t	2026-03-03 23:57:26.921675
7	2	FURN-CHAIR-05	t	2026-03-03 23:57:26.921675
8	2	FURN-CHAIR-06	t	2026-03-03 23:57:26.921675
9	3	FURN-BENCHSET-01	t	2026-03-03 23:57:26.921675
10	3	FURN-BENCHSET-02	t	2026-03-03 23:57:26.921675
11	4	TENT-6X6-01	t	2026-03-03 23:57:26.921675
12	5	TENT-8X4-01	t	2026-03-03 23:57:26.921675
14	7	TENT-3X3-01	t	2026-03-03 23:58:48.200124
13	6	TENT-6X10-01	f	2026-03-03 23:57:26.921675
\.


--
-- Data for Name: tent_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tent_categories (category_id, capacity, season_rating, packed_weight_kg, floor_area_m2, estimated_build_time_minutes, construction_cost, deconstruction_cost) FROM stdin;
4	45	5	\N	36.00	45	799.50	799.50
5	40	4	\N	32.00	45	699.50	699.50
6	80	5	\N	60.00	60	1199.50	1199.50
7	6	2	15.00	9.00	30	199.00	199.00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, role, created_at) FROM stdin;
1	karl.wikell@gmail.com	scrypt:32768:8:1$1z5iIQD92wfjBVUN$8e62ff9a3ae9b98321b1d2d4fb80b2dc37f9534802db8fc5b717b50aea3d5bba2063347d6a20bc955b32d55af40da2f2e1eebdb9268b96a8f291933462f26251	admin	2026-03-03 23:57:26.921675
2	hej.hej@hej.hej	scrypt:32768:8:1$eyn1bDVNtnXitaoA$acd11765235f78a0f71f91e2f3063a92cb049d3c59bf355bb27356fae6787e159390388c3a544667d4ac060c6bc1c8a7918decd4ebd1b1b4bc71b05b85fb4b20	customer	2026-03-03 23:57:26.921675
\.


--
-- Name: bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bookings_id_seq', 2, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 7, true);


--
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_id_seq', 1, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_id_seq', 14, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: booking_items booking_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT booking_items_pkey PRIMARY KEY (booking_id, item_id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: categories categories_display_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_display_name_key UNIQUE (display_name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: customers customers_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_user_id_key UNIQUE (user_id);


--
-- Name: furnishing_categories furnishing_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.furnishing_categories
    ADD CONSTRAINT furnishing_categories_pkey PRIMARY KEY (category_id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: items items_sku_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_sku_key UNIQUE (sku);


--
-- Name: tent_categories tent_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tent_categories
    ADD CONSTRAINT tent_categories_pkey PRIMARY KEY (category_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_booking_items_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_items_item_id ON public.booking_items USING btree (item_id);


--
-- Name: idx_bookings_customer_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_customer_created ON public.bookings USING btree (customer_id, created_at);


--
-- Name: idx_bookings_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_dates ON public.bookings USING btree (start_date, end_date);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);


--
-- Name: idx_items_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_items_active ON public.items USING btree (is_active);


--
-- Name: idx_items_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_items_category ON public.items USING btree (category_id);


--
-- Name: furnishing_categories before_furncat_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_furncat_insert BEFORE INSERT OR UPDATE ON public.furnishing_categories FOR EACH ROW EXECUTE FUNCTION public.trg_prevent_two_category_subtypes();


--
-- Name: tent_categories before_tentcat_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_tentcat_insert BEFORE INSERT OR UPDATE ON public.tent_categories FOR EACH ROW EXECUTE FUNCTION public.trg_prevent_two_category_subtypes();


--
-- Name: categories category_subtype_required; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER category_subtype_required AFTER INSERT ON public.categories DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.trg_category_must_have_exactly_one_subtype();


--
-- Name: booking_items prevent_overlap_on_booking_items; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER prevent_overlap_on_booking_items BEFORE INSERT OR UPDATE ON public.booking_items FOR EACH ROW EXECUTE FUNCTION public.trg_prevent_overlapping_item_booking();


--
-- Name: booking_items booking_items_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT booking_items_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: booking_items booking_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_items
    ADD CONSTRAINT booking_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE RESTRICT;


--
-- Name: bookings bookings_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE RESTRICT;


--
-- Name: customers customers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: furnishing_categories furnishing_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.furnishing_categories
    ADD CONSTRAINT furnishing_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: items items_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: tent_categories tent_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tent_categories
    ADD CONSTRAINT tent_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict l1QlVMgW1qDCcfktlvozg9hOY1e5B8sgZVIDJWEOSq0IiypqgGuVZFhnrQBZuuL

