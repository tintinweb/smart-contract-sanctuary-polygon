/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

pragma solidity ^0.8.10;
interface marketPlace{
function _cancelOrder(address nftAddress, uint256 assetId) external ;
}
contract cancelListing {
    address _marketplace;
    constructor (address _market){
        _marketplace = _market;

    }
    function cancelOrder(address nftAddress, uint256 assetId) public {
        marketPlace(_marketplace)._cancelOrder(nftAddress , assetId);
    }
}