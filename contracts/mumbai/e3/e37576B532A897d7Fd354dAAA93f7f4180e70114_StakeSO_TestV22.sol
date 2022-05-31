// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// standard imports
import "@openzeppelin/contracts/access/Ownable.sol";
// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



/*
what is missing?
eventually make upgradable
*/

contract StakeSO_TestV22 is Ownable {


    uint256 public totalStaked;

    // initStaking variable
    bool _init;

    // SONFT and FLtoken
    IERC20 public rewardsToken;
    IERC721 public stakeNFT;

    // mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // mapping from rarity to rate
    mapping(uint16 => uint256) rarityToRate;

    // mapping form rarity to slots
    mapping(uint16 => uint256) rarityToSlots;

    // array of all stakers to loop through
    address[] stakerAddresses;

    // interest rate per 
    uint256 interestRate;


    struct Staker {
        uint256[] tokenIds;
        uint256[] timestamps;
        // stores rate at time of staking
        uint256[] idRates;
        address tokenOwner;
        // if nft is unstaked without claiming tokens, remaining claimable tokens are written here
        uint256 unclaimedTokens;
        bool created;
    }

    /*-------------  MODIFIERS ------------- */
    
    modifier lockContract() {
        require(compareUnclaimedToRemaining(), "Not enough Tokens in contract remaining");
        _;
    }
    
     

     /*-------------  Initialisation ------------- */



    /**
    Single gateway to intialize the staking contract after deploying
    Sets the contract with the SO NFT and FLO reward token 
     */
    function initStaking(
        IERC20 _rewardsToken,
        IERC721 _NFT
    )
        external
    {
        require(!_init, "Already initialised");
        rewardsToken = _rewardsToken;
        stakeNFT = _NFT;
        _init = true;
    }



 /*-------------  Staking, Unstaking & Claiming -------------*/
    
    /*
    Stake NFT specified by Token ID
    */
    // staking not possible if not enough tokens in contract
    function stake(uint256 _tokenId) public lockContract{

        // staker needs to own tokenId
        require(stakeNFT.ownerOf(_tokenId) == msg.sender, "you don't own this NFT, screenshots do not count");

        // transfer NFT to contract
        stakeNFT.transferFrom(msg.sender, address(this), _tokenId);

        // get staker struct (if it does not exists, creates new one)
        Staker storage staker = stakers[msg.sender];
        if(!staker.created) {
            // set token owner
            staker.tokenOwner = msg.sender;
            // toggle boolean created
            staker.created = true;
            // add address to arraay of addresses
            stakerAddresses.push(msg.sender);
        }

        // push newly staked token to array
        staker.tokenIds.push(_tokenId);
        // push current timestamp to array
        staker.timestamps.push(block.timestamp);
        // TODO: CHECK CORRECTNESS
        // push current rate of staked tokenId corresponding to rarity
        uint16 rarity = getRarity(_tokenId);
        uint256 rate = getCurrentRate(rarity);
        staker.idRates.push(rate);
        // increase number of staked nfts
        totalStaked = totalStaked += 1;
    }


    /*
    this function lets a user stake multiple tokens (input: [7,9,12,35,...,420])
    */
    function batchStaking(uint256[] calldata _tokenIds) public {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i]);
        }
    }


    /*
    Unstake Token specified by tokenId
    When unstaking one (of possibly multiple NFTs), ALL earned Tokens are send
    to unstaker as well as nft
    */
    function unstakeAndClaim(uint256 _tokenId) public {

        // get staker struct
        Staker storage unstaker = stakers[msg.sender]; 
        // unstaker needs to be owner of tokenId
        require(unstaker.tokenOwner == msg.sender, "invalid tokenId");

        // send earned tokens to unstaker (timestamps are updated)
        uint256 amountEarned = calculateEarnedTokens(unstaker) * (10**18);
        rewardsToken.transfer(msg.sender, amountEarned);

        // get last index of array tokenIds
        uint256 lastIndex = unstaker.tokenIds.length - 1;
        // get (key)value of last index of tokenIds and idRates
        uint256 lastIndexKeyTokenId = unstaker.tokenIds[lastIndex];
        // TODO: CHECK CORRECTNESS
        uint256 lastIndexKeyIdRate = unstaker.idRates[lastIndex];
        // get index of token to unstake
        uint256 tokenIdIndex = getIndexForTokenId(_tokenId);

        // replace unstaked tokenId & idRate with last stored tokenId 
        // (order does not matter for timestamps since all have been updated during withdrawal)

        // TODO: CHECK CORRECTNESS
        unstaker.tokenIds[tokenIdIndex] = lastIndexKeyTokenId;
        unstaker.idRates[tokenIdIndex] = lastIndexKeyIdRate;

        // pop last value of array tokenIds, timestamps & idRates
        unstaker.tokenIds.pop();
        unstaker.timestamps.pop();
        // TODO: CHECK CORRECTNESS
        unstaker.idRates.pop();

        // send back unstaked NFT
        stakeNFT.transferFrom(address(this), msg.sender, _tokenId);
        // set unstaker.unclaimed to zero
        unstaker.unclaimedTokens = 0;
        // decrease totalStaked by one
        totalStaked = totalStaked -= 1;
    }



    /*
    this function lets a user unstake multiple tokens and
    claim all earned tokens (input: [7,9,12,35,...,420])
    */
    function batchUnstakeAndClaim(uint256[] calldata _tokenIds) public {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            // since unstakeAndClaim claims tokens earned by all staked NFTs, just call once
            if(i == 1) {
                unstakeAndClaim(_tokenIds[i]);
            }
            // else call unstakeWithoutClaim, such that no unnecessary zero
            // token transfers are made
            else {
                unstakeWithoutClaim(_tokenIds[i]);
            }
        }
    }


    /*
    This function allows stakers to claim the amount of tokens earned (by ALL staked NFTs)
    without unstaking tokens
    */
    function claim() public {

        // get staker struct object of claimer
        Staker storage claimer = stakers[msg.sender];

        // check whether mapping and struct address match
        require(claimer.tokenOwner == msg.sender, "weird error");

        // get rewards earned
        uint256 amount = calculateEarnedTokens(claimer) * (10**18);

        // rewards earned have to be larger than zero (else the caller wastes gas)
        require(amount > 0, "No tokens earned");
        
        // set all timestamps to current timestamp
        for(uint256 i = 0; i < claimer.timestamps.length; i++) {
            claimer.timestamps[i] = block.timestamp;
        }

        // transfer tokens from contract to msg.sender
        rewardsToken.transfer(msg.sender, amount);

        // CORRECTED LINE: may 24th 
        claimer.unclaimedTokens = 0;
    }


    /*
    This function lets users unstake without claiming the earned tokens
    */
    function unstakeWithoutClaim(uint256 _tokenId) public {
        // get staker struct
        Staker storage staker = stakers[msg.sender];
        // get earned tokens of specific nft
        uint256 earnedByToken = calculateSingleEarning(_tokenId, msg.sender);
        // add unclaimed tokens to struct staker
        staker.unclaimedTokens += earnedByToken;

        // get last index of array
        uint256 lastIndex = staker.tokenIds.length - 1;
        // get (key)value of last index
        uint256 lastIndexKeyTokenId = staker.tokenIds[lastIndex];
        // TODO: CHECK CORRECTNESS
        uint256 lastIndexKeyTimestamp = staker.timestamps[lastIndex];
        uint256 lastIndexKeyIdRate = staker.idRates[lastIndex];
        // get index of token to unstake
        uint256 tokenIdIndex = getIndexForTokenId(_tokenId);


        // replace unstaked tokenId with last stored tokenId 
        // (order does not matter since timestamps have been updated during withdrawal)
        staker.tokenIds[tokenIdIndex] = lastIndexKeyTokenId;
        // TODO: CHECK CORRECTNESS
        staker.timestamps[tokenIdIndex] = lastIndexKeyTimestamp;
        staker.idRates[tokenIdIndex] = lastIndexKeyIdRate;

        // pop last value of array tokenIds, timestamps & idRates
        staker.tokenIds.pop();
        staker.timestamps.pop();
        // TODO: CHECK CORRECTNESS
        staker.idRates.pop();
        
        // unstake NFT
        stakeNFT.transferFrom(address(this), msg.sender, _tokenId);
        totalStaked -= 1;
    }


    /*
    this function lets a user unstake multiple tokens
    without claiming earned tokens (input: [7,9,12,35,...,420])
    */
    function batchUnstakeWithoutClaim(uint256[] calldata _tokenIds) public {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            unstakeWithoutClaim(_tokenIds[i]);
        }
    }


/*------------- Calculation & Logics -------------*/

    /*
    this function returns the earnings of one single NFT
    */
    function calculateSingleEarning(uint256 _tokenId, address _staker) public view returns(uint256) {
        // get staker struct
        Staker storage staker = stakers[_staker];
        uint256 amount = 0;
        require(staker.tokenIds.length > 0, "no token staked");
        // get specific amount earned by token
        for(uint256 i = 0; i < staker.tokenIds.length; i++) {
            if(staker.tokenIds[i] == _tokenId) {
                uint256 stakedAt = staker.timestamps[i];
                // TODO: CHECK CORRECTNESS
                uint256 timeNow = block.timestamp;
                uint256 rate =  staker.idRates[i];
                amount = (rate * (timeNow - stakedAt)) / (86400);
                return amount;
            }
        }
        return amount;
    }



    /*
    This function calculates amount of tokens earned by the staker,
    called internally when claiming
    */ 
    function calculateEarnedTokens(Staker storage _staker) internal view returns(uint256) {
        // amount earned
        uint256 amount = 0;

        // get amount of NFTs staked
        uint256 NFTsStaked = _staker.tokenIds.length;

        // time at the moment of withdrawal
        uint256 timeNow = block.timestamp;

        // calculate amount earned per NFT and sum up
        for(uint256 i = 0; i < NFTsStaked; i++) {
            uint256 staketAtTime = _staker.timestamps[i];
            // divided by amount of seconds per day - e.g. if staked one day, 
            // difference should be > 86400, divided by 86400 = 1,
            //  times interestRate = earned tokens
            // TODO: CHECK CORRECTNESS
            uint256 rate = _staker.idRates[i];
            amount += (rate * (timeNow - staketAtTime)) / (86400);  
        }
        // include unclaimed tokens from already unstaked nfts
        if(_staker.created) {
            amount += _staker.unclaimedTokens;
        }
        return amount;
    }



    /*
    read only function: returns amount of tokens earned until moment function has been called
    */ 
    function returnEarnedInterest(address _earner) public view returns(uint256) {
        Staker storage staker = stakers[_earner];
        uint256 amount = 0;

        // get amount of NFTs staked
        uint256 NFTsStaked = staker.tokenIds.length;

        // time at the moment of withdrawal
        uint256 timeNow = block.timestamp;

        // calculate amount earned per NFT and sum up
        for(uint256 i = 0; i < NFTsStaked; i++) {
            uint256 staketAtTime = staker.timestamps[i];
            // divided by amount of seconds per day - e.g. if staked one day, difference should be > 86400, divided by 86400 = 1, times interestRate = earned tokens
            //amount += (interestRate.mul(timeNow.sub(staketAtTime))).div(86400);
            //TODO CHANGE!!!!!!
            uint256 rate = staker.idRates[i];
            amount += (rate * (timeNow - staketAtTime)) / (86400);
        }
        // include unclaimed tokens from already unstaked nfts
        if(staker.created) {
            amount += staker.unclaimedTokens;
        }
        return amount;
    }



    /*
    this function returns the index of the token ID in a stakers struct array of tokenIds,
    reverts if queried tokenId not in array
    */
    function getIndexForTokenId(uint256 _tokenId) internal view returns(uint256) {
        Staker storage _staker = stakers[msg.sender];
        for(uint256 i = 0; i < _staker.tokenIds.length; i++) {
            if(_staker.tokenIds[i] == _tokenId) {
                return i;
            }
        }
        revert();
    }






    /*------------- Administrative -------------*/

    /* lets owner withdraw contract if enough tokens in contract () */
    function adminWithdraw(uint256 _amount) public onlyOwner lockContract {
        uint256 unclaimedTokens = getTotalUnclaimedTokens();
        require(unclaimedTokens - _amount > _amount, 'not enough tokens remaining');
        rewardsToken.transfer(msg.sender, _amount);
        
    }



    /*
    This function sets the interest rate per rarity - 
    from common to legendary, e.g. [100, 200, ..., 500]
     - only by contract owner
    InterestRate in form of tokens earned per day (?),
    e.g. interestRate = 500 * 10^18 <==> 500 FloTokens per day
    */ 
    function setInterestRates(uint256[] calldata _interestRates) public onlyOwner {
        uint256 length = _interestRates.length;
        require(length < 6, 'only 5 rarities');
        for(uint16 i = 0; i < length; i++) {
            rarityToRate[i] = _interestRates[i];
        }
    }

    /*
    This function sets the number of slots per rarity - 
    from common to legendary, e.g. [1000, 300, ..., 3]
     - only by contract owner
    */
    function setSlots(uint256[] calldata _numberOfSlots) public onlyOwner {
        uint256 length = _numberOfSlots.length;
        for(uint16 i = 0; i < length; i++) {
            rarityToSlots[i] = _numberOfSlots[i];
        }
    }

    function setNFT(IERC721 _NFT) public onlyOwner {
        stakeNFT = _NFT;
    }

    function setRewardsToken(IERC20 _rewardsToken) public onlyOwner {
        rewardsToken = _rewardsToken;
    }



    /*
    New stuff staking concept
    1) get rarity
     */

    /* 
    returns rarity based on token ID:
    legendary = 4, epic = 3, ultra rare = 2, rare = 1, common = 0
     */
    function getRarity(uint256 _tokenId) public pure returns(uint16) {
        if(_tokenId >= 5501) {
            return 0;
        }
        else if(_tokenId >= 2001) {
            return 1;
        }
        else if(_tokenId >= 501) {
            return 2;
        }
        else if(_tokenId >= 11) {
            return 3;
        }
        else return 4;
    }

    /* gets rate (DSIGN per second) for a specific rarity */
    function getCurrentRate(uint16 _rarity) public view returns(uint256) {
        uint256 rate = rarityToRate[_rarity];
        return rate;
    }



    /* gets slots for a specific rarity */
    function getNumberSlots(uint16 _rarity) public view returns(uint256) {
        uint256 numberOfSlots = rarityToSlots[_rarity];
        return numberOfSlots;
    }


    /* returns current contract balance */
    function getContractBalance() public view returns(uint256) {
        return rewardsToken.balanceOf(address(this));
    }

    /*
    this function returns the amount of tokens unclaimed by all stakers
    */
    function getTotalUnclaimedTokens() public view returns(uint256) {
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < stakerAddresses.length; i++) {
            // Loop through all addresses, get struct tsaker, calc unclaimed tokens, add to total
            totalAmount += calculateEarnedTokens(stakers[stakerAddresses[i]]);
            totalAmount += stakers[stakerAddresses[i]].unclaimedTokens;
        }
        return totalAmount;
    }

    /*
    this function returns true if the contract balance is higher than amount of unclaimed tokens 
    */
    function compareUnclaimedToRemaining() public view returns(bool) {
        // get remaining tokens in contract
        uint256 _contractBalance = getContractBalance();
        // get unclaimed tokens amount
        uint256 unclaimedTokens = getTotalUnclaimedTokens();
        if(_contractBalance < unclaimedTokens) {
            // if more unclaimedTokens than contractBalance, return false, else true
            return false;
        }
        return true;
    }


    /* returns current consumption rate due to staked NFTS */
    function getConsumptionRate() public view returns(uint256) {
        uint256 consumptionRatePerDay = 0;
        for(uint256 i = 0; i < stakerAddresses.length; i++) {
            Staker storage staker = stakers[stakerAddresses[i]];
            uint256 NFTsStaked = staker.tokenIds.length;
            for(uint256 j = 0; j< NFTsStaked; j++) {
                consumptionRatePerDay += staker.idRates[j];
            }

        }
        return consumptionRatePerDay;
    }
    
    function daysLeft() public view returns(uint256) {
        uint256 consumptionRatePerDay = getConsumptionRate();
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(consumptionRatePerDay != 0, 'consumtion rate is zero');
        return balance/consumptionRatePerDay;
    }
    
    function getRemainingSlots() public view returns(uint256[5] memory) {
        uint256[5] memory slots = [rarityToSlots[0], rarityToSlots[1], 
        rarityToSlots[2], rarityToSlots[3], rarityToSlots[4]];
        uint256 leng = stakerAddresses.length;
        for(uint256 i = 0; i < leng; i++) {
            Staker storage staker = stakers[stakerAddresses[i]];
            for(uint256 j = 0; j < leng; j++) {
                uint256 rarity = getRarity(staker.tokenIds[j]);
                slots[rarity] -= 1;
            }
        }
        
        return slots;
    }

    function getTokenIdsforAddress(address _staker) public view returns(uint256[] memory) {
        uint256[] memory ids;
        Staker storage staker = stakers[_staker];
        uint256 leng = staker.tokenIds.length;
        for(uint256 i = 0; i < leng; i++) {
            ids[i] = staker.tokenIds[i];
        }
        return ids;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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