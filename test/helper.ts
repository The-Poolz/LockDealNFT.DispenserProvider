import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
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
        } else if (typeof element === "number" || ethers.BigNumber.isBigNumber(element)) {
            types.push("uint256")
            values.push(element)
        } else if (typeof element === "object" && !Array.isArray(element)) {
            types.push("address")
            values.push(element.simpleProvider)
            types.push("uint256[]")
            values.push(element.params)
        }
    }
    const packedData = ethers.utils.solidityKeccak256(types, values)
    return signer.signMessage(ethers.utils.arrayify(packedData))
}