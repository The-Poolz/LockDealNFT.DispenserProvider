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
    let poolId: number
    let addresses: string[]
    let params: [BigNumber]
    let validTime: BigNumber
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
        params = [amount]
        addresses = [signer.address, token.address]
        poolId = (await lockDealNFT.totalSupply()).toNumber()
        await token.approve(vaultManager.address, amount)
        await dispenserProvider.connect(owner).createNewPool(addresses, params, creationSignature)
        validTime = ethers.BigNumber.from((await time.latest()) + ONE_DAY)
        userData = { simpleProvider: lockProvider.address, params: [amount.div(2), validTime] }
        usersData = [userData]
    })

    it("should return name of contract", async () => {
        expect(await dispenserProvider.name()).to.equal("DispenserProvider")
    })

    it("should increase leftAmount after creation", async () => {
        expect(await dispenserProvider.poolIdToAmount(poolId)).to.equal(amount)
    })

    it("should deacrease leftAmount after lock", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature)
        expect(await dispenserProvider.poolIdToAmount(poolId)).to.equal(amount.div(2))
    })

    it("should transfer if available", async () => {
        userData = { simpleProvider: dealProvider.address, params: [amount] }
        usersData = [userData]
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        const beforeBalance = await token.balanceOf(user.address)
        await dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature)
        // check if user has tokens after the transfer
        expect(await token.balanceOf(user.address)).to.equal(beforeBalance.add(amount))
    })

    it("should create lock if approved for all", async () => {
        await lockDealNFT.connect(user).setApprovalForAll(owner.address, true)
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.connect(owner).dispenseLock(poolId, validTime, user.address, usersData, signature)
        ).to.not.reverted
        await lockDealNFT.connect(user).setApprovalForAll(owner.address, false)
    })

    it("should create lock if approved poolId", async () => {
        await lockDealNFT.connect(signer).approve(owner.address, poolId)
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.connect(owner).dispenseLock(poolId, validTime, user.address, usersData, signature)
        ).to.not.reverted
    })

    it("should revert double creation", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature)
        await expect(
            dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature)
        ).to.be.revertedWith("DispenserProvider: Tokens already taken")
    })

    it("should revert invalid signer address", async () => {
        addresses = [constants.AddressZero, token.address]
        await expect(
            dispenserProvider.connect(owner).createNewPool(addresses, params, creationSignature)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert if sender is invalid", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.connect(owner).dispenseLock(poolId, validTime, user.address, usersData, signature)
        ).to.be.revertedWith("DispenserProvider: Caller is not approved")
    })

    it("should revert zero token address", async () => {
        addresses = [signer.address, constants.AddressZero]
        await expect(
            dispenserProvider.connect(owner).createNewPool(addresses, params, creationSignature)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert invalid amount", async () => {
        params = [BigNumber.from(0)]
        await expect(
            dispenserProvider.connect(owner).createNewPool(addresses, params, creationSignature)
        ).to.be.revertedWith("amount must be greater than 0")
    })

    it("should emit TokensDispensed event", async () => {
        const signatureData = [poolId, validTime, user.address, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature))
            .to.emit(dispenserProvider, "TokensDispensed")
            .withArgs(poolId, user.address, amount.div(2), amount.div(2))
    })

    it("should support IERC165 interface", async () => {
        expect(await dispenserProvider.supportsInterface('0x01ffc9a7')).to.equal(true)
    })

    it("should support IDispenserProvider interface", async () => {
        expect(await dispenserProvider.supportsInterface('0xda28ff53')).to.equal(true)
    })

    it("should revert if params amount greater than leftAmount", async () => {
        userData = { simpleProvider: lockProvider.address, params: [amount, validTime] }
        usersData = [userData, userData]
        const signatureData = [poolId, validTime, user.address, userData, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature)
        ).to.be.revertedWith("DispenserProvider: Not enough tokens in the pool")
    })

    it("should revert zero params amount", async () => {
        const invalidUserData = { simpleProvider: lockProvider.address, params: [0, validTime] }
        usersData = [userData, invalidUserData]
        const signatureData = [poolId, validTime, user.address, userData, invalidUserData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.connect(user).dispenseLock(poolId, validTime, user.address, usersData, signature)
        ).to.be.revertedWith("DispenserProvider: Amount must be greater than 0")
    })
})
