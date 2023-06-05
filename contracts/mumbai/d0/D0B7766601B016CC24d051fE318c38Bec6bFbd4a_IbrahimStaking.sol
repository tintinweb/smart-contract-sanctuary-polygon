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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

interface IIICNft {
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IILCToken {
     function mint(address to, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IILCToken.sol";
import "./IIICNft.sol";

contract IbrahimStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public nft;

    address public token;

    uint256 public DAILY_REWARDS;

    mapping(uint256 => uint256) public lastClaimTime;
    mapping(uint256 => bool) public isStakedToken;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public userTotalRewards;
    mapping(address => uint256[]) public userStakedTokens;
    mapping(uint256 => stakeInfo) public stakedTokensInfo;

    struct stakeInfo {
        uint256 tokenId;
        address owner;
        uint256 stakedTime;
    }

    uint256[] public stakedTokenList;

    uint256 public totalStakedTokens;
    uint256 public totalRewardsClaimed;

    bool public marketingAllocationSent = false;
    bool public contingencyAllocationSent = false;
    bool public stakingEnabled = false;

    event TokenStaked(address indexed staker, uint256 indexed tokenId);

    event TokenUnstaked(
        address indexed staker,
        uint256 indexed tokenId,
        uint256 rewards
    );

    event RewardsClaimed(
        address indexed staker,
        uint256 tokenId,
        uint256 rewards
    );

    address public MARKETING_WALLET;
    address public CONTINGENCY_WALLET;
    uint256 public constant MARKETING_ALLOCATION = 100_000 ether;
    uint256 public constant CONTINGENCY_ALLOCATION = 100_000 ether;
    uint256 public constant MAX_TOKEN_SUPPLY = 1_000_000 ether;

    modifier onlyStaked(uint256 tokenId) {
        require(isStakedToken[tokenId] == true, "Token not staked.");
        _;
    }

    modifier onlyUnstaked(uint256 tokenId) {
        require(isStakedToken[tokenId] == false, "Token already staked.");
        _;
    }

    modifier onlyNftOwner(uint256 tokenId) {
        require(
            IIICNft(nft).ownerOf(tokenId) == msg.sender,
            "You must own the NFT to stake it."
        );
        _;
    }

    modifier underMaxTokenSupply() {
        require(
            IILCToken(token).totalSupply() < MAX_TOKEN_SUPPLY,
            "Token allocation exhausted"
        );
        _;
    }

    modifier amountUnderMaxTokenSupply(uint256 amount) {
        require(
            IILCToken(token).totalSupply() + amount <= MAX_TOKEN_SUPPLY,
            "Token allocation exhausted"
        );
        _;
    }

    modifier stakingIsEnabled() {
        require(stakingEnabled == true, "Staking is disabled");
        _;
    }

    modifier onlyStakedNftOwner(uint256 tokenId) {
        require(
            tokenOwner[tokenId] == msg.sender,
            "You must own the NFT to unstake it."
        );
        _;
    }

    modifier onlyStakedNftUser(address user) {
        require(
            userStakedTokens[user].length > 0,
            "No tokens staked for this address."
        );
        _;
    }

    function sendMarketingAllocation() external onlyOwner {
        require(
            marketingAllocationSent == false,
            "Marketing allocation already sent"
        );
        require(MARKETING_WALLET != address(0), "Invalid address");
        mintRewardToken(MARKETING_WALLET, MARKETING_ALLOCATION);
        marketingAllocationSent = true;
    }

    function sendContingencyAllocation() external onlyOwner {
        require(
            contingencyAllocationSent == false,
            "Contingency allocation already sent"
        );
        require(CONTINGENCY_WALLET != address(0), "Invalid address");
        mintRewardToken(CONTINGENCY_WALLET, CONTINGENCY_ALLOCATION);
        contingencyAllocationSent = true;
    }

    function setDailyRewards(uint256 _newRewards) external onlyOwner {
        DAILY_REWARDS = _newRewards;
    }

    function setStakingEnabled(bool _enabled) external onlyOwner {
        stakingEnabled = _enabled;
    }

    function setMarketingWallet(address _wallet) external onlyOwner {
        MARKETING_WALLET = _wallet;
    }

    function setContingencyWallet(address _wallet) external onlyOwner {
        CONTINGENCY_WALLET = _wallet;
    }

    function setNftContract(address _nft) external onlyOwner {
        require(nft == address(0), "NFT address already set");
        nft = _nft;
    }

    function setTokenContract(address _token) external onlyOwner {
        require(token == address(0), "Token address already set");
        token = _token;
    }

    function stake(
        uint256 tokenId
    )
    public
    onlyUnstaked(tokenId)
    onlyNftOwner(tokenId)
    underMaxTokenSupply
    stakingIsEnabled
    {
        IIICNft(nft).transferFrom(msg.sender, address(this), tokenId);

        require(
            IIICNft(nft).ownerOf(tokenId) == address(this),
            "Token transfer failed"
        );

        stakedTokenList.push(tokenId);
        userStakedTokens[msg.sender].push(tokenId);
        tokenOwner[tokenId] = msg.sender;
        isStakedToken[tokenId] = true;
        totalStakedTokens++;
        lastClaimTime[tokenId] = block.timestamp;

        stakedTokensInfo[tokenId] = stakeInfo(tokenId, msg.sender, block.timestamp);

        emit TokenStaked(msg.sender, tokenId);
    }

    function stakeMany(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i]);
        }
    }

    function unstake(
        uint256 tokenId
    ) public onlyStaked(tokenId) onlyStakedNftOwner(tokenId) {
        uint256 stakedTime = block.timestamp - lastClaimTime[tokenId];
        uint256 rewards = calculateRewards(stakedTime);
        IIICNft(nft).transferFrom(address(this), msg.sender, tokenId);
        require(
            IIICNft(nft).ownerOf(tokenId) == msg.sender,
            "Token transfer failed"
        );

        mintRewardToken(msg.sender, rewards);
        totalRewardsClaimed += rewards;
        userTotalRewards[msg.sender] += rewards;
        isStakedToken[tokenId] = false;
        tokenOwner[tokenId] = address(0);
        lastClaimTime[tokenId] = block.timestamp;

        delete stakedTokensInfo[tokenId];

        uint256 length = userStakedTokens[msg.sender].length;
        for (uint256 i = 0; i < length; i++) {
            if (userStakedTokens[msg.sender][i] == tokenId) {
                userStakedTokens[msg.sender][i] = userStakedTokens[msg.sender][
                length - 1
                ];
                userStakedTokens[msg.sender].pop();
                break;
            }
        }

        for (uint256 i = 0; i < stakedTokenList.length; i++) {
            if (stakedTokenList[i] == tokenId) {
                stakedTokenList[i] = stakedTokenList[stakedTokenList.length - 1];
                stakedTokenList.pop();
                break;
            }
        }

        totalStakedTokens--;
        emit TokenUnstaked(msg.sender, tokenId, rewards);
    }

    function unstakeMany(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
    }

    function claimRewardsForTokenId(
        uint256 tokenId
    ) public nonReentrant onlyStakedNftOwner(tokenId) onlyStaked(tokenId) {
        uint256 stakedTime = block.timestamp - lastClaimTime[tokenId];
        uint256 rewards = calculateRewards(stakedTime);

        require(rewards > 0, "No rewards available to claim.");

        mintRewardToken(msg.sender, rewards);
        lastClaimTime[tokenId] = block.timestamp;
        userTotalRewards[msg.sender] += rewards;
        totalRewardsClaimed += rewards;
        emit RewardsClaimed(msg.sender, tokenId, rewards);
    }

    function claimRewardsForAddress(
        address user
    ) external nonReentrant onlyStakedNftUser(user) {
        uint256 rewards = 0;
        for (uint256 i = 0; i < userStakedTokens[user].length; i++) {
            uint256 tokenId = userStakedTokens[user][i];
            require(
                msg.sender == tokenOwner[tokenId],
                "You are not the owner of this token."
            );
            uint256 stakedTime = block.timestamp - lastClaimTime[tokenId];
            uint256 indexedRewards = calculateRewards(stakedTime);
            rewards += indexedRewards;
            lastClaimTime[tokenId] = block.timestamp;
            emit RewardsClaimed(user, tokenId, indexedRewards);
        }
        require(rewards > 0, "No rewards available to claim.");
        mintRewardToken(user, rewards);
        userTotalRewards[user] += rewards;
        totalRewardsClaimed += rewards;
    }

    function mintRewardToken(
        address to,
        uint256 amount
    ) internal amountUnderMaxTokenSupply(amount) {
        IILCToken(token).mint(to, amount);
    }

    function releaseAllRewards() public onlyOwner {
        uint256[] memory tokenIds = IIICNft(nft).tokensOfOwner(address(this));

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isStakedToken[tokenIds[i]] == true) {
                uint256 tokenId = tokenIds[i];
                address owner = tokenOwner[tokenId];
                uint256 stakedTime = block.timestamp - lastClaimTime[tokenId];
                uint256 rewards = calculateRewards(stakedTime);
                mintRewardToken(owner, rewards);
                totalRewardsClaimed += rewards;
                userTotalRewards[owner] += rewards;
                lastClaimTime[tokenId] = block.timestamp;
            }
        }
    }

    function initiateHalving() external onlyOwner {
        DAILY_REWARDS /= 2;
    }

    function ownerMintRewardToken(
        address to,
        uint256 amount
    ) external onlyOwner amountUnderMaxTokenSupply(amount) {
        mintRewardToken(to, amount);
    }

    function getUnclaimedRewardsForAddress(
        address _address
    ) public view returns (uint256 rewards) {
        if (userStakedTokens[_address].length == 0) {
            return 0;
        }
        uint256[] memory tokenIds = userStakedTokens[_address];
        rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 stakedTime = block.timestamp - lastClaimTime[tokenId];
            rewards += calculateRewards(stakedTime);
        }
    }

    function getUnclaimedRewardsForTokenId(
        uint256 tokenId
    ) external view returns (uint256 rewards) {
        if (isStakedToken[tokenId] == false) {
            return 0;
        }

        uint256 stakedTime = block.timestamp - lastClaimTime[tokenId];
        rewards = calculateRewards(stakedTime);
    }

    function getTotalRewardsForAddress(
        address _address
    ) external view returns (uint256 rewards) {
        rewards = getUnclaimedRewardsForAddress(_address);
        rewards += userTotalRewards[_address];
    }

    function getTokenIdsForAddress(
        address user
    ) external view returns (uint256[] memory) {
        return userStakedTokens[user];
    }

    function getAllStakedList() public view returns (stakeInfo[] memory) {
        stakeInfo[] memory stakedTokens = new stakeInfo[](stakedTokenList.length);
        for (uint256 i = 0; i < stakedTokenList.length; i++) {
            stakedTokens[i] = stakedTokensInfo[stakedTokenList[i]];
        }
        return stakedTokens;
    }

    function calculateRewards(
        uint256 stakedTime
    ) public view returns (uint256 rewards) {
        rewards = stakedTime.mul(DAILY_REWARDS) / 1 days;

        uint256 totalSupply = IILCToken(token).totalSupply();
        if (totalSupply >= MAX_TOKEN_SUPPLY) {
            return 0;
        }

        if (totalSupply + rewards > MAX_TOKEN_SUPPLY) {
            return rewards = MAX_TOKEN_SUPPLY - totalSupply;
        }
        return rewards;
    }

    function getNFTsForAddress(
        address owner
    ) external view returns (uint256[] memory) {
        return IIICNft(nft).tokensOfOwner(owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return tokenOwner[tokenId];
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256[] memory stakedTokensForUser = userStakedTokens[account];
        return stakedTokensForUser.length;
    }
}