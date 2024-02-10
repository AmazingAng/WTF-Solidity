// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * PaymentSplit
 * @dev This contract will distribute the received ETH to several accounts according to the pre-determined share.Received ETH will be stored in PaymentSplit, and each beneficiary needs to call the release() function to claim it.
 */
contract PaymentSplit {
    // event
    event PayeeAdded(address account, uint256 shares); // Event for adding a payee
    event PaymentReleased(address to, uint256 amount); // Event for releasing payment to a payee
    event PaymentReceived(address from, uint256 amount); // Event for receiving payment to the contract

    uint256 public totalShares; // Total shares of the contract
    uint256 public totalReleased; // Total amount of payments released from the contract

    mapping(address => uint256) public shares; // Mapping to store the shares of each payee
    mapping(address => uint256) public released; // Mapping to store the amount of payments released to each payee
    address[] public payees; // Array  of payees

    /**
     * @dev Constructor to initialize the payees array (_payees) and their shares (_shares).
     *      The length of both arrays cannot be 0 and must be equal.
            Each element in the _shares array must be greater than 0, 
            and each address in _payees must not be a zero address and must be unique.
     */
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        // Check that the length of _payees and _shares arrays are equal and not empty
        require(
            _payees.length == _shares.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(_payees.length > 0, "PaymentSplitter: no payees");
        //  Call the _addPayee function to update the payees addresses (payees), their shares (shares), and the total shares (totalShares)
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev Callback function, receive ETH emit PaymentReceived event
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Splits funds to the designated payee address "_account". Anyone can trigger this function, but the funds will be transferred to the "_account" address.
     * Calls the "releasable()" function.
     */
    function release(address payable _account) public virtual {
        // The "_account" address must be a valid payee.
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // Calculate the payment due to the "_account" address.
        uint256 payment = releasable(_account);
        // The payment due cannot be zero.
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // Update the "totalReleased" and "released" amounts for each payee.
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
        // Calculate the total income of the profit-sharing contract
        uint256 totalReceived = address(this).balance + totalReleased;
        // Call _pendingPayment to calculate the amount of ETH that account is entitled to
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    /**
     * @dev According to the payee address `_account`, the total income of the distribution contract `_totalReceived` and the money received by the address `_alreadyReleased`, calculate the `ETH` that the payee should now distribute.
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        // ETH due to account = Total ETH due - ETH received
        return
            (_totalReceived * shares[_account]) /
            totalShares -
            _alreadyReleased;
    }

    /**
     * @dev Add payee_account and corresponding share_accountShares. It can only be called in the constructor and cannot be modified.
     */
    function _addPayee(address _account, uint256 _accountShares) private {
        // Check that _account is not 0 address
        require(
            _account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        // Check that _accountShares is not 0
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // Check that _account is not duplicated
        require(
            shares[_account] == 0,
            "PaymentSplitter: account already has shares"
        );
        // Update payees, shares and totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        // emit add payee event
        emit PayeeAdded(_account, _accountShares);
    }
}
