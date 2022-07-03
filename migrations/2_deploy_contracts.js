const PreSale = artifacts.require('PreSale')
const Vesting = artifacts.require('Vesting')

const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')
const GOEYCOIN = artifacts.require('GOEYCOIN')

module.exports = async function (deployer, network, accounts) {
  console.log('network', network)
  await deployer.deploy(CRPLAY, {
    from: accounts[0],
  })
  await deployer.deploy(USDT, {
    from: accounts[0],
  })

  await deployer.deploy(GOEYCOIN, {
    from: accounts[0],
  })

  await deployer.deploy(Vesting, {
    from: accounts[0],
  })

  let vesting = await Vesting.deployed()

  await deployer.deploy(
    PreSale,
    '0xD99D1c33F9fC3444f8101754aBC46c52416550D1',
    vesting.address,
    {
      from: accounts[0],
    },
  )

  let presale = await PreSale.deployed()

  vesting.addContractRole(presale.address, {
    from: accounts[0],
  })

  if (network == 'development' || network == 'testnet') {
    let crplayToken = await CRPLAY.deployed()
    let usdtToken = await USDT.deployed()
    let goeyToken = await GOEYCOIN.deployed()

    await presale.createCategory('Metaverse', 'google.com')
    await presale.createCategory('Mobility', 'google.com')

    let total = web3.utils.toWei('1', 'ether')
    let price = web3.utils.toWei('0.0002135', 'ether')

    let minPerUser = web3.utils.toWei('10', 'wei')
    let maxPerUser = web3.utils.toWei('1000', 'wei')

    let softCap = web3.utils.toWei('10000', 'wei')
    let hardCap = web3.utils.toWei('1000000', 'wei')

    let percent = web3.utils.toWei('50', 'wei')

    let finish = 1664675814
    let inital = 1656727014

    await crplayToken.approve(presale.address, total)
    await goeyToken.approve(presale.address, total)

    await presale.addSale({
      total: total,
      price: price,
      startTime: inital,
      endTime: finish,
      hasVesting: true,
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
    })

    await presale.addSale({
      total: total,
      price: price,
      startTime: inital,
      endTime: finish,
      hasVesting: true,
      startTimeVesting: inital,
      finishTimeVesting: finish,
      totalPercentLiquidPool: percent,
      softCap: softCap,
      hardCap: hardCap,
      minPerUser: minPerUser,
      maxPerUser: maxPerUser,
      urlProperties:
        'https://gateway.pinata.cloud/ipfs/QmQQ7itEULZf1NFcYyRS12aCx3PdzXNBUrdsBndhjHX9SN',
      token_: goeyToken.address,
      paymentToken_: usdtToken.address,
      category: 2,
    })

    await presale.start(1)
    await presale.start(2)
  }
}
