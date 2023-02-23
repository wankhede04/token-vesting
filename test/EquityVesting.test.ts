import { expect } from 'chai'
import { Signer } from 'ethers'
import { ethers } from 'hardhat'
import { time } from '@nomicfoundation/hardhat-network-helpers'
import {
  EquityToken,
  EquityToken__factory,
  EquityVesting,
  EquityVesting__factory,
} from '../typechain'

describe('EquityVesting', function () {
  let EquityVesting: EquityVesting__factory
  let EquityToken: EquityToken__factory
  let token: EquityToken
  let vesting: EquityVesting
  let deployer: string
  let owner: Signer
  let alice: Signer

  this.beforeAll(async () => {
    ;[owner, alice] = await ethers.getSigners()
    deployer = await owner.getAddress()
    EquityToken = await ethers.getContractFactory('EquityToken')
    EquityVesting = await ethers.getContractFactory('EquityVesting')
  })
  this.beforeEach(async () => {
    const mintAmount = process.env.MINT_AMOUNT || '10000000000000000000000'
    const admin = process.env.ADMIN || deployer

    token = await EquityToken.deploy('Equity Token', 'ETKN', mintAmount)
    await token.deployed()

    vesting = await EquityVesting.deploy(token.address, admin)
    await vesting.deployed()

    await (
      await token.transfer(vesting.address, ethers.utils.parseEther('1200'))
    ).wait()
  })

  it('Should deploy EquityVesting', async () => {
    const receipt = await vesting.deployed()
    expect(receipt.deployTransaction.confirmations).not.equal(0)
  })

  describe('Claim Equity', function () {
    let tony: Signer
    let chris: Signer
    let hugh: Signer
    const yearInSeconds = 31536000
    const CXO = '0xb7f414843e68da0b34c0fe72d1e077bca7ad8d815444157b9e3e6ccc0d4f0b68'
    const SENIOR_MANAGER = '0xd3d780eaccdeb67c1d22abd19ec5480ce7d3f8b12b05d8346b4a7b5d8a14a8ad'
    const OTHER = '0x35b65de3b579a9ce74763d33e74f08dcef72a66ee55fd214549ace2be760d16d'
    this.beforeEach(async () => {
      ;[, , tony, chris, hugh] = await ethers.getSigners()
      await (
        await vesting.addEmployees(
          [
            await tony.getAddress(),
            await chris.getAddress(),
            await hugh.getAddress(),
          ],
          [CXO, SENIOR_MANAGER, OTHER],
        )
      ).wait()
    })

    describe('Positive', function () {
      it('Should claim equity token', async () => {
        const balanceBefore = await token.balanceOf(await tony.getAddress())
        const current = await time.latest()
        await time.increaseTo(current + yearInSeconds + 1)
        const claimAmount = await vesting.getEquityToClaim(await tony.getAddress())
        await (await vesting.connect(tony).claimEquity()).wait()
        const balanceAfter = await token.balanceOf(await tony.getAddress())
        expect(balanceAfter.sub(balanceBefore)).equal(
          ethers.utils.parseEther('250'),
        )
        expect(balanceAfter.sub(balanceBefore)).equal(claimAmount.amount)
      })

      it('Should claim equity token after vesting end', async () => {
        const balanceBefore = await token.balanceOf(await tony.getAddress())
        const current = await time.latest()
        await time.increaseTo(current + yearInSeconds * 4)
        await (await vesting.connect(tony).claimEquity()).wait()
        const balanceAfter = await token.balanceOf(await tony.getAddress())
        expect(balanceAfter.sub(balanceBefore)).equal(
          ethers.utils.parseEther('1000'),
        )
      })
    })

    describe('Negative', function () {
      it('Should not claim equity token after total claim', async () => {
        const current = await time.latest()
        await time.increaseTo(current + yearInSeconds * 4)
        await (await vesting.connect(tony).claimEquity()).wait()

        await expect(vesting.connect(tony).claimEquity()).revertedWith(
          'EquityVesting: zero amount to claim',
        )
      })

      it('Should not claim equity token twice a year', async () => {
        const current = await time.latest()
        await time.increaseTo(current + yearInSeconds)
        await (await vesting.connect(tony).claimEquity()).wait()

        await expect(vesting.connect(tony).claimEquity()).revertedWith(
          'EquityVesting: zero amount to claim',
        )
      })

      it('Should not claim equity token before vesting cliff', async () => {
        const current = await time.latest()
        await time.increaseTo(current + 3600)

        await expect(vesting.connect(tony).claimEquity()).revertedWith(
          'EquityVesting: zero amount to claim',
        )
      })
    })
  })
})
