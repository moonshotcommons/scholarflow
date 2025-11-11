module scholarflow::grant {
    use iota::event;

    /// Capability granting authority to mint grants.
    public struct AdminCap has key { id: UID }

    /// An owned grant object assigned to a student.
    public struct Grant has key {
        id: UID,
        student: address,
        amount: u64,
        state: vector<u8>,
    }

    /// Emitted when a grant is minted.
    public struct GrantMinted has copy, drop, store {
        student: address,
        amount: u64,
        grant_id: ID,
    }

        /// Runs once at package publish. Transfers AdminCap to the publisher.
    fun init(ctx: &mut TxContext) {
        let cap = AdminCap { id: object::new(ctx) };
        let publisher = tx_context::sender(ctx);
        transfer::transfer(cap, publisher);
    }

    public entry fun mint(
        student: address,
        amount: u64,
        _state: vector<u8>,
        _cap: &AdminCap,
        ctx: &mut TxContext
    ) {
        // TODO: Create Grant, emit event, transfer to `student`.
        // Hints: object::new(ctx), object::id(&grant), transfer::transfer(grant, student)
        let grant = Grant {
            id: object::new(ctx),
            student: student,
            amount: amount,
            state: _state,
        };
        event::emit(GrantMinted {
            student: student,
            amount: amount,
            grant_id: object::id(&grant),
        });
        transfer::transfer(grant, student);
    }

        /// Mint a grant and return its ID so callers (e.g., a PTB) can chain actions.
    public entry fun mint_return_id(
        student: address,
        amount: u64,
        _state: vector<u8>,
        _cap: &AdminCap,
        ctx: &mut TxContext
    ): ID {
        let grant = Grant { id: object::new(ctx), student, amount, state: _state };
        let gid: ID = object::id(&grant);
        event::emit(GrantMinted { student, amount, grant_id: gid });
        transfer::transfer(grant, student);
        gid
    }

    public fun state_of(_g: &Grant): vector<u8> {
        _g.state
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        let cap = AdminCap { id: object::new(ctx) };
        let publisher = tx_context::sender(ctx);
        transfer::transfer(cap, publisher);
    }
}