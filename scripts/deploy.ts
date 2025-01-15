import { ethers } from "hardhat"

async function deploy() {
    // Fetch the LockDealNFT address from environment variables
    const lockDealNFT = process.env.LOCK_DEAL_NFT_ADDRESS
    console.log(lockDealNFT)
    if (!lockDealNFT) {
        throw new Error("LockDealNFT address is not set in the environment variables.")
    }

    const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
    const dispenserProvider = await DispenserProvider.deploy(lockDealNFT)

    console.log("DispenserProvider deployed to:", await dispenserProvider.getAddress())
}

deploy().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
