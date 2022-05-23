// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TokensTracker {
    address[] tokens;
    event AddAddress(address _tokenAddress);

    function getAddresses() public view returns (address[] memory) {
        return tokens;
    }

    function addAddress(address _tokenAddress) public {
        emit AddAddress(_tokenAddress);
        tokens.push(_tokenAddress);
    }
}