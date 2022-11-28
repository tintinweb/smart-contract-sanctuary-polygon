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
/**
 ______   ______   ______   ______   ______   __     __    
/\  ___\ /\  ___\ /\  ___\ /\  == \ /\  __ \ /\ \  _ \ \   
\ \  __\ \ \___  \\ \ \____\ \  __< \ \ \/\ \\ \ \/ ".\ \  
 \ \_____\\/\_____\\ \_____\\ \_\ \_\\ \_____\\ \__/".~\_\ 
  \/_____/ \/_____/ \/_____/ \/_/ /_/ \/_____/ \/_/   \/_/ 

 */
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./extensions/LensExtension.sol";

contract Escrow is Ownable, LensExtension {
    uint256 public protocolFee; // basis points
    mapping(address => uint256) public feesEarned;

    uint256 internal count;
    mapping(uint256 => Bounty) public bounties;
    mapping(address => bool) public allowedDepositors;

    bool internal onlyAllowedDepositors = true;

    struct Bounty {
        uint256 amount;
        address sponsor;
        address token;
    }

    // EVENTS
    event BountyCreated(uint256 bountyId, Bounty bounty);
    event BountySettled(uint256 bountyId);
    event BountyRefunded(uint256 bountyId);
    event DepositorsAdded(address[] depositors);
    event DepositorsRemoved(address[] depositors);
    event OpenTheGates();
    event SetProtocolFee(uint256 protocolFee);

    // ERRORS
    error EarlySettlement();
    error NotArbiter();
    error DepositorNotAllowed();
    error InvalidSplits();

    constructor(address _lensHub, uint256 _protocolFee)
        Ownable()
        LensExtension(_lensHub)
    {
        protocolFee = _protocolFee;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice desposits tokens creating an open bounty
     * @param token token to deposit
     * @param amount amount of token to deposit
     */
    function deposit(address token, uint256 amount)
        external
        returns (uint256 bountyId)
    {
        if (onlyAllowedDepositors && !allowedDepositors[_msgSender()]) {
            revert DepositorNotAllowed();
        }
        Bounty memory newBounty = Bounty(amount, _msgSender(), token);
        bounties[++count] = newBounty;

        IERC20(token).transferFrom(
            _msgSender(),
            address(this),
            amount + calcFee(amount)
        );

        emit BountyCreated(count, newBounty);
        return count;
    }

    /**
     * @notice settles the bounty by splitting evenly between all recipients
     * @param bountyId bounty to settle
     * @param recipients list of addresses to disperse to
     */
    function settle(
        uint256 bountyId,
        address[] calldata recipients,
        PostWithSigData[] calldata posts
    ) external {
        uint256 split = 100000 / recipients.length;
        Bounty memory bounty = bounties[bountyId];
        if (_msgSender() != bounty.sponsor) {
            revert NotArbiter();
        }

        IERC20 token = IERC20(bounty.token);
        for (uint256 i = 0; i < recipients.length; ++i) {
            uint256 recipSplit = (split * bounty.amount) / 100000;
            token.transfer(recipients[i], recipSplit);
        }

        feesEarned[bounty.token] += calcFee(bounty.amount);

        postWithSigBatch(posts);

        delete bounties[bountyId];

        emit BountySettled(bountyId);
    }

    /**
     * @notice settles the bounty by splitting between all recipients and posts to Lens
     * @param bountyId bounty to settle
     * @param recipients list of addresses to disperse to
     * @param splits list of split amounts to go to each recipient
     * @param posts PostWithSigData to post to Lens on recipients behalf
     */
    function rankedSettle(
        uint256 bountyId,
        address[] calldata recipients,
        uint256[] calldata splits,
        PostWithSigData[] calldata posts
    ) external {
        Bounty memory bounty = bounties[bountyId];
        if (_msgSender() != bounty.sponsor) {
            revert NotArbiter();
        }

        uint256 splitTotal;
        IERC20 token = IERC20(bounty.token);
        for (uint256 i = 0; i < recipients.length; ++i) {
            splitTotal += splits[i];
            token.transfer(recipients[i], splits[i]);
        }

        if (splitTotal > bounty.amount) {
            revert InvalidSplits();
        }

        uint256 totalSpend = bounty.amount + calcFee(bounty.amount);
        uint256 updatedFee = calcFee(splitTotal);

        feesEarned[bounty.token] += updatedFee;

        unchecked {
            token.transfer(
                bounty.sponsor,
                totalSpend - splitTotal - updatedFee
            );
        }

        postWithSigBatch(posts);

        delete bounties[bountyId];

        emit BountySettled(bountyId);
    }

    /**
     * @notice can be called by owner to refund bounty in case of issue
     * @param bountyId id of bounty to refund
     */
    function refund(uint256 bountyId) external onlyOwner {
        Bounty memory bounty = bounties[bountyId];
        uint256 amountPlusFee = bounty.amount + calcFee(bounty.amount);
        IERC20(bounty.token).transfer(bounty.sponsor, amountPlusFee);

        delete bounties[bountyId];

        emit BountyRefunded(bountyId);
    }

    /**
     * @notice calculates the fee to be paid on a token amount
     * @param amount token amount to calculate fee for
     */
    function calcFee(uint256 amount) public view returns (uint256) {
        return (amount * protocolFee) / 10_000;
    }

    // ADMIN FUNCTIONS

    /// @notice sets the protocol fee (in basis points). Close all outstanding bounties before calling
    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        protocolFee = _protocolFee;

        emit SetProtocolFee(_protocolFee);
    }

    /// @notice withdraws all accumulated fees
    function withdrawFees(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; ++i) {
            uint256 contractBal = feesEarned[_tokens[i]];
            feesEarned[_tokens[i]] = 0;
            IERC20(_tokens[i]).transfer(owner(), contractBal);
        }
    }

    /// @notice add list of depositors to allowlist
    function addDepositors(address[] calldata _allowedDepositors)
        external
        onlyOwner
    {
        for (uint8 i = 0; i < _allowedDepositors.length; ++i) {
            allowedDepositors[_allowedDepositors[i]] = true;
        }

        emit DepositorsAdded(_allowedDepositors);
    }

    /// @notice remove list of depositors from allowlist
    function removeDepositors(address[] calldata _allowedDepositors)
        external
        onlyOwner
    {
        for (uint8 i = 0; i < _allowedDepositors.length; ++i) {
            allowedDepositors[_allowedDepositors[i]] = false;
        }

        emit DepositorsRemoved(_allowedDepositors);
    }

    /// @notice remove allowlist requirement for depositors
    function openTheGates() external onlyOwner {
        onlyAllowedDepositors = false;

        emit OpenTheGates();
    }

    /// @notice fallback function to prevent accidental ether transfers
    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface DataTypes {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct PostWithSigData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }
}

interface ILensHub is DataTypes {
    function postWithSig(PostWithSigData calldata vars)
        external
        returns (uint256);
}

contract LensExtension is DataTypes {
    address internal lensHubAddress;

    constructor(address _lensHub) {
        lensHubAddress = _lensHub;
    }

    function postWithSigBatch(PostWithSigData[] calldata posts) internal {
        ILensHub lensHub = ILensHub(lensHubAddress);
        for (uint256 i = 0; i < posts.length; ++i) {
            lensHub.postWithSig(posts[i]);
        }
    }
}