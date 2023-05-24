/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Vault {
    event Received(address, uint);

    address immutable public owner;

    constructor(address _owner){
        owner = _owner;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

contract VaultFactory {
    address public proxyFactory;
    address public safeImplementation;
    address public moduleImplementation;
    address public guardImplementation;

    event VaultCreated(address indexed safe, uint256, address[], address[]);

    // constructor(address _proxyFactory, address _safeImplementation, address _moduleImplementation, address _guardImplementation) {
    constructor() {
        // proxyFactory = _proxyFactory;
        // safeImplementation = _safeImplementation;
        // moduleImplementation = _moduleImplementation;
        // guardImplementation = _guardImplementation;
    }

    function createSafeWallet(address[] calldata _owners, uint256 _threshold, address[] calldata _recoverers) external {

        // address safe = 0x7EDEa359C22eB1Cc57985b28D7d57C3074Be76D0;
        address vault = address(new Vault(msg.sender));

        emit VaultCreated(vault, _threshold, _owners, _recoverers);
    }

    // function initVault(address[] calldata _recoverers) public {
    //     GnosisSafe safe = GnosisSafe(payable(address(this)));

    //     // Enable MyModule
    //     safe.enableModule(address(moduleImplementation));

    //     // Set the MyGuard as the fallback handler
    //     safe.setGuard(address(guardImplementation));
    // }
}