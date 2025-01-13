import { ethers } from "hardhat"
import { createEIP712Signature } from "../test/helper"
import { IDispenserProvider } from "../typechain-types"

const ONE_DAY = 86400

async function createSignature() {
    const validUntil = ONE_DAY
    const [signer] = await ethers.getSigners()
    const poolId = 15n
    const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
    const data: IDispenserProvider.BuilderStruct[] = [
        {
            simpleProvider: contractAddress,
            params: [1000n, validUntil],
        },
        {
            simpleProvider: contractAddress,
            params: [2000n, validUntil],
        },
    ]
    await createEIP712Signature(poolId, await signer.getAddress(), validUntil, signer, contractAddress, data)
}

createSignature().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
