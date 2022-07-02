const PreSale = artifacts.require('PreSale')
const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')

const util = require('../utils/time')

contract('PreSale', async (accounts) => {
  const accountSale = accounts[0]
  const accountCrPlay = accounts[1]
  const accountInvestor = accounts[2]
  const category1 = 1

  it('create category', async () => {
    let preSale = await PreSale.deployed()
    try {
      await preSale.createCategory('zero', 'google.com', {
        from: accountSale,
      })
    }catch(e){
      console.log(e)
    }
    const listCategory = await preSale.listCategory.call()
    console.log(listCategory)
    assert.equal(listCategory.length, 1)
  })

  it('create sale', async () => {
    let crplayToken = await CRPLAY.deployed()
    let usdtToken = await USDT.deployed()
    let preSale = await PreSale.deployed()
    try {
      await preSale.addSale(
        'https://gateway.pinata.cloud/ipfs/QmepP6HUacEEgqCqFsTFEReq78mQRspFYEsndKeRjo8jwx',
        crplayToken.address,
        usdtToken.address,
        1,
        {
          from: accountSale,
        },
      )
    } catch (e) {
      assert.isNotNull(e, 'there was no error')
    }
  })

  it('start sale', async () => {
    let crplayToken = await CRPLAY.deployed()
    let usdtToken = await USDT.deployed()
    let preSale = await PreSale.deployed()

    var inital = util.addHours(1, new Date())
    var finish = util.addHours(1000, new Date())

    var vestingInital = util.addHours(1, new Date())
    var vestingFinish = util.addHours(10000, new Date())

    const total = web3.utils.toWei('10', 'ether')
    const price = web3.utils.toWei('1', 'ether')

    await crplayToken.approve(preSale.address,total)

    try {
      await preSale.start(
        0,
        total,
        price,
        inital,
        finish,
        true,
        vestingInital,
        vestingFinish,
        50,
        {
          from: accountSale,
        },
      )
    } catch (e) {
      assert.isNotNull(e, 'there was no error')
    }
  })

  // it('get price', async () => {
  //   let preSale = await PreSale.deployed()
  //   const price = await preSale.getTokenPrice.call()
  //   console.log(price.toString())
  // })
})
