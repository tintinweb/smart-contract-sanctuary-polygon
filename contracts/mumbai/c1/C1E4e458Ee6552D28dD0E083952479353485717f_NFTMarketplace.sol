// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IOneForge.sol";

contract NFTMarketplace {
    IERC721 private immutable mintNft;
    IERC20 private immutable ogtToken;
    IOneForge private immutable oneForge;

    uint256 public itemId;

    struct SaleNFT {
        uint256 tokenId;
        uint256 price;
        uint256 length;
        address sellerAddr;
    }

    mapping(uint256 => SaleNFT) public saleNFTItem;

    event BuyNFT(
        address indexed userAddr,
        address indexed sellerAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event SellNFT(
        uint256 id,
        uint256 indexed tokenId,
        uint256 price,
        address indexed sellerAddress
    );
    event SellNFTForFloatPrice(
        uint256 id,
        uint256 indexed tokenId,
        uint256 price,
        address indexed sellerAddress
    );
    event RemoveNFT(uint256 indexed tokenId);

    event ChangeFloatPrice(
        uint256 indexed tokenId,
        uint256 indexed id,
        uint256 changedPrice
    );

    constructor(
        IERC721 _nft,
        IERC20 _token,
        IOneForge _forge
    ) {
        mintNft = _nft;
        ogtToken = _token;
        oneForge = _forge;
    }

    /**
     *@dev User will able to buy NFT
     * Requirements:
     * -msg.sender cannot be zero address & seller address.
     * Emit a {BuyNFT} event.
     */
    function buyNFTItem(uint256 _id) external payable {
        SaleNFT memory saleNft = saleNFTItem[_id];

        require(msg.sender != address(0), "Cannot buy to zero address");
        require(msg.sender != saleNft.sellerAddr, "Seller cannot buy");
        require(msg.value >= saleNft.price, "Not enough funds");

        address payable sellerAddress = payable(saleNft.sellerAddr);
        uint256 tokenId = saleNft.tokenId;
        uint256 idLength = saleNft.length;
        uint256 refundPrice = msg.value - saleNft.price;
        emit BuyNFT(msg.sender, saleNft.sellerAddr, tokenId, saleNft.price);

        delete saleNFTItem[_id];
        payable(sellerAddress).transfer(saleNft.price);
        payable(msg.sender).transfer(refundPrice);

        if (idLength == 1) {
            mintNft.safeTransferFrom(sellerAddress, msg.sender, tokenId);
        } else {
            oneForge.setLinkedListOwner(tokenId, msg.sender);
        }
    }

    /**
     *@dev Only seller can remove nft from sell.
     *Emits a {RemoveNFT} event.
     */
    function removeNFTFromSell(uint256 _itemId) external {
        SaleNFT memory saleNft = saleNFTItem[_itemId];
        require(
            msg.sender == saleNft.sellerAddr,
            "Only seller can remove nft from sell"
        );

        emit RemoveNFT(saleNft.tokenId);
        delete saleNFTItem[_itemId];
    }

    /**
    *@dev sell nft for fixed price
    *@param _tokenId uint256 to put single nft on sell _tokenId is between 2653 to 132650
     - to put merge list on sell _tokenId should be greater than 140000
    *@param _price uint256 price of the nft (price in wei).
    */
    function sellNFTItem(uint256 _tokenId, uint256 _price) external {
        uint256 len;
        uint256 listSize = oneForge.sizeOfList(_tokenId);
        address ownerOfList = oneForge.listIdOwner(_tokenId);

        if (2653 <= _tokenId && _tokenId <= 132650) {
            require(
                msg.sender == mintNft.ownerOf(_tokenId),
                "Not called by owner"
            );
            len = 1;
        } else if (_tokenId >= 140000) {
            require(listSize != 0, "Not contain any data");
            require(msg.sender == ownerOfList, "Not owned NFT");
            len = listSize;
        }
        _sellFixed(_tokenId, _price, len);
    }

    /**
    *@dev sell nft for float price
    *@param _tokenId uint256 to put single nft on sell _tokenId is between 2653 to 132650
     - to put merge list on sell _tokenId should be greater than 140000
    *@param _premiumValue uint256 premium value between 1000 to 10000.
    *@param _floatPrice uint256 price of nft.
     */
    function sellNFTItemForFloatPrice(
        uint256 _tokenId,
        uint256 _premiumValue,
        uint256 _floatPrice
    ) external {
        uint256 len;
        uint256 listSize = oneForge.sizeOfList(_tokenId);
        address ownerOfList = oneForge.listIdOwner(_tokenId);

        if (2653 <= _tokenId && _tokenId <= 132650) {
            require(
                msg.sender == mintNft.ownerOf(_tokenId),
                "Not called by owner"
            );
            len = 1;
        } else if (_tokenId >= 140000) {
            require(listSize != 0, "Not contain any data");
            require(msg.sender == ownerOfList, "Not owned NFT");
            len = listSize;
        }
        _sellFloat(_tokenId, _premiumValue, len, _floatPrice);
    }

    /**
     *@dev to change price of nft.
     *Emits a {ChangeFloatPrice} event.
     */
    function changeFloatPrice(
        uint256 premiumNo,
        uint256 _id,
        uint256 floatPrice
    ) external returns (uint256) {
        require(
            premiumNo >= 10,
            "Premimum value must be greater than equal to 10"
        );
        require(
            premiumNo <= 100,
            "Premimum value must be less than equal to 100"
        );
        require(
            msg.sender == saleNFTItem[_id].sellerAddr,
            "Only seller allow to change price"
        );
        SaleNFT storage saleNFT = saleNFTItem[_id];

        uint256 premium = (floatPrice * premiumNo) / 100;
        uint256 _price = floatPrice + premium;

        saleNFT.price = _price;

        emit ChangeFloatPrice(saleNFT.tokenId, _id, _price);
        return _price;
    }

    function _sellFixed(
        uint256 _tokenId,
        uint256 price_,
        uint256 sizeOfToken
    ) internal {
        itemId++;
        SaleNFT storage saleNft = saleNFTItem[itemId];

        saleNft.tokenId = _tokenId;
        saleNft.price = price_;
        saleNft.sellerAddr = msg.sender;
        saleNft.length = sizeOfToken;

        emit SellNFT(itemId, _tokenId, price_, msg.sender);
    }

    function _sellFloat(
        uint256 _tokenId,
        uint256 _premiumValue,
        uint256 _sizeOfToken,
        uint256 _floatPrice
    ) internal {
        require(
            _premiumValue >= 10,
            "Premimum value must be greater than equal to 10"
        );
        require(
            _premiumValue <= 100,
            "Premimum value must be less than equal to 100"
        );
        itemId++;

        uint256 premium = (_floatPrice * _premiumValue) / 100;
        uint256 priceFloat = _floatPrice + premium;

        SaleNFT storage saleNFT = saleNFTItem[itemId];

        saleNFT.tokenId = _tokenId;
        saleNFT.price = priceFloat;
        saleNFT.sellerAddr = msg.sender;
        saleNFT.length = _sizeOfToken;

        emit SellNFTForFloatPrice(itemId, _tokenId, priceFloat, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOneForge {
    function sizeOfList(uint256 _id) external view returns (uint256);

    function setLinkedListOwner(uint256 _listId, address user) external;

    function listIdOwner(uint256 id) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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