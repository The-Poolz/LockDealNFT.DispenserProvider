import { ethers } from "hardhat"

async function main() {
    const lockDealNFT = ""
    const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
    const dispenserProvider = await DispenserProvider.deploy(lockDealNFT)

    console.log("DispenserProvider deployed to:", await dispenserProvider.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
