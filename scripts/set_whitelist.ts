import {
    Connection,
    Ed25519Keypair,
    JsonRpcProvider,
    RawSigner,
    testnetConnection,
    TransactionBlock
} from '@mysten/sui.js';
import * as dotenv from "dotenv";
import {batch_serialize, delay} from "./utils";

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    // const c = new Connection({fullnode: "https://rpc-testnet.suiscan.xyz:443"})
    const provider = new JsonRpcProvider(testnetConnection)
    const signer = new RawSigner(keypair, provider)

    const packageId = "0xc5b18811206c9ef35b516cd90f1736e7504f17fec147179298cc6851f2aa10a9"
    const global = "0x9876b64fad60ef76235f56c3221a4ee1aa891eaa3b86b10ed16195169c7c3e19"

    const dataPath = "./data/filtered_109851.json"
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

        const result = await signer.dryRunTransactionBlock({
            transactionBlock: txb
        });
        console.log(result.effects.gasUsed, result.effects?.status)

        // const result = await signer.signAndExecuteTransactionBlock({
        //     transactionBlock: txb, options: {showEffects: true}
        // });
        // console.log({ result }, result.effects?.status)

        await delay(10000)
    }
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});