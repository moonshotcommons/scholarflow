#[test_only]
module scholarflow::tests_lifecycle {
    #[test_only]
    use scholarflow::access::{Self as access, Roles};
    #[test_only]
    use scholarflow::grant::{Self, Grant, AdminCap};
    #[test_only]
    use scholarflow::lifecycle::{Self, Requests};
    #[test_only]
    use iota::table::{Self as table, Table};
     #[test_only]
    use iota::test_scenario::{Self, Scenario};
    use std::debug;


    const ADMIN: address = @0xAAA1;
    const ISSUER: address = @0xAAA2;
    const REVOKER: address = @0xAAA3;
    const STUDENT: address = @0xBBB1;

    /// Arrange helpers: seed roles inline for tests.
    // #[test]
    // fun setup(ctx: &mut TxContext): Roles {
    //     // Step 1: Create a Roles object with fresh UID and empty tables for admins/issuers/revokers.
    //     // Step 2: Insert ADMIN into admins, ISSUER into issuers, REVOKER into revokers.
    //     // Step 3: Return the configured Roles value for use in tests.
    //     debug::print(&b"begining setup");
    //     let _roles = create_roles_for_testing(ADMIN, ISSUER, REVOKER, ctx);
    //     debug::print(&b"ending setup");
    //     _roles
    // }

    #[test]
    // #[expected_failure(abort_code = lifecycle::EOnlyIssuer)]
    fun request_requires_issuer() {
        // Steps:
        // 1) Begin scenario with STUDENT (non-issuer).
        // 2) Call setup to create roles mapping without STUDENT as issuer.
        // 3) Attempt lifecycle::request_grant; expect abort EOnlyIssuer.
        let mut scenario = test_scenario::begin(ADMIN);
        {
            grant::init_for_testing(scenario.ctx());
        };

        scenario.next_tx(ADMIN);
        
        {
            let admCap = scenario.take_from_sender<AdminCap>();
            access::create_roles(&admCap, scenario.ctx());
            scenario.return_to_sender<AdminCap>(admCap);
        };

        scenario.next_tx(ADMIN);
        
        {
            let admCap = scenario.take_from_sender<AdminCap>();
            lifecycle::create_requests(&admCap, scenario.ctx());
            scenario.return_to_sender<AdminCap>(admCap);
        };

        scenario.next_tx(STUDENT);
        
        {
            let mut requests = scenario.take_shared<Requests>();
            lifecycle::request_grant(&mut requests, 1000, scenario.ctx());
            test_scenario::return_shared<Requests>(requests);
        };

        scenario.next_tx(ADMIN);
        
        {
           let mut requests = scenario.take_shared<Requests>();
           let roles = scenario.take_shared<Roles>();
           let admCap = scenario.take_from_sender<AdminCap>();
           lifecycle::approve_grant(&mut requests, STUDENT, &roles, &admCap, scenario.ctx());
           test_scenario::return_shared<Requests>(requests);
           test_scenario::return_shared<Roles>(roles);
            scenario.return_to_sender<AdminCap>(admCap);
        };
        
        scenario.end();
        
    }

    // #[test]
    // fun request_succeeds_for_issuer() {
    //     // Steps:
    //     // 1) Begin scenario with ISSUER.
    //     // 2) Call setup to include ISSUER in issuers table.
    //     // 3) Call lifecycle::request_grant; assert no abort (optionally verify state is PENDING).
    // }

    // #[test]
    // #[expected_failure(abort_code = lifecycle::EOnlyIssuer)]
    // fun approve_requires_issuer() {
    //     // Suggested approach:
    //     // 1) Begin scenario with ISSUER; setup roles; request_grant to create a pending grant.
    //     // 2) Next tx with STUDENT (not issuer); take the Grant owned by ISSUER or park it for borrowing.
    //     // 3) Call lifecycle::approve_grant(&mut grant, &roles) as non-issuer; expect abort EOnlyIssuer.
    // }

    // #[test]
    // #[expected_failure(abort_code = lifecycle::EOnlyRevoker)]
    // fun revoke_requires_revoker() {
    //     // Suggested approach:
    //     // 1) Begin scenario as ISSUER; create a pending grant, then approve it (ACTIVE) with an issuer.
    //     // 2) Next tx as STUDENT (non-revoker); call revoke_grant on the ACTIVE grant; expect EOnlyRevoker.
    // }

    // #[test]
    // fun valid_transition_pending_to_active() {
    //     // Suggested approach:
    //     // 1) Begin scenario as ISSUER; setup roles; request_grant to create PENDING grant.
    //     // 2) Approve as ISSUER; assert lifecycle::is_active(&grant) == true.
    //     //    You can retrieve/return objects with test_scenario::take_from_sender / return_to_sender.
    // }

    // #[test]
    // #[expected_failure(abort_code = lifecycle::EInvalidTransition)]
    // fun invalid_transition_active_to_pending() {
    //     // Suggested approach:
    //     // 1) Move grant to ACTIVE via approve.
    //     // 2) Attempt to transition back to PENDING (e.g., by calling request/approve logic incorrectly) and expect EInvalidTransition.
    // }

    // #[test]
    // fun idempotent_indexing_example_if_applicable() {
    //     // If you maintain any indexes (e.g., registry), upsert twice with same values
    //     // and assert there is no duplication or inconsistent state.
    // }
}