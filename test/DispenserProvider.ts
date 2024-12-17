import { DispenserProvider } from "../typechain-types/contracts/DispenserProvider"
import { LockDealNFT } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/LockDealNFT/LockDealNFT"
import { DealProvider } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/SimpleProviders/DealProvider/DealProvider"
import { MockVaultManager as VaultManager } from "../typechain-types/contracts/mock/MockVaultManager"
import { LockDealProvider } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/SimpleProviders/LockProvider/LockDealProvider"
import { ERC20Token } from "../typechain-types/@poolzfinance/poolz-helper-v2/contracts/token/ERC20Token"
import { TimedDealProvider } from "../typechain-types/@poolzfinance/lockdeal-nft/contracts/SimpleProviders/TimedDealProvider/TimedDealProvider"
import { IDispenserProvider } from "../typechain-types/contracts/DispenserProvider"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai"
import { createSignature } from "./helper"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"

describe("Dispenser Provider tests", function () {
    let caller: SignerWithAddress
    let receiver: SignerWithAddress
    let signer: SignerWithAddress
    let dispenserProvider: DispenserProvider
    let token: ERC20Token
    let lockDealNFT: LockDealNFT
    let dealProvider: DealProvider
    let userData: IDispenserProvider.BuilderStruct
    let usersData: IDispenserProvider.BuilderStruct[]
    let lockProvider: LockDealProvider
    let timedProvider: TimedDealProvider
    let vaultManager: VaultManager
    let poolId: bigint
    let addresses: string[]
    let params: [bigint]
    let validTime: number
    const creationSignature: Uint8Array = ethers.toUtf8Bytes("signature")
    const amount = ethers.parseUnits("10", 18)
    const ONE_DAY = 86400

    before(async () => {
        [caller, receiver, signer] = await ethers.getSigners()
        const VaultManagerFactory = await ethers.getContractFactory("MockVaultManager")
        vaultManager = (await VaultManagerFactory.deploy()) as VaultManager
        const LockDealNFTFactory = await ethers.getContractFactory("LockDealNFT")
        lockDealNFT = (await LockDealNFTFactory.deploy(await vaultManager.getAddress(), "")) as LockDealNFT
        const DispenserProvider = await ethers.getContractFactory("DispenserProvider")
        dispenserProvider = await DispenserProvider.deploy(await lockDealNFT.getAddress())
        const DealProvider = await ethers.getContractFactory("DealProvider")
        dealProvider = await DealProvider.deploy(await lockDealNFT.getAddress())
        const LockDealProvider = await ethers.getContractFactory("LockDealProvider")
        lockProvider = await LockDealProvider.deploy(await lockDealNFT.getAddress(), await dealProvider.getAddress())
        const TimedDealProvider = await ethers.getContractFactory("TimedDealProvider")
        timedProvider = await TimedDealProvider.deploy(lockDealNFT.getAddress(), await lockProvider.getAddress())
        await lockDealNFT.setApprovedContract(await dealProvider.getAddress(), true)
        await lockDealNFT.setApprovedContract(await lockProvider.getAddress(), true)
        await lockDealNFT.setApprovedContract(await timedProvider.getAddress(), true)
        await lockDealNFT.setApprovedContract(await dispenserProvider.getAddress(), true)
    })

    beforeEach(async () => {
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        token = await ERC20Token.deploy("Test", "TST")
        params = [amount]
        addresses = [await signer.getAddress(), await token.getAddress()]
        poolId = await lockDealNFT.totalSupply()
        await token.approve(await vaultManager.getAddress(), amount)
        await dispenserProvider.createNewPool(addresses, params, creationSignature)
        validTime = (await time.latest()) + ONE_DAY
        userData = { simpleProvider: await lockProvider.getAddress(), params: [amount / 2n, validTime] }
        usersData = [userData]
    })

    it("should return name of contract", async () => {
        expect(await dispenserProvider.name()).to.equal("DispenserProvider")
    })

    it("should increase leftAmount after creation", async () => {
        expect(await dispenserProvider.poolIdToAmount(poolId)).to.equal(amount)
    })

    it("should deacrease leftAmount after lock", async () => {
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await dispenserProvider
            .connect(receiver)
            .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        expect(await dispenserProvider.poolIdToAmount(poolId)).to.equal(amount / 2n)
    })

    it("should withdraw if available and disper approved", async () => {
        await lockDealNFT.connect(receiver).setApprovalForAll(await dispenserProvider.getAddress(), true)
        userData = { simpleProvider: await dealProvider.getAddress(), params: [amount] }
        usersData = [userData]
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        const beforeBalance = await token.balanceOf(await receiver.getAddress())
        await dispenserProvider
            .connect(receiver)
            .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        // check if user has tokens after the withdraw
        expect(await token.balanceOf(await receiver.getAddress())).to.equal(beforeBalance + amount)
        await lockDealNFT.connect(receiver).setApprovalForAll(await dispenserProvider.getAddress(), false)
    })

    it("should not withdraw if dispenser not approved", async () => {
        userData = { simpleProvider: await dealProvider.getAddress(), params: [amount] }
        usersData = [userData]
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        const beforeBalance = await token.balanceOf(await receiver.getAddress())
        await dispenserProvider
            .connect(receiver)
            .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        // check if user doesn't have tokens after the withdraw
        expect(await token.balanceOf(await receiver.getAddress())).to.equal(beforeBalance)
    })

    it("should create a lock if the caller is approved by the receiver.", async () => {
        await lockDealNFT.connect(receiver).setApprovalForAll(await caller.getAddress(), true)
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider.dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        ).to.not.reverted
        await lockDealNFT.connect(receiver).setApprovalForAll(await caller.getAddress(), false)
    })

    it("should revert double creation", async () => {
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await dispenserProvider
            .connect(receiver)
            .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        await expect(
            dispenserProvider
                .connect(receiver)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        ).to.be.revertedWithCustomError(dispenserProvider, "TokensAlreadyTaken")
    })

    it("should revert invalid signer address", async () => {
        addresses = [ethers.ZeroAddress, await token.getAddress()]
        await expect(dispenserProvider.createNewPool(addresses, params, creationSignature)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert authorization if the caller is neither the owner, the receiver, nor approved by the receiver", async () => {
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider
                .connect(caller)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        ).to.be.revertedWithCustomError(dispenserProvider, "CallerNotApproved")
    })

    it("should revert zero token address", async () => {
        addresses = [await signer.getAddress(), ethers.ZeroAddress]
        await expect(dispenserProvider.createNewPool(addresses, params, creationSignature)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert invalid amount", async () => {
        params = [0n]
        await expect(dispenserProvider.createNewPool(addresses, params, creationSignature)).to.be.revertedWith(
            "amount must be greater than 0"
        )
    })

    it("should emit PoolCreated event", async () => {
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider
                .connect(receiver)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        )
            .to.emit(dispenserProvider, "PoolCreated")
            .withArgs(poolId + 1n, await lockProvider.getAddress())
    })

    it("should emit TokensDispensed event", async () => {
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider
                .connect(receiver)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        )
            .to.emit(dispenserProvider, "TokensDispensed")
            .withArgs(poolId, await receiver.getAddress(), amount / 2n, amount / 2n)
    })

    it("should support IERC165 interface", async () => {
        expect(await dispenserProvider.supportsInterface("0x01ffc9a7")).to.equal(true)
    })

    it("should support IDispenserProvider interface", async () => {
        expect(await dispenserProvider.supportsInterface("0xda28ff53")).to.equal(true)
    })

    it("should revert if params amount greater than leftAmount", async () => {
        userData = { simpleProvider: await lockProvider.getAddress(), params: [amount, validTime] }
        const usersData = [userData, userData]
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData, userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider
                .connect(receiver)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        ).to.be.revertedWithCustomError(dispenserProvider, "NotEnoughTokensInPool")
    })

    it("should revert zero params amount", async () => {
        const invalidUserData = { simpleProvider: await lockProvider.getAddress(), params: [0, validTime] }
        const usersData = [userData, invalidUserData]
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData, invalidUserData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider
                .connect(receiver)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        ).to.be.revertedWithCustomError(dispenserProvider, "AmountMustBeGreaterThanZero")
    })

    it("should allow the pool owner to call dispense for the receiver", async () => {
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        const balanceBefore = await lockDealNFT["balanceOf(address)"](await receiver.getAddress())
        await dispenserProvider
            .connect(signer)
            .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        const balanceAfter = await lockDealNFT["balanceOf(address)"](await receiver.getAddress())
        expect(balanceAfter).to.equal(balanceBefore + 1n)
    })

    it("should revert if the parameters length is zero", async () => {
        const userData = { simpleProvider: await lockProvider.getAddress(), params: [] }
        const usersData = [userData]
        const signatureData = [poolId, validTime, await receiver.getAddress(), userData]
        const signature = await createSignature(signer, signatureData)
        await expect(
            dispenserProvider
                .connect(receiver)
                .dispenseLock(poolId, validTime, await receiver.getAddress(), usersData, signature)
        ).to.be.revertedWithCustomError(dispenserProvider, "ZeroParamsLength")
    })
})
