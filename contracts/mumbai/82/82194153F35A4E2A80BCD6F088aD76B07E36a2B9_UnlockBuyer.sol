// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IUnlock {
    function purchase(
        uint256[] memory _values,
        address[] memory _recipients,
        address[] memory _referrers,
        address[] memory _keyManagers,
        bytes[] calldata _data
    ) external payable returns (uint[] memory);
}

contract UnlockBuyer {
    uint public unlockTime;
    address payable public owner;
    uint256 public price = 0.05 ether;
    
    event Purchase(address buyer, uint256 price, uint[] tokenIds);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function purchase(address _lockAddress, uint256 _value, address _to) external payable {
        require(msg.value >= price, "Insufficient funds");
        require(_value >= price, "_value argument must match price");

        uint[] memory tokenIds;

        uint[] memory values = new uint[](1);
        values[0] = _value;

        address[] memory recipients = new address[](1);
        recipients[0] = _to;

        address[] memory referrers = new address[](1);
        referrers[0] = address(0x6C3b3225759Cbda68F96378A9F0277B4374f9F06);

        address[] memory keyManagers = new address[](1);
        keyManagers[0] = address(0);

        bool success;
        try IUnlock(_lockAddress).purchase{value: msg.value}(
            values, //50000000000000000
            recipients,
            referrers,
            keyManagers,
            new bytes[](1)
        ) returns (uint[] memory _tokenIds) {
            tokenIds = _tokenIds;
            success = true;
        } catch {
            success = false;
        }

        require(success, "Minting NFT failed");

        // Emit event to indicate successful purchase
        emit Purchase(msg.sender, price, tokenIds);
    }

    function withdraw() public {
        require(msg.sender == owner, "You aren't the owner");

        owner.transfer(address(this).balance);
    }
}