// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../nfts/IFrameItNFTCommons.sol";
import "../utils/Ownable.sol";
import "./IFrameItAlbum.sol";

contract FrameItAlbum is Ownable {

    struct AlbumStruct {
        mapping(uint32 => uint32[]) nfts;
        uint256 totalNFTs;
    }

    mapping(address => AlbumStruct[]) private fullAlbum;

    event albumPopulated(address indexed _nft, uint256 _index, uint256 _length, address _user);

    function populateAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external {
        require((msg.sender == IFrameItNFTCommons(_nftContract).owner()) || (msg.sender == owner), "BadOwner");

        uint256 index = fullAlbum[_nftContract].length;
        fullAlbum[_nftContract].push();
        AlbumStruct storage album = fullAlbum[_nftContract][index];
        for (uint256 i=_startIndex; i<_ids.length; i++) {
            for (uint32 j=0; j<_ids[i].length; j++) {
                uint32 albumId = uint32(i+1);
                album.nfts[albumId].push(_ids[i][j]);
            }
        }
        album.totalNFTs = _ids.length;

        emit albumPopulated(_nftContract, index, _ids.length, msg.sender);
    }

    function destroyAlbum(address _nftContract, uint256 _index) external {
        delete fullAlbum[_nftContract][_index];
    }

    function getAlbumItem(address _nftContract, uint256 _albumIndex, uint32 _i, uint256 _j) external view returns (uint32) {
        return fullAlbum[_nftContract][_albumIndex].nfts[_i][_j];
    }

    function getAlbumTotalItems(address _nftContract, uint256 _albumIndex) external view returns(uint256) {
        return fullAlbum[_nftContract][_albumIndex].totalNFTs;
    }

    function checkAlbumComplete(address _nftContract, uint256 _albumIndex, address _user) external view returns (bool) {
        uint256 totalAlbumNFTs = fullAlbum[_nftContract][_albumIndex].totalNFTs;

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = fullAlbum[_nftContract][_albumIndex].nfts[albumId];
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

    function getUserAlbumIds(address _nftContract, uint256 _albumIndex, address _user) external view returns (bool[] memory) {
        uint256 totalAlbumNFTs = fullAlbum[_nftContract][_albumIndex].totalNFTs;
        bool[] memory ids = new bool[](totalAlbumNFTs);

        for (uint256 i=0; i<totalAlbumNFTs; i++) {
            uint32 albumId = uint32(i+1);
            uint32[] memory nfts = fullAlbum[_nftContract][_albumIndex].nfts[albumId];
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

    function getUserNFTsForAlbumId(address _nftContract, uint256 _albumIndex, address _user, uint32 _albumId) external view returns (uint32[] memory) {
        uint32[] memory nfts = fullAlbum[_nftContract][_albumIndex].nfts[_albumId];
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

    function getNFTsIdsForAlbumId(address _nftContract, uint256 _albumIndex, uint32 _albumId) external view returns (uint32[] memory) {
        return fullAlbum[_nftContract][_albumIndex].nfts[_albumId];
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
pragma solidity ^0.8.16;

interface IFrameItAlbum {

    function populateAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external;
    function destroyAlbum(address _nftContract, uint256 _albumIndex) external;
    function checkAlbumComplete(address _nftContract, uint256 _albumIndex, address _user) external view returns (bool);
    function getUserAlbumIds(address _nftContract, uint256 _albumIndex, address _user) external view returns (uint256[] memory);
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