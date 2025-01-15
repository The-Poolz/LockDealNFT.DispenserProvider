import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"

export async function createSignature(poolId: bigint, validUntil: number, signer: SignerWithAddress) {
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
