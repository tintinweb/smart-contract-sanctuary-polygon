// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// standard imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



/*
what is missing?
-require statements when tokens are send, reentrancy ...(security)
eventually make upgradable
*/

contract StakeSO_testV4 is Ownable, ReentrancyGuard{


    // address owner; // 0x09313956466bef5c9EA924CC8b25389BcDc9Ec77

    // SO tokens staked
    uint256 public totalStaked;

    // initStaking variable
    bool initialised = false;

    // SONFT and FLtoken
    IERC20 public rewardsToken;
    IERC721 public stakeNFT;



    //address public FLV1_address; // = 0xC64baE6a8887a542B4544b5E84d45B899574d299;
    //address public SOV1_address; // = 0x7ab3cdD064c178CC03B57B5975f05bB985b1441c;


    // mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // array of all stakers to loop through
    address[] stakerAddresses;

    // interest rate per 
    uint256 interestRate;

    /*
    Staker has attributes:
    -tokenOwner: address of user
    -tokenIds: Array of tokenIds staked by tokenOwner
    -timestamps: Array of timetsamps (same order as tokenIds),
                 holding time when corressponding token has been staked
    */ 

    struct Staker {
        uint256[] tokenIds;
        uint256[] timestamps;
        address tokenOwner;
        // if nft is unstaked without claiming tokens, remaining claimable tokens are written here
        uint256 unclaimedTokens;
        bool created;
    }

    // remove what happens in 
    constructor() {}

    /*-------------  MODIFIERS ------------- */

    modifier lockContract() {
        require(compareUnclaimedToRemaining(), "Not enough Tokens in contract remaining");
        _;
    }



    /*-------------  FUNCTIONS ------------- */


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
        require(!initialised, "Already initialised");
        rewardsToken = _rewardsToken;
        stakeNFT = _NFT;
        initialised = true;
    }

    

    /*-------------  Staking, Unstaking & Claiming -------------*/
    
    /*
    Stake NFT specified by Token ID
    */
    // staking not possible if not enough tokens in contract
    function stake(uint256 _tokenId) public lockContract() {

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
        // increase number of staked nfts
        totalStaked = totalStaked += 1;
    }

    /*
    this function lets a user stake multiple tokens (input: [7,9,12,35,...,420])
    */
    function batchStaking(uint256[] calldata _tokenIds) public lockContract nonReentrant(){
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
        require(unstaker.tokenOwner == msg.sender, "tokenId not in your possesion");

    
        // send earned tokens to unstaker
        uint256 amountEarned = calculateEarnedTokens(unstaker) * (10**18);
        rewardsToken.transfer(msg.sender, amountEarned);

        // get last index of array tokenIds
        uint256 lastIndex = unstaker.tokenIds.length - 1;
        // get (key)value of last index
        uint256 lastIndexKey = unstaker.tokenIds[lastIndex];
        // get index of token to unstake
        uint256 tokenIdIndex = getIndexForTokenId(_tokenId);

        // replace unstaked tokenId with last stored tokenId 
        // (order does not matter since timestamps have been updated during withdrawal)
        unstaker.tokenIds[tokenIdIndex] = lastIndexKey;

        // pop last value of array tokenIds and timestamps
        unstaker.tokenIds.pop();
        unstaker.timestamps.pop();

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
    function batchUnstakeAndClaim(uint256[] calldata _tokenIds) public nonReentrant() {
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
            // set unclaimed tokens from already unstaked nfts to zero
        }

        // transfer tokens from contract to msg.sender
        rewardsToken.transfer(msg.sender, amount);
    }



    /*
    This function lets users unstake without claiming the earned tokens
    TODO: remove token id and timestamps from struct array
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
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        // get index of token to unstake
        uint256 tokenIdIndex = getIndexForTokenId(_tokenId);

        // replace unstaked tokenId with last stored tokenId 
        // (order does not matter since timestamps have been updated during withdrawal)
        staker.tokenIds[tokenIdIndex] = lastIndexKey;

        // pop last value of array tokenIds and timestamps
        staker.tokenIds.pop();
        staker.timestamps.pop();
        
        // unstake NFT
        stakeNFT.transferFrom(address(this), msg.sender, _tokenId);
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
                uint256 timeNow = block.timestamp;
                amount = (interestRate * (timeNow - stakedAt)) / (86400);
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
            // divided by amount of seconds per day - e.g. if staked one day, difference should be > 86400, divided by 86400 = 1, times interestRate = earned tokens
            amount += (interestRate * (timeNow - staketAtTime)) / (86400);  
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
            amount += (interestRate * (timeNow - staketAtTime)) / (86400);
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

    /*
    This function sets the interest rate - only by contract owner
    InterestRate in form of tokens earned per day (?),
    e.g. interestRate = 500 <==> 500 FloTokens per day
    */
    function setInterestRate(uint256 _interestRate) public onlyOwner() {
        interestRate = _interestRate;
    }


    /*
    this function lets the admin withdraw _amount flotokens,
    as long as the remaining amount in the contract is larger thn the unclaimed
    */
    // if not enough tokens in contract, cant withdraw
    function withdrawAdmin(uint256 _amount) public lockContract() onlyOwner() {

        uint256 balanceContract = rewardsToken.balanceOf(address(this));
        uint256 difference = balanceContract - _amount;
        uint256 unclaimed = getTotalUnclaimedTokens();
        require(difference > unclaimed, "Not enough tokens left");
        rewardsToken.transfer(owner(), _amount);
    }



    /*
    this function returns the amount of tokens unclaimed by all stakers
    */
    function getTotalUnclaimedTokens() public view returns(uint256) {
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < stakerAddresses.length; i++) {
            // Loop through all addresses, get struct tsaker, calc unclaimed tokens, add to total
            totalAmount += calculateEarnedTokens(stakers[stakerAddresses[i]]);
        }
        return totalAmount;
    }


    /*
    this function returns true if the contract balance is higher than amount of unclaimed tokens 
    */
    function compareUnclaimedToRemaining() public view returns(bool) {
        // get remaining tokens in contract
        uint256 _contractBalance = rewardsToken.balanceOf(address(this));
        // get unclaimed tokens amount
        uint256 unclaimedTokens = getTotalUnclaimedTokens();
        if(_contractBalance < unclaimedTokens) {
            // if more unclaimedTokens than contractBalance, return false, else true
            return false;
        }
        return true;
    }

    /*
    this function releases all staked NFTs and unclaimed tokens to their owners
    */
    function releaseAllStakedAndUnclaimed() public onlyOwner() {
        // if less tokens in contract than unclaimed, cant realease
        bool possible = compareUnclaimedToRemaining();
        require(possible, "Release not possible, not enough tokens in contract");

        // loop through all addresses who staked once
        for(uint256 i = 0; i < stakerAddresses.length; i++) {
            // get i-th staker
            Staker storage staker = stakers[stakerAddresses[i]];
            // get unclaimed tokens of current staker
            uint256 amountOfStaker = calculateEarnedTokens(staker);
            // set unclaimed to zero
            staker.unclaimedTokens = 0;
            // transfer tokens
            rewardsToken.transfer(stakerAddresses[i], amountOfStaker);

            // loop through all staked tokens of current staker
            for(uint256 j = 0; j < staker.tokenIds.length; j++) {
                // get id
                uint256 id = staker.tokenIds[j];
                // transfer token sepcified by id
                stakeNFT.transferFrom(address(this), stakerAddresses[i], id);

                // get last index of array
                uint256 lastIndex = staker.tokenIds.length - 1;
                // get (key)value of last index
                uint256 lastIndexKey = staker.tokenIds[lastIndex];
                // get index of token to unstake
                uint256 tokenIdIndex = getIndexForTokenId(id);

                // replace unstaked tokenId with last stored tokenId 
                // (order does not matter since timestamps have been updated during withdrawal)
                staker.tokenIds[tokenIdIndex] = lastIndexKey;

                // pop last value of array tokenIds and timestamps
                staker.tokenIds.pop();
                staker.timestamps.pop();
            }
        }
        // set totalStaked to zero
        totalStaked = 0;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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