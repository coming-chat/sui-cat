import {
    Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock,
} from '@mysten/sui.js';

import * as dotenv from "dotenv";

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    const connection = new Connection({fullnode: "https://rpc-mainnet.suiscan.xyz:443"})
    const provider = new JsonRpcProvider(connection)
    const signer = new RawSigner(keypair, provider)

    const packageId = "0x6e8afef4fe19f8981ca0b651b2ca4e60191790b7cef2ba8664f0f2e073803f3d"
    const global = "0xa233bbfe148cb67da828c7d1e4817374995fc112fda379b39c22b770f47e85f7"

    const txb = new TransactionBlock();

    txb.setGasBudget(10000000000)

    // public entry fun withdraw(
    //     global: &mut Global,
    //     ctx: &mut TxContext,
    // )
    txb.moveCall(
        {
            target: `${packageId}::suicat::withdraw`,
            arguments: [
                txb.object(global)
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