import {
    Connection, Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock, UpgradePolicy
} from '@mysten/sui.js';

import * as dotenv from "dotenv";
import { execSync } from 'child_process';

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    const connection = new Connection({fullnode: "https://sui-mainnet-endpoint.blockvision.org:443"})
    const provider = new JsonRpcProvider(connection)
    const signer = new RawSigner(keypair, provider)

    const { modules, dependencies, digest } = JSON.parse(
        execSync(
            `sui move build --dump-bytecode-as-base64`,
            { encoding: "utf8" }
        )
    )

    console.log(modules)
    console.log(dependencies)

    const packageId = "0x6e8afef4fe19f8981ca0b651b2ca4e60191790b7cef2ba8664f0f2e073803f3d"
    const capId = "0x785a8b75fe6d0812325546e84fc79c01f62f272e7f2788cd860d5869d3bf63f1"

    const txb = new TransactionBlock();

    txb.setGasBudget(10000000000)

    const ticket = txb.moveCall({
        target: '0x2::package::authorize_upgrade',
        arguments: [
            txb.object(capId),
            txb.pure(UpgradePolicy.COMPATIBLE),
            txb.pure(digest)
        ],
    });

    const receipt = txb.upgrade({
        modules,
        dependencies,
        packageId,
        ticket,
    });

    txb.moveCall({
        target: '0x2::package::commit_upgrade',
        arguments: [
            txb.object(capId),
            receipt
        ],
    });

    txb.transferObjects(
        [txb.object(capId)],
        txb.pure(await signer.getAddress())
    );

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