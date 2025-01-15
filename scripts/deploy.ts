import { ethers } from "hardhat"

async function deploy() {
    const lockDealNFT = "0xe42876a77108E8B3B2af53907f5e533Cba2Ce7BE"
    const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
    const dispenserProvider = await DispenserProvider.deploy(lockDealNFT)

    console.log("DispenserProvider deployed to:", await dispenserProvider.getAddress())
}

deploy().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
