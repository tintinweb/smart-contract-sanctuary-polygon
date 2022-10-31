// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";
import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";

import "../../oracles/EngraveRuneOracle/EngraveRuneOracleCaller.sol";

contract EngraveRune is
    RuneContractCallerOwnable,
    ZomonContractCallerOwnable,
    EngraveRuneOracleCaller
{
    constructor(
        address _runeContractAddress,
        address _zomonContractAddress,
        address _engraveRuneOracleContractAddress
    )
        RuneContractCallerOwnable(_runeContractAddress)
        ZomonContractCallerOwnable(_zomonContractAddress)
        EngraveRuneOracleCaller(_engraveRuneOracleContractAddress)
    {}

    function _matchZomonHasFreeRuneSlot(Zomon memory _zomon)
        internal
        pure
        returns (bool)
    {
        uint8 previousEvolutionsSlots = (_zomon.evolution - 1) *
            _zomon.maxRunesCount;

        return
            _zomon.runesIds.length <
            previousEvolutionsSlots + _zomon.maxRunesCount;
    }

    function engrave(uint256 _runeServerId, uint256 _zomonTokenId) external {
        // Check sender has Rune
        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >= 1,
            "RUNE_NOT_OWNED"
        );

        // Check Rune is approved
        require(
            runeContract.isApprovedForAll(_msgSender(), address(this)),
            "RUNE_NOT_APPROVED"
        );

        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        // Check Zomon has a free rune slot
        require(
            _matchZomonHasFreeRuneSlot(zomon),
            "ZOMON_DOES_NOT_HAVE_FREE_RUNE_SLOT"
        );

        _callEngraveRuneOracle(_msgSender(), _runeServerId, _zomonTokenId);
    }

    function engraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(engraveRuneOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingEngraveRuneRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingEngraveRuneRequests[_requestId];

        // Burn Rune
        runeContract.burn(_to, _runeServerId, 1);

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);
    }

    function _matchZomonHasRune(Zomon memory _zomon, uint16 _runeServerId)
        internal
        pure
        returns (bool)
    {
        uint256 previousEvolutionsSlots = (_zomon.evolution - 1) *
            _zomon.maxRunesCount;

        for (
            uint256 i = previousEvolutionsSlots;
            i < _zomon.runesIds.length;
            i++
        ) {
            if (_zomon.runesIds[i] == _runeServerId) {
                return true;
            }
        }

        return false;
    }

    function disengrave(uint256 _runeServerId, uint256 _zomonTokenId) external {
        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        // Check Zomon has rune
        require(
            _matchZomonHasRune(zomon, uint16(_runeServerId)),
            "ZOMON_DOES_NOT_HAVE_RUNE"
        );

        _callDisengraveRuneOracle(_msgSender(), _runeServerId, _zomonTokenId);
    }

    function disengraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(engraveRuneOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingDisengraveRuneRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingDisengraveRuneRequests[_requestId];

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);

        // Mint Rune
        runeContract.mint(_to, _runeServerId, 1, "");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Zomon {
    /* 32 bytes pack */
    uint16 serverId;
    uint16 setId;
    uint8 edition;
    uint8 rarityId;
    uint8 genderId;
    uint8 zodiacSignId;
    uint16 skillId;
    uint16 leaderSkillId;
    bool canLevelUp;
    bool canEvolve;
    uint16 level;
    uint8 evolution;
    uint24 hp;
    uint24 attack;
    uint24 defense;
    uint24 critical;
    uint24 evasion;
    /*****************/
    bool isShiny;
    uint8 shinyBoostedStat; // 0 = none, 1 = hp, 2 = attack, 3 = defense, 4 = critical, 5 = evasion
    uint16 maxLevel;
    uint8 maxRunesCount;
    uint16 generation;
    uint8 innerTokenDecimals;
    uint8[] typesIds;
    uint16[] diceFacesIds;
    uint16[] runesIds;
    string name;
    address innerTokenAddress;
    uint256 minLevelInnerTokenBalance;
    uint256 maxLevelInnerTokenBalance;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/RUNE/IRune.sol";

contract RuneContractCallerOwnable is Ownable {
    IRune public runeContract;

    constructor(address _runeContractAddress) {
        setRuneContract(_runeContractAddress);
    }

    function setRuneContract(address _address) public onlyOwner {
        IRune candidateContract = IRune(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_RUNE_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_RUNE_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        runeContract = candidateContract;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/ZOMON/IZomon.sol";

contract ZomonContractCallerOwnable is Ownable {
    IZomon public zomonContract;

    constructor(address _zomonContractAddress) {
        setZomonContract(_zomonContractAddress);
    }

    function setZomonContract(address _address) public onlyOwner {
        IZomon candidateContract = IZomon(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_ZOMON_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_ZOMON_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        zomonContract = candidateContract;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEngraveRuneOracle.sol";

abstract contract EngraveRuneOracleCaller is
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_ENGRAVE_RUNE_ORACLE_CALLER = true;

    IEngraveRuneOracle public engraveRuneOracleContract;

    mapping(uint256 => bool) internal _pendingEngraveRuneRequests;
    mapping(uint256 => bool) internal _pendingDisengraveRuneRequests;

    constructor(address _engraveRuneOracleContractAddress) {
        setEngraveRuneOracleContractAddress(_engraveRuneOracleContractAddress);
    }

    function setEngraveRuneOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IEngraveRuneOracle candidateContract = IEngraveRuneOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_ENGRAVE_RUNE_ORACLE());

        // Set the new contract address
        engraveRuneOracleContract = candidateContract;
    }

    // Entry point for engraving
    function _callEngraveRuneOracle(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = engraveRuneOracleContract.requestRuneEngrave(
            _to,
            _runeServerId,
            _zomonTokenId
        );
        _pendingEngraveRuneRequests[requestId] = true;
        return requestId;
    }

    // Exit point for engraving, to be implemented by the use case contract
    function engraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;

    // Entry point for disengraving
    function _callDisengraveRuneOracle(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = engraveRuneOracleContract.requestRuneDisengrave(
            _to,
            _runeServerId,
            _zomonTokenId
        );
        _pendingDisengraveRuneRequests[requestId] = true;
        return requestId;
    }

    // Exit point for disengraving, to be implemented by the use case contract
    function disengraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./IRuneStruct.sol";

interface IRune is IERC1155 {
    function IS_RUNE_CONTRACT() external pure returns (bool);

    function getRune(uint256 _serverId) external view returns (Rune memory);

    function mint(
        address to,
        uint256 serverId,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata serverIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 serverId,
        uint256 value
    ) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Rune {
    uint16 serverId;
    uint16 setId;
    uint8 typeId;
    uint16 charmedRuneServerId;
    uint8 runesCountToCharm;
    string name;
}

struct RunesMint {
    uint256[] ids;
    uint256[] amounts;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IZomonStruct.sol";

interface IZomon is IERC721 {
    function IS_ZOMON_CONTRACT() external pure returns (bool);

    function getZomon(uint256 _tokenId) external view returns (Zomon memory);

    function getCurrentInnerTokenBalance(uint256 _tokenId)
        external
        returns (uint256);

    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI,
        Zomon memory _zomonData
    ) external;

    function burn(uint256 _tokenId) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FundsManagementOwnable is Ownable {
    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function withdraw(address _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "WITHDRAW_FAILED");
    }

    function recoverERC20(
        address _tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            IERC20(_tokenAddress).transfer(_to, _tokenAmount),
            "RECOVERY_FAILED"
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEngraveRuneOracle {
    function IS_ENGRAVE_RUNE_ORACLE() external returns (bool);

    function requestRuneEngrave(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) external returns (uint256);

    function reportRuneEngrave(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;

    function requestRuneDisengrave(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) external returns (uint256);

    function reportRuneDisengrave(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
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