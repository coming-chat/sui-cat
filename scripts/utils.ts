import {readFileSync} from "fs";
import {equal} from "assert";
import {bcs} from "@mysten/sui.js";

export function load(path: string) {
    const whitelist = JSON.parse(readFileSync(path, "utf8"))

    console.log("load items:", whitelist.length)
    equal(whitelist.length, 29)

    return whitelist
}

export function batch_serialize(path: string) {
    let maxSize = 16*1024
    let start = 0
    let addresses = load(path)

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

export async function delay(ms: number) {
    return new Promise(resolve => {
        setTimeout(()=>{resolve(true)}, ms)
    })
}

