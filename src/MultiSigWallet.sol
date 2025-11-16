// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IMultiSigWallet.sol";

/**
 * @title MultiSigWallet
 * @author Secudity (Security + Solidity)
 * @notice A secure multi-signature wallet requiring multiple confirmations for transactions
 * @dev Implements security best practices:
 *      - Checks-Effects-Interactions pattern
 *      - Custom errors for gas efficiency
 *      - Reentrancy protection
 *      - Event emission for transparency
 */
contract MultiSigWallet is IMultiSigWallet {
    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // Transaction index => owner => confirmed
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    // Modifiers
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TxDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert TxAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert TxAlreadyConfirmed();
        _;
    }

    /**
     * @notice Constructor to initialize the multi-sig wallet
     * @param _owners Array of owner addresses
     * @param _numConfirmationsRequired Number of confirmations required to execute a transaction
     */
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        if (_owners.length == 0) revert InvalidOwner();
        if (
            _numConfirmationsRequired == 0 ||
            _numConfirmationsRequired > _owners.length
        ) {
            revert InvalidRequiredConfirmations();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert InvalidOwner();
            if (isOwner[owner]) revert OwnerNotUnique();

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * @notice Allows contract to receive ETH
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @notice Submit a transaction for confirmation
     * @param _to Destination address
     * @param _value Amount of ETH to send
     * @param _data Transaction data
     * @return Transaction index
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner returns (uint256) {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);

        return txIndex;
    }

    /**
     * @notice Confirm a transaction
     * @param _txIndex Transaction index
     */
    function confirmTransaction(
        uint256 _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Execute a confirmed transaction
     * @param _txIndex Transaction index
     */
    function executeTransaction(
        uint256 _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction.numConfirmations < numConfirmationsRequired) {
            revert CannotExecuteTx();
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert TxFailed();

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Revoke confirmation for a transaction
     * @param _txIndex Transaction index
     */
    function revokeConfirmation(
        uint256 _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) revert TxNotConfirmed();

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @notice Get all owners
     * @return Array of owner addresses
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Get transaction count
     * @return Total number of transactions
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Get transaction details
     * @param _txIndex Transaction index
     * @return to Destination address
     * @return value Amount of ETH
     * @return data Transaction data
     * @return executed Execution status
     * @return numConfirmations Number of confirmations
     */
    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}
