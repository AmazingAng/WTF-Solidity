// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * PaymentSplit 
 * * @dev This contract will distribute the received ETH to several accounts according to the pre-determined share. Received ETH will be stored in the account sharing contract, and each beneficiary needs to call the release() function to receive it.
 */
contract PaymentSplit{
    // event 
    event PayeeAdded(address account, uint256 shares); // addition of beneficiary event
    event PaymentReleased(address to, uint256 amount); // payee withdrawal event
    event PaymentReceived(address from, uint256 amount); // receipt of payment event

    uint256 public totalShares; // total share
    uint256 public totalReleased; // total payment

    mapping(address => uint256) public shares; // each beneficiary's share
    mapping(address => uint256) public released; // aount paid to each beneficiary
    address[] public payees; // beneficiary array

    /**
     * @dev Initialize beneficiary array _payees and share share array _shares
     * The length of the array cannot be 0, and the lengths of the two arrays must be equal. The elements in _shares must be greater than 0, and the address in _payees cannot be 0 and cannot have duplicate addresses
     */
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        // Check that the _payees and _shares arrays have the same length and are not 0
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        // Call _addPayee to update beneficiary address payees, beneficiary shares shares and total shares totalShares
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev Callback function, receive ETH release PaymentReceived event
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev For valid beneficiary address _account, the corresponding ETH is sent directly to the beneficiary address. Anyone can trigger this function, but the money will be sent to the account address.
     * The releasable() function is called.
     */
    function release(address payable _account) public virtual {
        // account must be a valid beneficiary
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // calculate the amount of ETH that the account is entitled to
        uint256 payment = releasable(_account);
        // deserved eth cannot be 0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // update the total payment totalReleased and the amount paid to each beneficiary released
        totalReleased += payment;
        released[_account] += payment;
        // transfer
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

    /**
     * @dev Calculate the eth that an account can receive.
     * The pendingPayment() function is called.
     */
    function releasable(address _account) public view returns (uint256) {
        // calculate the total revenue of the split contract totalReceived
        uint256 totalReceived = address(this).balance + totalReleased;
        // call _pendingPayment to calculate the ETH due to the account
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    /**
     * @dev According to the beneficiary's address `_account`, the total income of the distribution contract `_totalReceived` and the money received by the address `_alreadyReleased`, calculate the `ETH` that the beneficiary should share now.
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        //  ETH to be received in the account = Total ETH to be received - ETH already received
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }

    /**
     * @dev Add beneficiary_account and corresponding share_accountShares. It can only be called in the constructor and cannot be modified.
     */
    function _addPayee(address _account, uint256 _accountShares) private {
        // check that _account is not 0 address
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        // check that _accountShares is not 0
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // check that _account is not duplicated
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        // update payees, shares and totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        // emit add beneficiary event
        emit PayeeAdded(_account, _accountShares);
    }
}
