const PreSale = artifacts.require('PreSale')

const CRPLAY = artifacts.require('CRPLAY')
const USDT = artifacts.require('USDT')

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(PreSale, '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45', {
    from: accounts[0],
  })

  await deployer.deploy(CRPLAY, {
    from: accounts[0],
  })
  await deployer.deploy(USDT, {
    from: accounts[0],
  })

  const totaTheter = web3.utils.toWei('10000', 'ether')

  const CRPLAYIntance = await CRPLAY.deployed()
  const USDTIntance = await USDT.deployed()
  CRPLAYIntance.transfer(accounts[1], totaTheter)
  USDTIntance.transfer(accounts[1], totaTheter)
}
