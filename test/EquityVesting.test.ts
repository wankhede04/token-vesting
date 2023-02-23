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
    const CXO = '0xb7f41484'
    const SENIOR_MANAGER = '0xd3d780ea'
    const OTHER = '0x35b65de3'
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
        await time.increaseTo(current + yearInSeconds)
        await (await vesting.connect(tony).claimEquity()).wait()
        const balanceAfter = await token.balanceOf(await tony.getAddress())
        expect(balanceAfter.sub(balanceBefore)).equal(
          ethers.utils.parseEther('250'),
        )
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
    })
  })
})
