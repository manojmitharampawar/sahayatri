CREATE TABLE IF NOT EXISTS family_groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS family_members (
    group_id BIGINT NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member',
    PRIMARY KEY (group_id, user_id)
);

CREATE INDEX idx_family_groups_owner ON family_groups(owner_id);
CREATE INDEX idx_family_members_user ON family_members(user_id);
