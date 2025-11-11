module scholarflow::lifecycle {
    use iota::event;
    use iota::table::{Self as table, Table};
    use scholarflow::{access, grant};

    const EOnlyIssuer: u64 = 10;
    const EOnlyRevoker: u64 = 11;
    const EInvalidTransition: u64 = 12;
    const ENoRequest: u64 = 13;

    const S_PENDING: vector<u8> = b"pending";
    const S_ACTIVE: vector<u8>  = b"active";
    const S_REVOKED: vector<u8> = b"revoked";

    /// Emitted when a student places/updates a grant request with an amount.
    public struct GrantRequested has copy, drop, store { student: address, amount: u64 }
    public struct GrantApproved  has copy, drop, store { grant_id: ID, student: address }
    public struct GrantRevoked   has copy, drop, store { grant_id: ID, by: address }

    /// Shared queue of requested grants: student -> requested amount.
    public struct Requests has key {
        id: UID,
        by_student: Table<address, u64>,
    }

    /// Create and share the Requests queue.
    public entry fun create_requests(_cap: &grant::AdminCap, _ctx: &mut TxContext) {
        // Step 1: Create Requests { id: object::new(ctx), by_student: table::new<address,u64>(ctx) }.
        // Step 2: share_object the queue.
        let requests = Requests {
            id: object::new(_ctx),
            by_student: table::new<address, u64>(_ctx),
        };
        transfer::share_object(requests);
    }

    /// A student requests a grant; upsert (student -> amount) and emit event.
    public entry fun request_grant(
        _requests: &mut Requests,
        _amount: u64,
        _ctx: &mut TxContext,
    ) {
        // Step 1: student = tx_context::sender(ctx).
        // Step 2: If contains, remove existing; then insert student -> amount.
        // Step 3: event::emit(GrantRequested { student, amount }).
        let student = tx_context::sender(_ctx);
        if (_requests.by_student.contains(student)) {
            _requests.by_student.remove(student);
        };
        _requests.by_student.add(student, _amount);
        event::emit(GrantRequested { student, amount: _amount });
    }

    /// Approve a student's pending request: remove from queue, mint via grant, transfer to student, emit event.
    public entry fun approve_grant(
        _requests: &mut Requests,
        _student: address,
        _roles: &access::Roles,
        _cap: &grant::AdminCap,
        _ctx: &mut TxContext
    ) {
        // Step 1: assert!(access::is_issuer(roles, sender)).
        // Step 2: assert pending exists for student, read & remove amount.
        // Step 3: call grant::mint_return_id(student, amount, /*state=*/ S_ACTIVE, cap, ctx).
        // Step 4: emit GrantApproved with the returned ID.
        let sender = tx_context::sender(_ctx);
        assert!(access::is_issuer(_roles, sender) || access::is_admin(_roles, sender), EOnlyIssuer);

        assert!(_requests.by_student.contains((_student)), ENoRequest);

        let amount = _requests.by_student.borrow(_student);
        let grant_id = grant::mint_return_id(_student, *amount, S_ACTIVE, _cap, _ctx);

        _requests.by_student.remove(_student);

        event::emit(GrantApproved { grant_id, student: _student });
    }

    /// Mark ACTIVE grant as REVOKED and emit event (issuer/ or revoker-gated per policy).
    public entry fun revoke_grant(_g: &grant::Grant, _roles: &access::Roles, _ctx: &mut TxContext) {
        // Step 1: Gate with your chosen role (issuer or revoker).
        // Step 2: Ensure state is ACTIVE (if your grant::Grant encodes lifecycle state).
        // Step 3: Set state to REVOKED via grant helper if provided, or only emit event.
        // Step 4: event::emit(GrantRevoked { grant_id: object::id(g), by: sender }).
        let sender = tx_context::sender(_ctx);
        let isOk = access::is_issuer(_roles, sender) || access::is_admin(_roles, sender);
        assert!(isOk, EOnlyIssuer);

        assert!(_g.state_of() == S_ACTIVE, EInvalidTransition);

        event::emit(GrantRevoked { grant_id: object::id(_g), by: sender });
    }
}