-- ========== OAUTH2 (ต้องมี) ==========
CREATE TABLE IF NOT EXISTS oauth2_registered_client (
    id VARCHAR(100) PRIMARY KEY,
    client_id VARCHAR(100) NOT NULL,
    client_id_issued_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    client_secret VARCHAR(200) DEFAULT NULL,
    client_secret_expires_at TIMESTAMP(6) WITH TIME ZONE DEFAULT NULL,
    client_name VARCHAR(200) NOT NULL,
    client_authentication_methods VARCHAR(1000) NOT NULL,
    authorization_grant_types VARCHAR(1000) NOT NULL,
    redirect_uris VARCHAR(1000) DEFAULT NULL,
    post_logout_redirect_uris VARCHAR(1000) DEFAULT NULL,
    scopes VARCHAR(1000) NOT NULL,
    client_settings VARCHAR(2000) NOT NULL,
    token_settings VARCHAR(2000) NOT NULL,
    CONSTRAINT uq_oauth2_client_client_id UNIQUE (client_id)
);

CREATE TABLE IF NOT EXISTS oauth2_authorization (
    id VARCHAR(100) PRIMARY KEY,
    registered_client_id VARCHAR(100) NOT NULL,
    principal_name VARCHAR(200) NOT NULL,
    authorization_grant_type VARCHAR(100) NOT NULL,
    authorized_scopes VARCHAR(1000),
    attributes TEXT,
    state VARCHAR(500),

    authorization_code_value BYTEA,
    authorization_code_issued_at TIMESTAMP(6) WITH TIME ZONE,
    authorization_code_expires_at TIMESTAMP(6) WITH TIME ZONE,
    authorization_code_metadata TEXT,

    access_token_value BYTEA,
    access_token_issued_at TIMESTAMP(6) WITH TIME ZONE,
    access_token_expires_at TIMESTAMP(6) WITH TIME ZONE,
    access_token_metadata TEXT,
    access_token_type VARCHAR(100),
    access_token_scopes VARCHAR(1000),

    oidc_id_token_value BYTEA,
    oidc_id_token_issued_at TIMESTAMP(6) WITH TIME ZONE,
    oidc_id_token_expires_at TIMESTAMP(6) WITH TIME ZONE,
    oidc_id_token_metadata TEXT,

    refresh_token_value BYTEA,
    refresh_token_issued_at TIMESTAMP(6) WITH TIME ZONE,
    refresh_token_expires_at TIMESTAMP(6) WITH TIME ZONE,
    refresh_token_metadata TEXT,

    CONSTRAINT fk_oauth2_authorization_client
        FOREIGN KEY (registered_client_id) REFERENCES oauth2_registered_client(id)
);

CREATE TABLE IF NOT EXISTS oauth2_authorization_consent (
    registered_client_id VARCHAR(100) NOT NULL,
    principal_name VARCHAR(200) NOT NULL,
    authorities VARCHAR(1000) NOT NULL,
    PRIMARY KEY (registered_client_id, principal_name)
);

CREATE INDEX IF NOT EXISTS idx_oauth2_auth_principal ON oauth2_authorization(principal_name);
CREATE INDEX IF NOT EXISTS idx_oauth2_auth_client ON oauth2_authorization(registered_client_id);

-- ========== USER SERVICE ==========
CREATE TABLE IF NOT EXISTS users (
    user_id BIGSERIAL PRIMARY KEY,
    user_uuid VARCHAR(40) NOT NULL,
    username VARCHAR(25) NOT NULL,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    email CITEXT NOT NULL,                           -- ใช้ citext สำหรับ unique แบบ case-insensitive
    member_id VARCHAR(40) NOT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    address VARCHAR(100) DEFAULT NULL,
    bio VARCHAR(100) DEFAULT NULL,
    qr_code_secret VARCHAR(50) DEFAULT NULL,
    qr_code_image_uri TEXT DEFAULT NULL,
    image_url VARCHAR(255) DEFAULT 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
    last_login TIMESTAMP(6) WITH TIME ZONE DEFAULT NULL,
    login_attempts INTEGER DEFAULT 0,
    mfa BOOLEAN NOT NULL DEFAULT FALSE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,           -- ให้ล็อกอินได้ทันทีใน dev
    account_non_expired BOOLEAN NOT NULL DEFAULT TRUE,
    account_non_locked BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_user_uuid UNIQUE (user_uuid),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT uq_users_member_id UNIQUE (member_id)
);

CREATE TABLE IF NOT EXISTS roles (
    role_id BIGSERIAL PRIMARY KEY,
    role_uuid VARCHAR(40) NOT NULL,
    name VARCHAR(25) NOT NULL,
    authority TEXT NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_roles_name UNIQUE (name),
    CONSTRAINT uq_roles_role_uuid UNIQUE (role_uuid)
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_role_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    CONSTRAINT fk_user_roles_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_user_roles_role_id FOREIGN KEY (role_id) REFERENCES roles (role_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_user_roles UNIQUE (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS credentials (
    credential_id BIGSERIAL PRIMARY KEY,
    credential_uuid VARCHAR(40) NOT NULL,
    user_id BIGINT NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_credentials_credential_uuid UNIQUE (credential_uuid),
    CONSTRAINT uq_credentials_user_id UNIQUE (user_id),
    CONSTRAINT fk_credentials_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS account_tokens (
    account_token_id BIGSERIAL PRIMARY KEY,
    token VARCHAR(40) NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_account_tokens_token UNIQUE (token),
    CONSTRAINT uq_account_tokens_user_id UNIQUE (user_id),
    CONSTRAINT fk_account_tokens_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS password_tokens (
    password_token_id BIGSERIAL PRIMARY KEY,
    token VARCHAR(40) NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_password_tokens_token UNIQUE (token),
    CONSTRAINT uq_password_tokens_user_id UNIQUE (user_id),
    CONSTRAINT fk_password_tokens_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS devices (
    device_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device VARCHAR(40) NOT NULL,
    client VARCHAR(40) NOT NULL,
    ip_address VARCHAR(100) NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_devices_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ===== Ticket / Task / File / Comment / Status ฯลฯ =====
CREATE TABLE IF NOT EXISTS tickets (
    ticket_id BIGSERIAL PRIMARY KEY,
    ticket_uuid VARCHAR(40) NOT NULL,
    user_id BIGINT NOT NULL,
    assignee_id BIGINT DEFAULT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    progress INTEGER NOT NULL DEFAULT 0,
    due_date TIMESTAMP(6) WITH TIME ZONE DEFAULT NOW() + INTERVAL '2 week',
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tickets_ticket_uuid UNIQUE (ticket_uuid),
    CONSTRAINT ck_tickets_progress CHECK ((progress >= 0) AND (progress <= 100)),
    CONSTRAINT fk_tickets_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_assignee_id FOREIGN KEY (assignee_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS tasks (
    task_id BIGSERIAL PRIMARY KEY,
    task_uuid VARCHAR(40) NOT NULL,
    ticket_id BIGINT NOT NULL,
    assignee_id BIGINT DEFAULT NULL,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(255) NOT NULL,
    due_date TIMESTAMP(6) WITH TIME ZONE DEFAULT NOW() + INTERVAL '1 week',
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tasks_task_uuid UNIQUE (task_uuid),
    CONSTRAINT fk_tasks_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets (ticket_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_tasks_assignee_id FOREIGN KEY (assignee_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS files (
    file_id BIGSERIAL PRIMARY KEY,
    file_uuid VARCHAR(40) NOT NULL,
    ticket_id BIGINT NOT NULL,
    extension VARCHAR(10) NOT NULL,
    formatted_size VARCHAR(10) NOT NULL,
    name VARCHAR(50) NOT NULL,
    size BIGINT NOT NULL,
    uri VARCHAR(255) NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_files_file_uuid UNIQUE (file_uuid),
    CONSTRAINT fk_files_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets (ticket_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS comments (
    comment_id BIGSERIAL PRIMARY KEY,
    comment_uuid VARCHAR(40) NOT NULL,
    user_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    comment TEXT NOT NULL,
    edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_comments_comment_uuid UNIQUE (comment_uuid),
    CONSTRAINT fk_comments_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_comments_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets (ticket_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS statuses (
    status_id BIGSERIAL PRIMARY KEY,
    status VARCHAR(20) NOT NULL,
    description VARCHAR(100) NOT NULL,
    CONSTRAINT ck_statuses_status CHECK(status IN ('NEW', 'IN PROGRESS', 'IN REVIEW', 'COMPLETED', 'IMPEDED', 'ASSIGNED', 'UNASSIGNED', 'CLOSED', 'PENDING'))
);

CREATE TABLE IF NOT EXISTS types (
    type_id BIGSERIAL PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    description VARCHAR(100) NOT NULL,
    CONSTRAINT ck_types_type CHECK(type IN ('INCIDENT', 'BUG', 'DESIGN', 'DEFECT', 'ENHANCEMENT'))
);

CREATE TABLE IF NOT EXISTS priorities (
    priority_id BIGSERIAL PRIMARY KEY,
    priority VARCHAR(10) NOT NULL,
    description VARCHAR(100) NOT NULL,
    CONSTRAINT ck_priorities_priority CHECK(priority IN ('LOW', 'MEDIUM', 'HIGH'))
);

CREATE TABLE IF NOT EXISTS ticket_statuses (
    ticket_status_id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    CONSTRAINT fk_ticket_statuses_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets (ticket_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_statuses_status_id FOREIGN KEY (status_id) REFERENCES statuses (status_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS ticket_types (
    ticket_type_id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    type_id BIGINT NOT NULL,
    CONSTRAINT fk_ticket_types_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets (ticket_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_types_type_id FOREIGN KEY (type_id) REFERENCES types (type_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS ticket_priorities (
    ticket_priority_id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    priority_id BIGINT NOT NULL,
    CONSTRAINT fk_ticket_priorities_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets (ticket_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_priorities_priority_id FOREIGN KEY (priority_id) REFERENCES priorities (priority_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS task_statuses (
    task_status_id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    CONSTRAINT fk_task_statuses_task_id FOREIGN KEY (task_id) REFERENCES tasks (task_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_task_statuses_status_id FOREIGN KEY (status_id) REFERENCES statuses (status_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS messages (
    message_id BIGSERIAL PRIMARY KEY,
    message_uuid VARCHAR(40) NOT NULL,
    conversation_id VARCHAR(40) NOT NULL,
    subject VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP(6) WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_messages_message_uuid UNIQUE (message_uuid),
    CONSTRAINT fk_messages_sender_id FOREIGN KEY (sender_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_messages_receiver_id FOREIGN KEY (receiver_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS message_statuses (
    message_status_id BIGSERIAL PRIMARY KEY,
    message_status VARCHAR(10) DEFAULT 'UNREAD',
    user_id BIGINT NOT NULL,
    message_id BIGINT NOT NULL,
    CONSTRAINT ck_message_statuses_message_status CHECK (message_status IN ('UNREAD', 'READ')),
    CONSTRAINT fk_message_statuses_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_message_statuses_message_id FOREIGN KEY (message_id) REFERENCES messages (message_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE
);

-- ===== Indexes for FK (ช่วย performance query/join) =====
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_credentials_user_id ON credentials(user_id);
CREATE INDEX IF NOT EXISTS idx_account_tokens_user_id ON account_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_tokens_user_id ON password_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_assignee_id ON tickets(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_ticket_id ON tasks(ticket_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_files_ticket_id ON files(ticket_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_ticket_id ON comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_statuses_ticket_id ON ticket_statuses(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_statuses_status_id ON ticket_statuses(status_id);
CREATE INDEX IF NOT EXISTS idx_ticket_types_ticket_id ON ticket_types(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_types_type_id ON ticket_types(type_id);
CREATE INDEX IF NOT EXISTS idx_ticket_priorities_ticket_id ON ticket_priorities(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_priorities_priority_id ON ticket_priorities(priority_id);
CREATE INDEX IF NOT EXISTS idx_task_statuses_task_id ON task_statuses(task_id);
CREATE INDEX IF NOT EXISTS idx_task_statuses_status_id ON task_statuses(status_id);

-- ===== Triggers สำหรับ updated_at =====
DO $$
BEGIN
  PERFORM 1 FROM pg_trigger WHERE tgname = 'trg_users_updated_at';
  IF NOT FOUND THEN
    CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_credentials_updated_at BEFORE UPDATE ON credentials FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_account_tokens_updated_at BEFORE UPDATE ON account_tokens FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_password_tokens_updated_at BEFORE UPDATE ON password_tokens FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_devices_updated_at BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_tickets_updated_at BEFORE UPDATE ON tickets FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_files_updated_at BEFORE UPDATE ON files FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    CREATE TRIGGER trg_messages_updated_at BEFORE UPDATE ON messages FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;
