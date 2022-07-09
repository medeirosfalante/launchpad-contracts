const PreSale = artifacts.require('PreSale')
const Vesting = artifacts.require('Vesting')
const Category = artifacts.require('CategoryContract')
const Order = artifacts.require('OrderContract')

const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Category, {
    from: accounts[0],
  })

  await deployer.deploy(Order, {
    from: accounts[0],
  })
  await deployer.deploy(USDT, {
    from: accounts[0],
  })

  await deployer.deploy(CRPLAY, {
    from: accounts[0],
  })
  await deployer.deploy(Vesting, {
    from: accounts[0],
  })

  let vesting = await Vesting.deployed()
  let category = await Category.deployed()
  let order = await Order.deployed()

  await deployer.deploy(
    PreSale,
    '0xD99D1c33F9fC3444f8101754aBC46c52416550D1',
    vesting.address,
    category.address,
    order.address,

    {
      from: accounts[0],
    },
  )

  let presale = await PreSale.deployed()

  vesting.addContractRole(presale.address, {
    from: accounts[0],
  })

  order.addContractRole(presale.address, {
    from: accounts[0],
  })
  if (network == 'development_test' || network == 'testnet') {
    let crplayToken = await CRPLAY.deployed()
    let usdtToken = await USDT.deployed()
    let total = web3.utils.toWei((16880000000 * 10 ** 10).toString(), 'wei')
    let price = web3.utils.toWei('0.0002135', 'ether')

    let minPerUser = web3.utils.toWei('10', 'wei')
    let maxPerUser = web3.utils.toWei('1000', 'wei')

    let softCap = web3.utils.toWei('10000', 'wei')
    let hardCap = web3.utils.toWei('1000000', 'wei')
    let finish = 1664675814
    let inital = 1656727014

    await crplayToken.approve(presale.address, total)

    await presale.addSale({
      total: total,
      price: price,
      startTime: inital,
      endTime: finish,
      hasVesting: false,
      initalPercentVesting: 10,
      startTimeVesting: inital,
      finishTimeVesting: finish,
      totalPercentLiquidPool: 50,
      softCap: softCap,
      hardCap: hardCap,
      minPerUser: minPerUser,
      maxPerUser: maxPerUser,
      urlProperties:
        'https://gateway.pinata.cloud/ipfs/QmaR8yFnMWT7bjq5HQjfbLRmWnGT97Un383SCEoxEaZJkV',
      token_: crplayToken.address,
      paymentToken_: usdtToken.address,
      category: 1,
      createLiquidPool: true,
      uniswapPrice: false,
      discontPrice: 50,
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
    await presale.start(1)
  }
}
