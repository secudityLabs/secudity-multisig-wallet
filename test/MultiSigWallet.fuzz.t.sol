// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletFuzzTest is Test {
    MultiSigWallet public wallet;
    
    address[] public owners;
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    
    uint256 public constant REQUIRED_CONFIRMATIONS = 2;
    
    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        wallet = new MultiSigWallet(owners, REQUIRED_CONFIRMATIONS);
        vm.deal(address(wallet), 100 ether);
    }
    
    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testFuzz_SubmitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public {
        vm.assume(to != address(0));
        vm.assume(value <= 100 ether);
        
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(to, value, data);
        
        (
            address txTo,
            uint256 txValue,
            bytes memory txData,
            bool executed,
            uint256 numConfirmations
        ) = wallet.getTransaction(txIndex);
        
        assertEq(txTo, to);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertFalse(executed);
        assertEq(numConfirmations, 0);
    }
    
    function testFuzz_ConfirmAndExecute(uint256 value) public {
        vm.assume(value > 0 && value <= 10 ether);
        
        address recipient = address(0x999);
        uint256 initialBalance = address(recipient).balance;
        
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, value, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner2);
        wallet.confirmTransaction(txIndex);
        
        vm.prank(owner3);
        wallet.executeTransaction(txIndex);
        
        assertEq(address(recipient).balance, initialBalance + value);
    }
    
    function testFuzz_MultipleTransactions(uint8 numTxs) public {
        vm.assume(numTxs > 0 && numTxs <= 50);
        
        for (uint256 i = 0; i < numTxs; i++) {
            vm.prank(owner1);
            wallet.submitTransaction(address(uint160(i)), 0.01 ether, "");
        }
        
        assertEq(wallet.getTransactionCount(), numTxs);
    }
    
    function testFuzz_CannotExecuteWithoutEnoughConfirmations(
        uint256 value
    ) public {
        vm.assume(value > 0 && value <= 10 ether);
        
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(address(0x999), value, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(txIndex);
        
        vm.expectRevert(IMultiSigWallet.CannotExecuteTx.selector);
        vm.prank(owner1);
        wallet.executeTransaction(txIndex);
    }
    
    function testFuzz_Deposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100 ether);
        
        uint256 initialBalance = address(wallet).balance;
        
        vm.deal(owner1, amount);
        vm.prank(owner1);
        (bool success, ) = address(wallet).call{value: amount}("");
        
        assertTrue(success);
        assertEq(address(wallet).balance, initialBalance + amount);
    }
}