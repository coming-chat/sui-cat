// Copyright 2023 ComingChat Authors. Licensed under Apache-2.0 License.
/// A `TransferPolicy` Rule which implements percentage-based royalty fee.
/// refer to https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/tests/kiosk/policies/royalty_policy.test.move
module suicat::royalty_policy {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::tx_context::{TxContext, sender};
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest,
        remove_rule
    };
    use sui::package::Publisher;
    use sui::transfer;

    use suicat::suicat::SuiCat;

    /// The `amount_bp` passed is more than 100%.
    const EIncorrectArgument: u64 = 0;
    /// The `Coin` used for payment is not enough to cover the fee.
    const EInsufficientAmount: u64 = 1;

    /// Max value for the `amount_bp`.
    const MAX_BPS: u16 = 10000;

    /// The "Rule" witness to authorize the policy.
    struct Rule has drop {}

    /// Configuration for the Rule.
    struct Config has store, drop {
        amount_bp: u16,
        beneficiary: address
    }

    public fun calculate(amount_bp: u16, paid: u64): u64 {
        (((paid as u128) * (amount_bp as u128) / 10000) as u64)
    }

    /// Creator action: Set the Royalty policy for the SuiCat.
    public fun set<SuiCat>(
        policy: &mut TransferPolicy<SuiCat>,
        cap: &TransferPolicyCap<SuiCat>,
        amount_bp: u16
    ) {
        assert!(amount_bp < MAX_BPS, EIncorrectArgument);
        policy::add_rule(Rule {}, policy, cap, Config { amount_bp, beneficiary: @beneficiary })
    }

    /// Buyer action: Pay the royalty fee for the transfer.
    public fun pay<SuiCat>(
        policy: &mut TransferPolicy<SuiCat>,
        request: &mut TransferRequest<SuiCat>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let config: &Config = policy::get_rule(Rule {}, policy);
        let paid = policy::paid(request);
        let amount = calculate(config.amount_bp, paid);

        assert!(coin::value(payment) >= amount, EInsufficientAmount);

        if (amount > 0) {
            let fee = coin::split(payment, amount, ctx);
            transfer::public_transfer(fee, config.beneficiary);
        };

        policy::add_receipt(Rule {}, request)
    }

    public fun get_rules(policy: &TransferPolicy<SuiCat>): (u16, address){
        let config: &Config = policy::get_rule(Rule {}, policy);
        return (config.amount_bp, config.beneficiary)
    }

    public entry fun new_royalty_policy(
        publisher: &Publisher,
        amount_bp: u16,
        ctx: &mut TxContext
    ) {
        let (policy, cap) = policy::new<SuiCat>(publisher, ctx);

        set<SuiCat>(&mut policy, &cap, amount_bp);

        transfer::public_share_object(policy);
        transfer::public_transfer(cap, sender(ctx));
    }

    public entry fun update_royalty_bp(
        policy: &mut TransferPolicy<SuiCat>,
        cap: &TransferPolicyCap<SuiCat>,
        amount_bp: u16
    ) {
        remove_rule<SuiCat, Rule, Config>(policy, cap);
        set<SuiCat>(policy, cap, amount_bp);
    }
}