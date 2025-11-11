module scholarflow::registry {
    use iota::event;
    use iota::table::{Self as table, Table};
    use scholarflow::grant::AdminCap;

    /// The shared Registry with an attached index of student -> grant ID.
    public struct Registry has key {
        id: UID,
        by_student: Table<address, ID>,
    }

    /// Emitted when a student is indexed with a grant ID.
    public struct GrantIndexed has copy, drop, store {
        student: address,
        grant_id: ID,
    }

        /// Create and share a Registry.
    public entry fun create(
        _cap: &AdminCap,
        ctx: &mut TxContext
    ) {
        let reg = Registry {
            id: object::new(ctx),
            by_student: table::new<address, ID>(ctx),
        };
        transfer::share_object(reg);
    }

        /// insert mapping student -> grant_id and emit an event.
    public entry fun index_grant(
        reg: &mut Registry,
        student: address,
        grant_id: ID,
        _cap: &AdminCap
    ) {
        if(reg.by_student.contains(student)) {
            reg.by_student.remove(student);
        };
        reg.by_student.add( student, grant_id);
        event::emit(GrantIndexed { student, grant_id });
    }
}