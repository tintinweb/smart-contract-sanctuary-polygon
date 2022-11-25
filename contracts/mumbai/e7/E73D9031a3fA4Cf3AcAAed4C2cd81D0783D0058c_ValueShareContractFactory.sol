// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./CloneFactory.sol";
import "./Ownable.sol";
import "./ValueShareContract.sol";

contract ValueShareContractFactory is Ownable, CloneFactory {
    // Mumbai Testnet addresses
    address public _erc721FactoryAddress = 0x7d46d74023507D30ccc2d3868129fbE4e400e40B; // 0x03ABAd83b9f2F182D6C9d3FA70619Abc2edc8ccC
    address public _fixedExchangeAddress = 0x25e1926E3d57eC0651e89C654AB0FA182C6D5CF7;
    address public _oceanAddress = 0xd8992Ed72C445c35Cb4A2be468568Ed1079357c8;

    event ValueShareContractCreated(address newValueShareContractAddress);

    address public valueShareContractAddress;

    constructor(address _valueShareContractAddress) {
        valueShareContractAddress = _valueShareContractAddress;
    }

    function setValueShareContractAddress(address _valueShareContractAddress) public onlyOwner {
        valueShareContractAddress = _valueShareContractAddress;
    }

    function createValueShareContract() public {
        address clone = createClone(valueShareContractAddress);
        ValueShareContract(clone).initialize(_erc721FactoryAddress, _fixedExchangeAddress, _oceanAddress, msg.sender);
        emit ValueShareContractCreated(clone);
    }
}