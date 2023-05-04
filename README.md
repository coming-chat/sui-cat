# SUI CAT
 

## Sui Object Display Standard

The basic set of properties suggested includes: 
- `name` - A name for the object. The name is displayed when users view the object. 
- `description` - A description for the object. The description is displayed when users view the object. 
- `link` - A link to the object to use in an application. 
- `image_url` - A URL or a blob with the image for the object. 
- `project_url` - A link to a website associated with the object or creator.
- `creator` - A string that indicates the object creator.

[Sui Object Display Standard](https://docs.sui.io/build/sui-object-display)


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
```


## publish
```bash
sui client publish --gas-budget 1000000000
```

## mainnet
package=0x8a1b7bf27a88e36602c373536a18c8bf2dde3633d91f5a070aa4b460e55e4868
global=0xb5e4ee5ce9e9e1552d9bd4a330cc3cea62c3c9a0fa35b473d1b73a93ca1b99fc
display=0x466cb9284d2e4a1f5ba6e65888e7fce3016b29858592fffe414ff33a39a8648f
publisher=0x879a4df5af14a967e9d7da9e03c31db40012f4ab0c43abaee52a9b4c541d888d
upgradeCap=0x457f2a8103da36a25be37dc6bab54c915f9fae74710ccf9aa5b36703448f34f8
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