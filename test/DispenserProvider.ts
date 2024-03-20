import { DispenserProvider } from "../typechain-types/contracts/DispenserProvider"
import { LockDealNFT } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/LockDealNFT/LockDealNFT"
import { DealProvider } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/SimpleProviders/DealProvider/DealProvider"
import { MockVaultManager as VaultManager } from "../typechain-types/contracts/mock/MockVaultManager"
import { LockDealProvider } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/SimpleProviders/LockProvider/LockDealProvider"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TimedDealProvider } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/SimpleProviders/TimedDealProvider/TimedDealProvider"
import { DispenserState } from "../typechain-types/contracts/DispenserProvider"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai"
import { createSignature } from "./helper"
import { Bytes, constants, BigNumber } from "ethers"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"

describe("Dispenser Provider tests", function () {
    let owner: SignerWithAddress
    let user: SignerWithAddress
    let signer: SignerWithAddress
    let dispenserProvider: DispenserProvider
    let token: ERC20Token
    let lockDealNFT: LockDealNFT
    let dealProvider: DealProvider
    let userData: DispenserState.BuilderStruct
    let usersData: DispenserState.BuilderStruct[]
    let lockProvider: LockDealProvider
    let timedProvider: TimedDealProvider
    let vaultManager: VaultManager
    let packedData: string
    let poolId: number
    let validTime: BigNumber
    const builderType = ["uint256", "uint256", "address", "tuple(address,uint256[])[]"]
    const creationSignature: Bytes = ethers.utils.toUtf8Bytes("signature")
    const amount = ethers.utils.parseUnits("10", 18)
    const ONE_DAY = 86400

    before(async () => {
        [owner, user, signer] = await ethers.getSigners()
        const VaultManagerFactory = await ethers.getContractFactory("MockVaultManager")
        vaultManager = (await VaultManagerFactory.deploy()) as VaultManager
        const LockDealNFTFactory = await ethers.getContractFactory("LockDealNFT")
        lockDealNFT = (await LockDealNFTFactory.deploy(vaultManager.address, "")) as LockDealNFT
        const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
        dispenserProvider = await DispenserProvider.deploy(lockDealNFT.address)
        const DealProvider = await ethers.getContractFactory("DealProvider")
        dealProvider = await DealProvider.deploy(lockDealNFT.address)
        const LockDealProvider = await ethers.getContractFactory("LockDealProvider")
        lockProvider = await LockDealProvider.deploy(lockDealNFT.address, dealProvider.address)
        const TimedDealProvider = await ethers.getContractFactory("TimedDealProvider")
        timedProvider = await TimedDealProvider.deploy(lockDealNFT.address, lockProvider.address)
        await lockDealNFT.setApprovedContract(dealProvider.address, true)
        await lockDealNFT.setApprovedContract(lockProvider.address, true)
        await lockDealNFT.setApprovedContract(timedProvider.address, true)
        await lockDealNFT.setApprovedContract(dispenserProvider.address, true)
        await lockDealNFT.connect(user).setApprovalForAll(dispenserProvider.address, true)
    })

    beforeEach(async () => {
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        token = await ERC20Token.deploy("Test", "TST")
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await token.approve(vaultManager.address, amount)
        await dispenserProvider.connect(owner).deposit(signer.address, token.address, amount, creationSignature)
        validTime = ethers.BigNumber.from((await time.latest()) + ONE_DAY)
        userData = { simpleProvider: lockProvider.address, params: [amount.div(2), validTime] }
        usersData = [{ simpleProvider: lockProvider.address, params: [amount.div(2), validTime] }]
        packedData = ethers.utils.defaultAbiCoder.encode(builderType, [
            poolId,
            validTime,
            user.address,
            [[dealProvider.address, [amount]]],
        ])
    })

    it("should return name of contract", async () => {
        expect(await dispenserProvider.name()).to.equal("DispenserProvider")
    })

    it("should increase leftAmount after creation", async () => {
        expect(await dispenserProvider.leftAmount(poolId)).to.equal(amount)
    })

    it("should deacrease leftAmount after lock", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await dispenserProvider.connect(user).createLock(poolId, validTime, user.address, usersData, signature)
        expect(await dispenserProvider.leftAmount(poolId)).to.equal(amount.div(2))
    })

    it("should transfer if available", async () => {
        userData = { simpleProvider: dealProvider.address, params: [amount] }
        usersData = [{ simpleProvider: dealProvider.address, params: [amount] }]
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        const beforeBalance = await token.balanceOf(user.address)
        await dispenserProvider.connect(user).createLock(poolId, validTime, user.address, usersData, signature)
        // check if user has tokens after the transfer
        expect(await token.balanceOf(user.address)).to.equal(beforeBalance.add(amount))
    })

    it("should revert double creation", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await dispenserProvider.connect(user).createLock(poolId, validTime, user.address, usersData, signature)
        await expect(
            dispenserProvider.connect(user).createLock(poolId, validTime, user.address, usersData, signature)
        ).to.be.revertedWith("DispenserProvider: Tokens already taken")
    })

    it("should revert invalid signer address", async () => {
        await expect(
            dispenserProvider.connect(owner).deposit(constants.AddressZero, token.address, amount, creationSignature)
        ).to.be.revertedWith("DispenserProvider: Invalid signer address")
    })

    it("should revert if sender is invalid", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.connect(owner).createLock(poolId, validTime, user.address, usersData, signature)
        ).to.be.revertedWith("DispenserProvider: Caller is not approved")
    })

    it("should revert invalid signer address", async () => {
        await expect(
            dispenserProvider.connect(owner).deposit(owner.address, constants.AddressZero, amount, creationSignature)
        ).to.be.revertedWith("DispenserProvider: Invalid token address")
    })

    it("should revert invalid signer address", async () => {
        await expect(
            dispenserProvider.connect(owner).deposit(owner.address, token.address, 0, creationSignature)
        ).to.be.revertedWith("DispenserProvider: Invalid amount")
    })

    it("should revert split", async () => {
        const halfRatio = ethers.utils.parseUnits("1", 21).div(2)
        const packedData = ethers.utils.defaultAbiCoder.encode(["uint256", "address"], [halfRatio, owner.address])
        await expect(
            lockDealNFT
                .connect(signer)
                [
                    "safeTransferFrom(address,address,uint256,bytes)"
                ](signer.address, lockDealNFT.address, poolId, packedData)
        ).to.be.revertedWith("DispenserProvider: Not implemented yet")
    })

    it("should revert withdraw", async () => {
        await expect(
            lockDealNFT
                .connect(signer)
                ["safeTransferFrom(address,address,uint256)"](signer.address, lockDealNFT.address, poolId)
        ).to.be.revertedWith("DispenserProvider: Not implemented yet")
    })
})
