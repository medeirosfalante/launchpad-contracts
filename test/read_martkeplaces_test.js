const PreSale = artifacts.require('PreSale')
const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')

const util = require('../utils/time')

contract('PreSale', async (accounts) => {
  const accountSale = accounts[0]
  const accountCrPlay = accounts[1]
  const accountInvestor = accounts[2]

  it('set pool', async () => {
    let crplayToken = await CRPLAY.deployed()
    let usdtToken = await USDT.deployed()
    let preSale = await PreSale.deployed()
    await preSale.setPairLiquidPool(crplayToken.address, usdtToken.address, {
      from: accountSale,
    })
  })
})
