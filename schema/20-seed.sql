-- ===== Roles (กันซ้ำด้วย ON CONFLICT) =====
INSERT INTO roles (role_uuid, name, authority)
VALUES ('7d1b82b1-92c7-4fae-b790-73eb1ac9d6b5', 'USER', 'user:read,user:update,ticket:create,ticket:read,ticket:update,comment:create,comment:read,comment:update,comment:delete,task:read')
ON CONFLICT (name) DO NOTHING;

INSERT INTO roles (role_uuid, name, authority)
VALUES ('1a0e13de-4fdf-4db0-8a3d-08fce64cbeaa', 'DEALER', 'user:read,user:update,ticket:create,ticket:read,ticket:update,comment:create,comment:read,comment:update,comment:delete,task:create,task:read,task:update,task:delete')
ON CONFLICT (name) DO NOTHING;

INSERT INTO roles (role_uuid, name, authority)
VALUES ('1a0e13de-4fdf-4db0-8a3d-08fce64cbe8c', 'TECH_SUPPORT', 'user:read,user:update,ticket:create,ticket:read,ticket:update,comment:create,comment:read,comment:update,comment:delete,task:create,task:read,task:update,task:delete')
ON CONFLICT (name) DO NOTHING;

INSERT INTO roles (role_uuid, name, authority)
VALUES ('894853e1-9238-4c64-b5d8-c0a29bdf1b94', 'MANAGER', 'user:create,user:read,user:update,ticket:create,ticket:read,ticket:update,ticket:delete,comment:create,comment:read,comment:update,comment:delete,task:create,task:read,task:update,task:delete')
ON CONFLICT (name) DO NOTHING;

INSERT INTO roles (role_uuid, name, authority)
VALUES ('7f907494-90b0-4165-b2fd-00e04fb18b49', 'ADMIN', 'user:create,user:read,user:update,user:delete,ticket:create,ticket:read,ticket:update,ticket:delete,comment:create,comment:read,comment:update,comment:delete,task:create,task:read,task:update,task:delete')
ON CONFLICT (name) DO NOTHING;

INSERT INTO roles (role_uuid, name, authority)
VALUES ('838ca5ee-eb15-427a-b380-6cf7bfbd68b7', 'SUPER_ADMIN', 'app:create,app:read,app:update,app:delete,user:create,user:read,user:update,user:delete,ticket:create,ticket:read,ticket:update,ticket:delete,comment:create,comment:read,comment:update,comment:delete,task:create,task:read,task:update,task:delete')
ON CONFLICT (name) DO NOTHING;

-- ===== Stored Procedure: create_user =====
CREATE OR REPLACE PROCEDURE create_user (
    IN p_user_uuid VARCHAR(40),
    IN p_first_name VARCHAR(25),
    IN p_last_name VARCHAR(25),
    IN p_email VARCHAR(254),
    IN p_username VARCHAR(25),
    IN p_password VARCHAR(255),
    IN p_credential_uuid VARCHAR(40),
    IN p_token VARCHAR(40),
    IN p_member_id VARCHAR(40)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    INSERT INTO users (user_uuid, first_name, last_name, email, username, member_id)
    VALUES (p_user_uuid, p_first_name, p_last_name, p_email, p_username, p_member_id)
    ON CONFLICT (username) DO NOTHING
    RETURNING user_id INTO v_user_id;

    IF v_user_id IS NULL THEN
        SELECT user_id INTO v_user_id FROM users WHERE username = p_username;
    END IF;

    INSERT INTO credentials (credential_uuid, user_id, password)
    VALUES (p_credential_uuid, v_user_id, p_password)
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO user_roles (user_id, role_id)
    VALUES (v_user_id, (SELECT role_id FROM roles WHERE name = 'USER'))
    ON CONFLICT (user_id, role_id) DO NOTHING;

    INSERT INTO account_tokens (user_id, token)
    VALUES (v_user_id, p_token)
    ON CONFLICT (user_id) DO NOTHING;
END;
$$;

-- ===== Admin (ใช้รหัสผ่าน BCRYPT ที่คุณมี) =====
CALL create_user(
    '7a7d9976-27dd-4d68-8113-beb2627e949e',
    'Junior', 'RT',
    'getarrayz@gmail.com',
    'admin',
    '$2a$12$MQhw2cYE85NltyyyERz/sesUNnU.WcWfdu8V0QGyNEDt80pki2ONC',
    'f7c5cd16-3fc9-4ea5-bcca-ed695993b263',
    '0b6e298e-dc46-41bd-9662-d627864433be',
    '68-54986-93'
);

-- อัปเกรด admin → SUPER_ADMIN (กันซ้ำ)
INSERT INTO user_roles (user_id, role_id)
SELECT u.user_id, r.role_id
FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'SUPER_ADMIN'
ON CONFLICT (user_id, role_id) DO NOTHING;

-- ===== OAuth2 Clients (dev-friendly) =====
-- แนะนำ upsert ตาม client_id เพื่อแก้ค่าได้ง่าย
CREATE OR REPLACE FUNCTION upsert_oauth2_client(
    p_id VARCHAR, p_client_id VARCHAR, p_secret VARCHAR, p_name VARCHAR,
    p_auth_methods VARCHAR, p_grants VARCHAR,
    p_redirect_uris VARCHAR, p_post_logout_uris VARCHAR,
    p_scopes VARCHAR, p_client_settings VARCHAR, p_token_settings VARCHAR
) RETURNS VOID AS $$
BEGIN
    INSERT INTO oauth2_registered_client (
        id, client_id, client_id_issued_at, client_secret, client_name,
        client_authentication_methods, authorization_grant_types,
        redirect_uris, post_logout_redirect_uris, scopes,
        client_settings, token_settings
    )
    VALUES (
        p_id, p_client_id, NOW(), p_secret, p_name,
        p_auth_methods, p_grants,
        p_redirect_uris, p_post_logout_uris, p_scopes,
        p_client_settings, p_token_settings
    )
    ON CONFLICT (client_id) DO UPDATE
      SET client_secret = EXCLUDED.client_secret,
          client_name = EXCLUDED.client_name,
          client_authentication_methods = EXCLUDED.client_authentication_methods,
          authorization_grant_types = EXCLUDED.authorization_grant_types,
          redirect_uris = EXCLUDED.redirect_uris,
          post_logout_redirect_uris = EXCLUDED.post_logout_redirect_uris,
          scopes = EXCLUDED.scopes,
          client_settings = EXCLUDED.client_settings,
          token_settings = EXCLUDED.token_settings;
END; $$ LANGUAGE plpgsql;

-- ตัวอย่าง client (ปรับให้ตรงกับ Auth Server ของคุณ)
SELECT upsert_oauth2_client(
  'c1', 'web-client', '{bcrypt}$2a$10$9v7p0bO3wJ1vBzJ1y7zN8e6yG9xq0P2JzTt6n2u1C7b9m6Qe0Qy6a', 'Web Client',
  'client_secret_basic',
  'authorization_code,refresh_token',
  'http://localhost:8080/login/oauth2/code/web-client-oidc',
  'http://localhost:8080/',
  'openid,profile,api.read',
  '{"require-proof-key": false, "require-authorization-consent": true}',
  '{"access-token-time-to-live": "PT1H", "refresh-token-time-to-live": "P30D", "reuse-refresh-tokens": true}'
);

SELECT upsert_oauth2_client(
  'c2', 'svc-client', '{bcrypt}$2a$10$E2f6p3z0s.3Qx0g8t2d6qO0Qx8KpQpUOtxh7s8l3g9Qy5a8rX2v7K', 'Service Client',
  'client_secret_basic',
  'client_credentials',
  NULL, NULL,
  'api.read',
  '{"require-proof-key": false, "require-authorization-consent": false}',
  '{"access-token-time-to-live": "PT30M"}'
);

SELECT upsert_oauth2_client(
  'c3', 'spa-client', null, 'SPA Client',
  'none',
  'authorization_code',
  'https://ticket.beus.biz/auth/callback',
  'https://ticket.beus.biz',
  'openid,profile,email,api.read',
  '{"require-proof-key": true, "require-authorization-consent": true}',
  '{"access-token-time-to-live": "PT15M", "reuse-refresh-tokens": false}'
);
