const { expect } = require('chai');

const { expectEvent } = require('./utils/expectEvent')

const { shouldSupportInterfaces } = require('./utils/SupportsInterface.behavior');

const Error = [ 'None', 'RevertWithMessage', 'RevertWithoutMessage', 'Panic' ]
  .reduce((acc, entry, idx) => Object.assign({ [entry]: idx }, acc), {});

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const firstTokenId = 1001;
const secondTokenId = 1002;
const nonExistentTokenId = 103;
const fourthTokenId = 1004;
const mintSlot = 99999;
const mintValue = 10000000;
const baseURI = 'https://api.example.com/v1/';

const RECEIVER_MAGIC_VALUE = '0x150b7a02';

let owner, approved, anotherApproved, operator, other

function shouldBehaveLikeERC721 (errorPrefix) {

  shouldSupportInterfaces([
    'ERC165',
    'ERC721',
  ]);

  context('with minted tokens', function () {

    beforeEach(async function () {
      [ owner, newOwner, approved, anotherApproved, operator, other ] = await ethers.getSigners();
      
      await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
      await this.token.mint(owner.address, secondTokenId, mintSlot, mintValue);
      this.toWhom = other;
      this.ERC721ReceiverMockFactory = await ethers.getContractFactory('ERC721ReceiverMock');
      this.NonReceiverMock = await ethers.getContractFactory('NonReceiverMock');
    });

    describe('balanceOf(address)', function () {
      context('when the given address owns some tokens', function () {
        it('returns the amount of tokens owned by the given address', async function () {
          expect(await this.token['balanceOf(address)'](owner.address)).to.be.eq(2)
        });
      });

      context('when the given address does not own any tokens', function () {
        it('returns 0', async function () {
          expect(await this.token['balanceOf(address)'](other.address)).to.be.equal(0);
        });
      });

      context('when querying the zero address', function () {
        it('throws', async function () {
          await expect(this.token['balanceOf(address)'](ZERO_ADDRESS)).to.revertedWith('ERC3525: balance query for the zero address');
        });
      });
    });

    describe('ownerOf', function () {
      context('when the given token ID was tracked by this token', function () {
        it('returns the owner of the given token ID', async function () {
          expect(await this.token.ownerOf(firstTokenId)).to.be.equal(owner.address);
        });
      });

      context('when the given token ID was not tracked by this token', function () {
        it('reverts', async function () {
          await expect(this.token.ownerOf(nonExistentTokenId)).to.revertedWith('ERC3525: invalid token ID');
        });
      });
    });

    describe('transfers', function () {
      const tokenId = firstTokenId;
      const data = '0x42';

      let tx = null
      let receipt = null;

      beforeEach(async function () {
        await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId);
        await this.token.connect(owner).setApprovalForAll(operator.address, true);
      });

      const transferWasSuccessful = function () {
        it('transfers the ownership of the given token ID to the given address', async function () {
          expect(await this.token.ownerOf(tokenId)).to.be.equal(this.toWhom.address);
        });

        it('emits a Transfer event', async function () {
          expectEvent(receipt, 'Transfer', { _from: owner.address, _to: this.toWhom.address, _tokenId: tokenId });
        });

        it('clears the approval for the token ID', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
        });

        it('adjusts owners balances', async function () {
          expect(await this.token['balanceOf(address)'](owner.address)).to.be.equal(1);
        });

        it('adjusts owners tokens by index', async function () {
          if (!this.token.tokenOfOwnerByIndex) return;

          expect(await this.token.tokenOfOwnerByIndex(this.toWhom.address, 0)).to.be.equal(tokenId);

          expect(await this.token.tokenOfOwnerByIndex(owner.address, 0)).to.be.not.equal(tokenId);
        });
      };

      const shouldTransferTokensByUsers = function (transferFunction) {
        context('when called by the owner', function () {
          beforeEach(async function () {
            (tx = await transferFunction.call(this, owner.address, this.toWhom.address, tokenId, owner));
            receipt = await tx.wait();
          });
          transferWasSuccessful();
        });

        context('when called by the approved individual', function () {
          beforeEach(async function () {
            (tx = await transferFunction.call(this, owner.address, this.toWhom.address, tokenId, approved));
            receipt = await tx.wait();
          });
          transferWasSuccessful();
        });

        context('when called by the operator', function () {
          beforeEach(async function () {
            (tx = await transferFunction.call(this, owner.address, this.toWhom.address, tokenId, operator));
            receipt = await tx.wait();
          });
          transferWasSuccessful();
        });

        context('when called by the operator without an approved user', function () {
          beforeEach(async function () {
            await this.token['approve(address,uint256)'](ZERO_ADDRESS, tokenId);
            (tx = await transferFunction.call(this, owner.address, this.toWhom.address, tokenId, operator));
            receipt = await tx.wait();
          });
          transferWasSuccessful();
        });

        context('when sent to the owner', function () {
          beforeEach(async function () {
            tx = await transferFunction.call(this, owner.address, owner.address, tokenId, owner);
            receipt = await tx.wait();
          });

          it('keeps ownership of the token', async function () {
            expect(await this.token.ownerOf(tokenId)).to.be.equal(owner.address);
          });

          it('clears the approval for the token ID', async function () {
            expect(await this.token.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
          });

          it('emits only a transfer event', async function () {
            expectEvent(receipt, 'Transfer', {
              _from: owner.address,
              _to: owner.address,
              _tokenId: tokenId,
            });
          });

          it('keeps the owner balance', async function () {
            expect(await this.token['balanceOf(address)'](owner.address)).to.be.equal(2);
          });

          it('keeps same tokens by index', async function () {
            if (!this.token.tokenOfOwnerByIndex) return;
            const tokensListed = await Promise.all(
              [0, 1].map(i => this.token.tokenOfOwnerByIndex(owner.address, i)),
            );
            expect(tokensListed.map(t => t.toNumber())).to.have.members(
              [firstTokenId, secondTokenId],
            );
          });
        });

        context('when the address of the previous owner is incorrect', function () {
          it('reverts', async function () {
            await expect(
              transferFunction.call(this, other.address, other.address, tokenId)
            ).to.revertedWith('ERC3525: transfer from invalid owner');
          });
        });

        context('when the sender is not authorized for the token id', function () {
          it('reverts', async function () {
            await expect(
              transferFunction.call(this, owner.address, other.address, tokenId, other)
            ).to.revertedWith('ERC3525: transfer caller is not owner nor approved');
          });
        });

        context('when the given token ID does not exist', function () {
          it('reverts', async function () {
            await expect(
              transferFunction.call(this, owner.address, other.address, nonExistentTokenId)
            ).to.revertedWith('ERC3525: invalid token ID');
          });
        });

        context('when the address to transfer the token to is the zero address', function () {
          it('reverts', async function () {
            await expect(
              transferFunction.call(this, owner.address, ZERO_ADDRESS, tokenId)
            ).to.revertedWith('ERC3525: transfer to the zero address');
          });
        });
      };

      describe('via transferFrom', function () {
        shouldTransferTokensByUsers(function (from, to, tokenId, sender = owner) {
          return this.token.connect(sender)['transferFrom(address,address,uint256)'](from, to, tokenId);
        });
      });

      describe('via safeTransferFrom', function () {
        const safeTransferFromWithData = function (from, to, tokenId, sender = owner) {
          return this.token.connect(sender)['safeTransferFrom(address,address,uint256,bytes)'](from, to, tokenId, data);
        };

        const safeTransferFromWithoutData = function (from, to, tokenId, sender = owner) {
          return this.token.connect(sender)['safeTransferFrom(address,address,uint256)'](from, to, tokenId);
        };

        const shouldTransferSafely = function (transferFun, data) {
          describe('to a user account', function () {
            shouldTransferTokensByUsers(transferFun);
          });

          describe('to a valid receiver contract', function () {
            beforeEach(async function () {
              this.receiver = await this.ERC721ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.None);
              this.toWhom = this.receiver;
            });

            shouldTransferTokensByUsers(transferFun);
          });
        };

        describe('with data', function () {
          shouldTransferSafely(safeTransferFromWithData, data);
        });

        describe('without data', function () {
          shouldTransferSafely(safeTransferFromWithoutData, null);
        });

        describe('to a non-receiver contract that implements ERC-165', function () {
          it('reverts', async function () {
            await expect(
              this.token['safeTransferFrom(address,address,uint256)'](owner.address, this.token.address, tokenId)
            ).to.revertedWith('ERC721: transfer to non ERC721Receiver implementer');
          });
        });

        describe('to a non-receiver contract that does not implement ERC-165', function () {
          it('reverts', async function () {
            const nonReceiver = await this.NonReceiverMock.deploy();
            await expect(
              this.token['safeTransferFrom(address,address,uint256)'](owner.address, nonReceiver.address, tokenId)
            ).to.revertedWith('ERC721: transfer to non ERC721Receiver implementer');
          });
        });

        describe('to a receiver contract returning unexpected value', function () {
          it('reverts', async function () {
            const invalidReceiver = await this.ERC721ReceiverMockFactory.deploy('0x12345678', Error.None);
            await expect(
              this.token['safeTransferFrom(address,address,uint256)'](owner.address, invalidReceiver.address, tokenId)
            ).to.revertedWith('ERC3525: transfer to non ERC721Receiver');
          });
        });

        describe('to a receiver contract that reverts with message', function () {
          it('reverts', async function () {
            const revertingReceiver = await this.ERC721ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithMessage);
            await expect(
              this.token['safeTransferFrom(address,address,uint256)'](owner.address, revertingReceiver.address, tokenId)
            ).to.revertedWith('ERC721ReceiverMock: reverting');
          });
        });

        describe('to a receiver contract that reverts without message', function () {
          it('reverts', async function () {
            const revertingReceiver = await this.ERC721ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.RevertWithoutMessage);
            await expect(
              this.token['safeTransferFrom(address,address,uint256)'](owner.address, revertingReceiver.address, tokenId)
            ).to.revertedWith('ERC721: transfer to non ERC721Receiver implementer');
          });
        });

        describe('to a receiver contract that panics', function () {
          it('reverts', async function () {
            const revertingReceiver = await this.ERC721ReceiverMockFactory.deploy(RECEIVER_MAGIC_VALUE, Error.Panic);
            await expect(
              this.token['safeTransferFrom(address,address,uint256)'](owner.address, revertingReceiver.address, tokenId)
            ).to.revertedWithPanic;
          });
        });
      });
    });

    describe('approve', function () {
      const tokenId = firstTokenId;

      let tx = null;
      let receipt = null;

      const itClearsApproval = function () {
        it('clears approval for the token', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
        });
      };

      const itApproves = function (address) {
        it('sets the approval for the target address', async function () {
          expect(await this.token.getApproved(tokenId)).to.be.equal(
            address == ZERO_ADDRESS ? ZERO_ADDRESS : approved.address
          );
        });
      };

      const itEmitsApprovalEvent = function (address) {
        it('emits an approval event', async function () {
          expectEvent(receipt, 'Approval', {
            _owner: owner.address,
            _approved: address == ZERO_ADDRESS ? ZERO_ADDRESS : approved.address,
            _tokenId: tokenId,
          });
        });
      };

      context('when clearing approval', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            (tx = await this.token.connect(owner)['approve(address,uint256)'](ZERO_ADDRESS, tokenId));
            receipt = await tx.wait();
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS);
        });

        context('when there was a prior approval', function () {
          beforeEach(async function () {
            await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId);
            (tx = await this.token.connect(owner)['approve(address,uint256)'](ZERO_ADDRESS, tokenId));
            receipt = await tx.wait();
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS);
        });
      });

      context('when approving a non-zero address', function () {
        context('when there was no prior approval', function () {
          beforeEach(async function () {
            (tx = await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId));
            receipt = await tx.wait();
          });

          itApproves();
          itEmitsApprovalEvent();
        });

        context('when there was a prior approval to the same address', function () {
          beforeEach(async function () {
            await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId);
            (tx = await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId));
            receipt = await tx.wait();
          });

          itApproves();
          itEmitsApprovalEvent();
        });

        context('when there was a prior approval to a different address', function () {
          beforeEach(async function () {
            await this.token.connect(owner)['approve(address,uint256)'](anotherApproved.address, tokenId);
            (tx = await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId));
            receipt = await tx.wait();
          });

          itApproves();
          itEmitsApprovalEvent();
        });
      });

      context('when the address that receives the approval is the owner', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(owner)['approve(address,uint256)'](owner.address, tokenId)
          ).to.revertedWith('ERC3525: approval to current owner');
        });
      });

      context('when the sender does not own the given token ID', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(other)['approve(address,uint256)'](approved.address, tokenId)
          ).to.revertedWith('ERC3525: approve caller is not owner nor approved for all');
        });
      });

      context('when the sender is approved for the given token ID', function () {
        it('reverts', async function () {
          await this.token.connect(owner)['approve(address,uint256)'](approved.address, tokenId);
          await expect(
            this.token.connect(approved)['approve(address,uint256)'](anotherApproved.address, tokenId)
          ).to.revertedWith('ERC3525: approve caller is not owner nor approved for all');
        });
      });

      context('when the sender is an operator', function () {
        beforeEach(async function () {
          await this.token.setApprovalForAll(operator.address, true);
          (tx = await this.token.connect(operator)['approve(address,uint256)'](approved.address, tokenId));
          receipt = await tx.wait();
        });

        itApproves();
        itEmitsApprovalEvent();
      });

      context('when the given token ID does not exist', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(operator)['approve(address,uint256)'](approved.address, nonExistentTokenId)
          ).to.revertedWith('ERC3525: invalid token ID');
        });
      });
    });

    describe('setApprovalForAll', function () {
      context('when the operator willing to approve is not the owner', function () {
        context('when there is no operator approval set by the sender', function () {
          it('approves the operator', async function () {
            await this.token.connect(owner).setApprovalForAll(operator.address, true);

            expect(await this.token.isApprovedForAll(owner.address, operator.address)).to.equal(true);
          });

          it('emits an approval event', async function () {
            const tx = await this.token.connect(owner).setApprovalForAll(operator.address, true);
            const receipt = await tx.wait();

            expectEvent(receipt, 'ApprovalForAll', {
              _owner: owner.address,
              _operator: operator.address,
              _approved: true,
            });
          });
        });

        context('when the operator was set as not approved', function () {
          beforeEach(async function () {
            await this.token.connect(owner).setApprovalForAll(operator.address, false);
          });

          it('approves the operator', async function () {
            await this.token.connect(owner).setApprovalForAll(operator.address, true);

            expect(await this.token.isApprovedForAll(owner.address, operator.address)).to.equal(true);
          });

          it('emits an approval event', async function () {
            const tx = await this.token.connect(owner).setApprovalForAll(operator.address, true);
            const receipt = await tx.wait();

            expectEvent(receipt, 'ApprovalForAll', {
              _owner: owner.address,
              _operator: operator.address,
              _approved: true,
            });
          });

          it('can unset the operator approval', async function () {
            await this.token.connect(owner).setApprovalForAll(operator.address, false);

            expect(await this.token.isApprovedForAll(owner.address, operator.address)).to.equal(false);
          });
        });

        context('when the operator was already approved', function () {
          beforeEach(async function () {
            await this.token.connect(owner).setApprovalForAll(operator.address, true);
          });

          it('keeps the approval to the given address', async function () {
            await this.token.connect(owner).setApprovalForAll(operator.address, true);

            expect(await this.token.isApprovedForAll(owner.address, operator.address)).to.equal(true);
          });

          it('emits an approval event', async function () {
            const tx = await this.token.connect(owner).setApprovalForAll(operator.address, true);
            const receipt = await tx.wait();

            expectEvent(receipt, 'ApprovalForAll', {
              _owner: owner.address,
              _operator: operator.address,
              _approved: true,
            });
          });
        });
      });

      context('when the operator is the owner', function () {
        it('reverts', async function () {
          await expect(
            this.token.connect(owner).setApprovalForAll(owner.address, true)
          ).to.rejectedWith('ERC3525: approve to caller');
        });
      });
    });

    describe('getApproved', async function () {
      context('when token is not minted', async function () {
        it('reverts', async function () {
          await expect(
            this.token.getApproved(nonExistentTokenId)
          ).to.rejectedWith('ERC3525: invalid token ID');
        });
      });

      context('when token has been minted ', async function () {
        it('should return the zero address', async function () {
          expect(await this.token.getApproved(firstTokenId)).to.be.equal(
            ZERO_ADDRESS,
          );
        });

        context('when account has been approved', async function () {
          beforeEach(async function () {
            await this.token.connect(owner)['approve(address,uint256)'](approved.address, firstTokenId);
          });

          it('returns approved account', async function () {
            expect(await this.token.getApproved(firstTokenId)).to.be.equal(approved.address);
          });
        });
      });
    });
  });

  describe('_mint', function () {
    it('reverts with a null destination address', async function () {
      await expect(
        this.token.mint(ZERO_ADDRESS, firstTokenId, mintSlot, mintValue)
      ).to.revertedWith('ERC3525: mint to the zero address');
    });

    context('with minted token', async function () {
      beforeEach(async function () {
        const tx = await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
        this.receipt = await tx.wait();
      });

      it('emits a Transfer event', function () {
        expectEvent(this.receipt, 'Transfer', { _from: ZERO_ADDRESS, _to: owner.address, _tokenId: firstTokenId });
      });

      it('creates the token', async function () {
        expect(await this.token['balanceOf(address)'](owner.address)).to.be.equal(1);
        expect(await this.token.ownerOf(firstTokenId)).to.equal(owner.address);
      });

      it('reverts when adding a token id that already exists', async function () {
        await expect(
          this.token.mint(owner.address, firstTokenId, mintSlot, mintValue)
        ).to.revertedWith('ERC3525: token already minted');
      });
    });
  });

  describe('_burn', function () {
    it('reverts when burning a non-existent token id', async function () {
      await expect(
        this.token.burn(nonExistentTokenId)
      ).to.revertedWith('ERC3525: invalid token ID');
    });

    context('with minted tokens', function () {
      beforeEach(async function () {
        await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
        await this.token.mint(owner.address, secondTokenId, mintSlot, mintValue);
      });

      context('with burnt token', function () {
        beforeEach(async function () {
          const tx = await this.token.burn(firstTokenId);
          this.receipt = await tx.wait();
        });

        it('emits a Transfer event', function () {
          expectEvent(this.receipt, 'Transfer', { _from: owner.address, _to: ZERO_ADDRESS, _tokenId: firstTokenId });
        });

        it('deletes the token', async function () {
          expect(await this.token['balanceOf(address)'](owner.address)).to.be.equal(1);
          await expect(
            this.token.ownerOf(firstTokenId)
          ).to.revertedWith('ERC3525: invalid token ID');
        });

        it('reverts when burning a token id that has been deleted', async function () {
          await expect(
            this.token.burn(firstTokenId)
          ).to.revertedWith('ERC3525: invalid token ID');
        });
      });
    });
  });
}

function shouldBehaveLikeERC721Enumerable (errorPrefix, owner, newOwner, approved, anotherApproved, operator, other) {
  shouldSupportInterfaces([
    'ERC721Enumerable',
  ]);

  context('with minted tokens', function () {
    beforeEach(async function () {
      [ owner, newOwner, approved, anotherApproved, operator, other ] = await ethers.getSigners();
      await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
      await this.token.mint(owner.address, secondTokenId, mintSlot, mintValue);
      this.toWhom = other;
    });

    describe('totalSupply', function () {
      it('returns total token supply', async function () {
        expect(await this.token.totalSupply()).to.be.equal(2);
      });
    });

    describe('tokenOfOwnerByIndex', function () {
      describe('when the given index is lower than the amount of tokens owned by the given address', function () {
        it('returns the token ID placed at the given index', async function () {
          expect(await this.token.tokenOfOwnerByIndex(owner.address, 0)).to.be.equal(firstTokenId);
        });
      });

      describe('when the index is greater than or equal to the total tokens owned by the given address', function () {
        it('reverts', async function () {
          await expect(
            this.token.tokenOfOwnerByIndex(owner.address, 2)
          ).to.revertedWith('ERC3525: owner index out of bounds');
        });
      });

      describe('when the given address does not own any token', function () {
        it('reverts', async function () {
          await expect(
            this.token.tokenOfOwnerByIndex(other.address, 0)
          ).to.revertedWith('ERC3525: owner index out of bounds');
        });
      });

      describe('after transferring all tokens to another user', function () {
        beforeEach(async function () {
          await this.token.connect(owner)['transferFrom(address,address,uint256)'](owner.address, other.address, firstTokenId);
          await this.token.connect(owner)['transferFrom(address,address,uint256)'](owner.address, other.address, secondTokenId);
        });

        it('returns correct token IDs for target', async function () {
          expect(await this.token['balanceOf(address)'](other.address)).to.be.equal(2);
          const tokensListed = await Promise.all(
            [0, 1].map(i => this.token.tokenOfOwnerByIndex(other.address, i)),
          );
          expect(tokensListed.map(t => t.toNumber())).to.have.members([firstTokenId, secondTokenId]);
        });

        it('returns empty collection for original owner', async function () {
          expect(await this.token['balanceOf(address)'](owner.address)).to.be.equal(0);
          await expect(
            this.token.tokenOfOwnerByIndex(owner.address, 0)
          ).to.revertedWith('ERC3525: owner index out of bounds');
        });
      });
    });

    describe('tokenByIndex', function () {
      it('returns all tokens', async function () {
        const tokensListed = await Promise.all(
          [0, 1].map(i => this.token.tokenByIndex(i)),
        );
        expect(tokensListed.map(t => t.toNumber())).to.have.members([firstTokenId, secondTokenId]);
      });

      it('reverts if index is greater than supply', async function () {
        await expect(
          this.token.tokenByIndex(2)
        ).to.revertedWith('ERC3525: global index out of bounds');
      });

      [firstTokenId, secondTokenId].forEach(function (tokenId) {
        it(`returns all tokens after burning token ${tokenId} and minting new tokens`, async function () {
          const newTokenId = 300;
          const anotherNewTokenId = 400;

          await this.token.burn(tokenId);
          await this.token.mint(newOwner.address, newTokenId, mintSlot, mintValue);
          await this.token.mint(newOwner.address, anotherNewTokenId, mintSlot, mintValue);

          expect(await this.token.totalSupply()).to.be.equal(3);

          const tokensListed = await Promise.all(
            [0, 1, 2].map(i => this.token.tokenByIndex(i)),
          );
          const expectedTokens = [firstTokenId, secondTokenId, newTokenId, anotherNewTokenId].filter(
            x => (x !== tokenId),
          );
          expect(tokensListed.map(t => t.toNumber())).to.have.members(expectedTokens);
        });
      });
    });
  });

  describe('_mint(address, uint256)', function () {
    it('reverts with a null destination address', async function () {
      await expect(
        this.token.mint(ZERO_ADDRESS, firstTokenId, mintSlot, mintValue)
      ).to.revertedWith('ERC3525: mint to the zero address');
    });

    context('with minted token', async function () {
      beforeEach(async function () {
        const tx = await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
        this.receipt = await tx.wait();
      });

      it('adjusts owner tokens by index', async function () {
        expect(await this.token.tokenOfOwnerByIndex(owner.address, 0)).to.be.equal(firstTokenId);
      });

      it('adjusts all tokens list', async function () {
        expect(await this.token.tokenByIndex(0)).to.be.equal(firstTokenId);
      });
    });
  });

  describe('_burn', function () {
    it('reverts when burning a non-existent token id', async function () {
      await expect(
        this.token.burn(firstTokenId)
      ).to.revertedWith('ERC3525: invalid token ID');
    });

    context('with minted tokens', function () {
      beforeEach(async function () {
        await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
        await this.token.mint(owner.address, secondTokenId, mintSlot, mintValue);
      });

      context('with burnt token', function () {
        beforeEach(async function () {
          const tx = await this.token.burn(firstTokenId);
          this.receipt = await tx.wait();
        });

        it('removes that token from the token list of the owner', async function () {
          expect(await this.token.tokenOfOwnerByIndex(owner.address, 0)).to.be.equal(secondTokenId);
        });

        it('adjusts all tokens list', async function () {
          expect(await this.token.tokenByIndex(0)).to.be.equal(secondTokenId);
        });

        it('burns all tokens', async function () {
          await this.token.connect(owner).burn(secondTokenId);
          expect(await this.token.totalSupply()).to.be.equal(0);
          await expect(
            this.token.tokenByIndex(0)
          ).to.revertedWith('ERC3525: global index out of bounds');
        });
      });
    });
  });
}

function shouldBehaveLikeERC721Metadata (errorPrefix, name, symbol) {
  shouldSupportInterfaces([
    'ERC721Metadata',
  ]);

  describe('metadata', function () {
    beforeEach(async function () {
      [ owner ] = await ethers.getSigners();
    });

    it('has a name', async function () {
      expect(await this.token.name()).to.be.equal(name);
    });

    it('has a symbol', async function () {
      expect(await this.token.symbol()).to.be.equal(symbol);
    });

    describe('token URI', function () {
      beforeEach(async function () {
        await this.token.mint(owner.address, firstTokenId, mintSlot, mintValue);
      });

      it('return empty string by default', async function () {
        expect(await this.token.tokenURI(firstTokenId)).to.be.equal('');
      });

      it('reverts when queried for non existent token id', async function () {
        await expect(
          this.token.tokenURI(nonExistentTokenId)
        ).to.revertedWith('ERC3525: invalid token ID');
      });

      describe('base URI', function () {
        beforeEach(function () {
          if (this.token.setBaseURI === undefined) {
            this.skip();
          }
        });

        it('base URI can be set', async function () {
          await this.token.setBaseURI(baseURI);
          expect(await this.token.baseURI()).to.equal(baseURI);
        });

        it('base URI is added as a prefix to the token URI', async function () {
          await this.token.setBaseURI(baseURI);
          expect(await this.token.tokenURI(firstTokenId)).to.be.equal(baseURI + firstTokenId.toString());
        });

        it('token URI can be changed by changing the base URI', async function () {
          await this.token.setBaseURI(baseURI);
          const newBaseURI = 'https://api.example.com/v2/';
          await this.token.setBaseURI(newBaseURI);
          expect(await this.token.tokenURI(firstTokenId)).to.be.equal(newBaseURI + firstTokenId.toString());
        });
      });
    });
  });
}

module.exports = {
  shouldBehaveLikeERC721,
  shouldBehaveLikeERC721Enumerable,
  shouldBehaveLikeERC721Metadata,
};

