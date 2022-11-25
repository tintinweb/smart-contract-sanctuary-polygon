/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT

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

// File: contracts/IseedStakingForInfinity.sol



pragma solidity >=0.7.0 <0.9.0;


interface InfinityCloudTokenInterface {
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IseedInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function walletOfUser (address _user) external view returns(uint256 [] memory);
}

contract IseedStakingForInfinity is Ownable {

    address [] public users;
    mapping (address => bool) public userExists;

    mapping (uint256 => uint256) public whenStakeStarted;       //id => stake time
    mapping (uint256 => uint256) public requestableTokens;      //id => total tokens that can be applied for
    mapping (uint256 => bool) public tokenAlreadyListed;        //id => bool (exists)

    uint256 public tokensToUnlock = 1000 * 10 ** 18;            //1.000 tokens to give to the user
    uint256 public stakeTime = 86400;                           //how many seconds there are in a day
    uint256 public rewardForTheMint = 10000 * 10 ** 18;         //10000 tokens as reward
    mapping(address => uint256) public tokensRedeemed;          //user => tokens redeemed

    address public infinityCloudTokenAddress;
    InfinityCloudTokenInterface infinityCloudTokenInstance;

    address public IseedAddress;
    IseedInterface IseedInstance;

    bool public stop = false;
    uint256 public tokensBunrt = 0;

    struct TokenInStaking {
        uint256 tokenId;
        bool inStaking;
    }

    constructor (address _IseedAddress, address _infinityCloudTokenAddress) {
        require(_IseedAddress != address(0), "Invalid address 0 for collection address!");
        require(_infinityCloudTokenAddress != address(0), "Invalid address 0 for ERC20!");

        IseedAddress = _IseedAddress;
        IseedInstance = IseedInterface(_IseedAddress);

        infinityCloudTokenAddress = _infinityCloudTokenAddress;
        infinityCloudTokenInstance = InfinityCloudTokenInterface(_infinityCloudTokenAddress);
    }


    modifier notStopped {
        require(!stop);
        _;
    }

    //FUNCTIONS
    function stakeToken(uint256 [] memory _tokenIds) public notStopped {

        if(!userExists[msg.sender]) {
            userExists[msg.sender] = true;
            users.push(msg.sender);
        }

        uint256 lengthOfIds = _tokenIds.length;
        uint256 tokenId = 0;

        for(uint256 i = 0; i < lengthOfIds; i++) {
            //owner of tokenId
            tokenId = _tokenIds[i];
            require(IseedInstance.ownerOf(tokenId) == msg.sender);

            //check if token has already been listed
            if(!tokenAlreadyListed[tokenId]) {
                requestableTokens[tokenId] = rewardForTheMint;
                tokenAlreadyListed[tokenId] = true;
            }

            //tokenId can be staked
            uint256 stakeStarted = whenStakeStarted[tokenId];
            require(block.timestamp >= stakeStarted + stakeTime, "Stake not available yet.");
            whenStakeStarted[tokenId] = block.timestamp;
            
            //tokens to the owner
            uint256 tokenAvailableForTheId = requestableTokens[tokenId];
            uint256 tokensToTransfer = 0;

            if(tokenAvailableForTheId > 0) {
                if (tokenAvailableForTheId > tokensToUnlock) {
                    tokensToTransfer = tokensToUnlock;
                    requestableTokens[tokenId] -= tokensToUnlock;
                } else {
                    tokensToTransfer = tokenAvailableForTheId;
                    requestableTokens[tokenId] = 0;
                }

                require(infinityCloudTokenInstance.transfer(msg.sender, tokensToUnlock), "Transfer not completed");
                tokensRedeemed[msg.sender] += tokensToUnlock;
            }
        }
    }

    function isTokenInStaking (uint256 _id) public view returns (bool) {
        uint256 stakeStarted = whenStakeStarted[_id];

        if(block.timestamp >= stakeStarted + stakeTime) {
            return false;
        } else {
            return true;
        }
    }

    function remainingInfinityTokens () public view returns (uint256) {
        if(stop) {
            return tokensBunrt;
        }
        return infinityCloudTokenInstance.balanceOf(address(this));
    }

    function usersTokensInStaking() public view returns (TokenInStaking [] memory) {
        uint256 [] memory tokens = IseedInstance.walletOfUser(msg.sender);
        TokenInStaking [] memory tokensInStaking = new TokenInStaking[](tokens.length);

        for(uint256 i = 0; i < tokens.length; i++){
            tokensInStaking[i] = TokenInStaking(tokens[i], isTokenInStaking(tokens[i]));
        }

        return tokensInStaking;
    }

    function tokensToRedeem () public view returns(uint256) {
        uint256 [] memory tokens = IseedInstance.walletOfUser(msg.sender);
        uint256 total = 0;
        for(uint256 i = 0; i < tokens.length; i++){
            total += requestableTokens[tokens[i]];
        }
        return total;
    }
    //#########################################################

    /**
    *   Stop staking
    */
    function stopStaking () public notStopped onlyOwner {
        uint256 balance = infinityCloudTokenInstance.balanceOf(address(this));
        tokensBunrt = balance;
        infinityCloudTokenInstance.burn(balance);
        stop = true;
    }
    //#############

    //SETTINGS
    function setStakingTime(uint256 _stakeTime) public notStopped onlyOwner {
        stakeTime = _stakeTime;
    }

    function setTokensToUnlock(uint256 _tokensToUnlock, uint256 _decimals) public notStopped onlyOwner {
        tokensToUnlock = _tokensToUnlock * 10 ** _decimals;
    }
}