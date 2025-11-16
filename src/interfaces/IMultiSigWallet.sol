// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IMultiSigWallet
 * @author Secudity
 * @notice Interface for Multi-Signature Wallet
 */
interface IMultiSigWallet {
    // Events
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    // Errors
    error NotOwner();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyConfirmed();
    error TxNotConfirmed();
    error CannotExecuteTx();
    error TxFailed();
    error InvalidOwner();
    error OwnerNotUnique();
    error InvalidRequiredConfirmations();

    // Functions
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (uint256);

    function confirmTransaction(uint256 _txIndex) external;

    function executeTransaction(uint256 _txIndex) external;

    function revokeConfirmation(uint256 _txIndex) external;

    function getOwners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint256);

    function getTransaction(
        uint256 _txIndex
    )
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        );
}
