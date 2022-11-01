// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IHashStratDAOToken.sol";
import "./IDivsDistributor.sol";


/**
 * This contract allows to distribute dividends to DAO token holders.
 *
 * The Owner of this contact should be DAOOperations that will be allow to
 * suspend or change the distribution periods.
 *
 */

contract DivsDistributor is Ownable, IDivsDistributor {

    event DistributionIntervalCreated(uint paymentIntervalId, uint dividendsAmount, uint blockFrom, uint blockTo);
    event DividendsClaimed(address indexed recipient, uint amount);


    uint immutable MIN_BLOCKS_INTERVAL = 1 * 24 * 60 * 60 / 2; 
    uint immutable MAX_BLOCKS_INTERVAL = 90 * 24 * 60 * 60 / 2; 

    // Number of blocks for a payment interval
    uint public paymentInterval = 30 * 24 * 60 * 60 / 2; // 30 days (Polygon block time is ~ 2s)


    // The DAO token to distribute to stakers
    IHashStratDAOToken immutable public hstToken;
    IERC20Metadata immutable public feesToken;

    uint public totalDivsPaid;
    DistributionInterval[] public distributionIntervals;
    

    struct DistributionInterval {
        uint id;
        uint reward;    // the divs to be distributed
        uint from;      // block number
        uint to;        // block number
        uint rewardsPaid;
    }

    // distribution_interval_id => ( account => claimed_amount) 
    mapping(uint => mapping(address => uint)) claimed;


    constructor(address feesTokenAddress, address hstTokenAddress) {
        feesToken = IERC20Metadata(feesTokenAddress);
        hstToken = IHashStratDAOToken(hstTokenAddress);
    }


    function getDistributionIntervals() public view returns (DistributionInterval[] memory) {
        return distributionIntervals;
    }


    function getDistributionIntervalsCount() public view returns (uint) {
        return distributionIntervals.length;
    }


    function claimableDivs(address account) public view returns (uint divs) {

        if (distributionIntervals.length == 0) return 0;

        DistributionInterval memory distribution = distributionIntervals[distributionIntervals.length - 1];

        if (distribution.from >= block.number) return 0;

        if (claimedDivs(distribution.id, account) == 0) {
            uint tokens = hstToken.getPastVotes(account, distribution.from);
            uint totalSupply = hstToken.getPastTotalSupply(distribution.from);

            divs = totalSupply > 0 ? distribution.reward * tokens / totalSupply : 0;
        }

        return divs;
    }


    function claimedDivs(uint distributionId, address account) public view returns (uint) {
        return claimed[distributionId][account];
    }


    // transfer dividends to sender
    function claimDivs() public {
        uint divs = claimableDivs(msg.sender);
        if (divs > 0) {
            DistributionInterval storage distribution = distributionIntervals[distributionIntervals.length - 1];
            claimed[distribution.id][msg.sender] = divs;
            distribution.rewardsPaid += divs;
            totalDivsPaid += divs;

            feesToken.transfer(msg.sender, divs);

            emit DividendsClaimed(msg.sender, divs);
        }
    }


    ///// IDivsDistributor
    
    function canCreateNewDistributionInterval() public view returns (bool) {
        return feesToken.balanceOf(address(this)) > 0 &&
               (distributionIntervals.length == 0 || block.number > distributionIntervals[distributionIntervals.length-1].to);
    }


    // Add a new reward period.
    // Requires to be called after the previous period ended and requires positive 'feesToken' balance
    function addDistributionInterval() external {
        require(canCreateNewDistributionInterval(), "Cannot create distribution interval");

        uint from = distributionIntervals.length == 0 ? block.number : distributionIntervals[distributionIntervals.length-1].to + 1;
        uint to = block.number + paymentInterval;

        // determine the reward amount
        uint reward = feesToken.balanceOf(address(this));
        distributionIntervals.push(DistributionInterval(distributionIntervals.length+1, reward, from, to, 0));

        emit DistributionIntervalCreated(distributionIntervals.length, reward, from, to);
    }


    //// OnlyOwner functionality
    function updatePaymentInterval(uint blocks) public onlyOwner {
        require (blocks >= MIN_BLOCKS_INTERVAL && blocks <= MAX_BLOCKS_INTERVAL, "Invalid payment interval");
        paymentInterval = blocks;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IHashStratDAOToken is IERC20Metadata {

    function maxSupply() external view returns (uint);
    function mint(address to, uint256 amount) external;
    function getPastVotes(address account, uint256 blockNumber) external view  returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);


    function delegates(address account) external view returns (address);
    function delegate(address delegator, address delegatee) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDivsDistributor {

    function canCreateNewDistributionInterval() external view returns (bool);
    function addDistributionInterval() external;
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