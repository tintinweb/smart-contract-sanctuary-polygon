// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IRhum.sol";
import "./IFlagStaking.sol";

contract RhumProduction is Ownable, ReentrancyGuard {
    IRhum internal immutable rewardsToken;
    IERC721 internal immutable nftCollection;
    IFlagStaking internal royalty;
    address treasuryGuild;
    mapping(uint256 => TavernInfos) internal taverns;
    struct TavernInfos {
        address owner;
        uint256 level;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 costNextLevelRhum;
        uint256 boost;
        uint256 tavernId;
    }

    uint256 internal rewardsPerDay;
    uint256 internal constant firstLevelCostRhum = 1000 * 10**18;
    uint256 internal constant nextCostLevelup = 2000;
    uint256 internal constant secondsToday = 86400;

    uint256 internal constant percentReduce = 12500 * 10**18;
    uint256 internal MaxStakedReduce = 10000 * 10**18;

    uint256 internal LevelUpPrice = 1 * 10**15;

    uint256 internal constant BIG_NUM = 10**18;
    uint256 internal constant Percent = 10000;
    uint256 internal constant tenPercent = 1000;
    uint256 internal constant two = 2;
    uint256 internal constant one = 1;
    uint256 internal constant zero = 0;

    mapping(address => uint256) internal amountStaked;

    mapping(address => uint256[]) public buildingIds;

    mapping(uint256 => address) public stakerAddress;

    constructor(
        IERC721 _nftCollection,
        IRhum _rewardsToken,
        IFlagStaking _royalty,
        address _treasuryGuild
    ) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        rewardsPerDay = 10000 * 10**18;
        royalty = _royalty;
        treasuryGuild = _treasuryGuild;
    }

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(
                nftCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "Can't stake Tavern you don't own!"
            );

            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = msg.sender;
            taverns[_tokenIds[i]].owner = msg.sender;
            taverns[_tokenIds[i]].timeOfLastUpdate = block.timestamp;
            taverns[_tokenIds[i]].tavernId = _tokenIds[i];
        }
        amountStaked[msg.sender] += _tokenIds.length;
    }

    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        _claimRewards(_tokenIds);
        for (uint256 i; i < _tokenIds.length; ++i) {
            require(
                stakerAddress[_tokenIds[i]] == msg.sender,
                "Can't unstake Tavern you don't own!"
            );
            uint256 rewards = calculateRewards(_tokenIds[i]);
            taverns[_tokenIds[i]].unclaimedRewards += rewards;
            stakerAddress[_tokenIds[i]] == address(0);
            taverns[_tokenIds[i]].owner = address(0);
            taverns[_tokenIds[i]].timeOfLastUpdate = block.timestamp;
            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        amountStaked[msg.sender] -= _tokenIds.length;
    }

    function claimRewards(uint256[] calldata _tokenIds) external nonReentrant {
        _claimRewards(_tokenIds);
    }

    function Levelup(uint256 tokenId) external payable nonReentrant {
        require(taverns[tokenId].owner == msg.sender, "Not your NFT!");
        require(msg.value >= LevelUpPrice, "Amount Price not low!");
        _claimReward(tokenId);
        _LevelUp(tokenId);
        (bool success, ) = payable(treasuryGuild).call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }

    function LevelupBatch(uint256[] calldata tokenIds)
        external
        payable
        nonReentrant
    {
        uint256 len = tokenIds.length;
        require(msg.value >= LevelUpPrice * len, "Amount Price not low!");
        for (uint256 i = 0; i < len; ++i) {
            require(taverns[tokenIds[i]].owner == msg.sender, "Not your NFT!");
            _claimReward(tokenIds[i]);
            _LevelUp(tokenIds[i]);
        }
        (bool success, ) = payable(treasuryGuild).call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }

    //////////
    // View //
    //////////

    function getTavernInfos(uint256 tavernId)
        external
        view
        returns (TavernInfos memory tavern)
    {
        return taverns[tavernId];
    }

    function getUserTavern(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 userTokenIds = amountStaked[user];
        uint256 totalTokenIds = nftCollection.balanceOf(address(this));
        uint256 currentIndex = 0;
        uint256[] memory _taverns = new uint256[](userTokenIds);
        for (uint256 i = 0; i < totalTokenIds; i++) {
            uint256 tokenId = IERC721Enumerable(address(nftCollection))
                .tokenOfOwnerByIndex(address(this), i);
            TavernInfos memory tavern = taverns[tokenId];
            if (tavern.owner == user) {
                _taverns[currentIndex] = tokenId;
                currentIndex++;
            }
        }
        return _taverns;
    }

    function getTavernsInfosArray(uint256[] calldata tavernIds)
        external
        view
        returns (TavernInfos[] memory tavernInfos)
    {
        uint256 currentIndex = 0;
        TavernInfos[] memory _taverns = new TavernInfos[](tavernIds.length);
        for (uint256 i = 0; i < tavernIds.length; i++) {
            _taverns[currentIndex] = taverns[tavernIds[i]];
            currentIndex++;
        }
        return _taverns;
    }

    function getLevelUpPrice() external view returns (uint256) {
        return LevelUpPrice;
    }

    function getRewardsPerDay() external view returns (uint256) {
        return rewardsPerDay;
    }

    function getTavernDailyProd(uint256 tavernId)
        external
        view
        returns (uint256)
    {
        if (taverns[tavernId].boost != zero) {
            return (((rewardsPerDay / (rewardsToken.fetchHalving())) *
                ((taverns[tavernId].boost))) / (Percent));
        } else {
            return (rewardsPerDay / rewardsToken.fetchHalving());
        }
    }

    function getLevel(uint256 tavernId) external view returns (uint256) {
        return taverns[tavernId].level;
    }

    /////////////
    // Internal//
    /////////////

    function availableRewards(uint256 _id) internal view returns (uint256) {
        return (taverns[_id].unclaimedRewards) + (calculateRewards(_id));
    }

    function calculFeeReduction(uint256 price, address user)
        internal
        view
        returns (uint256)
    {
        uint256 userStake = royalty.addressStakedBalance(user);
        if (userStake > MaxStakedReduce) {
            userStake = MaxStakedReduce;
        }
        return (price -
            ((((userStake * BIG_NUM) / percentReduce) * price) / BIG_NUM));
    }

    function _claimRewards(uint256[] calldata _tokenIds) internal {
        for (uint256 i; i < _tokenIds.length; ++i) {
            _claimReward(_tokenIds[i]);
        }
    }

    function _claimReward(uint256 tokenId) internal {
        require(stakerAddress[tokenId] == msg.sender);
        uint256 reward = calculateRewards(tokenId) +
            (taverns[tokenId].unclaimedRewards);
        taverns[tokenId].timeOfLastUpdate = block.timestamp;
        taverns[tokenId].unclaimedRewards = zero;
        rewardsToken.mint(msg.sender, reward);
    }

    function calculateRewards(uint256 id)
        internal
        view
        returns (uint256 _rewards)
    {
        return
            (((((block.timestamp) - (taverns[id].timeOfLastUpdate)) *
                (calculateBoost(id))) / (Percent)) *
                ((rewardsPerDay / (rewardsToken.fetchHalving())))) /
            (secondsToday);
    }

    function calculateBoost(uint256 id) internal view returns (uint256 _boost) {
        if (taverns[id].boost != zero) {
            return taverns[id].boost;
        } else {
            return Percent;
        }
    }

    function _LevelUp(uint256 tokenId) internal {
        if (taverns[tokenId].level >= one) {
            rewardsToken.burnFrom(
                msg.sender,
                calculFeeReduction(
                    taverns[tokenId].costNextLevelRhum,
                    msg.sender
                )
            );
            taverns[tokenId].boost += (((taverns[tokenId].boost) *
                (tenPercent)) / (Percent));
            taverns[tokenId].costNextLevelRhum += (((
                taverns[tokenId].costNextLevelRhum
            ) * (nextCostLevelup)) / Percent);
            taverns[tokenId].level += one;
        } else {
            taverns[tokenId].level = two;
            taverns[tokenId].boost = Percent + tenPercent;
            taverns[tokenId].costNextLevelRhum =
                firstLevelCostRhum +
                ((firstLevelCostRhum * (nextCostLevelup)) / (Percent));
            rewardsToken.burnFrom(
                msg.sender,
                calculFeeReduction(firstLevelCostRhum, msg.sender)
            );
        }
    }

    ///////////
    // Owner //
    ///////////

    function setRewardsPerDay(uint256 _newValue) public onlyOwner {
        rewardsPerDay = _newValue;
    }

    function setLevelUpPrice(uint256 _newValue) public onlyOwner {
        LevelUpPrice = _newValue;
    }

    function setRoyalty(IFlagStaking _newRoyalty) public onlyOwner {
        royalty = _newRoyalty;
    }

    // function dev testnet
    function setTavernLevel(uint256 tavernId, uint256 _level) public {
        taverns[tavernId].level = _level;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IRhum {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint amount) external;

    function burn(uint amount) external;

    function fetchHalving() external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFlagStaking {
    // --------- UTILITY FUNCTIONS ------------
    function isStaker(address _address) external view returns (bool);

    // ----------- STAKING ACTIONS ------------
    function createStake(uint _amount) external;

    function removeStake(uint _amount) external;

    // Backup function in case something happens with the update rewards functions
    function emergencyUnstake(uint _amount) external;

    // ------------ REWARD ACTIONS ---------------
    function getRewards() external;

    function updateAddressRewardsBalance(address _address)
        external
        returns (uint);

    function updateBigRewardsPerToken() external;

    function userPendingRewards(address _address) external view returns (uint);

    // ------------ ADMIN ACTIONS ---------------
    function withdrawRewards(uint _amount) external;

    function depositRewards(uint _amount) external;

    function setDailyEmissions(uint _amount) external;

    function pause() external;

    function unpause() external;

    // ------------ VIEW FUNCTIONS ---------------
    function timeSinceLastReward() external view returns (uint);

    function rewardsBalance() external view returns (uint);

    function addressStakedBalance(address _address)
        external
        view
        returns (uint);

    function showStakingToken() external view returns (address);

    function showRewardToken() external view returns (address);

    function showBigRewardsPerToken() external view returns (uint);

    function showBigUserRewardsCollected() external view returns (uint);

    function showLockTimeRemaining(address _address)
        external
        view
        returns (uint256);
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