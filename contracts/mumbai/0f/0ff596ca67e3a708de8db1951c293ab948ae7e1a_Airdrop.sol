/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Airdrop is Pausable {
    
    using SafeMath for uint256;

    address public admin;
    IERC20 public token;

    uint256 public airdropAmount;
    uint256 public allotmentCount;
    uint256 public totalTokensAllotedTillDate;
    uint256 public totalClaimedTokens;
    uint256 public USDPerToken;
    uint256 public referralLevelOneBonusPercentage; // 1 - 100
    uint256 public referralLevelTwoBonusPercentage; // 1 - 100

    uint256 public totalReferalLevelOneReward;
    uint256 public totalReferalLevelTwoReward;
    uint256 public totalTokensAirdropped;
    uint256 public totalTokensPurchasedByBuy;

    struct Allotment {
        uint256 allotmentID;
        address userAddress;
        uint256 startTime;
        uint256 tokenAlloted;
    }

    mapping(uint256 => Allotment) public allotments;
    mapping(address => bool) public userAvailedAirdrop;
    mapping(address => uint256) public userAllotmentCount;
    mapping(address => uint256[]) public userAllotmentIds;
    mapping(address => uint256) public totalTokensPurchased;
    mapping(address => uint256) public userMintedBalance;
    mapping(address => bool) public validReferral;
    mapping(address => address) public userReferrer;
    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public usersLevelOneReferralEarning;
    mapping(address => uint256) public usersLevelTwoReferralEarning;
    mapping(address => uint256) public usersTotalTokenPurchased;
    mapping(address => uint256) public usersTotalTokenAirdrop;

    AggregatorV3Interface public pricefeedMATICUSD =
        AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);

    constructor(address _tokenAddress, address _admin, uint256 _USDPerToken, uint256 _airdropAmount, uint256 _referralLevelOneBonusPercentage, uint256 _referralLevelTwoBonusPercentage) {
        token = IERC20(_tokenAddress);
        admin = _admin;
        USDPerToken = _USDPerToken;
        airdropAmount = _airdropAmount;
        referralLevelOneBonusPercentage = _referralLevelOneBonusPercentage;
        referralLevelTwoBonusPercentage = _referralLevelTwoBonusPercentage;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "ONLY_ADMIN_CAN_EXECUTE_THIS_FUNCTION");
        _;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function updateAirdropAmount(uint256 _newAirdropAmount) public onlyAdmin {
        airdropAmount = _newAirdropAmount;
    }

    function updateReferralPercentage(uint256 _referralLevelOneBonusPercentage, uint256 _referralLevelTwoBonusPercentage) public onlyAdmin {
        referralLevelOneBonusPercentage = _referralLevelOneBonusPercentage;
        referralLevelTwoBonusPercentage = _referralLevelTwoBonusPercentage;
    }

    function getLatestMaticPrice() internal view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = pricefeedMATICUSD.latestRoundData();
        return price;
    }

    function buyTokens() public payable whenNotPaused {
        address referralAddress = userReferrer[msg.sender];
        uint256 USDPerMatic = uint256(getLatestMaticPrice());
        uint256 amount = USDPerMatic.mul(10000000000).mul(msg.value).div(USDPerToken);

        if(validReferral[referralAddress] && referralAddress != address(0)) {
            uint256 levelOnebonus = amount.mul(referralLevelOneBonusPercentage).div(100);
            allotToken(referralAddress, levelOnebonus);
            usersLevelOneReferralEarning[referralAddress] = usersLevelOneReferralEarning[referralAddress] + levelOnebonus;
            totalReferalLevelOneReward = totalReferalLevelOneReward + levelOnebonus;
            if(userReferrer[referralAddress] != address(0) ) {
                uint256 levelTwoBonus = airdropAmount.mul(referralLevelTwoBonusPercentage).div(100);
                allotToken(userReferrer[referralAddress], levelTwoBonus);
                usersLevelTwoReferralEarning[userReferrer[referralAddress]] = usersLevelTwoReferralEarning[userReferrer[referralAddress]] + levelTwoBonus;
                totalReferalLevelTwoReward = totalReferalLevelTwoReward + levelTwoBonus;
            }
        }
        allotToken(msg.sender, amount);
        usersTotalTokenPurchased[msg.sender] = usersTotalTokenPurchased[msg.sender] + amount;
        totalTokensPurchasedByBuy = totalTokensPurchasedByBuy + amount;
        (bool sent, bytes memory data) = payable(admin).call{value: msg.value}("");
        require(sent, "Failed to send Matic");
    }

    function airdrop(address _account, address _referralAddress) public whenNotPaused {
        require(!userAvailedAirdrop[_account], "Airdrop already availed");
        if(validReferral[_referralAddress] && _referralAddress != address(0)) {
            uint256 levelOnebonus = airdropAmount.mul(referralLevelOneBonusPercentage).div(100);
            allotToken(_referralAddress, levelOnebonus);
            usersLevelOneReferralEarning[_referralAddress] = usersLevelOneReferralEarning[_referralAddress] + levelOnebonus;
            totalReferalLevelOneReward = totalReferalLevelOneReward + levelOnebonus;
            if(userReferrer[_referralAddress] != address(0) ) {
                uint256 levelTwoBonus = airdropAmount.mul(referralLevelTwoBonusPercentage).div(100);
                allotToken(userReferrer[_referralAddress], levelTwoBonus);
                usersLevelTwoReferralEarning[userReferrer[_referralAddress]] = usersLevelTwoReferralEarning[userReferrer[_referralAddress]] + levelTwoBonus;
                totalReferalLevelTwoReward = totalReferalLevelTwoReward + levelTwoBonus;
            }
        }
        allotToken(_account, airdropAmount);
        userReferrer[_account] = _referralAddress;
        totalTokensAirdropped = totalTokensAirdropped + airdropAmount;
        usersTotalTokenAirdrop[_account] = usersTotalTokenAirdrop[_account] + airdropAmount;
    }

    function directTransferByAdmin(address _account, uint256 _amount) public onlyAdmin whenNotPaused {
        allotToken(_account, _amount);
    }

    function allotToken(address _address, uint256 _amount) internal {
        allotmentCount = allotmentCount + 1;
        Allotment memory alt = Allotment(
            allotmentCount,
            _address,
            block.timestamp,
            _amount
        );
        allotments[allotmentCount] = alt;
        totalTokensPurchased[_address] =
            totalTokensPurchased[_address] +
            _amount;
        userAllotmentIds[_address].push(allotmentCount);
        userAllotmentCount[_address] = userAllotmentCount[_address] + 1;
        totalTokensAllotedTillDate = totalTokensAllotedTillDate + _amount;
        validReferral[_address] = true;
        uint256 oneDayAllotment = _amount.div(730);
        token.transfer(_address, oneDayAllotment);
    }

    function getUserTokensAvailableForMinting(address _address)
        public
        view
        returns (uint256)
    {
        uint256 amount = 0;

        for (uint256 i = 0; i < userAllotmentIds[_address].length; i++) {
            
            uint256 numberOfDays = (
                block.timestamp.sub(
                    allotments[userAllotmentIds[_address][i]].startTime
                )
            ).div(10 minutes);
            
            uint256 oneDayAllotment = allotments[userAllotmentIds[_address][i]]
                .tokenAlloted
                .div(20);
            
            // Number of Days = Number of days - First Day(It's amount is credited immediately)
            numberOfDays = numberOfDays.sub(1);

            amount = amount + numberOfDays.mul(oneDayAllotment);
        }

        return amount.sub(claimedTokens[_address]);
    }

    function claimTokens() public {
        uint256 amount = getUserTokensAvailableForMinting(msg.sender);
        token.transfer(msg.sender, amount);
        claimedTokens[msg.sender] = amount;
        totalClaimedTokens = totalClaimedTokens.add(amount);
    }

    function adminTokenWithdrawal() public onlyAdmin {
        uint256 unclaimedTokens = totalTokensAllotedTillDate.sub(totalClaimedTokens);
        uint256 extraTokens = token.balanceOf(address(this)).sub(unclaimedTokens);
        token.transfer(admin, extraTokens);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

}