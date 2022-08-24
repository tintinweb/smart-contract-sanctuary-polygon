/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

library HashTransaction {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant CREATE_AUCTION_TYPEHASH = keccak256("CreateAuction(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant CREATE_SALE_TYPEHASH = keccak256("CreateSale(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant WITHDRAW_AUCTION_TYPEHASH = keccak256("WithdrawAuction(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant UPDATE_WHITELISTED_BUYER_TYPEHASH = keccak256("UpdateWhitelistedBuyer(address nftContractAddress,uint256 tokenId,address newWhitelistedBuyer,address user,uint256 nonce)");
    bytes32 private constant UPDATE_MINIMUM_PRICE_TYPEHASH = keccak256("UpdateMinimumPrice(address nftContractAddress,uint256 tokenId,uint128 newMinPrice,address user,uint256 nonce)");
    bytes32 private constant UPDATE_BUY_NOW_PRICE_TYPEHASH = keccak256("UpdateBuyNowPrice(address nftContractAddress,uint256 tokenId,uint128 newBuyNowPrice,address user,uint256 nonce)");
    bytes32 private constant TAKE_HIGHEST_BID_TYPEHASH = keccak256("TakeHighestBid(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant TAKE_OFFER_TYPEHASH = keccak256("TakeOffer(address nftContractAddress,uint256 tokenId,address bidder,address user,uint256 nonce)");
    uint256 constant chainId = 137;

    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Lensport Marketplace Domain")),    // name
                keccak256(bytes("1")),                              // version
                chainId,
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function hashCreateAuctionTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(CREATE_AUCTION_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashCreateSaleTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(CREATE_SALE_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashWithdrawAuctionTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(WITHDRAW_AUCTION_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashUpdateWhitelistedBuyerTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address newWhitelistedBuyer, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_WHITELISTED_BUYER_TYPEHASH, nftContractAddress, tokenId, newWhitelistedBuyer, user, nonce))));
    }

    function hashUpdateMinimumPriceTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, uint128 newMinPrice, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_MINIMUM_PRICE_TYPEHASH, nftContractAddress, tokenId, newMinPrice, user, nonce))));
    }

    function hashUpdateBuyNowPriceTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, uint128 newBuyNowPrice, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_BUY_NOW_PRICE_TYPEHASH, nftContractAddress, tokenId, newBuyNowPrice, user, nonce))));
    }

    function hashTakeHighestBidTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(TAKE_HIGHEST_BID_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashTakeOfferTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address bidder, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(TAKE_OFFER_TYPEHASH, nftContractAddress, tokenId, bidder, user, nonce))));
    }

}