/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol

pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/AutomationBase.sol


pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/AutomationCompatible.sol


pragma solidity ^0.8.0;



abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: Raffle.sol


pragma solidity ^0.8.7;











abstract contract Ownable {
    address private _owner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// Raffle contract using ERC20 $AMBER token for tickets, and ERC721 NFTs for prizes.
contract MustasheRaffle is ERC721Holder, Ownable, AutomationCompatibleInterface {
    
    using SafeMath for uint256;

    address public tokenAddress = 0x8865BC57c58Be23137ACE9ED1Ae1A05fE5c8B209; // $AMBER address
    address public feeAddress = 0x5CEe0e6D261dA886aa4F02FB47f45E1E9fa4991b; // Fee address
    address public deadAddress = 0x000000000000000000000000000000000000dEaD; // Burn address

    struct Raffle {
        uint256 id; // Raffle Id
        uint256 ticketPrice; // Raffle ticket price ( 1 ticket )
        uint256 ticketSupply; // Raffle ticket supply
        uint256 ticketSold; // Raffle tickets sold
        uint256 endTime; // Raffle end time
        uint256 winnerTicket; // Raffle winner ticket
        address creator; // Raffle Creator address
        bool ended; // Raffle ended: true / false
        address nftContract; // Nft Contract address
        uint256 nftId; // Nft Id
        uint256 maxTicketsPerAddress; // Max tickets per raffle for wallet
    }

    struct WalletInfo {
        uint256 totalRafflesCreated;
        uint256 totalRafflesCompleted;
        uint256 totalRafflesParticipated;
        uint256 totalRafflesUnsuccessful;
        uint256 totalTokensSentToDead;
    }

        mapping(address => WalletInfo) public walletData;
        
        mapping(address => uint256) public totalTokensSentToDeadPerParticipant;
        mapping(uint256 => mapping(address => uint256)) public ticketsBoughtPerRaffle;

        mapping(uint256 => Raffle) public raffles;
        mapping(uint256 => mapping(uint256 => address)) public tickets;
        mapping(uint256 => address[]) public participants;
        mapping(uint256 => bool) public isRaffleEnded;

        uint256 public totalTokensSentToDead;
        uint256 public totalRafflesCompleted;

        mapping(address => bool) public participatedAddresses;
        mapping(uint256 => bool) private rafflesEndedSuccessfully;
        mapping(address => bool) public allowedNftCollections;

        uint256 public raffleCount;

        mapping(address => bool) private bannedAddresses;
        mapping(address => bool) private allowedAddresses;

        uint256 private constant TOKEN_DECIMALS = 10**18;
        uint256 private constant FEE_PERCENTAGE = 2;
        uint256 private constant CREATOR_PERCENTAGE = 90;
        uint256 private constant DEAD_PERCENTAGE = 8;

    event RaffleCreated (
        uint256 id,
        uint256 ticketPrice,
        uint256 ticketSupply,
        address creator,
        address nftContract,
        uint256 nftId
    );
        event NftCollectionAllowed(address nftCollection);
        event NftCollectionBlocked(address nftCollection);
        event RaffleExpired(uint256 indexed raffleId);
        event RaffleParticipated(uint256 id, uint256 ticketCount, address participant);
        event RaffleEnded(uint256 id, uint256 winnerTicket, address winner);
        event AddressBanned(address indexed bannedAddress);
        event AddressUnbanned(address indexed unbannedAddress);
        event TokensWithdrawn(address indexed tokenAddress, uint256 amount);

    constructor() {}

   function createRaffle(
        uint256 ticketPrice,
        uint256 ticketSupply,
        address nftContract,
        uint256 nftId,
        uint256 duration,
        uint256 maxTicketsPerAddress
    ) external notBanned {
        require(ticketPrice > 0, "Ticket price must be greater than zero");
        require(ticketSupply > 0, "Ticket supply must be greater than zero");
        require(isNftCollectionAllowed(nftContract), "NFT collection not allowed");

        uint256 endTime = block.timestamp + duration;

        raffleCount++;
        raffles[raffleCount] = Raffle(
        raffleCount,
        ticketPrice,
        ticketSupply,
        0,
        endTime,
        0,
        msg.sender,
        false,
        nftContract,
        nftId,
        maxTicketsPerAddress
        );

        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(msg.sender, address(this), nftId);

        walletData[msg.sender].totalRafflesCreated++;

        emit RaffleCreated(raffleCount, ticketPrice, ticketSupply, msg.sender, nftContract, nftId);
    }

    modifier onlyAllowedNftCollections() {
        require(allowedNftCollections[msg.sender], "NFT collection not allowed");
        _;
    }

     modifier raffleNotEnded(uint256 raffleId) {
        require(!raffles[raffleId].ended, "Raffle has already ended");
        _;
    }

    modifier raffleFullySoldOut(uint256 raffleId) {
        require(raffles[raffleId].ticketSold == raffles[raffleId].ticketSupply, "Raffle is not fully sold out");
        _;
    }

      modifier notBanned() {
        require(!bannedAddresses[msg.sender], "Banned address");
        _;
    }

    modifier onlyAllowedAddresses() {
        require(allowedAddresses[msg.sender], "Address not allowed");
        _;
    }

    function checkUpkeep(bytes calldata) external pure override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = true;

        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata) external override {

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (!raffles[i].ended && raffles[i].endTime <= block.timestamp) {
                endRaffleAfterExpiry(i);
            }
        }
    }

    function banAddress(address addressToBan) external onlyOwner {
        require(addressToBan != address(0), "Invalid address");
        require(!bannedAddresses[addressToBan], "Address already banned");
        bannedAddresses[addressToBan] = true;
        emit AddressBanned(addressToBan);
    }

    function unbanAddress(address addressToUnban) external onlyOwner {
        require(addressToUnban != address(0), "Invalid address");
        require(bannedAddresses[addressToUnban], "Address not banned");
        bannedAddresses[addressToUnban] = false;
        emit AddressUnbanned(addressToUnban);
    }
    
    function _updateTotalTokensSentToDead(uint256 amount) private {
        totalTokensSentToDead = totalTokensSentToDead.add(amount);
    }

    function _trackParticipatedAddress(address participant) private {
        if (!participatedAddresses[participant]) {
            participatedAddresses[participant] = true;
            totalRafflesCompleted++;
        }
    }

    function getTotalTokensSentToDead() public view returns (uint256) {
        return totalTokensSentToDead.div(TOKEN_DECIMALS);
    }

    function getTotalRafflesCompleted() public view returns (uint256) {
        uint256 completedRaffleCount = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (rafflesEndedSuccessfully[i]) {
                completedRaffleCount++;
            }
        }
        return completedRaffleCount;
    }

    function allowNftCollection(address nftCollection) external onlyOwner {
        allowedNftCollections[nftCollection] = true;
        emit NftCollectionAllowed(nftCollection);
     }

    function blockNftCollection(address nftCollection) external onlyOwner {
        allowedNftCollections[nftCollection] = false;
        emit NftCollectionBlocked(nftCollection);
    }

    function isNftCollectionAllowed(address nftCollection) public view returns (bool) {
        return allowedNftCollections[nftCollection];
    }

    function participateRaffle(uint256 raffleId, uint256 ticketCount) external notBanned {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(!raffles[raffleId].ended, "Raffle has ended");
        require(block.timestamp <= raffles[raffleId].endTime, "Raffle has already ended");
        require(ticketCount > 0, "Ticket count must be greater than zero");
        require(
            raffles[raffleId].ticketSold.add(ticketCount) <= raffles[raffleId].ticketSupply,
            "Not enough tickets available"
        );
        require(
            getParticipantTicketCount(raffleId, msg.sender).add(ticketCount) <= raffles[raffleId].maxTicketsPerAddress,
            "Exceeded maximum tickets per address"
        );
        require(raffles[raffleId].creator != msg.sender, "Creators are not allowed to participate");

        uint256 totalPrice = raffles[raffleId].ticketPrice.mul(ticketCount).mul(TOKEN_DECIMALS);
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= totalPrice, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= totalPrice, "Insufficient token allowance");

        token.transferFrom(msg.sender, address(this), totalPrice);

        for (uint256 i = 0; i < ticketCount; i++) {
            raffles[raffleId].ticketSold++;
            tickets[raffleId][raffles[raffleId].ticketSold] = msg.sender;
            ticketsBoughtPerRaffle[raffleId][msg.sender]++;
        }

        if (!participatedAddresses[msg.sender]) {
            participatedAddresses[msg.sender] = true;
            totalRafflesCompleted++;
        }

        participants[raffleId].push(msg.sender);

        if (raffles[raffleId].ticketSold == raffles[raffleId].ticketSupply) {
            isRaffleEnded[raffleId] = true;
            _endRaffle(raffleId);
        }

        walletData[msg.sender].totalRafflesParticipated++;
        participants[raffleId].push(msg.sender);

        emit RaffleParticipated(raffleId, ticketCount, msg.sender);
    }

    function _endRaffle(uint256 raffleId) internal raffleNotEnded(raffleId) raffleFullySoldOut(raffleId) {
        raffles[raffleId].ended = true;

        uint256 winningTicket = generateRandomNumber(raffleId, raffles[raffleId].ticketSupply);
        raffles[raffleId].winnerTicket = winningTicket;

        address winner = tickets[raffleId][winningTicket];

        IERC721 nft = IERC721(raffles[raffleId].nftContract);
        nft.safeTransferFrom(address(this), winner, raffles[raffleId].nftId);

        IERC20 token = IERC20(tokenAddress);
        uint256 prizeAmount = raffles[raffleId].ticketPrice.mul(raffles[raffleId].ticketSupply).mul(TOKEN_DECIMALS);
        uint256 creatorAmount = prizeAmount.mul(CREATOR_PERCENTAGE).div(100);
        uint256 feeAmount = prizeAmount.mul(FEE_PERCENTAGE).div(100);
        uint256 deadAmount = prizeAmount.mul(DEAD_PERCENTAGE).div(100);

        token.transfer(raffles[raffleId].creator, creatorAmount);
        token.transfer(feeAddress, feeAmount);
        token.transfer(deadAddress, deadAmount);

        _updateTotalTokensSentToDead(deadAmount);

        rafflesEndedSuccessfully[raffleId] = true;

        walletData[raffles[raffleId].creator].totalTokensSentToDead += deadAmount;
        walletData[raffles[raffleId].creator].totalRafflesCompleted++;

        emit RaffleEnded(raffleId, winningTicket, winner);
    }

    function endRaffleAfterExpiry(uint256 raffleId) internal {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(raffles[raffleId].ended == false, "Raffle has already ended");
        require(raffles[raffleId].endTime > 0 && block.timestamp > raffles[raffleId].endTime, "Raffle has not expired yet");

        raffles[raffleId].ended = true;

        IERC20 token = IERC20(tokenAddress);
        uint256 ticketPrice = raffles[raffleId].ticketPrice;

        for (uint256 i = 0; i < participants[raffleId].length; i++) {
            address participant = participants[raffleId][i];
            uint256 participantTicketCount = getParticipantTicketCount(raffleId, participant);
            uint256 refundAmount = participantTicketCount.mul(ticketPrice).mul(TOKEN_DECIMALS);

            try token.transfer(participant, refundAmount) {
            } catch {
                for (uint256 j = 0; j < i; j++) {
                    address prevParticipant = participants[raffleId][j];
                    uint256 prevParticipantTicketCount = getParticipantTicketCount(raffleId, prevParticipant);
                    uint256 prevRefundAmount = prevParticipantTicketCount.mul(ticketPrice).mul(TOKEN_DECIMALS);
                    token.transfer(prevParticipant, prevRefundAmount);
                }
                revert("Token transfer failed, refunds reverted");
            }
        }

        IERC721 nft = IERC721(raffles[raffleId].nftContract);
        nft.safeTransferFrom(address(this), raffles[raffleId].creator, raffles[raffleId].nftId);

        delete raffles[raffleId];
        delete participants[raffleId];

        emit RaffleEnded(raffleId, 0, address(0));
    }

    function getParticipantTicketCount(uint256 raffleId, address participant) private view returns (uint256) {
        uint256 ticketCount = 0;

        for (uint256 i = 1; i <= raffles[raffleId].ticketSold; i++) {
            if (tickets[raffleId][i] == participant) {
                ticketCount++;
            }
        }
        return ticketCount;
    }

    function generateRandomNumber(uint256 raffleId, uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed, raffleId))) %
            raffles[raffleId].ticketSupply +
            1;
    }


    function getWalletInfo(address walletAddress) external view returns (uint256, uint256, uint256, uint256, uint256) {
        WalletInfo memory info = walletData[walletAddress];
        return (
            info.totalRafflesCreated,
            info.totalRafflesCompleted,
            info.totalRafflesParticipated,
            info.totalRafflesUnsuccessful,
            info.totalTokensSentToDead
        );
    }

    function getTicketsBoughtByAddress(uint256 raffleId, address participant) external view returns (uint256) {
        return ticketsBoughtPerRaffle[raffleId][participant];
    }

    function getActiveRaffles() public view returns (Raffle[] memory) {
        uint256 activeRaffleCount = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (!raffles[i].ended && raffles[i].creator != address(0)) {
                activeRaffleCount++;
            }
        }

        Raffle[] memory activeRaffles = new Raffle[](activeRaffleCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (!raffles[i].ended && raffles[i].creator != address(0)) {
                activeRaffles[index] = raffles[i];
                index++;
            }
        }
        return activeRaffles;
    }

    function getEndedRaffles() public view returns (Raffle[] memory) {
        uint256 endedRaffleCount = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (isRaffleEnded[i]) {
                endedRaffleCount++;
            }
        }

        Raffle[] memory endedRaffles = new Raffle[](endedRaffleCount);
        uint256 index = 0;

        for (uint256 i = 1; i <= raffleCount; i++) {
            if (isRaffleEnded[i]) {
                endedRaffles[index] = raffles[i];
                index++;
            }
        }
        return endedRaffles;
    }

    function getActiveRaffleParticipants(uint256 raffleId) public view returns (address[] memory, uint256[] memory) {
        require(raffles[raffleId].id > 0, "Raffle does not exist");
        require(!raffles[raffleId].ended, "Raffle has ended");

        uint256 participantCount = participants[raffleId].length;

        address[] memory participantAddresses = new address[](participantCount);
        uint256[] memory ticketCounts = new uint256[](participantCount);

        for (uint256 i = 0; i < participantCount; i++) {
            address participant = participants[raffleId][i];
            uint256 count = getParticipantTicketCount(raffleId, participant);
            participantAddresses[i] = participant;
            ticketCounts[i] = count;
        }
        return (participantAddresses, ticketCounts);
    }

    function withdrawTokens(address tokenToWithdraw, uint256 amount) external onlyOwner {
        require(tokenToWithdraw != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(tokenToWithdraw);

        uint256 withdrawalAmount = amount * TOKEN_DECIMALS;

        require(token.balanceOf(address(this)) >= withdrawalAmount, "Insufficient token balance in the contract");
        require(token.transfer(msg.sender, withdrawalAmount), "Token transfer failed");

        emit TokensWithdrawn(tokenToWithdraw, withdrawalAmount);
    }

}