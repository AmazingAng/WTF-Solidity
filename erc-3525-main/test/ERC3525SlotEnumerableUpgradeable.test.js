const { shouldBehaveLikeERC3525SlotEnumerable } = require('./ERC3525.behavior');

async function deployERC3525(name, symbol, decimals) {
  const ERC3525Factory = await ethers.getContractFactory('ERC3525AllRoundMockUpgradeableWithInit');
  const erc3525 = await ERC3525Factory.deploy(name, symbol, decimals);
  await erc3525.deployed();
  return erc3525;
}

describe('ERC3525SlotEnumerableUpgradeable', () => {

  const name = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;

  beforeEach(async function () {
    this.token = await deployERC3525(name, symbol, decimals);
  })

  shouldBehaveLikeERC3525SlotEnumerable('ERC3525SlotEnumerableUpgradeable');

})