//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SBTBase.sol";

import "./interface/ITask.sol";
import "./interface/IMetadata.sol";



contract DeTask is SBTBase, Ownable {
    // 手续费
    // uint private taskFee  = 1*10**17;
    uint private taskFee  = 0;
    uint private applyFee = 0;
    address private feeReceiver;

    address public meta;

    using Counters for Counters.Counter;

    event TaskCreated(uint indexed taskId, address issuer, TaskInfo task);
    event TaskModified(uint indexed taskId, address issuer, TaskInfo task);
    event TaskDisabled(uint indexed taskId, bool disabled);

    event ApplyFor(uint indexed taskId, address indexed worker, uint cost);
    event CancelApply(uint indexed taskId, address worker);
    
    event ModifyFee(uint taskFee, uint applyFee, address feeReceiver);


    Counters.Counter private taskIds;
    //taskId =>
    mapping(uint => TaskInfo) public tasks; 

    //报名信息: taskId => worker
    mapping(uint => mapping(address => uint)) private applyCosts;

    constructor() SBTBase("DeTask", "DeTask") {
        feeReceiver = msg.sender;
    }

    function createTask(address who, TaskInfo memory task) external payable {
        require(msg.value >= taskFee, "Not enough taskFee.");
        taskIds.increment();

        uint taskId = taskIds.current();        
        tasks[taskId] = TaskInfo({
            title: task.title,
            attachment: task.attachment,  // ipfs hash
            currency: task.currency,
            budget: task.budget,
            period: task.period,
            skills: task.skills,
            timestamp: uint32(block.timestamp),
            disabled: false
        });

        _mint(who, taskId);

        emit TaskCreated(taskId, who, tasks[taskId]);
    }

    function modifyTask(uint taskId, TaskInfo memory task) external payable {
        require(msg.sender == ownerOf(taskId), "No permission.");

        TaskInfo storage taskInfo = tasks[taskId];

        taskInfo.title = task.title;
        taskInfo.attachment = task.attachment;
        taskInfo.currency = task.currency;
        taskInfo.budget = task.budget;
        taskInfo.period = task.period;
        taskInfo.skills = task.skills;
        taskInfo.disabled = task.disabled;

        emit TaskModified(taskId, msg.sender, taskInfo);
    }

    function getTaskInfo(uint256 taskId)  external view returns (string memory title,
        string memory attachment,
        uint8 currency,
        uint128 budget,
        uint32 period,
        uint48 skills,    // uint8[6]
        uint32 timestamp,
        bool disabled) {
            TaskInfo memory task = tasks[taskId];
            title = task.title;
            attachment = task.attachment;
            currency = task.currency;
            budget = task.budget; 
            period = task.period;
            skills = task.skills;
            timestamp = task.timestamp;
            disabled = task.disabled;
        }


    function applyFor(address who, uint taskId, uint _cost) public payable {
        require(msg.value >= applyFee, "low fee");
        doApply(who, taskId, _cost);
    }

    function doApply(address who, uint taskId, uint _cost) internal {
        require(who != ownerOf(taskId), "Not apply for orders yourself.");
        require(!tasks[taskId].disabled, "The apply switch is closed.");

        applyCosts[taskId][who] = _cost;
        emit ApplyFor(taskId, who, _cost);
    }

    function cancelApply(uint taskId) public {
        require(applyCosts[taskId][msg.sender] > 0, "Not applied.");
        applyCosts[taskId][msg.sender] = 0;

        emit CancelApply(taskId, msg.sender);
    }

    function applyAndCancel(address who, uint[] memory _taskIds, uint[] memory costs, uint[] memory cancelIds) external payable { 
        uint applyNum = _taskIds.length; 
        require(msg.value >= applyFee * applyNum, "low fee");
        for( uint i=0; i < applyNum; i++) {
            doApply(who, _taskIds[i], costs[i]);
        }

        for( uint i=0; i < cancelIds.length; i++) {
            cancelApply(cancelIds[i]);
        }
    }

    function disableTask(uint taskId, bool _disabled) external {
        require(msg.sender == ownerOf(taskId), "No permission.");
        require(tasks[taskId].disabled != _disabled, "same state.");

        tasks[taskId].disabled = _disabled;
        emit TaskDisabled(taskId, _disabled);
    }

    function transferFee(uint amount) external {
        (bool success, ) = feeReceiver.call{value: amount}(new bytes(0));
        require(success, 'ETH transfer failed');
    }

    function updateFeeReceiver(uint _taskFee, uint _applyFee, address _receiver) external onlyOwner {
        taskFee = _taskFee;
        applyFee = _applyFee;
        feeReceiver = _receiver;

        emit ModifyFee(_taskFee, _applyFee, _receiver);
    }

    function setMetaContract(address _meta) external onlyOwner {
        require(_meta != address(0), "zero address");
        meta = _meta;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return IMetadata(meta).tokenURI(tokenId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interface/IERC5192.sol";

/**
 * @dev Implementation of Soulbound Token[SBT]: Non-tranable Token
 */
contract SBTBase is ERC165, IERC721, IERC721Metadata, IERC5192 {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI} need override.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return "";
    }

    function approve(address , uint256 ) public virtual override {
        revert("SBT:non-approvable");
    }

    function getApproved(uint256 ) public view virtual override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address , bool ) public virtual override {
        revert("SBT:non-approvable");
    }

    function isApprovedForAll(address , address ) public view virtual override returns (bool) {
        return false;
    }

    function transferFrom(
        address ,
        address ,
        uint256 
    ) public virtual override {
        revert("SBT:non-transferable");
    }

    function safeTransferFrom(
        address ,
        address ,
        uint256 
    ) public virtual override {
        revert("SBT:non-transferable");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address ,
        address ,
        uint256 ,
        bytes memory 
    ) public virtual override {
        revert("SBT:non-transferable");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
        emit Locked(tokenId);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function locked(uint256 tokenId) external view override returns (bool) {
        if (_exists(tokenId)) {
            return true;
        } else {
            return false;
        }
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct TaskInfo {
    string title;
    string attachment;
    uint8 currency;
    uint128 budget;
    uint32 period;
    uint48 skills;    // uint8[6]
    uint32 timestamp;
    bool disabled;
}


interface ITask {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tasks(uint256 tokenId)  external view returns (TaskInfo memory);
    function getTaskInfo(uint256 tokenId)  external view returns (string memory title,
        string memory attachment,
        uint8 currency,
        uint128 budget,
        uint32 period,
        uint48 skills,    // uint8[6]
        uint32 timestamp,
        bool disabled);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5192 {
  /// @notice Emitted when the locking status is changed to locked.
  /// @dev If a token is minted and the status is locked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Locked(uint256 tokenId);

  /// @notice Emitted when the locking status is changed to unlocked.
  /// @dev If a token is minted and the status is unlocked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Unlocked(uint256 tokenId);

  /// @notice Returns the locking status of an Soulbound Token
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param tokenId The identifier for an SBT.
  function locked(uint256 tokenId) external view returns (bool);
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