/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/darkmatter/rewards/StakingView.sol


pragma solidity ^0.8.4;


interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract StakingView {
    using SafeMath for uint256;

    address public nftAddr;

    struct PoolInfo {
        string poolName;
        address tokenAddr;
        string tokenSymbol;
        uint8 tokenDecimals;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 depositTime;
    }
    PoolInfo[] PoolsArr;

    // poolIdx => nftId => true/false
    mapping(uint256 => mapping(uint256 => bool)) public ClaimsTable;

    // rarityRangeArr defines the ranges of rarity
    // e.g. [1, 300, 1000, 2000, 4000, 8888], here the first range is "1-300" (1st tokenId to 300th tokenId), the second is "300-1000", etc.
    uint256[] public rarityRangeArr;

    // rarityPercentArr defines the percentage of each rarity range
    // e.g. [10, 20, 30, 40, 50], here the first range (which is mentioned as 1-300 in the above comment) owns "10%" of totalAmout of every pool,
    // the second owns "20%", etc.
    uint256[] public rarityPercentArr;

    function totalPools() public view returns (uint256) {
        return PoolsArr.length;
    }

    function poolInfoOfId(uint256 _poolId)
        public
        view
        returns (PoolInfo memory)
    {
        return PoolsArr[_poolId];
    }

    struct NFTRewardInfo {
        address tokenAddr;
        uint256 tokenAmt;
        string tokenSymbol;
        uint8 tokenDecimals;
    }

    function rewardsOf(uint256 _poolId, uint256 _tokenId)
        public
        view
        returns (NFTRewardInfo memory)
    {
        address _rwdToken = poolInfoOfId(_poolId).tokenAddr;
        string memory _rwdTokenSymbol = poolInfoOfId(_poolId).tokenSymbol;
        uint8 _tokenDec = poolInfoOfId(_poolId).tokenDecimals;

        if (ClaimsTable[_poolId][_tokenId] == true) {
            return NFTRewardInfo(_rwdToken, 0, _rwdTokenSymbol, _tokenDec); // already claimed
        }

        for (uint256 i = 1; i < rarityRangeArr.length; i++) {
            if (_tokenId <= rarityRangeArr[i]) {
                uint256 _totalPoolAmt = PoolsArr[_poolId].totalAmount;
                uint256 _rarityPercent = rarityPercentArr[i - 1];

                uint256 _rwdsForCurrRange = _totalPoolAmt
                    .mul(_rarityPercent)
                    .div(100);
                uint256 _noOfNFTsInRange = rarityRangeArr[i] -
                    rarityRangeArr[i - 1];
                if (i == 1) _noOfNFTsInRange += 1; // we need to add 1 to the total no. of NFTs in the first range
                // as the number at index 0 is part of first range unlike the others

                uint256 _nftRwds = _rwdsForCurrRange.div(_noOfNFTsInRange);
                return
                    NFTRewardInfo(
                        _rwdToken,
                        _nftRwds,
                        _rwdTokenSymbol,
                        _tokenDec
                    );
            }
        }
        return NFTRewardInfo(_rwdToken, 0, _rwdTokenSymbol, _tokenDec); // out of range tokenId
    }
}
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/darkmatter/rewards/StakingAdmin.sol


pragma solidity ^0.8.4;



contract StakingAdmin is StakingView, Ownable {
    function updateRarity(
        uint256[] memory _rarityRangeArr,
        uint256[] memory _rarityPercentArr
    ) external onlyOwner {
        for (uint256 i = 1; i < _rarityRangeArr.length; i++) {
            require(
                _rarityRangeArr[i] > _rarityRangeArr[i - 1],
                'rarityRangeArr must be in ascending order'
            );
        }
        require(
            _rarityRangeArr.length == _rarityPercentArr.length + 1,
            'rarityRangeArr will have one more element than rarityPercentArr'
        );
        uint256 _totalPercent;
        for (uint256 i = 0; i < _rarityPercentArr.length; i++) {
            _totalPercent += _rarityPercentArr[i];
        }
        require(_totalPercent == 100, 'totalPercent must be 100');

        rarityRangeArr = _rarityRangeArr;
        rarityPercentArr = _rarityPercentArr;
    }

    event RewardsDeposited(
        address indexed tokenAddr,
        string tokenSymbol,
        uint8 tokenDecimals,
        uint256 tokenAmount,
        uint256 depositTime
    );

    function depositRewards(
        string calldata _poolName,
        address _tokenAddr,
        uint256 _tokenAmt
    ) external payable onlyOwner {
        string memory _tokenSymbol = 'ETH';
        uint8 _tokenDecimals = 18;
        if (_tokenAddr == address(0)) {
            require(msg.value >= _tokenAmt, 'Insufficent ETH sent');
        } else {
            _tokenSymbol = IERC20(_tokenAddr).symbol();
            _tokenDecimals = IERC20(_tokenAddr).decimals();
            IERC20(_tokenAddr).transferFrom(
                msg.sender,
                address(this),
                _tokenAmt
            );
        }

        PoolsArr.push(
            PoolInfo(
                _poolName,
                _tokenAddr,
                _tokenSymbol,
                _tokenDecimals,
                _tokenAmt,
                0,
                block.timestamp
            )
        );

        emit RewardsDeposited(
            _tokenAddr,
            _tokenSymbol,
            _tokenDecimals,
            _tokenAmt,
            block.timestamp
        );
    }

    event RewardsWithdrawn(address tokenAddress, uint256 amount);

    function withdrawRewards(
        address _tokenAddr,
        uint256 _amount,
        bool _withdrawAll
    ) external onlyOwner {
        if (_tokenAddr == address(0)) {
            if (_withdrawAll) {
                payable(owner()).transfer(address(this).balance);
            } else {
                payable(owner()).transfer(_amount);
            }
        } else {
            if (_withdrawAll) {
                uint256 _bal1 = IERC20(_tokenAddr).balanceOf(address(this));
                IERC20(_tokenAddr).transfer(owner(), _bal1);
            } else {
                IERC20(_tokenAddr).transfer(owner(), _amount);
            }
        }
        emit RewardsWithdrawn(_tokenAddr, _amount);
    }

    event PoolAmountsUpdated(uint256 poolId, uint256 poolAmount);

    function updatePoolAmounts(uint256 _poolId, uint256 _poolAmt)
        external
        onlyOwner
    {
        if (_poolAmt == 0) {
            // delete pool
            uint256 lastIdx = PoolsArr.length - 1;
            PoolsArr[_poolId] = PoolsArr[lastIdx];
            PoolsArr.pop();
        } else {
            PoolsArr[_poolId].totalAmount = _poolAmt;
        }
        emit PoolAmountsUpdated(_poolId, _poolAmt);
    }
}
// File: contracts/darkmatter/rewards/Rewards.sol


pragma solidity ^0.8.4;


contract Rewards is StakingAdmin {
    constructor(address _nftAddr) {
        nftAddr = _nftAddr;
    }

    event RewardsClaimed(
        uint256 indexed poolId,
        uint256 indexed nftId,
        uint256 rewardAmount,
        address indexed nftOwner,
        uint256 claimTime
    );

    function _claimRewardOf(uint256 _tokenId) private {
        address _tokenOwner = IERC721(nftAddr).ownerOf(_tokenId);
        require(msg.sender == _tokenOwner, 'Only NFT-owner can claim rewards');

        for (uint256 i = 0; i < totalPools(); i++) {
            NFTRewardInfo memory _rwdsInfo = rewardsOf(i, _tokenId);

            // reward amount == 0 if pool does not exist or reward amount already claimed
            if (_rwdsInfo.tokenAmt == 0) continue;

            ClaimsTable[i][_tokenId] = true;

            if (_rwdsInfo.tokenAddr == address(0))
                payable(_tokenOwner).transfer(_rwdsInfo.tokenAmt);
            else
                IERC20(_rwdsInfo.tokenAddr).transfer(
                    _tokenOwner,
                    _rwdsInfo.tokenAmt
                );
            emit RewardsClaimed(
                i,
                _tokenId,
                _rwdsInfo.tokenAmt,
                _tokenOwner,
                block.timestamp
            );
        }
    }

    function claimRewardsOf(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _claimRewardOf(_tokenIds[i]);
        }
    }
}