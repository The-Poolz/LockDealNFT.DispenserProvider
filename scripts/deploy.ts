import { ethers } from "hardhat"
import { LockDealNFT } from "../typechain-types"

async function deploy() {
    // Fetch the LockDealNFT address from environment variables
    const lockDealNFT = process.env.LOCK_DEAL_NFT_ADDRESS

    if (!lockDealNFT) {
        throw new Error("LockDealNFT address is not set in the environment variables.")
    }
    // get LockDealNFT contract
    const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
    const lockDealNFTContract: LockDealNFT = LockDealNFT.attach(lockDealNFT) as LockDealNFT

    const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
    const dispenserProvider = await DispenserProvider.deploy(lockDealNFT)

    console.log("DispenserProvider deployed to:", await dispenserProvider.getAddress())
    // approve dispenser provider to mint NFTs
    await lockDealNFTContract.setApprovedContract(await dispenserProvider.getAddress(), true)
    console.log("DispenserProvider approved to mint NFTs")
}

deploy().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
