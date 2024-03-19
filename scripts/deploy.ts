import { ethers } from "hardhat"

async function main() {
    const lockDealNFT = ""
    const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
    const dispenserProvider = await DispenserProvider.deploy(lockDealNFT)

    await dispenserProvider.deployed()

    console.log("TemplateContract deployed to:", dispenserProvider.address)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
