// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// 0x1d47ba0c3e0f1544549ea3b92c3b2ce3de6aaa6a
interface AlterBodyInterFace {
    function CheckAvatarCreator(uint256) external returns (address);
}

contract AlterOS_new is Ownable, ReentrancyGuard {
    using Address for address;
    address public contractOwner;
    uint256 private _marketplaceFee;
    uint256[] private _openListings;
    // uint256[] private _listedTokens;
    uint256 private _listingId = 1;
    uint256 private _contractID = 1;
    address[] private NFTCollectionContracts;

    enum State {
        INITIATED,
        SOLD,
        CANCELLED
    }

    struct Listing {
        uint256 listingId;
        bool isErc721;
        State state;
        address nftAddress;
        address seller;
        address creator;
        address erc20Address;
        uint256[] tokenIds;
        uint256 amount;
        uint256 price;
        address buyer;
    }

    mapping(uint256 => Listing) public _listings;

    mapping(uint256 => bool) private _listedTokens;

    struct AllowedContractsList {
        address contractAddress;
        string contractName;
        address creatorAdress;
        bool isValid;
    }

    mapping(uint256 => AllowedContractsList) public _collectionContracts;

    /**
     * @dev Emitted when new listing is created by the owner of the contract. Amount is valid only for ERC-1155 tokens
     */
    event ListingCreated(
        bool isErc721,
        address indexed seller,
        address indexed creator,
        address indexed nftAddress,
        uint256[] tokenIds,
        uint256 listingId,
        uint256 amount,
        uint256 price,
        address erc20Address,
        uint256 updatedTimeStamp
    );

    event AllowedContractsAdded(
        address indexed contractAddress,
        string contractName,
        address indexed creatorAdress
    );

    /**
     * @dev Emitted when listing assets were sold.
     */
    event ListingSold(
        address indexed buyer,
        uint256 indexed listingId,
        uint256 updatedTimeStamp
    );

    /**
     * @dev Emitted when listing was cancelled and assets were returned to the seller.
     */
    event ListingCancelled(uint256 indexed listingId, uint256 updatedTimeStamp);

    event ListingPriceUpdation(
        uint256 indexed listingId,
        uint256 price,
        uint256 updatedTimeStamp
    );

    constructor(uint256 _feePercent) {
        _marketplaceFee = _feePercent;
        contractOwner = msg.sender;
    }

    function getMarketplaceFee() public view virtual returns (uint256) {
        return _marketplaceFee;
    }

    function getListing(uint256 listingId)
        public
        view
        virtual
        returns (Listing memory)
    {
        return _listings[listingId];
    }

    function getOpenListings() public view virtual returns (uint256[] memory) {
        return _openListings;
    }

    function setMarketplaceFee(uint256 fee) public virtual onlyOwner {
        _marketplaceFee = fee;
    }

    function addAcceptableContracts(
        address contractAddress,
        string memory contractName,
        address creatorAdress
    ) public virtual nonReentrant {
        if (
            keccak256(
                abi.encodePacked(
                    _collectionContracts[_contractID].contractAddress
                )
            ) == keccak256(abi.encodePacked(contractAddress))
        ) {
            revert("Contract address already added");
        }

        AllowedContractsList memory contractsAddresses = AllowedContractsList(
            contractAddress,
            contractName,
            creatorAdress,
            true
        );
        _collectionContracts[_contractID] = contractsAddresses;

        NFTCollectionContracts.push(contractAddress);

        emit AllowedContractsAdded(
            contractAddress,
            contractName,
            creatorAdress
        );

        _contractID++;
    }

    /*
     * @operation Create new listing of the NFT token in the marketplace.
     * @param listingId - ID of the listing, must be unique
     * @param isErc721 - whether the listing is for ERC721 or ERC1155 token
     * @param nftAddress - address of the NFT token
     * @param tokenId - ID of the NFT token
     * @param price - Price for the token. It could be in wei or smallest ERC20 value, if @param erc20Address is not 0x0 address
     * @param amount - ERC1155 only, number of tokens to sold.
     * @param erc20Address - address of the ERC20 token, which will be used for the payment. If native asset is used, this should be 0x0 address
     */

    function createListing(
        bool isErc721,
        address nftAddress,
        uint256[] memory tokenIds,
        uint256 price,
        address seller,
        uint256 amount,
        address erc20Address
    ) public payable nonReentrant {
        // if (
        //   keccak256(abi.encodePacked(_listings[_listingId].listingId)) ==
        //   keccak256(abi.encodePacked(_listingId))
        // ) {
        //   revert("Listing already existed for current listing Id");
        // }
        require(
            keccak256(abi.encodePacked(_listings[_listingId].listingId)) !=
                keccak256(abi.encodePacked(_listingId)),
            "Listing already existed for current listing Id"
        );
        for (uint256 i; i < tokenIds.length; ) {
            require(
                _listedTokens[tokenIds[i]] != true,
                "Token is already listed"
            );
        }
        if (!isErc721) {
            require(amount > 0);
            for (uint256 i; i < tokenIds.length; ) {
                require(
                    IERC1155(nftAddress).balanceOf(seller, tokenIds[i]) >=
                        amount,
                    "ERC1155 token balance is not sufficient for the seller.."
                );
                unchecked {
                    i++;
                }
            }
        } else {
            for (uint256 i; i < tokenIds.length; ) {
                require(
                    IERC721(nftAddress).ownerOf(tokenIds[i]) == seller,
                    "ERC721 token does not belong to the author."
                );
                unchecked {
                    i++;
                }
            }
        }
        address _creator = AlterBodyInterFace(nftAddress).CheckAvatarCreator(
            tokenIds[0]
        );

        Listing memory listing = Listing(
            _listingId,
            isErc721,
            State.INITIATED,
            nftAddress,
            seller,
            _creator,
            erc20Address,
            tokenIds,
            amount,
            price,
            address(0)
        );
        _listings[_listingId] = listing;
        _openListings.push(_listingId);
        for (uint256 i; i < tokenIds.length; ) {
            _listedTokens[tokenIds[i]] = true;
        }
        emit ListingCreated(
            isErc721,
            seller,
            _creator,
            nftAddress,
            tokenIds,
            _listingId,
            amount,
            price,
            erc20Address,
            block.timestamp
        );
        _listingId++;
    }

    /*
     * @operation Buyer wants to buy NFT from listing. All the required checks must pass.
     * Buyer must either send MATIC with this endpoint, or ERC20 tokens will be deducted from his account to the marketplace contract.
     * @param listingId - id of the listing to buy
     * @param erc20Address - optional address of the ERC20 token to pay for the assets, if listing is listed in ERC20
     */
    function buyAssetFromListing(uint256 listingId, address erc20Address)
        public
        payable
        nonReentrant
    {
        Listing memory listing = _listings[listingId];
        // if (listing.state != State.INITIATED) {
        //   // if (msg.value > 0) {
        //   //   Address.sendValue(payable(msg.sender), msg.value);
        //   // }
        //   revert("Listing is in wrong state. Aborting.");
        // }
        require(
            listing.state == State.INITIATED,
            "Listing is in wrong state. Aborting."
        );

        if (listing.isErc721) {
            for (uint256 i; i < listing.tokenIds.length; ) {
                if (
                    IERC721(listing.nftAddress).getApproved(
                        listing.tokenIds[i]
                    ) != address(this)
                ) {
                    // if (msg.value > 0) {
                    //   Address.sendValue(payable(msg.sender), msg.value);
                    // }
                    revert(
                        "Asset is not owned by this listing. Probably was not sent to the smart contract, or was already sold."
                    );
                }
                unchecked {
                    i++;
                }
            }
        } else {
            for (uint256 i; i < listing.tokenIds.length; ) {
                if (
                    IERC1155(listing.nftAddress).balanceOf(
                        listing.seller,
                        listing.tokenIds[i]
                    ) < listing.amount
                ) {
                    // if (msg.value > 0) {
                    //   Address.sendValue(payable(msg.sender), msg.value);
                    // }
                    revert(
                        "Insufficient balance of the asset in this listing. Probably was not sent to the smart contract, or was already sold."
                    );
                }
                unchecked {
                    i++;
                }
            }
        }
        if (listing.erc20Address != erc20Address) {
            // if (msg.value > 0) {
            //   Address.sendValue(payable(msg.sender), msg.value);
            // }
            revert(
                "ERC20 token address as a payer method should be the same as in the listing. Either listing, or method call has wrong ERC20 address."
            );
        }
        uint256 fee = listing.price *
            ((_marketplaceFee / 1000000000000000000) / 100);
        listing.state = State.SOLD;
        listing.buyer = msg.sender;
        _listings[listingId] = listing;
        uint256[] memory tokenIds = listing.tokenIds;
        for (uint256 i; i < tokenIds.length; ) {
            _listedTokens[tokenIds[i]] = false;
        }
        if (listing.erc20Address == address(0)) {
            if (listing.price + fee > msg.value) {
                // if (msg.value > 0) {
                //   Address.sendValue(payable(msg.sender), msg.value);
                // }
                revert("Insufficient price paid for the asset.");
            }
            Address.sendValue(payable(address(this)), fee);
            Address.sendValue(payable(listing.seller), listing.price);
            // Overpaid price is returned back to the sender
            if (msg.value - listing.price - fee > 0) {
                Address.sendValue(
                    payable(msg.sender),
                    msg.value - listing.price - fee
                );
            }
            if (listing.isErc721) {
                for (uint256 i; i < listing.tokenIds.length; ) {
                    IERC721(listing.nftAddress).safeTransferFrom(
                        listing.seller,
                        msg.sender,
                        listing.tokenIds[i],
                        abi.encodePacked(
                            "SafeTransferFrom",
                            "'''###'''",
                            _uint2str(listing.price)
                        )
                    );
                    unchecked {
                        i++;
                    }
                }
            } else {
                for (uint256 i; i < listing.tokenIds.length; ) {
                    IERC1155(listing.nftAddress).safeTransferFrom(
                        listing.seller,
                        msg.sender,
                        listing.tokenIds[i],
                        listing.amount,
                        ""
                    );
                    unchecked {
                        i++;
                    }
                }
            }
        } else {
            IERC20 token = IERC20(listing.erc20Address);
            if (
                listing.price + fee > token.allowance(msg.sender, address(this))
            ) {
                // if (msg.value > 0) {
                //   Address.sendValue(payable(msg.sender), msg.value);
                // }
                revert(
                    "Insufficient ERC20 allowance balance for paying for the asset."
                );
            }
            token.transferFrom(msg.sender, address(this), fee);
            token.transferFrom(msg.sender, listing.seller, listing.price);
            // if (msg.value > 0) {
            //   Address.sendValue(payable(msg.sender), msg.value);
            // }
            if (listing.isErc721) {
                bytes memory bytesInput = abi.encodePacked(
                    "CUSTOMTOKEN0x",
                    _toAsciiString(listing.erc20Address),
                    "'''###'''",
                    _uint2str(listing.price)
                );
                for (uint256 i; i < listing.tokenIds.length; ) {
                    IERC721(listing.nftAddress).safeTransferFrom(
                        listing.seller,
                        msg.sender,
                        listing.tokenIds[i],
                        bytesInput
                    );
                    unchecked {
                        i++;
                    }
                }
            } else {
                for (uint256 i; i < listing.tokenIds.length; ) {
                    IERC1155(listing.nftAddress).safeTransferFrom(
                        listing.seller,
                        msg.sender,
                        listing.tokenIds[i],
                        listing.amount,
                        ""
                    );
                    unchecked {
                        i++;
                    }
                }
            }
        }
        _toRemove(listingId);
        emit ListingSold(msg.sender, listingId, block.timestamp);
    }

    function cancelListing(uint256 listingId) public virtual nonReentrant {
        Listing memory listing = _listings[listingId];
        require(
            listing.state == State.INITIATED,
            "Listing is not in INITIATED state. Aborting."
        );
        require(
            listing.seller == msg.sender || msg.sender == owner(),
            "Listing can't be cancelled from other then seller or owner. Aborting."
        );
        listing.state = State.CANCELLED;
        _listings[listingId] = listing;
        uint256[] memory tokenIds = listing.tokenIds;
        for (uint256 i; i < tokenIds.length; ) {
            _listedTokens[tokenIds[i]] = false;
        }
        _toRemove(listingId);
        emit ListingCancelled(listingId, block.timestamp);
    }

    function updateListingPrice(uint256 listingId, uint256 _price)
        public
        virtual
        nonReentrant
    {
        Listing memory listing = _listings[listingId];
        require(
            listing.state == State.INITIATED,
            "Listing is not in INITIATED state. Aborting."
        );
        require(
            listing.seller == msg.sender || msg.sender == owner(),
            "Listing can't be modified from other then seller or owner. Aborting."
        );
        listing.price = _price;
        _listings[listingId] = listing;
        emit ListingPriceUpdation(listingId, _price, block.timestamp);
    }

    function _toRemove(uint256 listingId) internal {
        for (uint256 x = 0; x < _openListings.length; x++) {
            if (
                keccak256(abi.encodePacked(_openListings[x])) ==
                keccak256(abi.encodePacked(listingId))
            ) {
                for (uint256 i = x; i < _openListings.length - 1; i++) {
                    _openListings[i] = _openListings[i + 1];
                }
                _openListings.pop();
            }
        }
    }

    function _toAsciiString(address x) internal pure returns (bytes memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return s;
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}