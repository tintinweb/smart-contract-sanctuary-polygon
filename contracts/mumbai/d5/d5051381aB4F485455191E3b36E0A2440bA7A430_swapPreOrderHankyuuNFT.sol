import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./abstract/BaseRelayRecipient.sol";
import "./interface/IHankyuuNFT.sol";
import "./interface/IHankyuuPreOrderNFT.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

contract swapPreOrderHankyuuNFT is BaseRelayRecipient, ReentrancyGuard {
    address public immutable HankyuuNFT;
    address public immutable HankyuuPONFT;

    event claimedPreOrder(
        uint256 indexed poId,
        uint256 indexed tokenId
    );

    constructor(
        address forwarder,
        address nft,
        address ponft
    ) {
        require(
            IHankyuuNFT(nft).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "swapPreOrderHankyuuNFT : This address is not NFT!"
        );
        require(
            IHankyuuPreOrderNFT(ponft).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "swapPreOrderHankyuuNFT : This address is not NFT!"
        );

        HankyuuNFT = nft;
        HankyuuPONFT = ponft;
        _setTrustedForwarder(forwarder);
    }

    function setTrustedForwarder(address forwarder) external {
        require(
            _msgSender() == IHankyuuNFT(HankyuuNFT).owner(),
            "swapPreOrderHankyuuNFT : Only NFT owner allowed!"
        );
        _setTrustedForwarder(forwarder);
    }

    function swapPreOrderNftToRealNft(
        uint256 nftPreOrderId
    ) external nonReentrant {
        IHankyuuPreOrderNFT.preOrderInfo memory data = IHankyuuPreOrderNFT(
            HankyuuPONFT
        ).preOrderData(nftPreOrderId);

        require(
            data.claimed == false,
            "swapPreOrderHankyuuNFT : already claimed !"
        );
        require(
            IHankyuuPreOrderNFT(HankyuuPONFT).exists(nftPreOrderId) == true,
            "swapPreOrderHankyuuNFT : this nft already burned !"
        );
        require(
            IHankyuuNFT(HankyuuNFT).eventRoles(data.eventId).released == true,
            "swapPreOrderHankyuuNFT : Please wait until released !"
        );

        IHankyuuPreOrderNFT(HankyuuPONFT).burn(nftPreOrderId);
        IHankyuuNFT(HankyuuNFT).mint(_msgSender(), data.eventId, data.tokenId);

        emit claimedPreOrder(
            nftPreOrderId,
            data.tokenId
        );
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

interface IHankyuuNFT {
    struct eventTokenRules {
        bool released;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 currentTokenId;
    }

    function approve (address to, uint256 tokenId) external;
    function balanceOf (address owner) external view returns (uint256);
    function burn (uint256 tokenId) external;
    function createEvent (uint8 typeOfEvent, uint256 startIdNft, uint256 endIdNft) external;
    function releaseEvent(uint256 eventId) external;
    function eventRoles (uint256 eventId) external view returns (eventTokenRules memory);
    function exists (uint256 tokenId) external view returns (bool);
    function getApproved (uint256 tokenId) external view returns (address);
    function isApprovedForAll (address owner, address operator) external view returns (bool);
    function isTrustedForwarder (address forwarder) external view returns (bool);
    function istrustedMinter (address minter) external view returns (bool);
    function mint (address target, uint256 eventId, uint256 targetId) external;
    function mintEvent (address target, uint256 eventId) external;
    function name () external view returns (string memory);
    function owner () external view returns (address);
    function ownerOf (uint256 tokenId) external view returns (address);
    function renounceOwnership () external;
    function royaltyInfo (uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
    function safeTransferFrom (address from, address to, uint256 tokenId) external;
    function safeTransferFrom (address from, address to, uint256 tokenId, bytes calldata _data) external;
    function setApprovalForAll (address operator, bool approved) external;
    function setTrustedForwarder (address forwarder) external;
    function setTrustedMinter (address minter, bool trust) external;
    function supportsInterface (bytes4 interfaceId) external view returns (bool);
    function symbol () external view returns (string memory);
    function tokenEvent (uint256 tokenId) external view returns (uint256);
    function tokenURI (uint256 tokenId) external view returns (string memory);
    function totalEvent () external view returns (uint256);
    function totalSupply () external view returns (uint256);
    function transferFrom (address from, address to, uint256 tokenId) external;
    function transferOwnership (address newOwner) external;
    function trustedForwarder () external view returns (address);
    function updateMetadataURI (string memory newUri) external;
    function updateRoyaltyReceiver (address target) external;
    function versionRecipient () external view returns (string memory);
}

import "./IRelayRecipient.sol";

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract BaseRelayRecipient is IRelayRecipient {
    address private _trustedForwarder;
        string public override versionRecipient = "2.2.0";

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

interface IHankyuuPreOrderNFT {
    struct preOrderInfo {
        bool claimed;
        uint256 eventId;
        uint256 tokenId;
    }

    function HankyuuNFT () external view returns (address);
    function ownerNft() external view returns(address);
    function approve (address to, uint256 tokenId) external;
    function balanceOf (address owner) external view returns (uint256);
    function burn (uint256 tokenId) external;
    function exists (uint256 tokenId) external view returns (bool);
    function getApproved (uint256 tokenId) external view returns (address);
    function isApprovedForAll (address owner, address operator) external view returns (bool);
    function isTrustedForwarder (address forwarder) external view returns (bool);
    function istrustedMinter (address minter) external view returns (bool);
    function mint (address target, uint256 eventId, uint256 targetId) external;
    function name () external view returns (string memory);
    function ownerOf (uint256 tokenId) external view returns (address);
    function preOrderData (uint256 tokenPOID) external view returns (preOrderInfo memory);
    function safeTransferFrom (address from, address to, uint256 tokenId) external;
    function safeTransferFrom (address from, address to, uint256 tokenId, bytes calldata _data) external;
    function setApprovalForAll (address operator, bool approved) external;
    function setTrustedForwarder (address forwarder) external;
    function setTrustedMinter (address minter, bool trust) external;
    function supportsInterface (bytes4 interfaceId) external view returns (bool);
    function symbol () external view returns (string memory);
    function tokenURI (uint256 tokenId) external view returns (string memory);
    function totalSupply () external view returns (uint256);
    function transferFrom (address from, address to, uint256 tokenId) external;
    function trustedForwarder () external view returns (address);
    function updateMetadataURI (string memory newUri) external;
    function versionRecipient () external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: none

pragma solidity ^0.8.0;

abstract contract IRelayRecipient {
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    function _msgSender() internal virtual view returns (address);

    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
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