// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDelicateDinos.sol";
import "./interfaces/IDelicateDinosRandomness.sol";

contract DelicateDinosRaffle is Ownable {
  bool internal favouredTokenIdsSet = false;
  uint256[] internal tokenIdTickets;
  mapping(uint256 => bool) public ticketIndexPicked;
  IDelicateDinosRandomness randomnessProvider;

  error MaxFavouredTokenId();

  constructor (address _randProvider) {
    randomnessProvider = IDelicateDinosRandomness(_randProvider);
  }

  /// @dev We may have to call it on batches of a few hundreds -> TODO test on mumbai how many it can handle
  /// @dev assume favouredTokenIds are sorted in ascending order and have no duplicates
  /// @param favouredTokenIds The ones that get several tickets in the lottery
  /// @param favourFactor How many tickets a favoured tokenId gets
  /// @param supply The total number of minted tokens
  function applyFavTokenIds(
    uint16[] calldata favouredTokenIds,
    uint8 favourFactor,
    uint256 supply
  ) external onlyOwner {
     if (uint256(favouredTokenIds[favouredTokenIds.length - 1]) > supply) revert MaxFavouredTokenId();

    uint256 tokenId = 1;
    uint256 idxFavoured = 0;

    while (idxFavoured < favouredTokenIds.length) {
      if (favouredTokenIds[idxFavoured] == tokenId) {
        // match - give several tickets
        for (uint8 j = 0; j < favourFactor; j++) {
          tokenIdTickets.push(tokenId);
          idxFavoured++;
        }
      } else {
        // no match - give one ticket
        tokenIdTickets.push(tokenId);
      }
      tokenId++;
    } 
    favouredTokenIdsSet = true;
  }

  /// @notice Drops nfts to lottery winners. 
  /// Winners are picked based on already available tickets. There are more tickets
  /// associated with the favoured tokenIds => those tokenIds' holders have higher chances.
  /// The lottery tickets were set in WhitelistManager.applyFavouredTokenIds.
  /// @dev Worst case O(n**2)
  /// @dev This function directly mints new dinos without dedicated vrf requests. 
  /// All the lottery functionality + the random allocation of traits happends based
  /// on the @param randomness seed.
  function performLotteryDrop(uint256 randomness, uint256 numberMaxMintable) external onlyOwner {
      uint256 numberExisting = IDelicateDinos(owner()).supply();
      uint256 numberDroppable = numberMaxMintable - numberExisting;

      uint256[] memory manySeeds = randomnessProvider.expandRandom(randomness, numberDroppable);
      
      uint256 dropCt = 0;
      while (dropCt < numberDroppable) {
          // initialize index from random seed
          uint256 idx = manySeeds[dropCt] % numberExisting + 1;
          // find first one not yet picked
          while (ticketIndexPicked[idx]) {
              idx++;
          }
          // mark pick
          ticketIndexPicked[idx] = true;
          // mint-drop
          IDelicateDinos(owner()).mintToOwnerOf(tokenIdTickets[idx], manySeeds[dropCt]); // reuse random number
          dropCt++;
      }
      IDelicateDinos(owner()).dropFinished();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDelicateDinos is IERC721 {
    function setDinoUpTokenAddress(address _contractAddress) external;

    function setUpgraderContract(address _upgraderContract) external;

    function withdraw() external;

    function supply() external returns (uint256);

    function startWhitelistMint(bytes32 merkleRoot, uint256 _fee) external;

    function startPublicSale(uint256 _fee) external;

    function startDropClaim() external;

    function stopMint(uint256 saleStateId) external;

    function setFee(uint256 _fee) external;

    function mintDinoWhitelisted(address addr, string memory name, bytes32[] calldata proof) external payable;

    function mintDinoPublicSale(address addr, string memory name) external payable;

    function mintDinoClaimed(uint256 tokenId, string memory name) external;

    function updateArtwork(uint256 tokenId, string memory newBaseUri) external;
    
    function getTraits(uint256 tokenId) external view returns(uint256, string memory);

    function updateTraits(uint256 tokenId, uint256 length, string memory name) external;

    function tokenIdHasArtwork(uint256 tokenId) external view returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintToOwnerOf(uint256 originTokenId, uint256 idx) external;

    function dropFinished() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDelicateDinosRandomness {
  function initMaster() external;
  function withdrawLink() external;
  /// @notice request for a randomness seed to use in the drop lottery
  function requestForDrop() external;
  /// @notice initiate request for a random number
  function getRandomNumber() external returns (bytes32 requestId);
  /// @notice request for a randomness seed to use in the impact simpulation
  function requestForImpact() external;
  function expandRandom(uint256 randomValue, uint256 n) external pure returns (uint256[] memory expandedValues);
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