const PreSale = artifacts.require('PreSale')
const Vesting = artifacts.require('Vesting')
const Category = artifacts.require('CategoryContract')
const Order = artifacts.require('OrderContract')

const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')
const GOEYCOIN = artifacts.require('GOEYCOIN')

const util = require('../utils/time')

contract('PreSale', async (accounts) => {
  const accountSale = accounts[0]
  const accountCrPlay = accounts[1]
  const accountInvestor = accounts[2]
  const category1 = 1

  it('create category', async () => {
    let category = await Category.deployed()
    try {
      await category.create('zero', 'google.com', {
        from: accountSale,
      })
    } catch (e) {
      console.log(e)
    }
    const listCategory = await category.list.call()
    assert.equal(listCategory.length, 1)
  })

  it('create sale', async () => {
    let crplayToken = await CRPLAY.deployed()
    let usdtToken = await USDT.deployed()
    let preSale = await PreSale.deployed()

    let total = web3.utils.toWei((16880000000 * 10 ** 10).toString(), 'wei')
    let price = web3.utils.toWei('0.0002135', 'ether')

    let minPerUser = web3.utils.toWei('10', 'wei')
    let maxPerUser = web3.utils.toWei('1000', 'wei')

    let softCap = web3.utils.toWei('10000', 'wei')
    let hardCap = web3.utils.toWei('1000000', 'wei')

    let percent = web3.utils.toWei('50', 'wei')

    let finish = 1664675814
    let inital = 1656727014

    try {
      await crplayToken.approve(preSale.address, total)
      await preSale.addSale({
        total: total,
        price: price,
        startTime: inital,
        endTime: finish,
        hasVesting: true,
        initalPercentVesting: 10,
        startTimeVesting: inital,
        finishTimeVesting: finish,
        totalPercentLiquidPool: percent,
        softCap: softCap,
        hardCap: hardCap,
        minPerUser: minPerUser,
        maxPerUser: maxPerUser,
        urlProperties:
          'https://gateway.pinata.cloud/ipfs/QmaR8yFnMWT7bjq5HQjfbLRmWnGT97Un383SCEoxEaZJkV',
        token_: crplayToken.address,
        paymentToken_: usdtToken.address,
        category: 1,
        createLiquidPool: false,
        forwards: [
          {
            addressReceiver: accounts[2],
            name: 'mkt',
            percent: 50,
            saleID: 0,
          },
          {
            addressReceiver: accounts[3],
            name: 'dev',
            percent: 50,
            saleID: 0,
          },
        ],
      })
    } catch (e) {
      assert.isNull(e, 'there was no error')
    }
  })

  it('list forward', async () => {
    let preSale = await PreSale.deployed()

    const listForwards = await preSale.listForwards.call(1)
    assert.equal(listForwards.length, 2)
  })

  it('start sale', async () => {
    let preSale = await PreSale.deployed()

    try {
      await preSale.start(1)
    } catch (e) {
      assert.isNull(e, 'there was no error')
    }
  })

  it('buy', async () => {
    let usdtToken = await USDT.deployed()
    let preSale = await PreSale.deployed()
    let vesting = await Vesting.deployed()
    let crplayToken = await CRPLAY.deployed()
    let order = await Order.deployed()

    let total = web3.utils.toWei('100', 'ether')
    let price = web3.utils.toWei('0.0002135', 'ether')

    await usdtToken.transfer(accounts[4], total)

    await usdtToken.approve(preSale.address, total, { from: accounts[4] })

    try {
      await preSale.buy(total, 1, { from: accounts[4] })
    } catch (e) {
      console.log(e)
      assert.isNull(e, 'there was no error')
    }

    const listOrders = await order.listByUser.call({ from: accounts[4] })
    assert.equal(listOrders.length, 1)
    const balanceUsdt = await usdtToken.balanceOf(accounts[4])
    const balancecrPlay = await crplayToken.balanceOf(vesting.address)
    assert.equal(
      balancecrPlay.toString(),
      parseFloat((total / price).toFixed(0)) * 10 ** 10,
    )
    const vestingBalance = await vesting.getTotal(
      accounts[4],
      crplayToken.address,
    )

    assert.equal(
      parseInt(vestingBalance.toString()) * 10 ** 10,
      parseFloat((total / price).toFixed(0)) * 10 ** 10,
    )

    assert.equal(balanceUsdt.toString(), 0)
  })

  it('claim vesting', async () => {
    let vesting = await Vesting.deployed()
    let crplayToken = await CRPLAY.deployed()
    const vestingBalance = await vesting.getTotal(
      accounts[4],
      crplayToken.address,
    )

    const vestingClaimBalance = await vesting.getClaimableAmount(
      accounts[4],
      crplayToken.address,
    )

    await vesting.claim(crplayToken.address, { from: accounts[4] })

    const vestingBalanceNew = await vesting.getTotal(
      accounts[4],
      crplayToken.address,
    )

    assert.equal(
      vestingBalanceNew.toString(),
      (vestingBalance - vestingClaimBalance).toString(),
    )
  })
})
