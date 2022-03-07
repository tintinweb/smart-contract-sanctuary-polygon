/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
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
contract BullManager {

    using SafeMath for uint256;



    enum TreeState {Active, Inactive}



    struct Tree {

        string name;

        uint lastClaimTime;

        uint expiration;

        uint accumulatedRewards;

        TreeState state;

    }



    IERC20 public token;

    address owner;



    uint256 public totalClaimed;

    uint256 public totalTrees; 

    uint public maxTreesPerUser;



    mapping(address => Tree[]) public treesOwned;



    // CHANGE THIS 

    address payable TREASURY = payable(0x109Eff973fF8D571d8450939656B5b73c170A096);

    address payable REWARDS = payable(0x109Eff973fF8D571d8450939656B5b73c170A096); 

    address payable LIQUIDITY = payable(0x109Eff973fF8D571d8450939656B5b73c170A096);



    // PER DAY 

    uint rewardPerTree = 0.225*10**18; 



    // Cost to buy a tree 

    uint costPerTree = 10*10**18;

    // uint treasuryPercent = 0.2; // Turns into matic 

    // uint liquidityPercent = 0.1; // Turns into 50% matic 

    // uint rewardsPercent = 0.7; // Pays tree holders 0.225 bull per day per tree

    // Cost to refresh

    uint refreshCost;

    

    event TreeCreated(address indexed _owner);

    event TreeExpired(address indexed _owner, string _treeName, uint _expiration);

    

    // MODIFIERS

    modifier onlyOwner() {

        require(msg.sender == owner, "Only Owner can Access!");

        _;

    }

    modifier checkActiveTrees(address _owner) {

        require(treesOwned[_owner].length > 0, "You own no trees!");

        // Check if any tree has expired

        for (uint i=0; i<treesOwned[_owner].length; i++) {

            if (treesOwned[_owner][i].expiration > block.timestamp) {

                emit TreeExpired(_owner, treesOwned[_owner][i].name, treesOwned[_owner][i].expiration);

                treesOwned[_owner][i].state = TreeState.Inactive;

                // delete treesOwned[_owner][i]; // send tree funds to address 

            } 

        }

        _;

    }



    // FUNCTIONS

    constructor(address _token) {

        token = IERC20(_token);

        owner = msg.sender;

    }



    // Create a tree given enough tokens 

    function createTreeWithTokens(string memory _treeName) public {

        require(treesOwned[msg.sender].length < maxTreesPerUser, "You have reached the maximum amount of trees!");

        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create Trees");

        require(token.balanceOf(msg.sender) >= costPerTree, "Not enough tokens to create Tree!");



        token.transferFrom(msg.sender, address(this), costPerTree);



        Tree memory newTree = Tree(_treeName, block.timestamp, block.timestamp+90 days, 0, TreeState.Active);

        treesOwned[msg.sender].push(newTree);

        totalTrees++;

    }



    // SWAP AND SEND TO POOLS (communicate with front-end)

    // function splitToPools(address _token1, uint _amount1, address _token2, uint _amount2) {

    //     uint _treasuryTransferAmount = _amount * treasuryPercent;

    //     uint _rewardsTransferAmount = _amount * rewardsPercent;

    //     uint _liquidityTransferAmount = _amount * liquidityPercent;



    //     TREASURY.transfer(_treasuryTransferAmount);

    //     REWARDS.transfer(_rewardsTransferAmount);

    //     LIQUIDITY.transfer(_liquidityTransferAmount);

    // }



    // CALCULATIONS

    // Calculate Rewards (good way to see if trees are expired without claiming anything)

    function calculateRewards(address _user) public checkActiveTrees(_user) returns(uint) {

        require(treesOwned[_user].length > 0, "You own no trees!");

        uint _totalRewards = 0;

        for (uint i=0; i<treesOwned[_user].length; i++) {

            if (treesOwned[_user][i].state == TreeState.Active) {

                uint epochsPassed = (block.timestamp-treesOwned[_user][i].lastClaimTime) / 1 days;

                treesOwned[_user][i].accumulatedRewards =  epochsPassed * rewardPerTree;

                _totalRewards += treesOwned[_user][i].accumulatedRewards;

            }

        }

        return _totalRewards;

    }



    // Calculate the cost to refresh trees (90 days) 

    function calculateRefreshCost(address _user) public checkActiveTrees(_user) returns(uint) {

        uint _totalCost = 0;



        for (uint i=0; i<treesOwned[_user].length; i++) {

            if (treesOwned[_user][i].state == TreeState.Inactive) {

                _totalCost += refreshCost;

            }

        }



        return _totalCost;

    }



    // CLAIMING

    // Claim Rewards

    function claimRewards() public {

        uint _rewards = calculateRewards(msg.sender);

        token.transfer(msg.sender, _rewards);

        // Set new Claim Time

        for (uint i=0; i<treesOwned[msg.sender].length; i++) {

            treesOwned[msg.sender][i].lastClaimTime = block.timestamp;

        }

    }





    // SETTERS

    function setCostPerTree(uint256 _cost) external onlyOwner {

        costPerTree = _cost;

    }

    function setRewardsPerTree(uint _reward) external onlyOwner {

        rewardPerTree = _reward;

    }

    function setMaxTreesPerUser(uint _max) external onlyOwner {

        maxTreesPerUser = _max;

    }

    function setRefreshCostPerTree(uint _refreshCost) external onlyOwner {

        refreshCost = _refreshCost;

    }

    function setRewardsAddress(address payable _address) external onlyOwner {

        REWARDS = _address;

    }

    function setLiquidityAddress(address payable _address) external onlyOwner {

        LIQUIDITY = _address;

    }

    function setTreasuryAddress(address payable _address) external onlyOwner {

        TREASURY = _address;

    }



    



    // Recover tokens that were accidentally sent to this address 

    function recoverTokens(IERC20 _erc20, address _to) public onlyOwner {

        require(address(_erc20) != address(token), "You can't recover default token");

        uint256 _balance = _erc20.balanceOf(address(this));

        _erc20.transfer(_to, _balance);

    }

}