import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { IDispenserProvider } from "../typechain-types/contracts/DispenserProvider"
import { ethers } from "hardhat"

export async function createSignature(signer: SignerWithAddress, data: any[]): Promise<string> {
    const types: string[] = []
    const values: any[] = []
    for (const element of data) {
        if (typeof element === "string") {
            types.push("address")
            values.push(element)
        } else if (typeof element === "object" && Array.isArray(element)) {
            types.push("uint256[]")
            values.push(element)
        } else if (typeof element === "number" || typeof element === "bigint") {
            types.push("uint256")
            values.push(element)
        } else if (typeof element === "object" && !Array.isArray(element)) {
            types.push("address")
            values.push(element.simpleProvider)
            types.push("uint256[]")
            values.push(element.params)
        }
    }
    const packedData = ethers.solidityPackedKeccak256(types, values)
    return signer.signMessage(ethers.getBytes(packedData))
}

// Function to create EIP-712 signature using signTypedData
export async function createEIP712Signature(
    poolId: bigint,
    receiver: string,
    validUntil: number,
    signer: SignerWithAddress,
    contractAddress: string,
    data: IDispenserProvider.BuilderStruct[]
): Promise<string> {
    const domain = {
        name: "DispenserProvider",
        version: "1",
        chainId: (await ethers.provider.getNetwork()).chainId,
        verifyingContract: contractAddress,
    }
    const types = {
        Builder: [
            { name: "simpleProvider", type: "address" },
            { name: "params", type: "uint256[]" },
        ],
        MessageStruct: [
            { name: "data", type: "Builder[]" },
            { name: "poolId", type: "uint256" },
            { name: "receiver", type: "address" },
            { name: "validUntil", type: "uint256" },
        ],
    }
    const value = {
        data: data,
        poolId: poolId.toString(),
        receiver: receiver,
        validUntil: validUntil,
    }

    // Use signTypedData to create the signature
    return await signer.signTypedData(domain, types, value)
}
