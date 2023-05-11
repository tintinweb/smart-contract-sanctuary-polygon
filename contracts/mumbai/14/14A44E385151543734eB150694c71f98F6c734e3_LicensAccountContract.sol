// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LicensAccountContract{
    
    mapping(address => string) public creatorCID;
    event CreatorUpdated(
        address creator,
        string creatorCID
    );

    event GasTransferred(
        uint256 maticCost
    );

    address treasuryWallet;

    constructor(address _treasuryWallet){
        treasuryWallet = _treasuryWallet;
    }


    function updateCreator(string calldata _creatorCID) external {
        uint256 gasCost = gasleft() * tx.gasprice;

        // Convert the gas cost to Matic
        uint256 maticCost = gasCost * 13 / 10 / 10**18;

        // Transfer the estimated gas cost to the recipient
        require(treasuryWallet.balance >= maticCost, "Insufficient balance to transfer gas from treasury wallet");
        (bool success, ) = payable(msg.sender).call{value: maticCost}("");
        require(success, "Transfer of MATIC failed");
        require(msg.sender.balance >= maticCost, "Insufficient balance to pay for gas");

        creatorCID[msg.sender] = _creatorCID;
        emit CreatorUpdated(msg.sender, _creatorCID);
        emit GasTransferred(maticCost);
    }
    
    function isRegistered(address _address) external view returns(bool){
        return bytes(creatorCID[_address]).length != 0;
    }
}