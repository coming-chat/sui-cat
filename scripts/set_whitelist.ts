import {
    bcs, Connection,
    Ed25519Keypair, JsonRpcProvider, RawSigner, TransactionBlock,
} from '@mysten/sui.js';

import * as fs from "fs";
import * as assert from "assert";
import * as dotenv from "dotenv";

const dataPath = "./scripts/whitelist-9873.json"

function read_json() {
    return JSON.parse(fs.readFileSync(dataPath, "utf8"))
}

function load() {
    const whitelist = read_json()

    var addresses: string[] = []
    for(var i = 0; i < whitelist.length; i++) {
        addresses.push(whitelist[i].address)
    }

    console.log("load items:", whitelist.length)
    assert.equal(whitelist.length, 9873)

    return addresses
}

function batch_serialize() {
    let maxSize = 16*1024
    let start = 0
    let addresses = load()

    var tmp_address = []
    var ser_address = []

    for (var i = start; i < addresses.length; i++) {
        tmp_address.push(addresses[i])

        if (tmp_address.length == 500) {
            let addresses_bytes = bcs.ser('vector<address>', tmp_address, {maxSize: maxSize}).toBytes()

            ser_address.push(addresses_bytes)

            console.log("serialized [", start, i, "]")

            tmp_address = []
            start = i+1
        }
    }

    if (tmp_address.length > 0) {
        let addresses_bytes = bcs.ser('vector<address>', tmp_address, {maxSize: maxSize}).toBytes()

        ser_address.push(addresses_bytes)

        console.log("serialized [", start, i-1, "]")
    }

    return ser_address
}

async function delay(ms: number) {
    return new Promise(resolve => {
        setTimeout(()=>{resolve(true)}, ms)
    })
}

async function main() {
    dotenv.config();

    const privkey = process.env.e76ePRIVKEY ?? "empty"
    const keypair = Ed25519Keypair.fromSecretKey(Buffer.from(privkey, 'hex'))

    const c = new Connection({fullnode: "https://rpc-testnet.suiscan.xyz:443"})
    const provider = new JsonRpcProvider(c)
    const signer = new RawSigner(keypair, provider)

    const packageId = "0xf1d4ee4b3a2787cd066180857fa0170ccd721c28e20d5f334f48d585ed367284"
    const global = "0x5055e205e2a783376ad64e1d49ae87409ac171e4d9c8d3ade32fc74cb0d112c0"

    const ser_whitelist = batch_serialize()
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