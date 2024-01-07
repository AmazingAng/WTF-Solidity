const { shouldBehaveLikeERC721, shouldBehaveLikeERC721Enumerable, shouldBehaveLikeERC721Metadata } = require('./ERC721.behavior');
const { shouldBehaveLikeERC3525, shouldBehaveLikeERC3525Metadata } = require('./ERC3525.behavior');

async function deployERC3525(name, symbol, decimals) {
  const ERC3525Factory = await ethers.getContractFactory('ERC3525BaseMock');
  const erc3525 = await ERC3525Factory.deploy(name, symbol, decimals);
  await erc3525.deployed();
  return erc3525;
}

describe('ERC3525', () => {

  const name = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;

  beforeEach(async function () {
    this.token = await deployERC3525(name, symbol, decimals);
  })

  shouldBehaveLikeERC721('ERC721');
  shouldBehaveLikeERC721Enumerable('ERC721Enumerable');
  shouldBehaveLikeERC721Metadata('ERC721Metadata', name, symbol);
  shouldBehaveLikeERC3525('ERC3525');
  shouldBehaveLikeERC3525Metadata('ERC3525Metadata');
  
})