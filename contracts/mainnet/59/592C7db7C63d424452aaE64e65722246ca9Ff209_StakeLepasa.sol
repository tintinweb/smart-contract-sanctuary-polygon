// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface NFT {
    function transferFrom(address from,address to,uint256 tokenId) external;
}

contract StakeLepasa is Pausable, Ownable,ReentrancyGuard {
    Token lepaToken;
    NFT nftToken;
    uint256 public planCount;

    struct Plan {
        uint256 rewardBal;
        uint256 maxApyPer; 
        uint256 maxCount;
        uint256 stakeCount;
        uint256 currCount;
        uint256 maxUsrStake;
        uint256 lockSeconds;
        uint256 expireSeconds;
        uint256 perNFTPrice;
        uint256 closeTS;
    }

    struct TokenInfo {
        uint256 planId;
        uint256 startTS;
        uint256 endTS;
        uint256 claimed;
    }

    event StakePlan(uint256 id);
    event Staked(address indexed from, uint256 planId,uint256[] _ids);
    event UnStaked(address indexed from, uint256[] _ids);
    event Claimed(address indexed from, uint256[] _ids, uint256 amount);

    /* planId => plan mapping */
    mapping(uint256 => Plan) public plans;

    /* tokenId => token info */
    mapping(uint256 => TokenInfo) public tokenInfos;

    // Mapping owner address to stake token count
    mapping(address => uint256) public userStakeCnt;

    // Mapping from token ID to staker address
    mapping(uint256 => address) public stakers;

    /* address->array index->tokenId */    
    mapping(address => mapping(uint256 => uint256)) stakedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) stakedTokensIndex;

    constructor(Token _tokenAddress,NFT _nfttokenAddress) {
        require(address(_tokenAddress) != address(0),"Token Address cannot be address 0");
        require(address(_nfttokenAddress) != address(0),"NFT Token Address cannot be address 0");
        
        lepaToken = _tokenAddress;
        nftToken = _nfttokenAddress;
    }

    function setStakePlan(uint256 id,uint256 _rewardBal,uint256 _maxApyPer,uint256 _maxCount,
        uint256 _maxUsrStake,uint256 _lockSeconds,uint256 _expireSeconds,
        uint256 _perNFTPrice,uint256 _planExpireSeconds) external onlyOwner {
        
        //require(_rewardBal <= lepaToken.balanceOf(address(this)),"Given reward is less then balance");

        if (plans[id].maxApyPer ==0)
            planCount++;

        plans[id].rewardBal = _rewardBal; // Staking reward bucket
        plans[id].maxApyPer = _maxApyPer;
        plans[id].maxCount = _maxCount;
        plans[id].maxUsrStake = _maxUsrStake;
        plans[id].lockSeconds = _lockSeconds; // stake lock seconds
        plans[id].expireSeconds = _expireSeconds; // yield maturity seconds
        plans[id].perNFTPrice = _perNFTPrice;
        plans[id].closeTS = block.timestamp + _planExpireSeconds; // plan closing timestamp

        emit StakePlan(id);
    }

    function transferToken(address to,uint256 amount) external onlyOwner{
        require(lepaToken.transfer(to, amount), "Token transfer failed!");  
    }

    function transferNFT(address to,uint256 tokenId) external onlyOwner{
        nftToken.transferFrom(address(this),to, tokenId);  
    }

    function getCurrentAPY(uint256 planId) public view returns (uint256) {
        require(plans[planId].rewardBal >0, "Invalid staking plan");
        uint256 perNFTShare;
        uint256 stakingBucket =  plans[planId].rewardBal;
        uint256 currstakeCount = plans[planId].currCount ==0 ? 1 : plans[planId].currCount; // avoid divisible by 0 error

        uint256 maxNFTShare = currstakeCount * plans[planId].perNFTPrice * plans[planId].maxApyPer/100;

        if (maxNFTShare < stakingBucket) 
            perNFTShare=maxNFTShare/currstakeCount;
        else
            perNFTShare=stakingBucket/currstakeCount;    

        return perNFTShare * 100/plans[planId].perNFTPrice;
    } 

    function getUnClaimedReward(uint256 tokenId) public view returns (uint256) {
        require(tokenInfos[tokenId].startTS >0, "Token not staked");

        uint256 apy;
        uint256 anualReward;
        uint256 perSecondReward;
        uint256 stakeSeconds;
        uint256 reward;
        uint256 matureTS;

        apy = getCurrentAPY(tokenInfos[tokenId].planId);
        anualReward = plans[tokenInfos[tokenId].planId].perNFTPrice * apy/100;
        perSecondReward = anualReward/(365 *86400);  
        matureTS = tokenInfos[tokenId].startTS + plans[tokenInfos[tokenId].planId].expireSeconds;

        if (tokenInfos[tokenId].endTS ==0) 
            if (block.timestamp > matureTS)
                stakeSeconds = matureTS - tokenInfos[tokenId].startTS;
            else
                stakeSeconds = block.timestamp - tokenInfos[tokenId].startTS;
        else
            if (tokenInfos[tokenId].endTS > matureTS)
                stakeSeconds = matureTS - tokenInfos[tokenId].startTS;
            else
                stakeSeconds = tokenInfos[tokenId].endTS - tokenInfos[tokenId].startTS;
        
        reward = stakeSeconds * perSecondReward;
        reward = reward - tokenInfos[tokenId].claimed;

        return reward;
    }

    function claimReward(uint256[] calldata _ids) external nonReentrant{
        require(_ids.length >0, "invalid arguments");
        uint256 totalClaimAmt=0;
        uint256 claimAmt=0;

        for(uint i = 0; i < _ids.length; i++) {
            require(plans[tokenInfos[_ids[i]].planId].closeTS < block.timestamp, "Cannot claim during staking period");
            require(stakers[_ids[i]] == _msgSender() ,"NFT does not belong to sender address");
            claimAmt = getUnClaimedReward(_ids[i]);
            tokenInfos[_ids[i]].claimed +=claimAmt;
            totalClaimAmt+=claimAmt;
        }
        
        require(totalClaimAmt > 0, "Claim amount invalid.");

        emit Claimed(_msgSender(),_ids, totalClaimAmt);
        require(lepaToken.transfer(_msgSender(), totalClaimAmt), "Token transfer failed!");  
    }

    function _claimStakeReward(address sender,uint256[] calldata _ids) internal{
        require(_ids.length >0, "invalid arguments");
        uint256 totalClaimAmt=0;
        uint256 claimAmt=0;

        for(uint i = 0; i < _ids.length; i++) {
            claimAmt = getUnClaimedReward(_ids[i]);
            tokenInfos[_ids[i]].claimed +=claimAmt;
            totalClaimAmt+=claimAmt;
        }
        
        if (totalClaimAmt > 0) {
            emit Claimed(sender,_ids, totalClaimAmt);
            require(lepaToken.transfer(sender, totalClaimAmt), "Token transfer failed!");  
        }
    }

    function stakeNFT(uint256 _planId,uint256[] calldata _ids) external whenNotPaused {
        require(plans[_planId].rewardBal >0, "Invalid staking plan");
        require(block.timestamp < plans[_planId].closeTS , "Plan Expired");
        
        require(_ids.length >0, "invalid arguments");
        require((plans[_planId].currCount + _ids.length) <= plans[_planId].maxCount,"NFT Collection Staking limit exceeded");
        require((userStakeCnt[_msgSender()] + _ids.length) <= plans[_planId].maxUsrStake,"User Staking limit exceeded");

        for (uint256 i = 0; i < _ids.length; i++) {
            nftToken.transferFrom(_msgSender(), address(this), _ids[i]);
            plans[_planId].currCount++;
            plans[_planId].stakeCount++;            
            stakers[_ids[i]] = _msgSender(); 

            stakedTokens[_msgSender()][userStakeCnt[_msgSender()]] = _ids[i];
            stakedTokensIndex[_ids[i]] = userStakeCnt[_msgSender()]; // check utility
            
            userStakeCnt[_msgSender()]++;

            tokenInfos[_ids[i]] = TokenInfo({
                planId: _planId,
                startTS: block.timestamp,
                endTS:0,
                claimed:0
            });
        }

        emit Staked(_msgSender(), _planId,_ids);
    }

    function UnStakeNFT(uint256[] calldata _ids) external whenNotPaused nonReentrant{
        require(_ids.length >0, "invalid arguments");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(stakers[_ids[i]] == _msgSender() ,"NFT is not staked by sender address");
            require(tokenInfos[_ids[i]].endTS ==0 ,"NFT is already unstaked");
            require(block.timestamp > (tokenInfos[_ids[i]].startTS + plans[tokenInfos[_ids[i]].planId].lockSeconds) , "NFT cannot be unstake before locking period.");

            nftToken.transferFrom(address(this),_msgSender(), _ids[i]);
            plans[tokenInfos[_ids[i]].planId].currCount--;

            tokenInfos[_ids[i]].endTS=block.timestamp;
            
            unStakeUserNFT(_msgSender(),_ids[i]); // minus from array, adjust array length
            
            userStakeCnt[_msgSender()]--;
            stakers[_ids[i]]=address(0);
        }

        emit UnStaked(_msgSender(),_ids);
        _claimStakeReward(_msgSender(),_ids);
    }

    function unStakeUserNFT(address from, uint256 tokenId) internal {
        uint256 lastTokenIndex = userStakeCnt[from] - 1;
        uint256 tokenIndex = stakedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = stakedTokens[from][lastTokenIndex];

            stakedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            stakedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete stakedTokensIndex[tokenId];
        delete stakedTokens[from][lastTokenIndex];
    }

    function tokensOfStaker(address _owner) external view returns  (uint256[] memory){
        uint256 tokenCount = userStakeCnt[_owner];
        
        uint256[] memory result = new uint256[](tokenCount);
            
        for(uint i = 0; i < tokenCount; i++) {
            result[i]=stakedTokens[_owner][i];
        }
        return result;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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