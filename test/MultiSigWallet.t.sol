// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    
    address[] public owners;
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    address public nonOwner = address(0x4);
    address public recipient = address(0x5);
    
    uint256 public constant REQUIRED_CONFIRMATIONS = 2;
    
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
    
    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        wallet = new MultiSigWallet(owners, REQUIRED_CONFIRMATIONS);
        
        // Fund the wallet
        vm.deal(address(wallet), 10 ether);
    }
    
    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Constructor_Success() public {
        assertEq(wallet.numConfirmationsRequired(), REQUIRED_CONFIRMATIONS);
        
        address[] memory walletOwners = wallet.getOwners();
        assertEq(walletOwners.length, 3);
        assertEq(walletOwners[0], owner1);
        assertEq(walletOwners[1], owner2);
        assertEq(walletOwners[2], owner3);
        
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
        assertFalse(wallet.isOwner(nonOwner));
    }
    
    function test_Constructor_RevertWhen_NoOwners() public {
        address[] memory emptyOwners = new address[](0);
        
        vm.expectRevert(IMultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(emptyOwners, 1);
    }
    
    function test_Constructor_RevertWhen_ZeroConfirmationsRequired() public {
        vm.expectRevert(IMultiSigWallet.InvalidRequiredConfirmations.selector);
        new MultiSigWallet(owners, 0);
    }
    
    function test_Constructor_RevertWhen_ConfirmationsExceedOwners() public {
        vm.expectRevert(IMultiSigWallet.InvalidRequiredConfirmations.selector);
        new MultiSigWallet(owners, 4);
    }
    
    function test_Constructor_RevertWhen_OwnerIsZeroAddress() public {
        address[] memory invalidOwners = new address[](3);
        invalidOwners[0] = owner1;
        invalidOwners[1] = address(0);
        invalidOwners[2] = owner3;
        
        vm.expectRevert(IMultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(invalidOwners, 2);
    }
    
    function test_Constructor_RevertWhen_DuplicateOwner() public {
        address[] memory duplicateOwners = new address[](3);
        duplicateOwners[0] = owner1;
        duplicateOwners[1] = owner2;
        duplicateOwners[2] = owner1; // Duplicate
        
        vm.expectRevert(IMultiSigWallet.OwnerNotUnique.selector);
        new MultiSigWallet(duplicateOwners, 2);
    }
    
    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Receive_Success() public {
        vm.expectEmit(true, false, false, true);
        emit Deposit(owner1, 1 ether, 11 ether);
        
        vm.prank(owner1);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);
        
        assertEq(address(wallet).balance, 11 ether);
    }
    
    /*//////////////////////////////////////////////////////////////
                        SUBMIT TRANSACTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_SubmitTransaction_Success() public {
        bytes memory data = "";
        
        vm.expectEmit(true, true, true, true);
        emit SubmitTransaction(owner1, 0, recipient, 1 ether, data);
        
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, data);
        
        assertEq(txIndex, 0);
        assertEq(wallet.getTransactionCount(), 1);
        
        (
            address to,
            uint256 value,
            bytes memory txData,
            bool executed,
            uint256 numConfirmations
        ) = wallet.getTransaction(0);
        
        assertEq(to, recipient);
        assertEq(value, 1 ether);
        assertEq(txData, data);
        assertFalse(executed);
        assertEq(numConfirmations, 0);
    }
    
    function test_SubmitTransaction_RevertWhen_NotOwner() public {
        vm.expectRevert(IMultiSigWallet.NotOwner.selector);
        
        vm.prank(nonOwner);
        wallet.submitTransaction(recipient, 1 ether, "");
    }
    
    /*//////////////////////////////////////////////////////////////
                        CONFIRM TRANSACTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_ConfirmTransaction_Success() public {
        // Submit transaction
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        // Confirm transaction
        vm.expectEmit(true, true, false, false);
        emit ConfirmTransaction(owner2, txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        assertTrue(wallet.isConfirmed(txIndex, owner2));
        
        (, , , , uint256 numConfirmations) = wallet.getTransaction(txIndex);
        assertEq(numConfirmations, 1);
    }
    
    function test_ConfirmTransaction_RevertWhen_NotOwner() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.expectRevert(IMultiSigWallet.NotOwner.selector);
        vm.prank(nonOwner);
        wallet.confirmTransaction(txIndex);
    }
    
    function test_ConfirmTransaction_RevertWhen_TxDoesNotExist() public {
        vm.expectRevert(IMultiSigWallet.TxDoesNotExist.selector);
        vm.prank(owner1);
        wallet.confirmTransaction(999);
    }
    
    function test_ConfirmTransaction_RevertWhen_AlreadyConfirmed() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.TxAlreadyConfirmed.selector);
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
    }
    
    function test_ConfirmTransaction_RevertWhen_AlreadyExecuted() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.TxAlreadyExecuted.selector);
        vm.prank(owner3);
        wallet.confirmTransaction(txIndex);
    }
    
    /*//////////////////////////////////////////////////////////////
                        EXECUTE TRANSACTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_ExecuteTransaction_Success() public {
        uint256 initialBalance = address(recipient).balance;
        
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.expectEmit(true, true, false, false);
        emit ExecuteTransaction(owner1, txIndex);
        
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);
        
        assertEq(address(recipient).balance, initialBalance + 1 ether);
        
        (, , , bool executed, ) = wallet.getTransaction(txIndex);
        assertTrue(executed);
    }
    
    function test_ExecuteTransaction_RevertWhen_NotOwner() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.NotOwner.selector);
        vm.prank(nonOwner);
        wallet.executeTransaction(txIndex);
    }
    
    function test_ExecuteTransaction_RevertWhen_NotEnoughConfirmations() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.CannotExecuteTx.selector);
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);
    }
    
    function test_ExecuteTransaction_RevertWhen_AlreadyExecuted() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.TxAlreadyExecuted.selector);
        vm.prank(owner2);
        wallet.executeTransaction(txIndex);
    }
    
    /*//////////////////////////////////////////////////////////////
                        REVOKE CONFIRMATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_RevokeConfirmation_Success() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.expectEmit(true, true, false, false);
        emit RevokeConfirmation(owner2, txIndex);
        
        vm.prank(owner2);
        wallet.revokeConfirmation(txIndex);
        
        assertFalse(wallet.isConfirmed(txIndex, owner2));
        
        (, , , , uint256 numConfirmations) = wallet.getTransaction(txIndex);
        assertEq(numConfirmations, 0);
    }
    
    function test_RevokeConfirmation_RevertWhen_NotConfirmed() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.expectRevert(IMultiSigWallet.TxNotConfirmed.selector);
        vm.prank(owner2);
        wallet.revokeConfirmation(txIndex);
    }
    
    function test_RevokeConfirmation_RevertWhen_AlreadyExecuted() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.TxAlreadyExecuted.selector);
        vm.prank(owner2);
        wallet.revokeConfirmation(txIndex);
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_GetOwners_Success() public {
        address[] memory walletOwners = wallet.getOwners();
        
        assertEq(walletOwners.length, 3);
        assertEq(walletOwners[0], owner1);
        assertEq(walletOwners[1], owner2);
        assertEq(walletOwners[2], owner3);
    }
    
    function test_GetTransactionCount_Success() public {
        assertEq(wallet.getTransactionCount(), 0);
        
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        assertEq(wallet.getTransactionCount(), 1);
        
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 2 ether, "");
        
        assertEq(wallet.getTransactionCount(), 2);
    }
}
