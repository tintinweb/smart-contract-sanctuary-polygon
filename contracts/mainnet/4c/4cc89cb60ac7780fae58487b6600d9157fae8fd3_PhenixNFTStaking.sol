/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: contracts/PhenixNFTStaking.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;





contract PhenixNFTStaking is Ownable {
    using SafeMath for uint256;

    uint256 private constant FXP_BASE = 1000000;
    uint256 private constant REWARD_INTERVAL = 86400;

    uint256 public dailyRewardRate;
    uint256 public maxNFTsPerTransaction;
    uint256 public totalStaked;

    address public rewardToken;
    address public erc721Token;
    bool public rewardsUnlocked;

    struct Commitment {
        uint256 time;
        uint256 multiplierNumerator;
    }

    struct Stake {
        uint256 tokenId;
        address stakeholder;
        uint256 lastRewardTimestamp;
        uint256 endStakeTimestamp;
        uint256 currentTokenRewardMultiplier;
        Commitment currentCommitment;
        uint256 dailyRewardRate;
    }

    mapping(address => uint256[]) public stakeholderTokens;
    mapping(uint256 => Stake) public stakeMapping;
    mapping(uint256 => uint256) public nftIdRewardMultiplier;
    mapping(address => uint256) public stakeholderTotalRewards;
    mapping(uint256 => Commitment) public stakingTimeCommitmentMapping;

    event StakeNFT(uint256 indexed _tokenId, address indexed _owner);
    event UnstakeNFT(uint256 indexed _tokenId, address indexed _owner);
    event ClaimRewards(
        address indexed _stakeholder,
        uint256 indexed _claimAmount
    );

    constructor(address _rewardTokenAddress, address _erc721TokenAddress) {
        // PHNX TOKEN (Mainnet): 0x6C997a37f5a1Dca62b58EEB01041f056942966B3;
        // FPC NFT Token (Mainnet): 0x752892900c197B9C5b10B93e6F19B0365c296F18;
        rewardToken = _rewardTokenAddress;
        erc721Token = _erc721TokenAddress;

        // Staking time commitments
        _setStakingTimeCommitment(120, 100, 100); // 2 Minutes (1.0x Multiplier)
        _setStakingTimeCommitment(300, 100, 100); // 5 Minutes (1.0x Multiplier)
        _setStakingTimeCommitment(600, 100, 100); // 10 Minutes (1.0x Multiplier)

        _setStakingTimeCommitment(15 * 86400, 100, 100); // 15 Days (1.05x Multiplier)
        _setStakingTimeCommitment(30 * 86400, 105, 100); // 30 Days (1.10x Multiplier)
        _setStakingTimeCommitment(60 * 86400, 110, 100); // 60 Days (1.20x Multiplier)

        dailyRewardRate = 4 ether;
        maxNFTsPerTransaction = 500;
    }

    modifier isOwnerOfERC721Token(uint256 _id) {
        require(
            IERC721(erc721Token).ownerOf(_id) == msg.sender,
            "User does not own this ERC721 Token."
        );
        _;
    }

    modifier maxNFTsNotExceeded(uint256[] calldata _tokenIds) {
        require(
            _tokenIds.length != 0 && _tokenIds.length <= maxNFTsPerTransaction,
            "Too many (or zero) NFTs to process in this transaction."
        );
        _;
    }

    modifier stakeCommitmentAllowed(uint256 _seconds) {
        require(
            stakingTimeCommitmentMapping[_seconds].multiplierNumerator != 0,
            "Staking for this period of time is not allowed."
        );
        _;
    }

    function withdrawRewardTokenAssets() external onlyOwner {
        IERC20(rewardToken).transfer(
            owner(),
            IERC20(rewardToken).balanceOf(address(this))
        );
    }

    function withdrawETHAssets() external onlyOwner {
        (bool success, ) = address(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to withdraw ETH from contract");
    }

    function setERC721TokenAddress(address _erc721Token) external onlyOwner {
        erc721Token = _erc721Token;
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    function setMaxNFTsPerTransaction(uint256 _amountPerTransation)
        external
        onlyOwner
    {
        maxNFTsPerTransaction = _amountPerTransation;
    }

    function setDailyRewardRate(uint256 _rewardRate) external onlyOwner {
        dailyRewardRate = _rewardRate;
    }

    function setRewardsUnlocked(bool _state) external onlyOwner {
        rewardsUnlocked = _state;
    }

    function setMultiplierOf(
        uint256[] calldata _tokenIds,
        uint256 _multiplierNumerator,
        uint256 _multiplierDenominator
    ) external onlyOwner {
        require(
            _multiplierNumerator > _multiplierDenominator,
            "Numerator must be greater than denominator."
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nftIdRewardMultiplier[_tokenIds[i]] =
                (FXP_BASE * _multiplierNumerator) /
                _multiplierDenominator;
        }
    }

    function _setStakingTimeCommitment(
        uint256 _seconds,
        uint256 _multiplierNumerator,
        uint256 _multiplierDenominator
    ) internal {
        stakingTimeCommitmentMapping[_seconds] = Commitment(
            _seconds,
            (FXP_BASE * _multiplierNumerator) / _multiplierDenominator
        );
    }

    function setStakingTimeCommitment(
        uint256 _seconds,
        uint256 _multiplierNumerator,
        uint256 _multiplierDenominator
    ) external onlyOwner {
        _setStakingTimeCommitment(
            _seconds,
            _multiplierNumerator,
            _multiplierDenominator
        );
    }

    function removeStakingTimeCommitment(uint256 _seconds) external onlyOwner {
        _setStakingTimeCommitment(_seconds, 0, 0);
    }

    function claimableRewardsOfStakedTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory stakedTokensOfOwner = stakeholderTokens[_owner];
        uint256[] memory result = new uint256[](stakedTokensOfOwner.length);

        for (uint256 i = 0; i < stakedTokensOfOwner.length; i++) {
            if (
                block.timestamp >=
                stakeMapping[stakedTokensOfOwner[i]].endStakeTimestamp
            ) {
                result[i] = rewardOf(stakedTokensOfOwner[i]);
            } else {
                result[i] = 0;
            }
        }

        return result;
    }

    function totalClaimableRewardsOf(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 totalClaimableRewards;
        uint256[] memory stakedTokensOfOwner = stakedTokensOf(_owner);

        for (uint256 i = 0; i < stakedTokensOfOwner.length; i++) {
            if (
                block.timestamp >=
                stakeMapping[stakedTokensOfOwner[i]].endStakeTimestamp
            ) {
                totalClaimableRewards = totalClaimableRewards.add(
                    rewardOf(stakedTokensOfOwner[i])
                );
            }
        }

        return totalClaimableRewards;
    }

    function pendingRewardsOfStakedTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory stakedTokensOfOwner = stakedTokensOf(_owner);
        uint256[] memory result = new uint256[](stakedTokensOfOwner.length);

        for (uint256 i = 0; i < stakedTokensOfOwner.length; i++) {
            result[i] = rewardOf(stakedTokensOfOwner[i]);
        }

        return result;
    }

    function totalPendingRewardOf(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 totalPendingReward;
        uint256[] memory stakedTokensOfOwner = stakedTokensOf(_owner);

        for (uint256 i = 0; i < stakedTokensOfOwner.length; i++) {
            totalPendingReward = totalPendingReward.add(
                rewardOf(stakedTokensOfOwner[i])
            );
        }

        return totalPendingReward;
    }

    function rewardOf(uint256 _tokenId) public view returns (uint256) {
        if (
            stakeMapping[_tokenId].stakeholder != address(0) &&
            stakeMapping[_tokenId].stakeholder ==
            IERC721(erc721Token).ownerOf(_tokenId) &&
            stakeMapping[_tokenId].endStakeTimestamp != 0
        ) {
            // Initialize as the commitment daily reward rate
            uint256 totalTokenAllocation = stakeMapping[_tokenId]
                .dailyRewardRate;

            // Determine timestamp for calculation in token reward
            uint256 timestamp = block.timestamp;
            if (timestamp > stakeMapping[_tokenId].endStakeTimestamp) {
                // Set timestamp as end stake timestamp if exceeds end stake timestamp
                timestamp = stakeMapping[_tokenId].endStakeTimestamp;
            }

            // Determine the delta between the defined timestamp and last claim timestamp
            uint256 lastRewardDelta = uint256(timestamp).sub(
                stakeMapping[_tokenId].lastRewardTimestamp
            );

            /* SHARE BASED CALCULATION 
            totalTokenAllocation = totalTokenAllocation
                .mul(dailyRewardRate)
                .div(FXP_BASE)
                .div(totalStaked);
            */

            uint256 nextRewardPercentage = lastRewardDelta.mul(FXP_BASE).div(
                REWARD_INTERVAL
            );

            totalTokenAllocation = totalTokenAllocation
                .mul(nextRewardPercentage)
                .div(FXP_BASE);

            uint256 rewardMultiplierNumerator = stakeMapping[_tokenId]
                .currentCommitment
                .multiplierNumerator;

            if (nftIdRewardMultiplier[_tokenId] != 0) {
                rewardMultiplierNumerator = rewardMultiplierNumerator
                    .add(nftIdRewardMultiplier[_tokenId])
                    .sub(FXP_BASE);
            }

            totalTokenAllocation = totalTokenAllocation
                .mul(rewardMultiplierNumerator)
                .div(FXP_BASE);

            return totalTokenAllocation;
        } else {
            return 0;
        }
    }

    function stakeholderInfo(address _stakeholder)
        public
        view
        returns (Stake[] memory)
    {
        uint256[] memory _stakeholderTokens = stakedTokensOf(_stakeholder);
        Stake[] memory result = new Stake[](uint256(_stakeholderTokens.length));

        for (uint256 i = 0; i < _stakeholderTokens.length; i++) {
            result[i] = stakeMapping[_stakeholderTokens[i]];
        }

        return result;
    }

    function stakedTokensOf(address _stakeholder)
        public
        view
        returns (uint256[] memory)
    {
        return stakeholderTokens[_stakeholder];
    }

    function _stakeNFT(uint256 _tokenId, uint256 _seconds)
        internal
        isOwnerOfERC721Token(_tokenId)
    {
        if (stakeMapping[_tokenId].stakeholder == msg.sender) {
            require(
                block.timestamp >= stakeMapping[_tokenId].endStakeTimestamp,
                "One or more of the NFTs attempting to be staked is still being staked by the function caller."
            );
        }

        if (stakeMapping[_tokenId].stakeholder != address(0)) {
            _removeStakeholderToken(_tokenId);
        }

        uint256 endStakeTimestamp = block.timestamp +
            stakingTimeCommitmentMapping[_seconds].time;

        stakeMapping[_tokenId] = Stake(
            _tokenId,
            msg.sender,
            block.timestamp,
            endStakeTimestamp,
            nftIdRewardMultiplier[_tokenId],
            stakingTimeCommitmentMapping[_seconds],
            dailyRewardRate
        );

        stakeholderTokens[msg.sender].push(_tokenId);
        totalStaked = totalStaked.add(1);

        emit StakeNFT(_tokenId, msg.sender);
    }

    function _unstakeNFT(uint256 _tokenId)
        internal
        isOwnerOfERC721Token(_tokenId)
    {
        _removeStakeholderToken(_tokenId);

        stakeMapping[_tokenId] = Stake(
            _tokenId,
            address(0),
            block.timestamp,
            0,
            nftIdRewardMultiplier[_tokenId],
            Commitment(0, 0),
            dailyRewardRate
        );

        emit UnstakeNFT(_tokenId, msg.sender);
    }

    function _removeStakeholderToken(uint256 _tokenId) internal {
        if (stakeholderTokens[stakeMapping[_tokenId].stakeholder].length > 0) {
            if (
                stakeholderTokens[stakeMapping[_tokenId].stakeholder].length !=
                1
            ) {
                for (
                    uint256 i = 0;
                    i <
                    stakeholderTokens[stakeMapping[_tokenId].stakeholder]
                        .length;
                    i++
                ) {
                    if (
                        stakeholderTokens[stakeMapping[_tokenId].stakeholder][
                            i
                        ] == _tokenId
                    ) {
                        stakeholderTokens[stakeMapping[_tokenId].stakeholder][
                            i
                        ] = stakeholderTokens[
                            stakeMapping[_tokenId].stakeholder
                        ][
                            stakeholderTokens[
                                stakeMapping[_tokenId].stakeholder
                            ].length - 1
                        ];
                        stakeholderTokens[stakeMapping[_tokenId].stakeholder]
                            .pop();
                    }
                }
            } else {
                stakeholderTokens[stakeMapping[_tokenId].stakeholder].pop();
            }
            totalStaked = totalStaked.sub(1);
        }
    }

    function claimRewards(uint256[] calldata _tokenIds, uint256 _seconds)
        external
        maxNFTsNotExceeded(_tokenIds)
        stakeCommitmentAllowed(_seconds)
    {
        uint256 totalRewards;
        uint256[] memory _stakeholderTokens = _tokenIds;

        for (uint256 i = 0; i < _stakeholderTokens.length; i++) {
            require(
                stakeMapping[_stakeholderTokens[i]].stakeholder == msg.sender &&
                    IERC721(erc721Token).ownerOf(_stakeholderTokens[i]) ==
                    stakeMapping[_stakeholderTokens[i]].stakeholder,
                "Functional caller is not the stakeholder or owner of 1 or more NFTs."
            );

            uint256 _rewardOf = rewardOf(_stakeholderTokens[i]);

            if (
                stakeMapping[_stakeholderTokens[i]].endStakeTimestamp != 0 &&
                (block.timestamp >
                    stakeMapping[_stakeholderTokens[i]].endStakeTimestamp ||
                    rewardsUnlocked == true)
            ) {
                totalRewards = totalRewards.add(_rewardOf);

                stakeMapping[_stakeholderTokens[i]].endStakeTimestamp = uint256(
                    block.timestamp
                ).add(stakingTimeCommitmentMapping[_seconds].time);

                stakeMapping[_stakeholderTokens[i]]
                    .currentCommitment = stakingTimeCommitmentMapping[_seconds];

                stakeMapping[_stakeholderTokens[i]].lastRewardTimestamp = block
                    .timestamp;

                stakeMapping[_stakeholderTokens[i]]
                    .dailyRewardRate = dailyRewardRate;
            }
        }

        stakeholderTotalRewards[msg.sender] = stakeholderTotalRewards[
            msg.sender
        ].add(totalRewards);

        IERC20(rewardToken).transfer(msg.sender, totalRewards);

        emit ClaimRewards(msg.sender, totalRewards);
    }

    function stakeNFT(uint256[] calldata _tokenIds, uint256 _seconds)
        external
        maxNFTsNotExceeded(_tokenIds)
        stakeCommitmentAllowed(_seconds)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakeMapping[_tokenIds[i]].stakeholder != msg.sender,
                "ERC721 Token already staked by this address."
            );

            _stakeNFT(_tokenIds[i], _seconds);
        }
    }

    function unstakeNFT(uint256[] calldata _tokenIds)
        external
        maxNFTsNotExceeded(_tokenIds)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakeMapping[_tokenIds[i]].stakeholder == msg.sender,
                "ERC721 Token is not being staked or is staked by another address."
            );

            _unstakeNFT(_tokenIds[i]);
        }
    }

    receive() external payable {}
}