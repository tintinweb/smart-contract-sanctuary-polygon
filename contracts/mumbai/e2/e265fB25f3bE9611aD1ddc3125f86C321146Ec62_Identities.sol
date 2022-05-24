// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IdentityFactory.sol";

contract Identities {
    function createNewIdentity(address[] memory _owners, uint256[] memory _equities) public returns (address) {
        IdentityFactory identity = new IdentityFactory(_owners, _equities);

        return address(identity);
    }
}