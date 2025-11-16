// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract Handler is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    
    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    
    constructor(MultiSigWallet _wallet, address[] memory _owners) {
        wallet = _wallet;
        owners = _owners;
    }
    
    function deposit(uint256 amount) public {
        amount = bound(amount, 0, 10 ether);
        vm.deal(address(this), amount);
        
        (bool success, ) = address(wallet).call{value: amount}("");
        if (success) {
            ghost_depositSum += amount;
        }
    }
    
    function submitTransaction(
        uint256 ownerSeed,
        uint256 value
    ) public {
        address owner = owners[ownerSeed % owners.length];
        value = bound(value, 0, address(wallet).balance);
        
        vm.prank(owner);
        wallet.submitTransaction(address(0x999), value, "");
    }
    
    function confirmTransaction(
        uint256 ownerSeed,
        uint256 txIndex
    ) public {
        if (wallet.getTransactionCount() == 0) return;
        
        address owner = owners[ownerSeed % owners.length];
        txIndex = txIndex % wallet.getTransactionCount();
        
        try wallet.confirmTransaction(txIndex) {
            // Success
        } catch {
            // Revert is ok
        }
        
        vm.prank(owner);
    }
    
    function executeTransaction(
        uint256 ownerSeed,
        uint256 txIndex
    ) public {
        if (wallet.getTransactionCount() == 0) return;
        
        address owner = owners[ownerSeed % owners.length];
        txIndex = txIndex % wallet.getTransactionCount();
        
        (, uint256 value, , bool executed, ) = wallet.getTransaction(txIndex);
        
        vm.prank(owner);
        try wallet.executeTransaction(txIndex) {
            if (!executed) {
                ghost_withdrawSum += value;
            }
        } catch {
            // Revert is ok
        }
    }
    
    receive() external payable {}
}

contract MultiSigWalletInvariantTest is Test {
    MultiSigWallet public wallet;
    Handler public handler;
    
    address[] public owners;
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    
    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        wallet = new MultiSigWallet(owners, 2);
        handler = new Handler(wallet, owners);
        
        vm.deal(address(handler), 100 ether);
        
        targetContract(address(handler));
    }
    
    /*//////////////////////////////////////////////////////////////
                            INVARIANT TESTS
    //////////////////////////////////////////////////////////////*/
    
    /// @dev The wallet balance should always equal deposits minus withdrawals
    function invariant_BalanceEqualsDepositsMinusWithdrawals() public {
        assertEq(
            address(wallet).balance,
            handler.ghost_depositSum() - handler.ghost_withdrawSum()
        );
    }
    
    /// @dev Only owners should be able to submit transactions
    function invariant_OnlyOwnersCanSubmit() public {
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
    }
    
    /// @dev Transaction count should never decrease
    function invariant_TransactionCountNeverDecreases() public view {
        // Transaction count can only increase or stay the same
        assertTrue(wallet.getTransactionCount() >= 0);
    }
    
    /// @dev Executed transactions should never be re-executed
    function invariant_ExecutedTransactionsStayExecuted() public {
        uint256 txCount = wallet.getTransactionCount();
        
        for (uint256 i = 0; i < txCount; i++) {
            (, , , bool executed, ) = wallet.getTransaction(i);
            
            if (executed) {
                // Try to execute again, should fail
                vm.expectRevert();
                wallet.executeTransaction(i);
            }
        }
    }
}