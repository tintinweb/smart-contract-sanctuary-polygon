// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract mockVaults {
    struct Vault {
        uint index;
        uint apy;
    }
    Vault[] public vaults;
    constructor (){
        for(uint i=0; i<100; i++) {
            vaults.push(Vault(i, 100));
        }
    }
    function getVaults() public view returns(Vault[] memory) {
        return vaults;
    }
}