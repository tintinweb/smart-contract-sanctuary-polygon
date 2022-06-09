/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

pragma solidity ^0.8.0;
contract EventUnLockTest {
    event Unlock(address userAddress, address nftAddress, uint tokenId);
    function unlockTokens(address userAddress, address nftAddress, uint tokenId) external {
        emit Unlock(userAddress, nftAddress, tokenId);
    }
}