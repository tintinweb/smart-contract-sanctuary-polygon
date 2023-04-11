// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../token/erc721/payable/IERC721PayableSpender.sol";

interface IMojo is IERC721 {
    function exists(uint256 tokenId) external returns (bool);

    function mintById(address to, uint256 tokenId) external;
}

interface IMojoSeed is IERC721 {
    function burn(uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/**
 * @title Sprouter
 * @notice Contract for sprouting Mojo Seeds into Mojos
 */
contract Sprouter is Ownable, IERC721PayableSpender, IERC165 {
    event MojoSeedPlanted(uint256 indexed seedId, address indexed owner);
    event MojoSprout(
        uint256 indexed seedId,
        address indexed owner,
        address indexed recipient
    );
    event PlantingActiveChange(bool plantingActive);
    event MojoSeedContractAddressChange(
        address oldMojoSeedContract,
        address newMojoSeedContract
    );
    event MojoContractAddressChange(
        address oldMojoContract,
        address newMojoContract
    );
    event SproutingDelayChange(uint256 oldDelay, uint256 newDelay);

    struct SeedStorage {
        // Mapping from owner to list of owned token IDs
        mapping(address => uint256[]) ownedTokens;
        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) allTokensIndex;
        // Mapping from token id to block number at time of planting
        mapping(uint256 => uint256) seedPlantBlockstamp;
    }

    //The ERC-165 identifier for the ERC-173 Ownable standard is 0x7f5828d0
    bytes4 private constant INTERFACE_ID_ERC173 = 0x7f5828d0;

    bool public plantingActive;
    IMojo public mojoContract;
    IMojoSeed public mojoSeedContract;
    uint256 public sproutingDelay;

    SeedStorage private seeds;

    constructor(
        address _owner,
        IMojo _mojoContract,
        IMojoSeed _mojoSeedContract,
        uint256 _sproutingDelay
    ) {
        _transferOwnership(_owner);
        mojoContract = _mojoContract;
        mojoSeedContract = _mojoSeedContract;
        sproutingDelay = _sproutingDelay;
    }

    function setPlantingActive(bool active) public onlyOwner {
        require(
            active != plantingActive,
            "Planting is already in the desired state"
        );
        plantingActive = active;
        emit PlantingActiveChange(plantingActive);
    }

    function setMojoContractAddress(IMojo _mojoContract) public onlyOwner {
        emit MojoContractAddressChange(
            address(mojoContract),
            address(_mojoContract)
        );
        mojoContract = _mojoContract;
    }

    function setMojoSeedContractAddress(IMojoSeed _mojoSeedContract)
        public
        onlyOwner
    {
        emit MojoSeedContractAddressChange(
            address(mojoSeedContract),
            address(_mojoSeedContract)
        );
        mojoSeedContract = _mojoSeedContract;
    }

    function setSproutingDelay(uint256 _sproutingDelay) public onlyOwner {
        emit SproutingDelayChange(sproutingDelay, _sproutingDelay);
        sproutingDelay = _sproutingDelay;
    }

    /**
     * @dev Called by the MojoSeed contract when the user gives approval.
     * This is used to approve the Sprouter contract to "spend" the MojoSeed and transfer it into it's own custody
     * in a single transaction.
     */
    function onApprovalReceived(
        address owner,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        require(plantingActive, "Planting is not active");

        require(
            _msgSender() == address(mojoSeedContract),
            "Can only plant Mojo Seeds"
        );
        require(!mojoContract.exists(tokenId), "Mojo already minted");
        require(owner != address(this), "Seed has already been deposited");

        seeds.allTokens.push(tokenId);
        seeds.allTokensIndex[tokenId] = seeds.allTokens.length - 1;

        seeds.ownedTokens[owner].push(tokenId);
        seeds.ownedTokensIndex[tokenId] = seeds.ownedTokens[owner].length - 1;

        seeds.seedPlantBlockstamp[tokenId] = block.number;

        mojoSeedContract.safeTransferFrom(owner, address(this), tokenId);

        emit MojoSeedPlanted(tokenId, owner);

        return IERC721PayableSpender.onApprovalReceived.selector;
    }

    /**
     * @dev Called by the user to burn the MojoSeed and mint a new Mojo
     */
    function sprout(uint256 seedId, address recipient) public {
        address sender = _msgSender();

        require(!mojoContract.exists(seedId), "Mojo already minted");
        require(isSeedOwner(sender, seedId), "Seed doesn't belong to sender");
        require(
            hasSproutingDelayPassed(seedId),
            "Sprouting delay has not passed"
        );

        _removeSeedFromAllTokensEnumeration(seedId);
        _removeSeedFromOwnerEnumeration(sender, seedId);

        mojoSeedContract.burn(seedId);
        mojoContract.mintById(recipient, seedId);

        emit MojoSprout(seedId, sender, recipient);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function isSeedOwner(address account, uint256 tokenId)
        public
        view
        returns (bool)
    {
        if (seeds.ownedTokens[account].length == 0) {
            return false;
        }

        return
            seeds.ownedTokens[account][seeds.ownedTokensIndex[tokenId]] ==
            tokenId;
    }

    function isSeedPlanted(uint256 tokenId) public view returns (bool) {
        if (seeds.allTokens.length == 0) {
            return false;
        }

        return seeds.allTokens[seeds.allTokensIndex[tokenId]] == tokenId;
    }

    function canSprout(uint256 seedId) public view returns (bool) {
        if (!isSeedPlanted(seedId)) {
            return false;
        }

        return hasSproutingDelayPassed(seedId);
    }

    function hasSproutingDelayPassed(uint256 seedId)
        public
        view
        returns (bool)
    {
        return
            seeds.seedPlantBlockstamp[seedId] + sproutingDelay <= block.number;
    }

    function enumerateSeeds(uint256 start, uint256 count)
        public
        view
        returns (uint256[] memory ids, uint256 total)
    {
        uint256 length = seeds.allTokens.length;
        if (start + count > length) {
            count = length - start;
        }

        ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = seeds.allTokens[start + i];
        }

        return (ids, length);
    }

    function enumerateSeedsOfOwner(
        address account,
        uint256 start,
        uint256 count
    ) public view returns (uint256[] memory ids, uint256 total) {
        uint256 length = seeds.ownedTokens[account].length;
        if (start + count > length) {
            count = length - start;
        }

        ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = seeds.ownedTokens[account][start + i];
        }

        return (ids, length);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721PayableSpender).interfaceId ||
            interfaceId == INTERFACE_ID_ERC173;
    }

    function _removeSeedFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = seeds.allTokens.length - 1;
        uint256 tokenIndex = seeds.allTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = seeds.allTokens[lastTokenIndex];

            seeds.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            seeds.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete seeds.allTokensIndex[tokenId];
        seeds.allTokens.pop();
    }

    function _removeSeedFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = seeds.ownedTokens[from].length - 1;
        uint256 tokenIndex = seeds.ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = seeds.ownedTokens[from][lastTokenIndex];

            seeds.ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            seeds.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete seeds.ownedTokensIndex[tokenId];
        seeds.ownedTokens[from].pop();
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721PayableSpender {
    function onApprovalReceived(address owner, uint256 tokenId, bytes memory data) external returns(bytes4);
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