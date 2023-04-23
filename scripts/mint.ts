import {
    Ed25519Keypair, JsonRpcProvider, RawSigner, testnetConnection, TransactionBlock,
} from '@mysten/sui.js';

import * as dotenv from "dotenv";

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    const provider = new JsonRpcProvider(testnetConnection)
    const signer = new RawSigner(keypair, provider)

    const packageId = "0xf1d4ee4b3a2787cd066180857fa0170ccd721c28e20d5f334f48d585ed367284"
    const global = "0x5055e205e2a783376ad64e1d49ae87409ac171e4d9c8d3ade32fc74cb0d112c0"
    const clock = "0x6"

    const txb = new TransactionBlock();

    txb.setGasBudget(1000000000)

    const coins = txb.splitCoins(
        txb.gas,
        [txb.pure(100000000)]
    )
    // public entry fun mint(
    //     global: &mut Global,
    //     clock: &Clock,
    //     coins: vector<Coin<SUI>>,
    //     ctx: &mut TxContext
    // )
    txb.moveCall(
        {
            target: `${packageId}::suicat::mint`,
            arguments: [
                txb.object(global),
                txb.object(clock),
                txb.makeMoveVec({objects: [coins[0]]})
            ]
        }
    )

    const result = await signer.dryRunTransactionBlock({
        transactionBlock: txb
    });
    console.log(result.effects.gasUsed, result.effects?.status)

    // const result = await signer.signAndExecuteTransactionBlock({
    //     transactionBlock: txb, options: {showEffects: true}
    // });
    // console.log({ result }, result.effects?.status)
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});