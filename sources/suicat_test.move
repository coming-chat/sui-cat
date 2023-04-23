// Copyright 2023 ComingChat Authors. Licensed under Apache-2.0 License.
#[test_only]
module suicat::suicat_test {
    use std::debug::print;
    use std::vector;

    use sui::clock;
    use sui::coin::{Coin, value, mint_for_testing};
    use sui::sui::SUI;
    use sui::test_scenario::{
        Scenario, next_tx, begin, end, ctx, take_shared,
        return_shared, take_from_sender, return_to_sender
    };

    use suicat::suicat::{
        init_for_testing, set_whitelist, Global, remain, prices, mint, remain_reserve,
        mint_reserve, SuiCat, withdraw, supply, time, minted_count, is_in_whitelist
    };

    // utilities
    fun scenario(): Scenario { begin(@0x1) }

    fun equal_minted_count(global: &Global, c1: u16, c2: u16): bool {
        let (c1_, c2_) = minted_count(global);

        return c1_ == c1 && c2_ == c2
    }

    // Tests section
    #[test]
    fun test_init() {
        let scenario = scenario();
        test_init_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_set_whitelist() {
        let scenario = scenario();
        test_set_whitelist_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_mint() {
        let scenario = scenario();
        test_mint_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_mint_reserve() {
        let scenario = scenario();
        test_mint_reserve_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_withdraw() {
        let scenario = scenario();
        test_withdraw_(&mut scenario);
        end(scenario);
    }

    fun test_init_(test: &mut Scenario) {
        let admin = @0xaaa;
        let beneficiary = @0xbbb;

        next_tx(test, admin);
        {
            init_for_testing(beneficiary, ctx(test));
        };
    }

    fun test_set_whitelist_(test: &mut Scenario) {
        test_init_(test);

        let admin = @0xaaa;
        let user1 = @0x111;
        let user2 = @0x222;
        let user3 = @0x333;

        next_tx(test, admin);
        {
            let global = take_shared<Global>(test);

            let whitelist = vector<address>[];
            vector::push_back(&mut whitelist, user1);
            vector::push_back(&mut whitelist, user2);

            set_whitelist(&mut global, whitelist, ctx(test));

            return_shared(global)
        };

        next_tx(test, user1);
        {
            let global = take_shared<Global>(test);

            assert!(is_in_whitelist(&global, user1), 1);
            assert!(is_in_whitelist(&global, user2), 2);
            assert!(!is_in_whitelist(&global, user3), 3);
            assert!(supply(&global) == 1000, 4);
            assert!(remain(&global) == 700, 5);
            assert!(remain_reserve(&global) == 300, 6);

            return_shared(global);
        }
    }

    fun test_mint_reserve_(test: &mut Scenario) {
        test_set_whitelist_(test);

        let admin = @0xaaa;
        let beneficiary = @0xbbb;

        next_tx(test, admin);
        {
            let global = take_shared<Global>(test);

            mint_reserve(&mut global, 1, ctx(test));

            assert!(remain(&global) == 700, 1);
            assert!(supply(&global) == 1000, 2);
            assert!(remain_reserve(&global) == 299, 3);
            assert!(equal_minted_count(&global, 0, 0), 4);

            return_shared(global);
        };

        next_tx(test, beneficiary);
        {
            let nft = take_from_sender<SuiCat>(test);

            print(&nft);

            return_to_sender(test, nft)
        };

        next_tx(test, admin);
        {
            let global = take_shared<Global>(test);

            mint_reserve(&mut global, 300, ctx(test));

            assert!(remain(&global) == 700, 1);
            assert!(supply(&global) == 1000, 2);
            assert!(remain_reserve(&global) == 0, 3);
            assert!(equal_minted_count(&global, 0, 0), 4);

            return_shared(global);
        };
    }

    fun test_mint_(test: &mut Scenario) {
        test_set_whitelist_(test);

        let clock = clock::create_for_testing(ctx(test));

        let user1 = @0x111;
        next_tx(test, user1);
        {
            let global = take_shared<Global>(test);

            let (start_time, _) = time(&global);
            clock::increment_for_testing(&mut clock, start_time + 1);

            let (price_whitelist, _) = prices(&global);
            let sui = mint_for_testing<SUI>(price_whitelist, ctx(test));

            mint(&mut global, &clock, vector<Coin<SUI>>[sui], ctx(test));

            assert!(remain(&global) == 699, 1);
            assert!(supply(&global) == 1000, 2);
            assert!(equal_minted_count((&global), 1, 0), 3);
            assert!(remain_reserve(&global) == 300, 4);

            return_shared(global);
        };

        let user2 = @0x222;
        next_tx(test, user2);
        {
            let global = take_shared<Global>(test);

            let (start_time, whitelist_stage) = time(&global);
            clock::increment_for_testing(&mut clock, start_time + whitelist_stage + 1);

            let (_, price_public) = prices(&global);
            let sui = mint_for_testing<SUI>(price_public, ctx(test));

            mint(&mut global, &clock, vector<Coin<SUI>>[sui], ctx(test));

            assert!(remain(&global) == 698, 1);
            assert!(supply(&global) == 1000, 2);
            assert!(equal_minted_count(&global, 1, 1), 3);
            assert!(remain_reserve(&global) == 300, 4);

            return_shared(global);
        };

        let user3 = @0x333;
        next_tx(test, user3);
        {
            let global = take_shared<Global>(test);
            let (_, price_public) = prices(&global);

            let sui = mint_for_testing<SUI>(price_public, ctx(test));
            mint(&mut global, &clock, vector<Coin<SUI>>[sui], ctx(test));

            assert!(remain(&global) == 697, 1);
            assert!(supply(&global) == 1000, 2);
            assert!(equal_minted_count(&global, 1, 2), 3);
            assert!(remain_reserve(&global) == 300, 4);

            return_shared(global);
        };

        let user1 = @0x111;
        next_tx(test, user1);
        {
            let nft = take_from_sender<SuiCat>(test);

            print(&nft);

            return_to_sender(test, nft);
        };

        clock::destroy_for_testing(clock);
    }

    fun test_withdraw_(test: &mut Scenario) {
        test_mint_(test);

        let beneficiary = @0xbbb;
        next_tx(test, beneficiary);
        {
            let global = take_shared<Global>(test);

            withdraw(&mut global, ctx(test));

            return_shared(global);
        };

        next_tx(test, beneficiary);
        {
            let global = take_shared<Global>(test);
            let sui = take_from_sender<Coin<SUI>>(test);

            let (price_early, price_public) = prices(&global);
            assert!(value(&sui) == price_early + 2 * price_public, 1);

            return_to_sender(test, sui);
            return_shared(global);
        }
    }
}