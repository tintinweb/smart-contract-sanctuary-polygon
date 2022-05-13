// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.11;

interface IERC165 {

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
    */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
*/

interface IERC721 is IERC165 {

    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);


    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */

    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
  

interface ITransferProxy {

    function erc721safeTransferFrom(IERC721 nftAddress, address from, address to, uint256 tokenId) external;
    
    function erc20safeTransferFrom(IERC20 nftAddress, address from, address to, uint256 value) external;
    
    function removeFromPack(address nftAddress, uint256[] calldata tokenIds) external;

}

contract Trade {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset(address indexed assetOwner, uint[]  tokenId, address indexed buyer);
    event ExecuteBid(address indexed assetOwner, uint[] tokenId, address indexed buyer);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    ITransferProxy public transferProxy;
    address public owner;
    mapping(uint256 => bool) private usedNonce;

    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        uint unitPrice;
        uint amount;
        uint qty;
        uint[] tokenId;
        bool isPacked;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee, ITransferProxy _transferProxy) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
    }

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns(bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns(bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function removeFromPack(address nftAddress, uint256[] calldata tokenIds) external onlyOwner {
        transferProxy.removeFromPack(nftAddress,tokenIds);
    }

    function buyAsset(Order calldata order, Sign calldata sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        if(order.isPacked) {
            transferProxy.removeFromPack(order.nftAddress, order.tokenId);
        }
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId, order.isPacked);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        bytes memory tokenIdHash = _encode(order.tokenId);
        verifySign(order.seller, tokenIdHash, order.unitPrice, order.erc20Address, order.nftAddress, order.qty, sign);        
        address buyer = msg.sender;
        tradeAsset(order.nftAddress, order.erc20Address , order.tokenId,fee, buyer, order.seller);
        emit BuyAsset(order.seller, order.tokenId, msg.sender);
        return true;
    }

    function executeBid(Order calldata order, Sign calldata sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        if(order.isPacked) {
            transferProxy.removeFromPack(order.nftAddress, order.tokenId);
        }
        Fee memory fee = getFees(order.amount, order.nftAddress, order.tokenId, order.isPacked);
        bytes memory tokenIdHash = _encode(order.tokenId);
        verifySign(order.buyer, tokenIdHash, order.unitPrice, order.erc20Address, order.nftAddress, order.qty, sign);
        address seller = msg.sender;
        tradeAsset(order.nftAddress, order.erc20Address, order.tokenId, fee, order.buyer, seller);
        emit ExecuteBid(msg.sender , order.tokenId, order.buyer);
        return true;
    }

    function getFees(uint paymentAmt, address buyingAssetAddress, uint[] calldata tokenId, bool isPacked) internal view returns(Fee memory) {
        address tokenCreator;
        uint platformFee;
        uint royalty;
        uint royaltyFee;
        uint assetFee;
        uint price = paymentAmt * 1000 / (1000 + buyerFeePermille);
        uint buyerFee = paymentAmt - price;
        uint sellerFee = price * sellerFeePermille / 1000;
        platformFee = buyerFee + sellerFee;
        for( uint256 i = 0; i < tokenId.length; i++) {
            (tokenCreator, royalty) = IERC721(buyingAssetAddress).royaltyInfo(tokenId[i], price);
            royaltyFee += royalty;
        }
        if(isPacked) {
            tokenCreator = owner;
        }
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function tradeAsset(address nftAddress, address erc20Address, uint[] calldata tokenId, Fee memory fee, address buyer, address seller) internal virtual {
        for( uint256 i = 0; i < tokenId.length; i++) {
        transferProxy.erc721safeTransferFrom(IERC721(nftAddress), seller, buyer, tokenId[i]);
        }
        if(fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(erc20Address), buyer, owner, fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(erc20Address), buyer, fee.tokenCreator, fee.royaltyFee);
        }
        transferProxy.erc20safeTransferFrom(IERC20(erc20Address), buyer, seller, fee.assetFee);
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s);
    }

    function verifySign(address signer, bytes memory tokenId, uint amount, address paymentAssetAddress, address assetAddress, uint qty, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, qty, sign.nonce));
        require(signer == getSigner(hash, sign), "buyer sign verification failed");
    }
    
    function _encode(uint256[] memory data) internal pure returns(bytes memory) {
        return  abi.encode(data);
    }
}