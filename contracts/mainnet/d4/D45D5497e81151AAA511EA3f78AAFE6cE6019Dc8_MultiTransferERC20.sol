/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

pragma solidity ^0.8.0;

interface ITransferFrom {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract MultiTransferERC20 {
    ITransferFrom public glm;

    constructor(ITransferFrom _glm) public {
        glm = _glm;
    }

    // A new version of batchTransfer inspired by GolemNetworkTokenBatching.sol
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Incompatible array lengths");
        require(recipients.length > 0, "Empty list of payments");

        for (uint i = 0; i < recipients.length; ++i) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            require(glm.transferFrom(msg.sender, recipient, amount), "TransferFrom unsuccessfull");
        }
    }
}