const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { expectEvent } = require('./utils/expectEvent')
const { shouldSupportInterfaces } = require('./utils/SupportsInterface.behavior');

const Error = [ 'None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic' ]
  .reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const MAX_UINT256 = BigNumber.from('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');

const firstSlot = 11;
const secondSlot = 22;
const nonExistentSlot = 99;

const firstTokenId = 1001;
const secondTokenId = 1002;
const thirdTokenId = 2001;
const fourthTokenId = 2002;
const nonExistentTokenId = 9901;

const firstTokenValue = 1000000;
const secondTokenValue = 2000000;
const thirdTokenValue = 3000000;
const fourthTokenValue = 4000000;

const RECEIVER_MAGIC_VALUE = '0x009ce20b';

let firstOwner, secondOwner, newOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other

function shouldBehaveLikeERC3525 (errorPrefix) {
  shouldSupportInterfaces([
    'ERC165',
    'ERC721',
    'ERC3525',
  ]);

  context('with minted tokens', function () {

    beforeEach(async function () {
      [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other ] = await ethers.getSigners();

      await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
      await this.token.mint(secondOwner.address, secondTokenId, firstSlot, secondTokenValue);
      await this.token.mint(firstOwner.address, thirdTokenId, secondSlot, thirdTokenValue);
      await this.token.mint(secondOwner.address, fourthTokenId, secondSlot, fourthTokenValue);
      this.toWhom = other;
      this.ERC3525ReceiverMockFactory = await ethers.getContractFactory('ERC3525ReceiverMock');
      this.NonReceiverMock = await ethers.getContractFactory('NonReceiverMock');
    });

    describe('balanceOf(uint256)', function () {
      context('when the given token is valid', function () {
        it('returns the value held by the token', async function () {
          expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(firstTokenValue);
          expect(await this.token['balanceOf(uint256)'](secondTokenId)).to.be.equal(secondTokenValue);
          expect(await this.token['balanceOf(uint256)'](thirdTokenId)).to.be.equal(thirdTokenValue);
          expect(await this.token['balanceOf(uint256)'](fourthTokenId)).to.be.equal(fourthTokenValue);
        });
      });

      context('when the given token does not exist', function () {
        it('reverts', async function () {
          await expect(this.token['balanceOf(uint256)'](0)).to.be.revertedWith('ERC3525: invalid token ID');
          await expect(this.token['balanceOf(uint256)'](nonExistentTokenId)).to.be.revertedWith('ERC3525: invalid token ID');
        });
      });
    });

    describe('slotOf', function () {
      context('when the given token is valid', function () {
        it('returns the slot of the token', async function () {
          expect(await this.token.slotOf(firstTokenId)).to.be.equal(firstSlot);
          expect(await this.token.slotOf(secondTokenId)).to.be.equal(firstSlot);
          expect(await this.token.slotOf(thirdTokenId)).to.be.equal(secondSlot);
          expect(await this.token.slotOf(fourthTokenId)).to.be.equal(secondSlot);
        });
      });

      context('when the given token does not exist', function () {
        it('reverts', async function () {
          await expect(this.token.slotOf(0)).to.be.revertedWith('ERC3525: invalid token ID');
          await expect(this.token.slotOf(nonExistentTokenId)).to.be.revertedWith('ERC3525: invalid token ID');
        });
      });
    });

    describe('transfer value from token to token', function () {
      const transferValue = 100;

      let tx = null;
      let receipt = null;

      beforeEach(async function() {
        await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
        await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, firstTokenValue);
        await this.token.connect(firstOwner).setApprovalForAll(operator.address, true);

        this.fromOwner = firstOwner;
        this.fromTokenId = firstTokenId;
        this.fromTokenValue = firstTokenValue;
        this.fromOwnerBalance = await this.token['balanceOf(address)'](this.fromOwner.address);

        this.toOwner = secondOwner;
        this.toTokenId = secondTokenId;
        this.toTokenValue = secondTokenValue;
        this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
      });

      const transferValueFromTokenToTokenWasSuccessful = function () {
        it('transfers value of one token ID to another token ID', async function() {
          expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromTokenValue - transferValue);
          expect(await this.token['balanceOf(uint256)'](this.toTokenId)).to.be.equal(this.toTokenValue + transferValue);
        });

        it('emits a TransferValue event', async function() {
          expectEvent(receipt, 'TransferValue', { _fromTokenId: this.fromTokenId, _toTokenId: this.toTokenId, _value: transferValue});
        });

        it('do not adjust owners balances', async function() {
          expect(await this.token['balanceOf(address)'](this.fromOwner.address)).to.be.equal(this.fromOwnerBalance);
          expect(await this.token['balanceOf(address)'](this.toOwner.address)).to.be.equal(this.toOwnerBalance);
        });

        it('do not adjust token owners', async function() {
          expect(await this.token.ownerOf(this.fromTokenId)).to.be.equal(this.fromOwner.address);
          expect(await this.token.ownerOf(this.toTokenId)).to.be.equal(this.toOwner.address);
        });

        it('do not adjust tokens slots', async function() {
          expect(await this.token.slotOf(this.fromTokenId)).to.be.equal(firstSlot);
          expect(await this.token.slotOf(this.toTokenId)).to.be.equal(firstSlot);
        });
      };

      const shouldTransferValueFromTokenToTokenByUsers = function () {
        context('when called by the owner', function () {
          this.beforeEach(async function () {
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          })
          transferValueFromTokenToTokenWasSuccessful();
        });

        context('when called by the token approved individual', function () {
          beforeEach(async function () {
            tx = await this.token.connect(approved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();
        });
        
        context('when called by the value approved individual', function () {
          beforeEach(async function () {
            this.allowanceBefore = await this.token.allowance(this.fromTokenId, valueApproved.address);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();

          it('adjust allowance', async function() {
            this.allowanceAfter = await this.token.allowance(this.fromTokenId, valueApproved.address);
            expect(this.allowanceAfter).to.be.equal(this.allowanceBefore - transferValue);
          });
        });
        
        context('when called by the unlimited value approved individual', function () {
          beforeEach(async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, MAX_UINT256);
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();

          it('adjust allowance', async function() {
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
          });
        });
        
        context('when called by the operator', function () {
          beforeEach(async function () {
            tx = await this.token.connect(operator)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();
        });

        context('when called by the operator without an approved user', function () {
          beforeEach(async function () {
            await this.token['approve(address,uint256)'](ZERO_ADDRESS, this.fromTokenId);
            tx = await this.token.connect(operator)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToTokenWasSuccessful();
        });

        context('when sent to the from token itself', function () {
          beforeEach(async function () {
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.fromTokenId, transferValue);
            receipt = await tx.wait();
          });

          it('keeps the ownership of the token', async function () {
            expect(await this.token.ownerOf(this.fromTokenId)).to.be.equal(this.fromOwner.address);
          });

          it('keeps the balance of the token', async function () {
            expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromTokenValue);
          });

          it('keeps the owner balance', async function () {
            expect(await this.token['balanceOf(address)'](this.fromOwner.address)).to.be.equal(this.fromOwnerBalance);
          });

          it('emits a TransferValue event', async function() {
            expectEvent(receipt, 'TransferValue', { _fromTokenId: this.fromTokenId, _toTokenId: this.fromTokenId, _value: transferValue});
          });
        });

        context('when transfer value exceeds balance of token', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, this.fromTokenValue + 1)
            ).to.be.revertedWith('ERC3525: insufficient balance for transfer');
          });
        });

        context('when transfer to a token with different slot', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, thirdTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: transfer to token with different slot');
          });
        });

        context('with invalid token ID', function() {
          it('reverts when from token ID is invalid', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](nonExistentTokenId, this.toTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: invalid token ID');
          });

          it('reverts when to token ID is invalid', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, nonExistentTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: transfer to invalid token ID');
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(other)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
            ).to.revertedWith('ERC3525: insufficient allowance');
          });
        });

        context('when transfer value exceeds allowance', function () {
          it('reverts', async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, transferValue - 1);
            await expect(
              this.token.connect(valueApproved)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
            ).to.be.revertedWith('ERC3525: insufficient allowance');
          });
        });
      };

      describe('to a token held by a user account', function () {
        shouldTransferValueFromTokenToTokenByUsers();
      });

      const deployReceiverAndMint = async function (magicValue, errorType) {
        this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(magicValue, errorType);
        this.toTokenId = 1003;
        this.toTokenValue = 100000;
        await this.token.mint(this.toOwner.address, this.toTokenId, firstSlot, this.toTokenValue);
        this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);      
      }

      describe('to a non-receiver contract that implements ERC-165', function () {
        beforeEach(async function () {
          this.toOwner = this.token;
          this.toTokenId = 1003;
          this.toTokenValue = 100000;
          await this.token.mint(this.toOwner.address, this.toTokenId, firstSlot, this.toTokenValue);
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);   
        });
        shouldTransferValueFromTokenToTokenByUsers();
      });

      describe('to a non-receiver contract that does not implements ERC-165', function () {
        beforeEach(async function () {
          this.toOwner = await this.NonReceiverMock.deploy();
          this.toTokenId = 1003;
          this.toTokenValue = 100000;
          await this.token.mint(this.toOwner.address, this.toTokenId, firstSlot, this.toTokenValue);
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);   
        });
        shouldTransferValueFromTokenToTokenByUsers();
      });

      describe('to a valid receiver contract', function () {
        beforeEach(async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.None);
        });
        shouldTransferValueFromTokenToTokenByUsers();
      });

      describe('to a receiver contract returning unexpected value', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, '0x12345678', Error.None);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWith('ERC3525: transfer rejected by ERC3525Receiver');
        });
      });

      describe('to a receiver contract that reverts with message', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWith('ERC3525ReceiverMock: reverting');
        });
      });

      describe('to a receiver contract that reverts without message', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.reverted;
        });
      });

      describe('to a receiver contract that panics', function () {
        it('reverts', async function () {
          await deployReceiverAndMint.call(this, RECEIVER_MAGIC_VALUE, Error.Panic);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,uint256,uint256)'](this.fromTokenId, this.toTokenId, transferValue)
          ).to.revertedWithPanic;
        });
      });
    });

    describe('transfer value from token to address', function () {
      const transferValue = 100;

      let tx = null;
      let receipt = null;

      beforeEach(async function () {
        await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
        await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, firstTokenValue);
        await this.token.connect(firstOwner).setApprovalForAll(operator.address, true);

        this.fromOwner = firstOwner;
        this.fromTokenId = firstTokenId;
        this.fromTokenValue = firstTokenValue;
        this.fromOwnerBalance = await this.token['balanceOf(address)'](this.fromOwner.address);

        this.toOwner = secondOwner;
        this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
      });

      const transferValueFromTokenToAddressWasSuccessful = function () {
        it('adjustments on owners balances', async function() {
          if (this.fromOwner != this.toOwner) {
            expect(await this.token['balanceOf(address)'](this.fromOwner.address)).to.be.equal(this.fromOwnerBalance);
          }
          expect(await this.token['balanceOf(address)'](this.toOwner.address)).to.be.equal(this.toOwnerBalance.add(1));
        })

        it('transfers value of one token ID to an address', async function() {
          expect(await this.token['balanceOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromTokenValue - transferValue);
          const toTokenId = await this.token['tokenOfOwnerByIndex(address,uint256)'](this.toOwner.address, this.toOwnerBalance);
          expect(await this.token['balanceOf(uint256)'](toTokenId)).to.be.equal(transferValue);
        });

        it('emits Transfer/SlotChanged/TransferValue event', async function() {
          const toTokenId = await this.token['tokenOfOwnerByIndex(address,uint256)'](this.toOwner.address, this.toOwnerBalance);
          expectEvent(receipt, 'Transfer', { _from: ZERO_ADDRESS, _to: this.toOwner.address, _tokenId: toTokenId });
          expectEvent(receipt, 'SlotChanged', { _tokenId: toTokenId, _oldSlot: 0, _newSlot: firstSlot });
          expectEvent(receipt, 'TransferValue', { _fromTokenId: this.fromTokenId, _toTokenId: toTokenId, _value: transferValue});
        });

        it('do not adjust owner of from token ID', async function() {
          expect(await this.token['ownerOf(uint256)'](this.fromTokenId)).to.be.equal(this.fromOwner.address);
        });

        it('do not adjust tokens slots', async function() {
          expect(await this.token['slotOf(uint256)'](this.fromTokenId)).to.be.equal(firstSlot);
          const toTokenId = await this.token['tokenOfOwnerByIndex(address,uint256)'](this.toOwner.address, this.toOwnerBalance);
          expect(await this.token['slotOf(uint256)'](toTokenId)).to.be.equal(firstSlot);
        });
      };

      const shouldTransferValueFromTokenToAddressByUsers = function () {
        context('when called by the owner', function () {
          this.beforeEach(async function () {
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          })
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when called by the token approved individual', function () {
          beforeEach(async function () {
            tx = await this.token.connect(approved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when called by the value approved individual', function () {
          beforeEach(async function () {
            this.allowanceBefore = await this.token.allowance(this.fromTokenId, valueApproved.address);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();

          it('adjust allowance', async function() {
            this.allowanceAfter = await this.token.allowance(this.fromTokenId, valueApproved.address);
            expect(this.allowanceAfter).to.be.equal(this.allowanceBefore - transferValue);
          });
        });

        context('when called by the unlimited value approved individual', function () {
          beforeEach(async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, MAX_UINT256);
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
            tx = await this.token.connect(valueApproved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();

          it('adjust allowance', async function() {
            expect(await this.token.allowance(this.fromTokenId, valueApproved.address)).to.be.equal(MAX_UINT256);
          });
        });
        
        context('when called by the operator', function () {
          beforeEach(async function () {
            tx = await this.token.connect(operator)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when called by the operator without an approved user', function () {
          beforeEach(async function () {
            await this.token['approve(address,uint256)'](ZERO_ADDRESS, this.fromTokenId);
            tx = await this.token.connect(operator)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            this.toOwner = this.fromOwner;
            this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
            tx = await this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue);
            receipt = await tx.wait();
          });
          transferValueFromTokenToAddressWasSuccessful();
        });

        context('when transfer value exceeds balance of token', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, this.fromTokenValue + 1)
            ).to.be.revertedWith('ERC3525: insufficient balance for transfer');
          });
        });

        context('transfer from invalid token ID', function() {
          it('reverts', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](nonExistentTokenId, this.toOwner.address, transferValue)
            ).to.be.revertedWith('ERC3525: invalid token ID');
          });
        });

        context('transfer to the zero address', function() {
          it('reverts', async function() {
            await expect(
              this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, ZERO_ADDRESS, transferValue)
            ).to.be.revertedWith('ERC3525: mint to the zero address');
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expect(
              this.token.connect(other)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
            ).to.revertedWith('ERC3525: insufficient allowance');
          });
        });

        context('when transfer value exceeds allowance', function () {
          it('reverts', async function () {
            await this.token.connect(this.fromOwner)['approve(uint256,address,uint256)'](this.fromTokenId, valueApproved.address, transferValue - 1);
            await expect(
              this.token.connect(valueApproved)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
            ).to.be.revertedWith('ERC3525: insufficient allowance');
          });
        });
      };

      describe('to a user account', function () {
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a non-receiver contract that implements ERC-165', function () {
        beforeEach(async function () {
          this.toOwner = this.token;
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
        });
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a non-receiver contract that does not implement ERC-165', function () {
        beforeEach(async function () {
          this.toOwner = await this.NonReceiverMock.deploy();
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
        });
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a valid receiver contract', function () {
        beforeEach(async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.None);
          this.toOwnerBalance = await this.token['balanceOf(address)'](this.toOwner.address);
        });
        shouldTransferValueFromTokenToAddressByUsers();
      });

      describe('to a receiver contract returning unexpected value', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy('0x12345678', Error.None);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWith('ERC3525: transfer rejected by ERC3525Receiver');
        });
      });

      describe('to a receiver contract that reverts with message', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWith('ERC3525ReceiverMock: reverting');
        });
      });

      describe('to a receiver contract that reverts without message', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.reverted;
        });
      });

      describe('to a receiver contract that panics', function () {
        it('reverts', async function () {
          this.toOwner = await this.ERC3525ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.Panic);
          await expect(
            this.token.connect(this.fromOwner)['transferFrom(uint256,address,uint256)'](this.fromTokenId, this.toOwner.address, transferValue)
          ).to.revertedWithPanic;
        });
      });
    });

    describe('approve value', function () {
      let tx = null;
      let receipt = null;

      beforeEach(async function () {
        this.allowance = 100000000;
      });

      const itClearsAllowance = function () {
        it('clears allowance for the token ID', async function () {
          expect(await this.token.allowance(firstTokenId, valueApproved.address)).to.be.equal(0);
        });
      };

      const itSetsAllowance = function () {
        it('sets allowance for the token ID', async function () {
          expect(await this.token.allowance(firstTokenId, valueApproved.address)).to.be.equal(this.allowance);
        });
      };

      const itEmitsApprovalValueEvent = function () {
        it('emits approval value event', async function () {
          expectEvent(receipt, 'ApprovalValue', {
            _tokenId: firstTokenId,
            _operator: valueApproved.address,
            _value: this.allowance,
          });
        });
      };

      context('when clearing allowance', function () {
        context('when set allowance to zero', function () {
          beforeEach(async function () {
            await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
            this.allowance = 0;
            tx = await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
            receipt = await tx.wait();
          });

          itClearsAllowance();
          itEmitsApprovalValueEvent();
        });

        context('when token was transfered', async function () {
          beforeEach(async function () {
            await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
            await this.token.connect(firstOwner)['transferFrom(address,address,uint256)'](firstOwner.address, secondOwner.address, firstTokenId);
          });

          itClearsAllowance();
        });
      });

      context('when approving to a non-zero address', function () {
        context('when where was no prior allowance', function () {
          beforeEach(async function () {
            tx = await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
            receipt = await tx.wait();
          });

          itSetsAllowance();
          itEmitsApprovalValueEvent();
        });

        context('when there was a prior allowance to the same address', function () {
          beforeEach(async function () {
            await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance - 1);            
            tx = await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
            receipt = await tx.wait();
          });

          itSetsAllowance();
          itEmitsApprovalValueEvent();
        });

        context('when there was a prior allowance to a different address', function () {
          beforeEach(async function () {
            await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
            tx = await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, anotherApproved.address, this.allowance - 1);
            receipt = await tx.wait();
          });

          it('sets allowance to the second value approved individual', async function () {
            expect(await this.token.allowance(firstTokenId, anotherApproved.address)).to.be.equal(this.allowance - 1);
          });
        });
      });

      context('when the address that receives the allowance is the owner', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, firstOwner.address, this.allowance)
          ).to.revertedWith('ERC3525: approval to current owner');
        });
      });

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(other)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance)
          ).to.revertedWith('ERC3525: approve caller is not owner nor approved');
        });
      });

      context('when the sender is approved for the given token ID', function () {
        it('approve value by token ID approved address', async function () {
          await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
          await this.token.connect(approved)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
          expect(await this.token.allowance(firstTokenId, valueApproved.address)).to.be.equal(this.allowance);
        });
      });

      context('when the sender is an operator', function () {
        beforeEach(async function () {
          await this.token.connect(firstOwner).setApprovalForAll(operator.address, true);
          tx = await this.token.connect(operator)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, this.allowance);
          receipt = await tx.wait();
        });

        itSetsAllowance();
        itEmitsApprovalValueEvent();
      });

      context('when then given token ID does not exist', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(firstOwner)['approve(uint256,address,uint256)'](nonExistentTokenId, valueApproved.address, this.allowance)
          ).to.revertedWith('ERC3525: invalid token ID');
        });
      });

      context('when set allowance to the zero address', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, ZERO_ADDRESS, this.allowance)
          ).to.revertedWith('ERC3525: approve value to the zero address');
        });
      });

    });

    describe('allowance', function () {
      context('when token is not minted', function () {
        it('reverts', async function () {
          await expect(
            this.token.allowance(nonExistentTokenId, firstOwner.address)
          ).to.revertedWith('ERC3525: invalid token ID');
        });
      });
    });
  });

  describe('value decimals', function () {
    it('returns the value decimals', async function () {
      expect(await this.token.valueDecimals()).to.be.equal(18);
    });
  });

  describe('_mint', function () {
    it('reverts with an invalid token ID', async function () {
      await expect(
        this.token.mint(firstOwner.address, 0, firstSlot, firstTokenValue)
      ).to.revertedWith('ERC3525: cannot mint zero tokenId');
    });

    it('emits a TransferValue event', async function () {
      const tx = await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
      const receipt = await tx.wait();
      expectEvent(receipt, 'TransferValue', { _fromTokenId: 0, _toTokenId: firstTokenId, _value: firstTokenValue });
    });
  });

  describe('_mintValue', function () {
    it('reverts with an invalid token ID', async function () {
      await expect(
        this.token.mintValue(nonExistentTokenId, firstTokenValue)
      ).to.revertedWith('ERC3525: invalid token ID');
    });

    context('with minted token', function () {
      let extraValue = 100;

      let tx = null;
      let receipt = null;

      beforeEach(async function () {
        await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
        this.ownerBalanceBefore = await this.token['balanceOf(address)'](firstOwner.address);
        tx = await this.token.mintValue(firstTokenId, extraValue);
        receipt = await tx.wait();
      });

      it('emits a TransferValue event', async function () {
        expectEvent(receipt, 'TransferValue', { _fromTokenId: 0, _toTokenId: firstTokenId, _value: extraValue });
      });

      it('adjusts token balance', async function () {
        expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(firstTokenValue + extraValue);
      });

      it('do not adjust token owner and slot', async function () {
        expect(await this.token.ownerOf(firstTokenId)).to.be.equal(firstOwner.address);
        expect(await this.token.slotOf(firstTokenId)).to.be.equal(firstSlot);
      });

      it('do not adjust owner balance', async function () {
        expect(await this.token['balanceOf(address)'](firstOwner.address)).to.be.equal(this.ownerBalanceBefore);
      });
    });
  });

  describe('_burn', function () {
    context('with minted tokens', function () {
      beforeEach(async function () {
        await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
        await this.token.mint(firstOwner.address, secondTokenId, firstSlot, firstTokenValue);
      });

      context('with burnt token', function () {
        let tx = null;
        let receipt = null;

        beforeEach(async function () {
          await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
          await this.token.connect(firstOwner)['approve(uint256,address,uint256)'](firstTokenId, approved.address, firstTokenValue);
          tx = await this.token.burn(firstTokenId);
          receipt = await tx.wait();
        });

        it('emits TransferValue/SlotChanged/Transfer events', async function () {
          expectEvent(receipt, 'TransferValue', { _fromTokenId: firstTokenId, _toTokenId: 0, _value: firstTokenValue });
          expectEvent(receipt, 'SlotChanged', { _tokenId: firstTokenId, _oldSlot: firstSlot, _newSlot: 0 });
          expectEvent(receipt, 'Transfer', { _from: firstOwner.address, _to: ZERO_ADDRESS, _tokenId: firstTokenId });
        });

        it('deletes the token', async function () {
          expect(await this.token['balanceOf(address)'](firstOwner.address)).to.be.equal(1);
          await expect(this.token.ownerOf(firstTokenId)).to.revertedWith('ERC3525: invalid token ID');
          await expect(this.token.slotOf(firstTokenId)).to.revertedWith('ERC3525: invalid token ID');
          await expect(this.token.getApproved(firstTokenId)).to.revertedWith('ERC3525: invalid token ID');
          await expect(this.token.allowance(firstTokenId, valueApproved.address)).to.revertedWith('ERC3525: invalid token ID');
        });

        context('when the burnt token ID is minted again', function () {
          beforeEach(async function () {
            await this.token.mint(firstOwner.address, firstTokenId, secondSlot, secondTokenValue);
          });

          it('updates token data', async function () {
            expect(await this.token.ownerOf(firstTokenId)).to.be.equal(firstOwner.address);
            expect(await this.token.slotOf(firstTokenId)).to.be.equal(secondSlot);
            expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(secondTokenValue);
          });

          it('does not keep previous approval info', async function () {
            expect(await this.token.getApproved(firstTokenId)).to.be.equal(ZERO_ADDRESS);
            expect(await this.token.allowance(firstTokenId, valueApproved.address)).to.be.equal(0);
          });
        });
      });
    });
  });

  describe('_burnValue', function () {
    it('reverts when burning value from a non-existent token id', async function () {
      await expect(
        this.token.burnValue(nonExistentTokenId, 100)
      ).to.revertedWith('ERC3525: invalid token ID');
    });

    context('with minted tokens', function () {
      const burnValue = 100;

      let tx = null;
      let receipt = null;

      beforeEach(async function () {
        await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
        this.ownerBalanceBefore = await this.token['balanceOf(address)'](firstOwner.address);
        tx = await this.token.burnValue(firstTokenId, burnValue);
        receipt = await tx.wait();
      });

      it('emits TransferValue event', async function () {
        expectEvent(receipt, 'TransferValue', { _fromTokenId: firstTokenId, _toTokenId: 0, _value: burnValue });
      })

      it('adjusts token balance', async function () {
        expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(firstTokenValue - burnValue);
      });

      it('does not adjust token owner and slot', async function () {
        expect(await this.token.ownerOf(firstTokenId)).to.be.equal(firstOwner.address);
        expect(await this.token.slotOf(firstTokenId)).to.be.equal(firstSlot);
      });

      it('does not adjust owner balance', async function () {
        expect(await this.token['balanceOf(address)'](firstOwner.address)).to.be.equal(this.ownerBalanceBefore);
      });

      it('reverts when burn value exceeds balance', async function () {
        await expect(
          this.token.burnValue(firstTokenId, firstTokenValue - burnValue + 1)
        ).to.revertedWith('ERC3525: burn value exceeds balance');
      });
    });
  });
}

function shouldBehaveLikeERC3525Metadata (errorPrefix) {
  shouldSupportInterfaces([
    'ERC721Metadata',
    'ERC3525Metadata'
  ]);

  describe('metadata', function () {
    context('contract URI', function () {
      it('return empty string by default', async function () {
        expect(await this.token.contractURI()).to.be.equal('');
      });
    });

    context('slot URI', function () {
      it('return empty string by default', async function () {
        expect(await this.token.slotURI(firstSlot)).to.be.equal('');
      });
    });
  });
}

function shouldBehaveLikeERC3525SlotEnumerable (errorPrefix) {
  shouldSupportInterfaces([
    'ERC3525SlotEnumerable'
  ]);

  context('with minted tokens', function () {

    beforeEach(async function () {
      [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other ] = await ethers.getSigners();

      await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
      await this.token.mint(secondOwner.address, secondTokenId, firstSlot, secondTokenValue);
      await this.token.mint(firstOwner.address, thirdTokenId, secondSlot, thirdTokenValue);
      await this.token.mint(secondOwner.address, fourthTokenId, secondSlot, fourthTokenValue);
    });

    const afterTransferFromAddressToAddress = function (validateFunc) {
      context('after transferring a token from address to address', function () {
        beforeEach(async function () {
          await this.token['transferFrom(address,address,uint256)'](firstOwner.address, secondOwner.address, firstTokenId);
        });
        validateFunc();
      });
    }

    const afterTransferFromTokenToToken = function (validateFunc) {
      context('after transferring value from token to token', function () {
        beforeEach(async function () {
          await this.token['transferFrom(uint256,uint256,uint256)'](firstTokenId, secondTokenId, 100);
        });
        validateFunc();
      });
    }

    const afterTransferFromTokenToAddress = function (validateFunc) {
      context('after transferring value from token to address', function () {
        beforeEach(async function () {
          const tx = await this.token['transferFrom(uint256,address,uint256)'](firstTokenId, secondOwner.address, 100);
          const receipt = await tx.wait();
          const transferEvent = receipt.events.filter(e => e.event === 'Transfer')[0];
          this.newTokenId = transferEvent.args['_tokenId'];
        });
        validateFunc();
      });
    }

    const afterBurningToken = function (validateFunc) {
      context('after burning token', function () {
        beforeEach(async function () {
          await this.token.burn(firstTokenId);
        });
        validateFunc();
      });
    }

    describe('slot count', function () {
      it('returns total slot count', async function () {
        expect(await this.token.slotCount()).to.be.equal(2);
      });
    });

    describe('slot by index', function () {
      it('returns all slots', async function () {
        const slotsListed = await Promise.all(
          [0, 1].map(i => this.token.slotByIndex(i)),
        );
        expect(slotsListed.map(s => s.toNumber())).to.have.members([firstSlot, secondSlot]);
      });

      it('reverts if index is greater than slot count', async function () {
        await expect(
          this.token.slotByIndex(2)
        ).to.revertedWith('ERC3525SlotEnumerable: slot index out of bounds')
      });
    });

    describe('tokenSupplyInSlot', function () {
      context('when there are tokens in the given slot', function () {
        it('returns the number of tokens in the given slot', async function () {
          expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(2);
          expect(await this.token.tokenSupplyInSlot(secondSlot)).to.be.equal(2);
        });
      });

      context('when there are no tokens in the given slot', function () {
        it('returns 0', async function () {
          expect(await this.token.tokenSupplyInSlot(nonExistentSlot)).to.be.equal(0);
        });
      });

      afterTransferFromAddressToAddress(function () {
        it('tokenSupplyInSlot should remain the same', async function () {
          expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(2);
        });
      });

      afterTransferFromTokenToToken(function () {
        it('tokenSupplyInSlot should remain the same', async function () {
          expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(2);
        });
      });

      afterTransferFromTokenToAddress(function () {
        it('adjusts tokenSupplyInSlot', async function () {
          expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(3);
        });
      });

      afterBurningToken(function () {
        it('adjusts tokenSupplyInSlot', async function () {
          expect(await this.token.tokenSupplyInSlot(firstSlot)).to.be.equal(1);
        });
      });
    });

    describe('tokenInSlotByIndex', function () {
      context('when the given index is lower than the amount of tokens in the given slot', function () {
        it('returns the token ID placed at the given index', async function () {
          expect(await this.token.tokenInSlotByIndex(firstSlot, 0)).to.be.equal(firstTokenId);
          expect(await this.token.tokenInSlotByIndex(firstSlot, 1)).to.be.equal(secondTokenId);
          expect(await this.token.tokenInSlotByIndex(secondSlot, 0)).to.be.equal(thirdTokenId);
          expect(await this.token.tokenInSlotByIndex(secondSlot, 1)).to.be.equal(fourthTokenId);
        });
      });

      context('when the given index is greater than or equal to the total tokens in the given slot', function () {
        it('reverts', async function () {
          await expect(
            this.token.tokenInSlotByIndex(firstSlot, 2)
          ).to.revertedWith('ERC3525SlotEnumerable: slot token index out of bounds');
        });
      });

      context('when where are no tokens in the given slot', function () {
        it('reverts', async function () {
          await expect(
            this.token.tokenInSlotByIndex(nonExistentSlot, 0)
          ).to.revertedWith('ERC3525SlotEnumerable: slot token index out of bounds');
        });
      });

      afterTransferFromAddressToAddress(function () {
        it('tokenInSlotByIndex should remain the same', async function () {
          expect(await this.token.tokenInSlotByIndex(firstSlot, 0)).to.be.equal(firstTokenId);
          expect(await this.token.tokenInSlotByIndex(firstSlot, 1)).to.be.equal(secondTokenId);
        });
      });

      afterTransferFromTokenToToken(function () {
        it('tokenInSlotByIndex should remain the same', async function () {
          expect(await this.token.tokenInSlotByIndex(firstSlot, 0)).to.be.equal(firstTokenId);
          expect(await this.token.tokenInSlotByIndex(firstSlot, 1)).to.be.equal(secondTokenId);
        });
      });

      afterTransferFromTokenToAddress(function () {
        it('adjusts tokenInSlotByIndex', async function () {
          expect(await this.token.tokenInSlotByIndex(firstSlot, 0)).to.be.equal(firstTokenId);
          expect(await this.token.tokenInSlotByIndex(firstSlot, 1)).to.be.equal(secondTokenId);
          expect(await this.token.tokenInSlotByIndex(firstSlot, 2)).to.be.equal(this.newTokenId.toNumber());
        });
      });

      afterBurningToken(function () {
        it('adjusts tokenSupplyInSlot', async function () {
          expect(await this.token.tokenInSlotByIndex(firstSlot, 0)).to.be.equal(secondTokenId);
        });
      });
    });
  });
}

function shouldBehaveLikeERC3525SlotApprovable (errorPrefix) {
  shouldSupportInterfaces([
    'ERC3525SlotApprovable',
  ]);

  beforeEach(async function () {
    [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other ] = await ethers.getSigners();

    await this.token.mint(firstOwner.address, firstTokenId, firstSlot, firstTokenValue);
    await this.token.mint(secondOwner.address, secondTokenId, firstSlot, secondTokenValue);
    await this.token.mint(firstOwner.address, thirdTokenId, secondSlot, thirdTokenValue);
    await this.token.mint(secondOwner.address, fourthTokenId, secondSlot, fourthTokenValue);
  });

  describe('setApprovalForSlot', function () {
    context('when slot operator is not the owner', function () {
      context('after being set as slot operator', function () {
        let tx = null;
        let receipt = null;

        beforeEach(async function () {
          tx = await this.token.connect(firstOwner).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, true);
          receipt = await tx.wait();
        });

        it('approves the slot operator', async function () {
          expect(await this.token.isApprovedForSlot(firstOwner.address, firstSlot, slotOperator.address)).to.be.equal(true);
        });

        it('emits an ApprovalForSlot event', async function () {
          expectEvent(receipt, 'ApprovalForSlot', { _owner: firstOwner.address, _slot: firstSlot, _operator: slotOperator.address, _approved: true });
        });

        context('when approving tokens by the slot operator', function () {
          it('slot operator can approve tokens of the owner in the approved slot', async function () {
            await this.token.connect(slotOperator)['approve(address,uint256)'](approved.address, firstTokenId);
            expect(await this.token.getApproved(firstTokenId)).to.be.equal(approved.address);
          });

          it('reverts when approving others tokens in the same slot', async function () {
            await expect(
              this.token.connect(slotOperator)['approve(address,uint256)'](approved.address, secondTokenId)
            ).to.revertedWith('ERC3525: approve caller is not owner nor approved for all/slot');
          });

          it('reverts when approving owners token in other slot', async function () {
            await expect(
              this.token.connect(slotOperator)['approve(address,uint256)'](approved.address, thirdTokenId)
            ).to.revertedWith('ERC3525: approve caller is not owner nor approved for all/slot');
          });
        });

        context('when approving values by the slot operator', function () {
          it('slot operator can approve values of the owner in the approved slot', async function () {
            await this.token.connect(slotOperator)['approve(uint256,address,uint256)'](firstTokenId, valueApproved.address, 10);
            expect(await this.token.allowance(firstTokenId, valueApproved.address)).to.be.equal(10);
          });

          it('reverts when approving others values in the same slot', async function () {
            await expect(
              this.token.connect(slotOperator)['approve(uint256,address,uint256)'](secondTokenId, valueApproved.address, 10)
            ).to.revertedWith('ERC3525: approve caller is not owner nor approved');
          });

          it('reverts when approving owners values in other slot', async function () {
            await expect(
              this.token.connect(slotOperator)['approve(uint256,address,uint256)'](thirdTokenId, valueApproved.address, 10)
            ).to.revertedWith('ERC3525: approve caller is not owner nor approved');
          });
        });

        context('when transferring tokens by the slot operator', function () {
          it('slot operator can transfer tokens of the owner in the approved slot', async function () {
            await this.token.connect(slotOperator)['transferFrom(address,address,uint256)'](firstOwner.address, secondOwner.address, firstTokenId);
            expect(await this.token.ownerOf(firstTokenId)).to.be.equal(secondOwner.address);
          });

          it('reverts when transferring others tokens in the same slot', async function () {
            await expect(
              this.token.connect(slotOperator)['transferFrom(address,address,uint256)'](secondOwner.address, firstOwner.address, secondTokenId)
            ).to.revertedWith('ERC3525: transfer caller is not owner nor approved');
          });

          it('reverts when transferring owners tokens in other slot', async function () {
            await expect(
              this.token.connect(slotOperator)['transferFrom(address,address,uint256)'](firstOwner.address, secondOwner.address, thirdTokenId)
            ).to.revertedWith('ERC3525: transfer caller is not owner nor approved');
          });
        });

        context('when transferring values by the slot operator', function () {
          it('slot operator can transfer values of the owner in the approved slot', async function () {
            await this.token.connect(slotOperator)['transferFrom(uint256,uint256,uint256)'](firstTokenId, secondTokenId, 100);
            expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(firstTokenValue - 100);
            expect(await this.token['balanceOf(uint256)'](secondTokenId)).to.be.equal(secondTokenValue + 100);

            await this.token.connect(slotOperator)['transferFrom(uint256,address,uint256)'](firstTokenId, other.address, 100);
            expect(await this.token['balanceOf(uint256)'](firstTokenId)).to.be.equal(firstTokenValue - 200);
            expect(await this.token['balanceOf(address)'](other.address)).to.be.equal(1);
          });

          it('reverts when transferring others values in the same slot', async function () {
            await expect(
              this.token.connect(slotOperator)['transferFrom(uint256,uint256,uint256)'](secondTokenId, firstTokenId, 100)
            ).to.revertedWith('ERC3525: insufficient allowance');

            await expect(
              this.token.connect(slotOperator)['transferFrom(uint256,address,uint256)'](secondTokenId, other.address, 100)
            ).to.revertedWith('ERC3525: insufficient allowance');
          });

          it('reverts when transferring owners values in other slot', async function () {
            await expect(
              this.token.connect(slotOperator)['transferFrom(uint256,uint256,uint256)'](thirdTokenId, fourthTokenId, 100)
            ).to.revertedWith('ERC3525: insufficient allowance');

            await expect(
              this.token.connect(slotOperator)['transferFrom(uint256,address,uint256)'](thirdTokenId, other.address, 100)
            ).to.revertedWith('ERC3525: insufficient allowance');
          });
        });
      });

      context('after being canceled slot approval', function () {
        let tx = null;
        let receipt = null;

        beforeEach(async function () {
          await this.token.connect(firstOwner).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, true);
          tx = await this.token.connect(firstOwner).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, false);
          receipt = await tx.wait();
        });

        it('unapproves the slot operator', async function () {
          expect(await this.token.isApprovedForSlot(firstOwner.address, firstSlot, slotOperator.address)).to.be.equal(false);
        });

        it('emits an ApprovalForSlot event', async function () {
          expectEvent(receipt, 'ApprovalForSlot', { _owner: firstOwner.address, _slot: firstSlot, _operator: slotOperator.address, _approved: false });
        });

        it('reverts when approving tokens of the owner in the unapproved slot', async function () {
          await expect(
            this.token.connect(slotOperator)['approve(address,uint256)'](approved.address, firstTokenId)
          ).to.revertedWith('ERC3525: approve caller is not owner nor approved for all/slot');
        });

        it('reverts when approving values of the owner in the unapproved slot', async function () {
          await expect(
            this.token.connect(slotOperator)['approve(uint256,address,uint256)'](firstTokenId, approved.address, 100)
          ).to.revertedWith('ERC3525: approve caller is not owner nor approved');
        });

        it('reverts when transferring tokens of the owner in the unapproved slot', async function () {
          await expect(
            this.token.connect(slotOperator)['transferFrom(address,address,uint256)'](firstOwner.address, secondOwner.address, firstTokenId)
          ).to.revertedWith('ERC3525: transfer caller is not owner nor approved');
        });

        it('reverts when transferring values of the owner in the unapproved slot', async function () {
          await expect(
            this.token.connect(slotOperator)['transferFrom(uint256,uint256,uint256)'](firstTokenId, secondTokenId, 100)
          ).to.revertedWith('ERC3525: insufficient allowance');

          await expect(
            this.token.connect(slotOperator)['transferFrom(uint256,address,uint256)'](firstTokenId, other.address, 100)
          ).to.revertedWith('ERC3525: insufficient allowance');
        });
      });
    });

    context('when slot operator is the owner', function () {
      it('reverts', async function () {
        await expect(
          this.token.setApprovalForSlot(firstOwner.address, firstSlot, firstOwner.address, true)
        ).to.revertedWith('ERC3525SlotApprovable: approve to owner');
      });
    });

    context('when slot operator is set not by the owner', function () {
      it('when set by operator', async function () {
        await this.token.connect(firstOwner).setApprovalForAll(operator.address, true);
        await this.token.connect(operator).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, true);
        expect(await this.token.isApprovedForSlot(firstOwner.address, firstSlot, slotOperator.address)).to.be.equal(true);
      });

      it('reverts when set by token approved user', async function () {
        await this.token.connect(firstOwner)['approve(address,uint256)'](approved.address, firstTokenId);
        await expect(
          this.token.connect(approved).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, true)
        ).to.revertedWith('ERC3525SlotApprovable: caller is not owner nor approved for all');
      });

      it('reverts when set by others', async function () {
        await expect(
          this.token.connect(other).setApprovalForSlot(firstOwner.address, firstSlot, slotOperator.address, true)
        ).to.revertedWith('ERC3525SlotApprovable: caller is not owner nor approved for all');
      });
    });
  });
}

module.exports = {
  shouldBehaveLikeERC3525,
  shouldBehaveLikeERC3525Metadata,
  shouldBehaveLikeERC3525SlotEnumerable,
  shouldBehaveLikeERC3525SlotApprovable
}
