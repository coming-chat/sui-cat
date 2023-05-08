import {
    Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock
} from '@mysten/sui.js';
import * as dotenv from "dotenv";
import {batch_serialize, delay} from "./utils";

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    const connection = new Connection({fullnode: "https://rpc-mainnet.suiscan.xyz:443"})
    const provider = new JsonRpcProvider(connection)
    const signer = new RawSigner(keypair, provider)

    const packageId = "0x6e8afef4fe19f8981ca0b651b2ca4e60191790b7cef2ba8664f0f2e073803f3d"
    const global = "0xa233bbfe148cb67da828c7d1e4817374995fc112fda379b39c22b770f47e85f7"

    const dataPath = "./data/whitelist3_difference_29.json"
    const ser_whitelist = batch_serialize(dataPath)
    console.log("batch size", ser_whitelist.length)

    for (let i = 0; i < ser_whitelist.length; i++) {
        const txb = new TransactionBlock();
        txb.setGasBudget(10000000000)

        // public entry fun set_whitelist(
        //     global: &mut Global,
        //     whitelist: vector<address>,
        //     ctx: &mut TxContext,
        // )
        txb.moveCall(
            {
                target: `${packageId}::suicat::set_whitelist`,
                arguments: [
                    txb.object(global),
                    txb.pure(ser_whitelist[i]),
                ]
            }
        )

        console.log("current batch: ", i)

        // const result = await signer.dryRunTransactionBlock({
        //     transactionBlock: txb
        // });
        // console.log(result.effects.gasUsed, result.effects?.status)

        const result = await signer.signAndExecuteTransactionBlock({
            transactionBlock: txb, options: {showEffects: true}
        });
        console.log({ result }, result.effects?.status)

        await delay(10000)
    }
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});