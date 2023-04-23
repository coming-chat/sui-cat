import {
    Ed25519Keypair, JsonRpcProvider, RawSigner, testnetConnection, TransactionBlock,
} from '@mysten/sui.js';

import * as dotenv from "dotenv";
import { execSync } from 'child_process';

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    const provider = new JsonRpcProvider(testnetConnection)
    const signer = new RawSigner(keypair, provider)

    const { modules, dependencies } = JSON.parse(
        execSync(
            `sui move build --dump-bytecode-as-base64`,
            { encoding: "utf8" }
        )
    )

    console.log(modules)
    console.log(dependencies)

    const txb = new TransactionBlock();

    txb.setGasBudget(10000000000)

    const cap = txb.publish({
        modules: modules,
        dependencies: dependencies
    })
    console.log(cap)

    txb.transferObjects([cap], txb.pure(await signer.getAddress()));

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