// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../nfts/IFrameItNFTCommons.sol";
import "../metatx/FrameItContext.sol";
import "../utils/Ownable.sol";

contract FrameItAlbum is FrameItContext, Ownable {

    struct AlbumStruct {
        mapping(uint32 => uint32[]) nfts;
        uint256 totalNFTs;
    }

    mapping(address => AlbumStruct) private fullAlbum;
    mapping(address => AlbumStruct) private commonsAlbum;
    mapping(address => AlbumStruct) private uncommonsAlbum;
    mapping(address => AlbumStruct) private raresAlbum;

    event albumPopulated(address indexed _nft, uint256 _length, address _user);
    event albumCommonsPopulated(address indexed _nft, uint256 _length, address _user);
    event albumUncommonsPopulated(address indexed _nft, uint256 _length, address _user);
    event albumRaresPopulated(address indexed _nft, uint256 _length, address _user);

    constructor(address _forwarder) FrameItContext(_forwarder) {
    }

    function populateAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external {
        require((_msgSender() == IFrameItNFTCommons(_nftContract).owner()) || (_msgSender() == owner), "BadOwner");

        for (uint256 i=_startIndex; i<_ids.length; i++) {
            for (uint32 j=0; j<_ids[i].length; j++) {
                uint32 albumId = uint32(i+1);
                fullAlbum[_nftContract].nfts[albumId].push(_ids[i][j]);
            }
        }
        fullAlbum[_nftContract].totalNFTs = _ids.length;

        emit albumPopulated(_nftContract, _ids.length, _msgSender());
    }

    function populateCommonsAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external {
        require((_msgSender() == IFrameItNFTCommons(_nftContract).owner()) || (_msgSender() == owner), "BadOwner");

        for (uint256 i=_startIndex; i<_ids.length; i++) {
            for (uint32 j=0; j<_ids[i].length; j++) {
                uint32 albumId = uint32(i+1);
                commonsAlbum[_nftContract].nfts[albumId].push(_ids[i][j]);
            }
        }
        commonsAlbum[_nftContract].totalNFTs = _ids.length;

        emit albumCommonsPopulated(_nftContract, _ids.length, _msgSender());
    }

    function populateUncommonsAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external {
        require((_msgSender() == IFrameItNFTCommons(_nftContract).owner()) || (_msgSender() == owner), "BadOwner");

        for (uint256 i=_startIndex; i<_ids.length; i++) {
            for (uint32 j=0; j<_ids[i].length; j++) {
                uint32 albumId = uint32(i+1);
                uncommonsAlbum[_nftContract].nfts[albumId].push(_ids[i][j]);
            }
        }
        uncommonsAlbum[_nftContract].totalNFTs = _ids.length;

        emit albumUncommonsPopulated(_nftContract, _ids.length, _msgSender());
    }

    function populateRaresAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external {
        require((_msgSender() == IFrameItNFTCommons(_nftContract).owner()) || (_msgSender() == owner), "BadOwner");

        for (uint256 i=_startIndex; i<_ids.length; i++) {
            for (uint32 j=0; j<_ids[i].length; j++) {
                uint32 albumId = uint32(i+1);
                raresAlbum[_nftContract].nfts[albumId].push(_ids[i][j]);
            }
        }
        raresAlbum[_nftContract].totalNFTs = _ids.length;

        emit albumRaresPopulated(_nftContract, _ids.length, _msgSender());
    }

    function getAlbumItem(address _nftContract, uint32 _i, uint256 _j) external view returns (uint32) {
        return fullAlbum[_nftContract].nfts[_i][_j];
    }

    function getAlbumTotalItems(address _nftContract) external view returns(uint256) {
        return fullAlbum[_nftContract].totalNFTs;
    }

    function checkAlbumComplete(address _nftContract, address _user) external view returns (bool) {
        uint256 totalAlbumNFTs = fullAlbum[_nftContract].totalNFTs;

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = fullAlbum[_nftContract].nfts[albumId];
            bool found = false;
            for (uint32 j=0; j<nfts.length; j++) {
                address _owner = IERC721(_nftContract).ownerOf(nfts[j]);
                if (_owner == _user) {
                    found = true;
                    continue;
                }
            }

            if (found == false) return false;
        }

        return true;
    }

    function checkAlbumCommonsComplete(address _nftContract, address _user) external view returns (bool) {
        uint256 totalAlbumNFTs = commonsAlbum[_nftContract].totalNFTs;

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = commonsAlbum[_nftContract].nfts[albumId];
            bool found = false;
            for (uint32 j=0; j<nfts.length; j++) {
                address _owner = IERC721(_nftContract).ownerOf(nfts[j]);
                if (_owner == _user) {
                    found = true;
                    continue;
                }
            }

            if (found == false) return false;
        }

        return true;
    }

    function checkAlbumUncommonsComplete(address _nftContract, address _user) external view returns (bool) {
        uint256 totalAlbumNFTs = uncommonsAlbum[_nftContract].totalNFTs;

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = uncommonsAlbum[_nftContract].nfts[albumId];
            bool found = false;
            for (uint32 j=0; j<nfts.length; j++) {
                address _owner = IERC721(_nftContract).ownerOf(nfts[j]);
                if (_owner == _user) {
                    found = true;
                    continue;
                }
            }

            if (found == false) return false;
        }

        return true;
    }

    function checkAlbumRaresComplete(address _nftContract, address _user) external view returns (bool) {
        uint256 totalAlbumNFTs = raresAlbum[_nftContract].totalNFTs;

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = raresAlbum[_nftContract].nfts[albumId];
            bool found = false;
            for (uint32 j=0; j<nfts.length; j++) {
                address _owner = IERC721(_nftContract).ownerOf(nfts[j]);
                if (_owner == _user) {
                    found = true;
                    continue;
                }
            }

            if (found == false) return false;
        }

        return true;
    }

    function getUserAlbumIds(address _nftContract, address _user) external view returns (bool[] memory) {
        uint256 totalAlbumNFTs = fullAlbum[_nftContract].totalNFTs;
        bool[] memory ids = new bool[](totalAlbumNFTs);

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = fullAlbum[_nftContract].nfts[albumId];
            bool found = false;
            for (uint32 j=0; j<nfts.length; j++) {
                address _owner = IERC721(_nftContract).ownerOf(nfts[j]);
                if (_owner == _user) {
                    found = true;
                    continue;
                }
            }

            ids[i] = found;
        }

        return ids;
    }

    function getUserNFTsForAlbumId(address _nftContract, address _user, uint32 _albumId) external view returns (uint32[] memory) {
        uint32[] memory nfts = fullAlbum[_nftContract].nfts[_albumId];
        uint32[] memory ids = new uint32[](nfts.length);

        uint256 counter = 0;
        for (uint256 i=0; i<nfts.length; i++) {
            address _owner = IERC721(_nftContract).ownerOf(nfts[i]);
            if (_owner == _user) {
                ids[counter] = nfts[i];
                counter++;
            }
        }

        return ids;
    }

    function getNFTsIdsForAlbumId(address _nftContract, uint32 _albumId) external view returns (uint32[] memory) {
        return fullAlbum[_nftContract].nfts[_albumId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address public owner;
    address public ownerPendingClaim;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnershipProposed(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OnlyOwner");
        _;
    }

    function proposeChangeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroAddress");
        ownerPendingClaim = newOwner;

        emit NewOwnershipProposed(msg.sender, newOwner);
    }

    function claimOwnership() external {
        require(msg.sender == ownerPendingClaim, "OnlyProposedOwner");

        ownerPendingClaim = address(0);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFrameItNFTCommons {

    function salesWallet() external view returns(address);
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract FrameItContext is ERC2771Context {

    constructor (address _forwarder) ERC2771Context(_forwarder) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}