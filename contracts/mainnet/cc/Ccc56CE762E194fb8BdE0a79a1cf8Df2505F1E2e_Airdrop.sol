// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface AirdropContract{
    function airdrop(address _to, uint256 amount) external;
}

contract Airdrop {

    address public contract_address;

    function set_address(address _address) public {
        contract_address = address(_address);
    }

    function airdrop(address[] memory addressArray) public {
        AirdropContract airdrop_contract = AirdropContract(contract_address);

        for(uint256 i=0; i < addressArray.length; i++) {
            address _to = addressArray[i];
            airdrop_contract.airdrop(_to, 1);
        }
    }
}