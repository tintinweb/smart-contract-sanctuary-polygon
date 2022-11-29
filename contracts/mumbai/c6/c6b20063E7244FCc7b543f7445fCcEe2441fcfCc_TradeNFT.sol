// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ICrossTower1155{
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}


contract TradeNFT is ReentrancyGuard{
    ICrossTower1155 public nft1155;
     
    event NFTBought(
        uint256 indexed TokenId,
        uint256 indexed NumOfEditions,
        uint256 indexed perEditionPrice,
        address PurchasedFrom,
        address PurchasedFor);

    constructor(address _nftAddress )  {
        nft1155 = ICrossTower1155(_nftAddress);
    }

    function buyNFT(
        uint256 _tokenId, address _from, address _to, uint256 _numOfEditions, uint256 _perEditionPrice)
        nonReentrant external payable 
    {
        require(nft1155.balanceOf(_from, _tokenId) >= _numOfEditions, "NFT Amount exceeds NFT Balance");
        require(msg.value >= _perEditionPrice * _numOfEditions, "Insuffient Fee Paid");

        //Calculate Royalty Fee and Asset Fee
        (address royaltyAddress, uint256 royaltyFeePerEdition) = nft1155.royaltyInfo(_tokenId, _perEditionPrice);
        uint256 royaltyFee = royaltyFeePerEdition * _numOfEditions;
        uint256 assetFee = msg.value - royaltyFee ;

        // Transfer Fees
        (bool sentAssetFee, ) = _from.call{value: assetFee}("");
        require(sentAssetFee, "Failed to send AssetFee");

        (bool sentRoyaltyfee, ) = royaltyAddress.call{value: royaltyFee}("");
        require(sentRoyaltyfee, "Failed to send Royaltyfee");

        // Transfer NFT
        nft1155.safeTransferFrom(_from, _to, _tokenId, _numOfEditions, "0x");

        emit NFTBought(_tokenId, _numOfEditions, _perEditionPrice, _from, _to);
    }
}