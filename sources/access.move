module scholarflow::access {
    use iota::event;
    use iota::table::{Self as table, Table};
    use scholarflow::grant; // Reuse the AdminCap minted in grant::init

    /// Errors
    const ENotAdmin: u64 = 1;
    const ENotIssuer: u64 = 2;
    const ENotRevoker: u64 = 3;
    const EAlreadyHasRole: u64 = 4;
    const ENoSuchRole: u64 = 5;

    // Capability is defined in scholarflow::grant::AdminCap (minted in init).

    /// Roles tracked in a shared Roles object.
    public struct Roles has key {
        id: UID,
        admins: Table<address, bool>,
        issuers: Table<address, bool>,
        revokers: Table<address, bool>,
    }

    /// Events for auditability.
    public struct RoleGranted has copy, drop, store { role: vector<u8>, who: address, by: address }
    public struct RoleRevoked has copy, drop, store { role: vector<u8>, who: address, by: address }

    /// Create and share role registry (seeded with publisher as admin).
    public entry fun create_roles(_cap: &grant::AdminCap, ctx: &mut TxContext) {
        // Step 1: Get the transaction sender address.
        // Step 2: Create a new Roles object with empty admin/issuer/revoker tables.
        // Step 3: Add the sender address to the admins table.
        // Step 4: Emit a RoleGranted event noting role "admin", who = sender, by = sender.
        // Step 5: Share the Roles object so it becomes a shared on‑chain object.
        let sender = tx_context::sender(ctx);
        let mut roles = Roles {
            id: object::new(ctx),
            admins: table::new<address, bool>(ctx),
            issuers: table::new<address, bool>(ctx),
            revokers: table::new<address, bool>(ctx),
        };
        roles.admins.add(sender, true);
        event::emit(RoleGranted { role: b"admin", who: sender, by: sender });
        transfer::share_object(roles);
    }

    /// Grant a role (admin-gated).
    public entry fun grant_role(
        _roles: &mut Roles, _role: vector<u8>, _who: address, _cap: &grant::AdminCap
    ) {
        // Gate with AdminCap (_cap). Suggested flow:
        // 1) Match role bytes: b"admin" | b"issuer" | b"revoker".
        // 2) Insert _who -> true into the corresponding table (admins/issuers/revokers).
        // 3) event::emit(RoleGranted { role: _role, who: _who, by: /* optional: actor */ 0x0 });
        //    If you want to record the actor, add a TxContext param and set by = tx_context::sender(ctx).
        if (_role == b"admin") {
            if(_roles.admins.contains(_who)) {
                abort EAlreadyHasRole
            };
            _roles.admins.add(_who, true);
        } else if (_role == b"issuer") {
            if(_roles.issuers.contains(_who)) {
                abort EAlreadyHasRole
            };
            _roles.issuers.add(_who, true);
        } else if (_role == b"revoker") {
            if(_roles.revokers.contains(_who)) {
                abort EAlreadyHasRole
            };
            _roles.revokers.add(_who, true);
        } else {
            abort ENoSuchRole
        };
        event::emit(RoleGranted { role: _role, who: _who, by: @0x0 });
    }

    /// Revoke a role (admin-gated).
    public entry fun revoke_role(
        _roles: &mut Roles, _role: vector<u8>, _who: address, _cap: &grant::AdminCap
    ) {
        // Gate with AdminCap (_cap). Suggested flow:
        // 1) Match role bytes and check presence with table::contains; abort with ENoSuchRole if missing.
        // 2) Remove _who from the matching table via table::remove.
        // 3) event::emit(RoleRevoked { role: _role, who: _who, by: /* optional actor */ 0x0 });

        if (_role == b"admin") {
            if (!_roles.admins.contains(_who)) {
                abort ENotAdmin
            };
            _roles.admins.remove(_who);
        } else if (_role == b"issuer") {
            if (!_roles.issuers.contains(_who)) {
                abort ENotIssuer
            };
            _roles.issuers.remove(_who);
        } else if (_role == b"revoker") {
            if (!_roles.revokers.contains(_who)) {
                abort ENotRevoker
            };
            _roles.revokers.remove(_who);
        } else {
            abort ENoSuchRole
        };
        event::emit(RoleRevoked { role: _role, who: _who, by: @0x0 });
    }

    /// Read helpers (pure) — used by lifecycle checks.
    public fun is_admin(_roles: &Roles, _addr: address): bool {
        // Step 1: Check if `_addr` exists in `roles.admins`.
        // Step 2: Return true if present, false otherwise.
        _roles.admins.contains(_addr)
    }
    public fun is_issuer(_roles: &Roles, _addr: address): bool {
        // Step 1: Check if `_addr` exists in `roles.issuers`.
        // Step 2: Return true if present, false otherwise.
        _roles.issuers.contains(_addr)
    }
    public fun is_revoker(_roles: &Roles, _addr: address): bool {
        // Step 1: Check if `_addr` exists in `roles.revokers`.
        // Step 2: Return true if present, false otherwise.
        _roles.revokers.contains(_addr)
    }
}