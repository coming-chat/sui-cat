# SUI CAT
The DMENS NFT-Pass program has been launched to encourage community participation, contribution, 
and development by attracting more partners and expanding the community.

`10000` SuiCat NFTs are equivalent to 20% of DMens equity (tokens).

## Sui Object Display Standard

The basic set of properties suggested includes: 
- `name` - A name for the object. The name is displayed when users view the object. 
- `description` - A description for the object. The description is displayed when users view the object. 
- `link` - A link to the object to use in an application. 
- `image_url` - A URL or a blob with the image for the object. 
- `project_url` - A link to a website associated with the object or creator.
- `creator` - A string that indicates the object creator.

[Sui Object Display Standard](https://docs.sui.io/build/sui-object-display)

## Transfer Policy
[TransferPolicy](https://github.com/MystenLabs/sui/blob/sui-v1.0.0/crates/sui-framework/packages/sui-framework/sources/kiosk/transfer_policy.move) 
is a highly customizable primitive, which provides an
interface for the type owner to set custom transfer rules for every
deal performed in the `Kiosk` or a similar system that integrates with TP.

- SuiCat provides a custom `royalty_policy` [shared object](https://explorer.sui.io/object/0x9c1969ebe46c491b60fa0ace12ec80f5b037794c2c8b5c976c50d07b5e61da6e), set the default `5% royalty`.

- For [Sui Kiosk Royalty](https://explorer.sui.io/object/0x434b5bd8f6a7b05fede0ff46c6e511d71ea326ed38056e3bcd681d2d7c2a7879?network=mainnet),
SuiCat created a new `royalty_policy` [shared object](https://explorer.sui.io/object/0xb14bfebf22d4808bcd8bb2df2b681db26dce6c1c42194d5db1545df36b0cc580) by [kiosk-royalty](https://github.com/coming-chat/kiosk-royalty). 
It's also the same `%5 royalty`.




## Core Object
```move

struct SuiCat has key,store {
    id: UID,
    index: u16,
    name: String
}
```

```move
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
```

## Core Entry Function

```move
// set global start time
// called by admin
public entry fun set_start_time(
    global: &mut Global,
    start_time: u64,
    ctx: &mut TxContext
)

// set prices of SuiCat
// called by admin
public entry fun set_prices(
    global: &mut Global,
    price_whitelist: u64,
    price_public: u64,
    ctx: &mut TxContext
)

// set wilte list accounts
// called by admin
public entry fun set_whitelist(
    global: &mut Global,
    whitelist: vector<address>,
    ctx: &mut TxContext
)

// set prices
// called by admin
public entry fun set_prices(
    global: &mut Global,
    price_whitelist: u64,
    price_public: u64,
    ctx: &mut TxContext
) 

// batch mint SuiCat to team
// [SuiCat#1, SuiCat#3000]
// called by admin
public entry fun mint_reserve(
    global: &mut Global,
    batch: u64,
    ctx: &mut TxContext
)

// mint one SuiCat
// random select in [SuiCat#3001, SuiCat#10000]
// called by user
public entry fun mint(
    global: &mut Global,
    clock: &Clock,
    coins: vector<Coin<SUI>>,
    ctx: &mut TxContext
)

// withdraw all fund to beneficiary
// called by admin or beneficiary
public entry fun withdraw(
    global: &mut Global,
    ctx: &mut TxContext
)

// update the royalty rate of SuiCat
// called by admin
public entry fun update_royalty_bp<SuiCat>(
    policy: &mut TransferPolicy<SuiCat>,
    cap: &TransferPolicyCap<SuiCat>,
    amount_bp: u16
)
```


## publish
```bash
sui client publish --gas-budget 1000000000
```

## mainnet
package=0x6e8afef4fe19f8981ca0b651b2ca4e60191790b7cef2ba8664f0f2e073803f3d
global=0xa233bbfe148cb67da828c7d1e4817374995fc112fda379b39c22b770f47e85f7
policy=0x9c1969ebe46c491b60fa0ace12ec80f5b037794c2c8b5c976c50d07b5e61da6e
policyCap=0x2c61ec298fde843f5ab89a900d210a02dac272f217aafb076bd62f79597003db
display=0x42d25dd8866f0417999f0c7582cbc2a413e74fbad33664f6a48b9989faff14e7
publisher=0x4d1418cc963fa0378c515901fd11d2bd29d04c6c4e797d5abc50151ffed245b5
upgradeCap=0x785a8b75fe6d0812325546e84fc79c01f62f272e7f2788cd860d5869d3bf63f1
policyConfig=0xeb258c8482672b807cbc0d7bcd70c535239de3cfa6d245715f245086db54ec1c
deployer=0x0f6e65716f1a33317c8914b24cc006475e6fafd797e34ffae72c76bf5ed4be12

clock=0x6

### set_whitelist
```bash
sui client call --gas-budget 1000000000 \
    --package $package \
    --module suicat \
    --function set_whitelist \
    --args $global '["0xd5780ffbf267242c899ac04f9300fa4e6506bc338f671076727d4e32cd1a8f8a"]'
```

### mint_reserve
```bash
sui client call --gas-budget 10000000000 \
    --package $package \
    --module suicat \
    --function mint_reserve \
    --args $global 750

```

### mint
coin=0x803b3e238251fec2627242f724eac4188c9072e0d2c489214359fbfe247907f5
```bash
sui client call --gas-budget 100000000 \
    --package $package \
    --module suicat \
    --function mint \
    --args $global $clock [\"$coin\"]
```

### withdraw
```bash
sui client call --gas-budget 100000000 \
    --package $package \
    --module suicat \
    --function withdraw \
    --args $global
```

## update display

```bash
sui client call --gas-budget 100000000 \
    --package 0x2 \
    --module display \
    --function edit \
    --type-args $package::suicat::SuiCat \
    --args $display "image_url" "ipfs://QmUwLR4GqGUyXCrHsUQGnmoLBhNWrRRt2VtxuyNCKeUVQS/{index}.png"
    
sui client call --gas-budget 100000000 \
    --package 0x2 \
    --module display \
    --function update_version \
    --type-args $package::suicat::SuiCat \
    --args $display
```

## update royalty rate

```bash
sui client call --gas-budget 100000000 \
    --package $package \
    --module royalty_policy \
    --function update_royalty_bp \
    --type-args $package::suicat::SuiCat \
    --args $policy $policyCap 300
```