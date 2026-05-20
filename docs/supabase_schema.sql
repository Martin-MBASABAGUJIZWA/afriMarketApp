-- ============================================================
-- AfriMarket — Complete Production Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- trigram search
CREATE EXTENSION IF NOT EXISTS "unaccent";   -- accent-insensitive search

-- ============================================================
-- PROFILES (extends auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name     TEXT NOT NULL DEFAULT '',
  email         TEXT,
  phone         TEXT,
  avatar_url    TEXT,
  location      TEXT,
  role          TEXT NOT NULL DEFAULT 'buyer'
                  CHECK (role IN ('buyer', 'seller', 'admin', 'super_admin')),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL UNIQUE,
  slug        TEXT NOT NULL UNIQUE,
  icon        TEXT,
  image_url   TEXT,
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order  INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SELLERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sellers (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_name  TEXT NOT NULL,
  category       TEXT NOT NULL DEFAULT 'General',
  description    TEXT,
  location       TEXT NOT NULL DEFAULT 'Kigali',
  phone          TEXT NOT NULL DEFAULT '',
  logo_url       TEXT,
  banner_url     TEXT,
  is_verified    BOOLEAN NOT NULL DEFAULT FALSE,
  is_open        BOOLEAN NOT NULL DEFAULT TRUE,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  rating         NUMERIC(3,2) NOT NULL DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  total_sales    INT NOT NULL DEFAULT 0,
  total_revenue  NUMERIC(14,2) NOT NULL DEFAULT 0.0,
  commission_rate NUMERIC(5,4) NOT NULL DEFAULT 0.05,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.products (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id      UUID NOT NULL REFERENCES public.sellers(id) ON DELETE CASCADE,
  category_id    UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  name           TEXT NOT NULL,
  description    TEXT,
  price          NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  compare_price  NUMERIC(12,2),                          -- original price for discounts
  unit           TEXT NOT NULL DEFAULT 'each',
  stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  sku            TEXT UNIQUE,
  image_urls     TEXT[] NOT NULL DEFAULT '{}',
  is_featured    BOOLEAN NOT NULL DEFAULT FALSE,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  rating         NUMERIC(3,2) NOT NULL DEFAULT 0.0,
  review_count   INT NOT NULL DEFAULT 0,
  sold_count     INT NOT NULL DEFAULT 0,
  tags           TEXT[] NOT NULL DEFAULT '{}',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at     TIMESTAMPTZ                              -- soft delete
);

CREATE INDEX IF NOT EXISTS idx_products_seller    ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category  ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_featured  ON public.products(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_active    ON public.products(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_search    ON public.products USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- ============================================================
-- CART ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cart_items (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity    INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_user ON public.cart_items(user_id);

-- ============================================================
-- ADDRESSES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.addresses (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label        TEXT NOT NULL DEFAULT 'Home',             -- Home / Work / Other
  full_name    TEXT NOT NULL,
  phone        TEXT NOT NULL,
  street       TEXT NOT NULL,
  district     TEXT NOT NULL,
  province     TEXT NOT NULL DEFAULT 'Kigali',
  country      TEXT NOT NULL DEFAULT 'Rwanda',
  is_default   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_addresses_user ON public.addresses(user_id);

-- ============================================================
-- ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id),
  seller_id       UUID NOT NULL REFERENCES public.sellers(id),
  address_id      UUID REFERENCES public.addresses(id),
  status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','confirmed','processing','shipped','delivered','completed','cancelled','refunded')),
  payment_method  TEXT NOT NULL DEFAULT 'cash',
  payment_status  TEXT NOT NULL DEFAULT 'unpaid'
                    CHECK (payment_status IN ('unpaid','paid','failed','refunded')),
  payment_ref     TEXT,
  subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
  delivery_fee    NUMERIC(12,2) NOT NULL DEFAULT 500,
  commission      NUMERIC(12,2) NOT NULL DEFAULT 0,
  total           NUMERIC(12,2) NOT NULL DEFAULT 0,
  notes           TEXT,
  cancelled_at    TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user   ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller ON public.orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- ============================================================
-- ORDER ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.order_items (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id     UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id   UUID NOT NULL REFERENCES public.products(id),
  product_name TEXT NOT NULL,                            -- snapshot at order time
  unit_price   NUMERIC(12,2) NOT NULL,
  quantity     INT NOT NULL CHECK (quantity > 0),
  total        NUMERIC(12,2) NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);

-- ============================================================
-- REVIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id  UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seller_id   UUID NOT NULL REFERENCES public.sellers(id),
  rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,           -- purchased before reviewing
  helpful     INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_product ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_seller  ON public.reviews(seller_id);

-- ============================================================
-- FAVORITES (wishlist)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON public.favorites(user_id);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL DEFAULT 'info'
                CHECK (type IN ('order','payment','promo','system','info','alert')),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB,
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user    ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread  ON public.notifications(user_id, is_read) WHERE is_read = FALSE;

-- ============================================================
-- COUPONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.coupons (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code          TEXT NOT NULL UNIQUE,
  type          TEXT NOT NULL DEFAULT 'percent' CHECK (type IN ('percent','fixed')),
  value         NUMERIC(10,2) NOT NULL,
  min_order     NUMERIC(10,2) NOT NULL DEFAULT 0,
  max_discount  NUMERIC(10,2),
  uses_limit    INT,
  uses_count    INT NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  expires_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- DISPUTES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.disputes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id    UUID NOT NULL REFERENCES public.orders(id),
  user_id     UUID NOT NULL REFERENCES public.profiles(id),
  seller_id   UUID NOT NULL REFERENCES public.sellers(id),
  reason      TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'open'
                CHECK (status IN ('open','investigating','resolved','closed')),
  resolution  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- AUDIT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.profiles(id),
  action     TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id  UUID,
  old_data   JSONB,
  new_data   JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_user   ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON public.audit_logs(action);

-- ============================================================
-- TRIGGERS — auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['profiles','sellers','products','orders','reviews']
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%1$s_updated_at ON public.%1$s;
       CREATE TRIGGER trg_%1$s_updated_at
       BEFORE UPDATE ON public.%1$s
       FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();', t);
  END LOOP;
END;
$$;

-- ============================================================
-- TRIGGER — auto-create profile on sign-up
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'buyer'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- TRIGGER — recalculate product rating after review upsert
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_product_rating()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.products
  SET
    rating       = (SELECT AVG(rating) FROM public.reviews WHERE product_id = NEW.product_id),
    review_count = (SELECT COUNT(*)    FROM public.reviews WHERE product_id = NEW.product_id)
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_rating ON public.reviews;
CREATE TRIGGER trg_product_rating
  AFTER INSERT OR UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_product_rating();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Helper to get the current user's role
CREATE OR REPLACE FUNCTION public.current_role_name()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- PROFILES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles: public read"    ON public.profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles: own insert"     ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "profiles: own update"     ON public.profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles: admin full"     ON public.profiles FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- CATEGORIES (read-only for buyers, managed by admins)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categories: public read"  ON public.categories FOR SELECT USING (is_active = TRUE);
CREATE POLICY "categories: admin write"  ON public.categories FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- SELLERS
ALTER TABLE public.sellers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sellers: public read"     ON public.sellers FOR SELECT USING (is_active = TRUE);
CREATE POLICY "sellers: own insert"      ON public.sellers FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "sellers: own update"      ON public.sellers FOR UPDATE
  USING (user_id = auth.uid());
CREATE POLICY "sellers: admin full"      ON public.sellers FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- PRODUCTS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products: public read"    ON public.products FOR SELECT
  USING (is_active = TRUE AND deleted_at IS NULL);
CREATE POLICY "products: seller insert"  ON public.products FOR INSERT
  WITH CHECK (seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()));
CREATE POLICY "products: seller update"  ON public.products FOR UPDATE
  USING (seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()));
CREATE POLICY "products: seller delete"  ON public.products FOR DELETE
  USING (seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()));
CREATE POLICY "products: admin full"     ON public.products FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- CART ITEMS
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cart: own access"         ON public.cart_items FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ADDRESSES
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "addresses: own access"    ON public.addresses FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ORDERS — buyers see their own; sellers see their shop's orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders: buyer read"       ON public.orders FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "orders: seller read"      ON public.orders FOR SELECT
  USING (seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()));
CREATE POLICY "orders: buyer insert"     ON public.orders FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "orders: seller update"    ON public.orders FOR UPDATE
  USING (seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()));
CREATE POLICY "orders: admin full"       ON public.orders FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- ORDER ITEMS
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_items: via order"   ON public.order_items FOR SELECT
  USING (
    order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
    OR
    order_id IN (
      SELECT o.id FROM public.orders o
      JOIN public.sellers s ON s.id = o.seller_id
      WHERE s.user_id = auth.uid()
    )
  );
CREATE POLICY "order_items: insert"      ON public.order_items FOR INSERT
  WITH CHECK (
    order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
  );

-- REVIEWS
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reviews: public read"     ON public.reviews FOR SELECT USING (TRUE);
CREATE POLICY "reviews: own write"       ON public.reviews FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "reviews: own update"      ON public.reviews FOR UPDATE
  USING (user_id = auth.uid());

-- FAVORITES
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "favorites: own access"    ON public.favorites FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- NOTIFICATIONS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifications: own read"  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "notifications: own update" ON public.notifications FOR UPDATE
  USING (user_id = auth.uid());
CREATE POLICY "notifications: service insert" ON public.notifications FOR INSERT
  WITH CHECK (TRUE);                        -- edge functions / service role only

-- COUPONS (public read)
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "coupons: public read"     ON public.coupons FOR SELECT USING (is_active = TRUE);
CREATE POLICY "coupons: admin write"     ON public.coupons FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- DISPUTES
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "disputes: own read"       ON public.disputes FOR SELECT
  USING (user_id = auth.uid() OR seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()));
CREATE POLICY "disputes: buyer insert"   ON public.disputes FOR INSERT
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "disputes: admin full"     ON public.disputes FOR ALL
  USING (public.current_role_name() IN ('admin','super_admin'));

-- AUDIT LOGS (admin only)
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit: admin read"        ON public.audit_logs FOR SELECT
  USING (public.current_role_name() IN ('admin','super_admin'));
CREATE POLICY "audit: service insert"    ON public.audit_logs FOR INSERT WITH CHECK (TRUE);

-- ============================================================
-- STORAGE BUCKETS
-- Run separately in: Supabase Dashboard → Storage
-- ============================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('products', 'products', TRUE);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', TRUE);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('banners', 'banners', TRUE);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', FALSE);

-- ============================================================
-- STORAGE BUCKET POLICIES — 'products' bucket
-- Apply in: Supabase Dashboard → Storage → products → Policies
-- ============================================================
-- The 'products' bucket stores product images uploaded by sellers.
-- Images are stored at path: {seller_auth_uid}/{timestamp}.{ext}
-- This path prefix enables per-seller RLS on storage.

-- 1. Public read — anyone (including guests) can view product images
CREATE POLICY "products bucket: public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'products');

-- 2. Authenticated insert — any logged-in user (seller) can upload
CREATE POLICY "products bucket: authenticated insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'products'
    AND auth.role() = 'authenticated'
  );

-- 3. Owner delete — sellers can only delete images they uploaded
--    (first path segment must match their auth UID)
CREATE POLICY "products bucket: owner delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'products'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- 4. Owner update — sellers can only update their own images
CREATE POLICY "products bucket: owner update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'products'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- STORAGE BUCKET POLICIES — 'avatars' bucket
-- ============================================================
-- Images stored at: {user_auth_uid}/{timestamp}.{ext}

CREATE POLICY "avatars bucket: public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars bucket: owner insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars bucket: owner delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- SEED: default categories
-- ============================================================
INSERT INTO public.categories (name, slug, icon, sort_order) VALUES
  ('Vegetables & Produce', 'vegetables', '🥦', 1),
  ('Fruits',               'fruits',     '🍎', 2),
  ('Meat & Fish',          'meat-fish',  '🥩', 3),
  ('Dairy & Eggs',         'dairy',      '🥛', 4),
  ('Bakery & Grains',      'bakery',     '🍞', 5),
  ('Beverages',            'beverages',  '🧃', 6),
  ('Electronics',          'electronics','📱', 7),
  ('Fashion & Clothing',   'fashion',    '👗', 8),
  ('Home & Garden',        'home',       '🏠', 9),
  ('Health & Beauty',      'health',     '💊', 10),
  ('Agriculture',          'agriculture','🌾', 11),
  ('Services',             'services',   '🛠️', 12)
ON CONFLICT (slug) DO NOTHING;
