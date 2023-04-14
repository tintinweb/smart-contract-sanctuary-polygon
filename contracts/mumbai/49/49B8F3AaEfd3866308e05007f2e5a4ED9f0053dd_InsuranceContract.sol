pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract InsuranceContract {
    using SafeMath for uint256;

    address public owner;
    address public usdtToken = 0x4e898f14c7E0e3ccb2761182317686A110bCcf42;
    address payable public insurancePool;
    uint256 public totalRefRewards;
    uint256 public refLevel1Rewards;
    uint256 public refLevel2Rewards;
    uint256 public refLevel3Rewards;
    mapping(address => bool) public admins;
    mapping(uint256 => Package) public packages;
    mapping(uint256 => address[]) public packageUsers;
    mapping(address => uint256) public packagePrices;
    mapping(address => mapping(address => uint256)) public userPackage;
    mapping(address => mapping(uint256 => address)) public userRefs;
    mapping(address => mapping(address => bool)) public isUserRef;
    
    event PackagePriceUpdated(address package, uint256 price);
    event PackagePurchased(address user, uint256 packageId, uint256 price);
    event ReferralRewardPaid(address user, address referrer, uint256 amount, uint256 level);
    
    struct Package {
        uint256 id;
        uint256 price;
    }
    
    constructor(address payable _insurancePool) {
        owner = msg.sender;
        insurancePool = _insurancePool;
        admins[msg.sender] = true;
        totalRefRewards = 0;
        refLevel1Rewards = 15;
        refLevel2Rewards = 10;
        refLevel3Rewards = 5;
        
        // Initialize packages
        packages[1] = Package(1, 100 * 1e6 );
        packages[2] = Package(2, 200 *1e6  );
        packages[3] = Package(3, 300 *1e6 );
        packages[4] = Package(4, 400 *1e6 );
        packages[5] = Package(5, 500 *1e6 );
        packages[6] = Package(6, 600 *1e6 );
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Only admin can call this function.");
        _;
    }
    
    function setPackagePrice(address package, uint256 price) public onlyAdmin {
        packagePrices[package] = price;
        emit PackagePriceUpdated(package, price);
    }
    
    function buyPackage(uint256 _packageId, address _referrer) public {
        require(_packageId > 0 && _packageId <= 6, "Invalid package ID");
        Package storage package = packages[_packageId];
        uint256 packagePrice = package.price;
        IERC20(usdtToken).transferFrom(msg.sender, address(this), packagePrice);
        
       

        // Send 70% of the package price to the predefined address
        uint256 payoutAmount = (packagePrice * 7) / 10;
        IERC20(usdtToken).transfer(owner, payoutAmount);

        // Add the user to the packageUsers mapping
        packageUsers[_packageId].push(msg.sender);

 // Distribute referral rewards
        distributeReferralRewards(packagePrice, msg.sender);
        // Emit event
        emit PackagePurchased(msg.sender, _packageId, packagePrice);
    }
function distributeReferralRewards(uint256 _packagePrice, address _currentUser) internal {
    address level1Referrer = userRefs[_currentUser][1];
    address level2Referrer = userRefs[level1Referrer][1];
    address level3Referrer = userRefs[level2Referrer][1];

    if (level1Referrer != address(0)) {
        uint256 level1Reward = _packagePrice.mul(refLevel1Rewards).div(100);
        IERC20(usdtToken).transfer(level1Referrer, level1Reward);
        totalRefRewards = totalRefRewards.add(level1Reward);
        emit ReferralRewardPaid(_currentUser, level1Referrer, level1Reward, 1);
    }

    if (level2Referrer != address(0)) {
        uint256 level2Reward = _packagePrice.mul(refLevel2Rewards).div(100);
        IERC20(usdtToken).transfer(level2Referrer, level2Reward);
        totalRefRewards = totalRefRewards.add(level2Reward);
        emit ReferralRewardPaid(_currentUser, level2Referrer, level2Reward, 2);
    }

    if (level3Referrer != address(0)) {
        uint256 level3Reward = _packagePrice.mul(refLevel3Rewards).div(100);
        IERC20(usdtToken).transfer(level3Referrer, level3Reward);
        totalRefRewards = totalRefRewards.add(level3Reward);
        emit ReferralRewardPaid(_currentUser,level3Referrer, level3Reward, 3);
    }
}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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