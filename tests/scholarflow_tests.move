#[test_only]
module scholarflow::tests_lifecycle {
    #[test_only]
    use scholarflow::access::{Self, Roles};
    #[test_only]
    use scholarflow::grant::{Self, AdminCap};
    #[test_only]
    use scholarflow::lifecycle::{Self, Requests};
     #[test_only]
    use iota::test_scenario;
    use std::debug;
    use std::string;

    const ENotAdmin: u64 = 1;
    const ENotIssuer: u64 = 2;
    const ENotRevoker: u64 = 3;
    const ADMIN: address = @0xAAA1;
    const ISSUER: address = @0xAAA2;
    const REVOKER: address = @0xAAA3;
    const STUDENT: address = @0xBBB1;

    fun setup() {
        debug::print(&string::utf8(b"beginning setup"));
        // Step 1: Begin scenario with ADMIN.
        let mut scenario = test_scenario::begin(ADMIN);
        {
            // Step 2: Initialize grant module with AdminCap.
            grant::init_for_testing(scenario.ctx());
        };

        // Step 3: Next tx with ADMIN.
        scenario.next_tx(ADMIN);
        
        {
            let admCap = scenario.take_from_sender<AdminCap>();
            // Step 4: Create roles with AdminCap.
            access::create_roles(&admCap, scenario.ctx());
            scenario.return_to_sender<AdminCap>(admCap);
        };
        
        // Step 4: Create roles with AdminCap.
        scenario.next_tx(ADMIN);
        
        {
            let mut roles = scenario.take_shared<Roles>();
            let admCap = scenario.take_from_sender<AdminCap>();
            access::grant_role(&mut roles, b"issuer", ISSUER, &admCap);
            access::grant_role(&mut roles, b"revoker", REVOKER, &admCap);
            test_scenario::return_shared<Roles>(roles);
            scenario.return_to_sender<AdminCap>(admCap);
        };

        scenario.next_tx(ADMIN);
        
        {
            let admCap = scenario.take_from_sender<AdminCap>();
            // Step 5: Create requests with AdminCap.
            lifecycle::create_requests(&admCap, scenario.ctx());
            scenario.return_to_sender<AdminCap>(admCap);
        };
        
        scenario.end();
    }

    #[test]
    fun roles_test() {
        setup();
        debug::print(&string::utf8(b"beginning roles_test"));

        let mut scenario = test_scenario::begin(ADMIN);
        {
            let roles = scenario.take_shared<Roles>();
            assert!(access::is_admin(&roles, ADMIN), ENotAdmin);
            assert!(access::is_issuer(&roles, ISSUER), ENotIssuer);
            assert!(access::is_revoker(&roles, REVOKER), ENotRevoker);
            test_scenario::return_shared<Roles>(roles);
        };
        scenario.end();
    }

    #[test]
    fun request_and_approve_grant() {
        setup();

        debug::print(&string::utf8(b"beginning request_and_approve_grant"));
        // Step 1: Begin scenario with ADMIN.
        let mut scenario = test_scenario::begin(STUDENT);
        
        {
            let mut requests = scenario.take_shared<Requests>();
            // Step 2: Request grant with amount 1000.
            lifecycle::request_grant(&mut requests, 1000, scenario.ctx());
            test_scenario::return_shared<Requests>(requests);
        };

        scenario.next_tx(ADMIN);
        
        {
           let mut requests = scenario.take_shared<Requests>();
           let roles = scenario.take_shared<Roles>();
           let admCap = scenario.take_from_sender<AdminCap>();
           // Step 3: Approve grant with ADMIN.
           lifecycle::approve_grant(&mut requests, STUDENT, &roles, &admCap, scenario.ctx());
           test_scenario::return_shared<Requests>(requests);
           test_scenario::return_shared<Roles>(roles);
            scenario.return_to_sender<AdminCap>(admCap);
        };
        
        scenario.end();
        
    }
}