// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MaticAirdrop {

    address public owner = 0x7ec5849FABE1B9211f60002168434615B62Cdc1F;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR: Msg.Sender is Not Owner");
        _;
    }

    function deposit() payable external {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function distributeFunds(address[] calldata recipients) external onlyOwner {
        uint toDistribute = address(this).balance/recipients.length;

        for(uint i = 0; i < recipients.length; i++){
            (bool success, ) = recipients[i].call{value:toDistribute}("");
            require(success, "Transfer failed.");
        }
    }
}