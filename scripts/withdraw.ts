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

    const packageId = "0xc5b18811206c9ef35b516cd90f1736e7504f17fec147179298cc6851f2aa10a9"
    const global = "0x9876b64fad60ef76235f56c3221a4ee1aa891eaa3b86b10ed16195169c7c3e19"

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