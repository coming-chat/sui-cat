// Copyright 2023 ComingChat Authors. Licensed under Apache-2.0 License.
module suicat::suicat {
    use std::string::{String, utf8};
    use std::vector::{Self, length};

    use sui::balance::{Self, Balance};
    use sui::bcs;
    use sui::clock::{timestamp_ms, Clock};
    use sui::coin::{Self, Coin, destroy_zero};
    use sui::display;
    use sui::hash;
    use sui::math::min;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::pay;
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext, sender};

    const NAME: vector<u8> = b"SuiCat#";
    const DEFAULT_LINK: vector<u8> = b"https://dmens.coming.chat";
    const DEFAULT_IMAGE_URL: vector<u8> = b"ipfs://QmUXzrqtqt5oahp1VBc8Jh5s4hts3tv7fuVxHEmjjmzTvP/dmens-cat.png";
    const DESCRIPTION: vector<u8> = b"The DMENS NFT-Pass program has been launched to encourage community participation, contribution, and development by attracting more partners and expanding the community.";
    const PROJECT_URL: vector<u8> = b"https://dmens.coming.chat";
    const CREATOR: vector<u8> = b"ComingChat";

    const MAX_SUPPLY: u16 = 10000;
    const MAX_U64: u64 = 18446744073709551615;
    const START: u64 = 1683637200000; // 2023-05-09 21:00:00
    const STAGE_WHITELIST: u64 = 72 * 60 * 60 * 1000; // 72 hours for whitelist
    const PRICE_WHITELIST: u64 = 300_000_000_000; // 300 SUI
    const PRICE_PUBLIC: u64 = 1_000_000_000_000; // 1000 SUI
    const TEAM_RESERVE: u16 = 3000;

    const ERR_NO_PERMISSION: u64 = 1;
    const ERR_NOT_START: u64 = 2;
    const ERR_ENDED: u64 = 3;
    const ERR_MINT_LIMIT: u64 = 4;
    const ERR_NOT_ENOUGH: u64 = 5;

    // One-Time-Witness for the module.
    struct SUICAT has drop {}

    struct SuiCat has key, store {
        id: UID,
        index: u16,
        name: String
    }

    // Caching indexes of Sui Cat to mint
    struct Vault has store {
        indexes: vector<u16>
    }

    // @creator the admin/owner of this contract
    // @start_time the start time of the SuiCat minting
    // @supply the max supply of SuiCat that can be mint
    // @team_reserve the initial reserve amount for team
    // @duration the duration(ms) of current mint stage
    // @whitelist the whitelist of SuiCat
    // @team_vault the indexes(#1-3000) of the SuiCat reserved for team mint
    // @mint_vault the indexes(#3001-10000) of the SuiCat for public mint
    // @price_whitelist the price of whitelist minting
    // @price_public the price of public minting
    // @minted_whitelist the minted count of whitelist
    // @minted_public the minted count of public
    // @balance Sui Coins received by the contract
    // @beneficiary who can receive all fund from contract while withdrawing
    struct Global has key {
        id: UID,
        creator: address,
        start_time: u64,
        supply: u16,
        team_reserve: u16,
        duration: u64,
        whitelist: Table<address, bool>,
        team_vault: Vault,
        mint_vault: Vault,
        price_whitelist: u64,
        price_public: u64,
        minted_whitelist: u16,
        minted_public: u16,
        balance: Balance<SUI>,
        beneficiary: address
    }

    fun init(otw: SUICAT, ctx: &mut TxContext) {
        // https://docs.sui.io/build/sui-object-display

        let keys = vector[
            // A name for the object. The name is displayed when users view the object.
            utf8(b"name"),
            // A description for the object. The description is displayed when users view the object.
            utf8(b"description"),
            // A link to the object to use in an application.
            utf8(b"link"),
            // A URL or a blob with the image for the object.
            utf8(b"image_url"),
            // A link to a website associated with the object or creator.
            utf8(b"project_url"),
            // A string that indicates the object creator.
            utf8(b"creator")
        ];
        let values = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(DEFAULT_IMAGE_URL),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        // Get a new `Display` object for the `SuiCat` type.
        let display = display::new_with_fields<SuiCat>(
            &publisher, keys, values, ctx
        );

        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);

        transfer::public_transfer(publisher, sender(ctx));
        transfer::public_transfer(display, sender(ctx));

        let global = Global {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            start_time: START,
            supply: MAX_SUPPLY,
            team_reserve: TEAM_RESERVE,
            duration: STAGE_WHITELIST,
            whitelist: table::new<address, bool>(ctx),
            team_vault: Vault { indexes: vector::empty<u16>() },
            mint_vault: Vault { indexes: vector::empty<u16>() },
            price_whitelist: PRICE_WHITELIST,
            price_public: PRICE_PUBLIC,
            minted_whitelist: 0,
            minted_public: 0,
            balance: balance::zero(),
            beneficiary: @beneficiary
        };

        let (i, j) = (1u16, global.team_reserve + 1);

        while (i <= global.team_reserve) {
            vector::push_back(&mut global.team_vault.indexes, i);
            i = i + 1
        };

        while (j <= global.supply) {
            vector::push_back(&mut global.mint_vault.indexes, j);
            j = j + 1
        };

        transfer::share_object(global);
    }

    #[test_only]
    public fun init_for_testing(
        beneficiary: address,
        ctx: &mut TxContext
    ) {
        let global = Global {
            id: object::new(ctx),
            creator: sender(ctx),
            start_time: 10,
            supply: 1000,
            team_reserve: 300,
            duration: STAGE_WHITELIST,
            whitelist: table::new<address, bool>(ctx),
            team_vault: Vault { indexes: vector::empty<u16>() },
            mint_vault: Vault { indexes: vector::empty<u16>() },
            price_whitelist: PRICE_WHITELIST,
            price_public: PRICE_PUBLIC,
            minted_whitelist: 0,
            minted_public: 0,
            balance: balance::zero(),
            beneficiary
        };

        let (i, j) = (1u16, global.team_reserve + 1);

        while (i <= global.team_reserve) {
            vector::push_back(&mut global.team_vault.indexes, i);
            i = i + 1
        };

        while (j <= global.supply) {
            vector::push_back(&mut global.mint_vault.indexes, j);
            j = j + 1
        };

        transfer::share_object(global);
    }

    #[test_only]
    public fun remain_reserve(global: &Global): u64 {
        return length(&global.team_vault.indexes)
    }

    fun seed(ctx: &mut TxContext): vector<u8> {
        let ctx_bytes = bcs::to_bytes(ctx);
        let uid = object::new(ctx);
        let uid_bytes: vector<u8> = object::uid_to_bytes(&uid);
        object::delete(uid);

        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, ctx_bytes);
        vector::append<u8>(&mut info, uid_bytes);

        let hash: vector<u8> = hash::keccak256(&info);
        hash
    }

    fun bytes_to_u64(bytes: vector<u8>): u64 {
        let value = 0u64;
        let i = 0u64;
        while (i < 8) {
            value = value | ((*vector::borrow(&bytes, i) as u64) << ((8 * (7 - i)) as u8));
            i = i + 1;
        };
        return value
    }

    fun u16_to_decimal_string(val: u16): vector<u8> {
        let vec = vector<u8>[];
        loop {
            let b = val % 10;
            vector::push_back(&mut vec, (48 + b as u8));
            val = val / 10;
            if (val <= 0) break;
        };
        vector::reverse(&mut vec);
        vec
    }

    fun select_nft(
        global: &mut Global,
        remain_count: u64,
        ctx: &mut TxContext
    ): SuiCat {
        assert!(remain_count > 0, ERR_ENDED);

        let random = bytes_to_u64(seed(ctx)) % remain_count;
        let index = vector::swap_remove(&mut global.mint_vault.indexes, random);

        SuiCat {
            id: object::new(ctx),
            index,
            name: generate_name(index)
        }
    }

    fun charge(
        global: &mut Global,
        coins: vector<Coin<SUI>>,
        price: u64,
        ctx: &mut TxContext
    ) {
        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);

        assert!(coin::value(&merged_coin) >= price, ERR_NOT_ENOUGH);

        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, price, ctx)
        );

        balance::join(&mut global.balance, balance);

        // transfer remain to account
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, sender(ctx))
        } else {
            destroy_zero(merged_coin)
        }
    }

    public fun remain(global: &Global): u64 {
        return length(&global.mint_vault.indexes)
    }

    public fun supply(global: &Global): u16 {
        return global.supply
    }

    public fun is_in_whitelist(global: &Global, account: address): bool {
        return table::contains(&global.whitelist, account)
    }

    public fun time(global: &Global): (u64, u64) {
        return (global.start_time, global.duration)
    }

    public fun prices(global: &Global): (u64, u64) {
        return (global.price_whitelist, global.price_public)
    }

    public fun minted_count(global: &Global): (u16, u16) {
        return (global.minted_whitelist, global.minted_public)
    }

    public fun generate_name(number: u16): String {
        let name = vector<u8>[];
        vector::append(&mut name, NAME);
        let number_string = u16_to_decimal_string(number);
        vector::append(&mut name, number_string);

        return utf8(name)
    }

    public entry fun set_start_time(
        global: &mut Global,
        start_time: u64,
        ctx: &mut TxContext
    ) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);

        global.start_time = start_time
    }

    public entry fun set_prices(
        global: &mut Global,
        price_whitelist: u64,
        price_public: u64,
        ctx: &mut TxContext
    ) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);

        global.price_whitelist = price_whitelist;
        global.price_public = price_public
    }

    public entry fun set_whitelist(
        global: &mut Global,
        whitelist: vector<address>,
        ctx: &mut TxContext,
    ) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let (i, len) = (0u64, vector::length(&whitelist));
        while (i < len) {
            let account = vector::pop_back(&mut whitelist);
            table::add(&mut global.whitelist, account, true);
            i = i + 1
        };
    }

    public entry fun mint_reserve(
        global: &mut Global,
        batch: u64,
        ctx: &mut TxContext
    ) {
        let account = tx_context::sender(ctx);
        assert!(global.creator == account, ERR_NO_PERMISSION);

        let remain = length(&global.team_vault.indexes);
        let mint_count = min(batch, remain);

        while (mint_count > 0) {
            let index = vector::pop_back(&mut global.team_vault.indexes);

            let nft = SuiCat {
                id: object::new(ctx),
                index,
                name: generate_name(index)
            };

            transfer::public_transfer(nft, global.beneficiary);

            mint_count = mint_count - 1
        }
    }

    public entry fun mint(
        global: &mut Global,
        clock: &Clock,
        coins: vector<Coin<SUI>>,
        ctx: &mut TxContext
    ) {
        let account = tx_context::sender(ctx);
        let remain_count = remain(global);
        let now = timestamp_ms(clock);

        assert!(now >= global.start_time, ERR_NOT_START);

        let (price_whitelist, price_public) = prices(global);
        if (now < global.start_time + global.duration) {
            assert!(table::contains(&global.whitelist, account), ERR_MINT_LIMIT);

            let nft = select_nft(global, remain_count, ctx);
            charge(global, coins, price_whitelist, ctx);
            transfer::public_transfer(nft, account);

            global.minted_whitelist = global.minted_whitelist + 1
        } else {
            let nft = select_nft(global, remain_count, ctx);
            charge(global, coins, price_public, ctx);
            transfer::public_transfer(nft, account);

            global.minted_public = global.minted_public + 1
        }
    }

    public entry fun withdraw(
        global: &mut Global,
        ctx: &mut TxContext,
    ) {
        let account = tx_context::sender(ctx);
        assert!(global.beneficiary == account || global.creator == account, ERR_NO_PERMISSION);

        let value = balance::value(&global.balance);

        if (value == 0) {
            return
        };

        let withdraw = coin::from_balance<SUI>(
            balance::split(&mut global.balance, value),
            ctx
        );

        transfer::public_transfer(
            withdraw,
            global.beneficiary
        );
    }
}