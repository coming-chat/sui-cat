// Copyright 2023 ComingChat Authors. Licensed under Apache-2.0 License.
#[test_only]
module suicat::royalty_policy_test {
    use sui::coin;
    use sui::sui::SUI;
    use sui::transfer_policy as policy;
    use sui::transfer_policy_tests as test;
    use sui::coin::Coin;
    use sui::package;
    use sui::test_scenario::{
        Scenario, begin, ctx, end, has_most_recent_for_sender, next_tx,
        take_from_sender, take_shared, return_shared, return_to_sender
    };

    use suicat::suicat::SuiCat;
    use suicat::royalty_policy::get_rules;
    use suicat::royalty_policy;
    use sui::transfer_policy::TransferPolicyCap;

    fun scenario(): Scenario { begin(@0xaaa) }

    struct OTW has drop {}

    #[test]
    fun test_default_flow() {
        let scenario = scenario();
        let publisher = package::test_claim(OTW {}, ctx(&mut scenario));

        // 1% royalty
        royalty_policy::new_royalty_policy(&mut publisher, 100, ctx(&mut scenario));

        let payment = coin::mint_for_testing<SUI>(5000, ctx(&mut scenario));

        assert!(!has_most_recent_for_sender<Coin<SUI>>(&scenario), 0);

        let admin =  @0xaaa;

        next_tx(&mut scenario, @beneficiary);
        {
            let policy = take_shared(&scenario);
            let (amount_bp, beneficiary) = get_rules(&policy);

            assert!(amount_bp == 100, 1);
            assert!(beneficiary == @beneficiary, 2);

            let request = policy::new_request<SuiCat>(test::fresh_id(ctx(&mut scenario)), 100000, test::fresh_id(ctx(&mut scenario)));

            royalty_policy::pay(&mut policy, &mut request, &mut payment, ctx(&mut scenario));
            policy::confirm_request(&mut policy, request);

            return_shared(policy)
        };

        next_tx(&mut scenario, @beneficiary);
        {
            let royalty = take_from_sender<Coin<SUI>>(&scenario);

            let burn = coin::burn_for_testing(royalty);

            assert!(burn == 1000, 3)
        };

        // 2% royalty
        next_tx(&mut scenario, admin);
        {
            let policy = take_shared(&scenario);
            let cap =take_from_sender<TransferPolicyCap<SuiCat>>(&scenario);

            royalty_policy::update_royalty_bp(&mut policy, &cap, 200);

            return_to_sender(&scenario, cap);
            return_shared(policy)
        };

        next_tx(&mut scenario, @beneficiary);
        {
            let policy = take_shared(&scenario);
            let (amount_bp, beneficiary) = get_rules(&policy);

            assert!(amount_bp == 200, 4);
            assert!(beneficiary == @beneficiary, 5);

            let request = policy::new_request<SuiCat>(test::fresh_id(ctx(&mut scenario)), 100000, test::fresh_id(ctx(&mut scenario)));

            royalty_policy::pay(&mut policy, &mut request, &mut payment, ctx(&mut scenario));
            policy::confirm_request(&mut policy, request);

            return_shared(policy)
        };

        next_tx(&mut scenario, @beneficiary);
        {
            let royalty = take_from_sender<Coin<SUI>>(&scenario);

            let burn = coin::burn_for_testing(royalty);

            assert!(burn == 2000, 6)
        };

        let remainder = coin::burn_for_testing(payment);
        assert!(remainder == 2000, 7);

        package::burn_publisher(publisher);
        end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suicat::royalty_policy::EIncorrectArgument)]
    fun test_incorrect_config() {
        let scenario = scenario();
        let ctx = ctx(&mut scenario);

        let (policy, cap) = test::prepare(ctx);

        royalty_policy::set(&mut policy, &cap, 11000);
        test::wrapup(policy, cap, ctx);

        end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = suicat::royalty_policy::EInsufficientAmount)]
    fun test_insufficient_amount() {
        let scenario = scenario();
        let ctx = ctx(&mut scenario);

        let (policy, cap) = test::prepare(ctx);

        // 1% royalty
        royalty_policy::set(&mut policy, &cap, 100);

        // Requires 1_000 MIST, coin has only 999
        let request = policy::new_request(test::fresh_id(ctx), 100000, test::fresh_id(ctx));
        let payment = coin::mint_for_testing<SUI>(999, ctx);

        royalty_policy::pay(&mut policy, &mut request, &mut payment, ctx);
        policy::confirm_request(&mut policy, request);

        coin::burn_for_testing(payment);
        test::wrapup(policy, cap, ctx);

        end(scenario);
    }
}