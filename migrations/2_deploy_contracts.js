const PreSale = artifacts.require('PreSale')

const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')
const GOEYCOIN = artifacts.require('GOEYCOIN')

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(
    PreSale,
    '0xD99D1c33F9fC3444f8101754aBC46c52416550D1',
    accounts[0],
    accounts[1],
    {
      from: accounts[0],
    },
  )

  await deployer.deploy(CRPLAY, {
    from: accounts[0],
  })
  await deployer.deploy(USDT, {
    from: accounts[0],
  })

  await deployer.deploy(GOEYCOIN, {
    from: accounts[0],
  })
}
