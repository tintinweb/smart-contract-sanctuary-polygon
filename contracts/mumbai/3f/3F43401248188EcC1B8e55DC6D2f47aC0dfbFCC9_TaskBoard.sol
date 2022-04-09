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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

abstract contract TaqAccessControl is Ownable {
    /// @notice Returns the token address.
    IERC721 public accessControlToken;

    event AccessControlTokenUpdated(IERC721 indexed previousAdress, IERC721 indexed newAdress);
    error NotTaqtiler();

    modifier onlyTaqtiler() {
        checkIfTaqtiler(msg.sender);
        _;
    }

    constructor(IERC721 _token) {
        emit AccessControlTokenUpdated(accessControlToken, _token);
        accessControlToken = _token;
    }

    /// @notice Update accessControlToken address from `accessControlToken` to `_token`.
    /// @dev Should use only the {TaqEmployee} address for now.
    /// @param _token The new accessControlToken address.
    function setTaqAccessControl(IERC721 _token) public onlyOwner {
        emit AccessControlTokenUpdated(accessControlToken, _token);
        accessControlToken = _token;
    }

    /// @notice Returns if `operator` is owned by a taqtiler.
    /// @param operator The address to be verified.
    /// @dev Check if `operator` has some balance on `accessControlToken`, assuming that those are only owned by taqtilers.
    function checkIfTaqtiler(address operator) public view returns (bool) {
        if (accessControlToken.balanceOf(operator) == 0) {
            revert NotTaqtiler();
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TaqAccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract TaskBoard is TaqAccessControl {
    enum TaskState {
        Uninitialized,
        Open,
        Canceled,
        Completed
    }

    struct Task {
        uint256 bounty;
        address issuer;
        address assignedTo;
        bool exists;
        string description;
        TaskState status;
        // only for view purposes
        address[] collaborators;
    }

    event Created(uint256 indexed taskId, address issuer);
    event Funded(uint256 indexed taskId, address collaborator, uint256 amount);
    event Canceled(uint256 indexed taskId, address by);
    event Completed(uint256 indexed taskId, address by, address to, uint256 amount);
    event Refunded(uint256 indexed taskId, address to, uint256 amount);
    event Assigned(uint256 indexed taskId, address to);
    event Unassigned(uint256 indexed taskId, address from, address by);
    event MinBountyUpdated(uint256 indexed previousValue, uint256 indexed newValue);
    event TokenAddressUpdated(IERC20 indexed previousAdress, IERC20 indexed newAdress);

    error Closed(uint256 taskId);
    error InvalidId(uint256 taskId);
    error InsufficientBounty(uint256 sent, uint256 required);
    error AlreadyAssigned(uint256 taskId, address assignedTo);
    error RefundNotAllowed(uint256 taskId);
    error ZeroMinBounty();
    error CompleteWithoutAssign(uint256 taskId);
    error Unauthorized();
    error EmptyDescripition();

    /// @notice Returns the token address.
    IERC20 public token;

    /// @notice Returns a task given its id.
    mapping(uint256 => Task) public tasks;

    /// @notice Returns the amount of tasks created.
    uint256 public taskCounter;

    /// @notice Returns the amount funded on a task by a collaborator.
    mapping(uint256 => mapping(address => uint256)) public fundedAmounts;

    /// @notice The minimun amount of tokens required to fund a task, including its creation.
    uint256 public minBounty;

    constructor(
        IERC721 _token0,
        IERC20 _token1,
        uint256 _minBounty
    ) TaqAccessControl(_token0) {
        if (_minBounty == 0) {
            revert ZeroMinBounty();
        }
        emit MinBountyUpdated(0, _minBounty);
        minBounty = _minBounty;
        emit TokenAddressUpdated(token, _token1);
        token = _token1;
    }

    /**
     * @dev Throws if called with a id of a not created task.
     */
    modifier exists(uint256 taskId) {
        if (!tasks[taskId].exists) {
            revert InvalidId(taskId);
        }
        _;
    }

    /// @notice Update token address from `token` to `_token`.
    /// @dev Should use only the TaqCoin address for now.
    /// @param _token The new token address.
    function setTokenAddress(IERC20 _token) external onlyOwner {
        emit TokenAddressUpdated(token, _token);
        token = _token;
    }

    /// @notice Update The minimun amount nedded to fund/create a task to `_minBounty`.
    /// @param _minBounty The minimun amount nedded to fund/create a task.
    function setMinBounty(uint256 _minBounty) external onlyOwner {
        if (_minBounty == 0) {
            revert ZeroMinBounty();
        }
        emit MinBountyUpdated(minBounty, _minBounty);
        minBounty = _minBounty;
    }

    /// @notice Create a task, setting `msg.sender` as its issuer.
    /// @param initialBounty The task initial bounty.
    /// @param description The task description.
    /// @return taskId The task identifier.
    function create(uint256 initialBounty, string calldata description) external onlyTaqtiler returns (uint256 taskId) {
        if (bytes(description).length == 0) {
            revert EmptyDescripition();
        }

        if (initialBounty < minBounty) {
            revert InsufficientBounty({ sent: initialBounty, required: minBounty });
        }

        Task memory task = Task(
            initialBounty,
            msg.sender,
            address(0),
            true,
            description,
            TaskState.Open,
            new address[](0)
        );

        taskId = taskCounter++;
        fundedAmounts[taskId][msg.sender] = initialBounty;
        tasks[taskId] = task;
        token.transferFrom(msg.sender, address(this), initialBounty);

        emit Created(taskId, task.issuer);
    }

    /// @notice Refund the amount of tokens delivered by collaborator on task `taskId`.
    /// @dev This function is idempotent and can be called by anyone.
    /// @param taskId The task identifier.
    function refund(uint256 taskId) external exists(taskId) {
        Task storage task = tasks[taskId];

        if (task.status != TaskState.Canceled) {
            revert RefundNotAllowed(taskId);
        }

        uint256 amount = fundedAmounts[taskId][msg.sender];
        delete fundedAmounts[taskId][msg.sender];
        token.transfer(msg.sender, amount);

        emit Refunded(taskId, msg.sender, amount);
    }

    /// @notice Use `amount` tokens from `msg.sender` to fund task `taskId`.
    /// @param taskId The task identifier.
    /// @param amount The amount of tokens beeing staked.
    function fund(uint256 taskId, uint256 amount) external onlyTaqtiler exists(taskId) {
        Task storage task = tasks[taskId];

        if (task.status != TaskState.Open) {
            revert Closed(taskId);
        }

        if (amount < minBounty) {
            revert InsufficientBounty({ sent: amount, required: minBounty });
        }

        uint256 fundedAmount = fundedAmounts[taskId][msg.sender];

        if (fundedAmount == 0) {
            task.collaborators.push(msg.sender);
        }

        task.bounty += amount;
        fundedAmounts[taskId][msg.sender] = fundedAmount + amount;

        token.transferFrom(msg.sender, address(this), amount);

        emit Funded(taskId, msg.sender, amount);
    }

    /// @notice Complete task `taskId`, sending staked tokens to who is assigned to it.
    /// @param taskId The task identifier.
    function complete(uint256 taskId) external exists(taskId) {
        Task storage task = tasks[taskId];

        if (task.status != TaskState.Open) {
            revert Closed(taskId);
        }

        if (task.issuer != msg.sender && owner() != msg.sender) {
            revert Unauthorized();
        }

        if (task.assignedTo == address(0)) {
            revert CompleteWithoutAssign(taskId);
        }

        task.status = TaskState.Completed;
        token.transfer(task.assignedTo, task.bounty);

        emit Completed(taskId, msg.sender, task.assignedTo, task.bounty);
    }

    /// @notice Assign `msg.sender` to task `taskId`.
    /// @param taskId The task identifier.
    function selfAssign(uint256 taskId) public onlyTaqtiler exists(taskId) {
        Task storage task = tasks[taskId];

        if (task.status != TaskState.Open) {
            revert Closed(taskId);
        }

        if (task.assignedTo != address(0)) {
            revert AlreadyAssigned(taskId, task.assignedTo);
        }

        task.assignedTo = msg.sender;

        emit Assigned(taskId, msg.sender);
    }

    /// @notice Cancel to fund task `taskId`, allowing collaborators to refund their tokens.
    /// @param taskId The task identifier.
    function cancel(uint256 taskId) external exists(taskId) {
        Task storage task = tasks[taskId];

        if (task.status != TaskState.Open) {
            revert Closed(taskId);
        }

        if (task.issuer != msg.sender && owner() != msg.sender) {
            revert Unauthorized();
        }

        task.status = TaskState.Canceled;

        emit Canceled(taskId, msg.sender);
    }

    /// @notice Unassign task `taskId` from who it is currently assigned to.
    /// @param taskId The task identifier.
    function unassign(uint256 taskId) external exists(taskId) {
        Task storage task = tasks[taskId];

        if (task.status != TaskState.Open) {
            revert Closed(taskId);
        }

        if (task.issuer != msg.sender && task.assignedTo != msg.sender && owner() != msg.sender) {
            revert Unauthorized();
        }

        emit Unassigned(taskId, task.assignedTo, msg.sender);

        delete task.assignedTo;
    }

    struct Fund {
        uint256 taskId;
        uint256 amount;
        address collaborator;
    }

    /// @notice Get the accounts that contributed to task `taskId`.
    /// @param taskId The task identifier.
    function collaborators(uint256 taskId) public view returns (address[] memory) {
        return tasks[taskId].collaborators;
    }

    /// @notice Get all funds made by `collaboratorAddress` per task.
    /// @param collaboratorAddress The collaborator address.
    /// @return funds List of funds made by `collaboratorAddress` and their amounts per task.
    function fundsByCollaborator(address collaboratorAddress) external view returns (Fund[] memory funds) {
        uint256 fundCounter;
        funds = new Fund[](taskCounter);

        for (uint256 taskId = 0; taskId < taskCounter; taskId++) {
            uint256 amount = fundedAmounts[taskId][collaboratorAddress];
            if (amount != 0) {
                funds[fundCounter++] = Fund(taskId, amount, collaboratorAddress);
            }
        }
    }

    /// @notice Get all funds made to `taskId` per collaborator
    /// @param taskId The task identifier.
    /// @return funds List of funds that were contributed to task `taskId` and their amounts per contributor.
    function fundsByTask(uint256 taskId) external view returns (Fund[] memory funds) {
        funds = new Fund[](taskCounter + 1);
        address[] memory addresses = tasks[taskId].collaborators;

        for (uint256 i = 0; i < addresses.length; i++) {
            address collaborator = addresses[i];
            uint256 amount = fundedAmounts[taskId][collaborator];

            funds[i] = Fund(taskId, amount, collaborator);
        }
    }
}