// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract DeployMultiSigWallet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Define owners - CHANGE THESE TO YOUR ACTUAL ADDRESSES
        address[] memory owners = new address[](3);
        owners[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Owner 1
        owners[1] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // Owner 2
        owners[2] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // Owner 3
        
        uint256 requiredConfirmations = 2;
        
        vm.startBroadcast(deployerPrivateKey);
        
        MultiSigWallet wallet = new MultiSigWallet(owners, requiredConfirmations);
        
        vm.stopBroadcast();
        
        console.log("MultiSigWallet deployed at:", address(wallet));
        console.log("Owners:");
        for (uint256 i = 0; i < owners.length; i++) {
            console.log("  -", owners[i]);
        }
        console.log("Required confirmations:", requiredConfirmations);
    }
}