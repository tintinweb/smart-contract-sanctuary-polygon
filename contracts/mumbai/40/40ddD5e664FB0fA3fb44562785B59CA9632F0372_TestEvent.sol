pragma solidity ^0.8.9;

contract TestEvent {

    event NFT_LISTED(address sender, uint256 count);
    event NFT_UNLISTED(address sender);

    function list(uint256 count) external{
        emit NFT_LISTED(msg.sender, count);
    }

    function unlist() external{
        emit NFT_UNLISTED(msg.sender);
    }
}