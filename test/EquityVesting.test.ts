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
})
