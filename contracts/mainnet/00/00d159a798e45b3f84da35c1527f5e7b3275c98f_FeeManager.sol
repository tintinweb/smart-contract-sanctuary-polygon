/**
 *Submitted for verification at polygonscan.com on 2022-12-01
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

// File: IFeeManager.sol


pragma solidity 0.8.4;

interface IFeeManager{
    function getFeeMultiplier(address user, address token) external view returns (uint256 basisPoints); //setting max multiplier at 6.5536
    function getTokenAllowed(address token) external view returns (bool allowed);
}
// File: FeeManager.sol


pragma solidity 0.8.4;



/**
 * @title Fee Manager
 *
 * @notice A fee manager contract designed for dApps organisations and Biconomy to coordinate meta transactions pricing
 *
 * @dev implements a default fee multiplier
 * @dev owners can set token specific fee multipliers
 * @dev owners can set fee multipliers specific to a given user of a token
 * @dev owners can remove fee multiplier settings, and instead have a given query return it's parent value
 * @dev hierarchy of fee multipliers : default --> token --> tokenUser 
 * 
 * @dev owners can allow tokens
 *
 */

 contract FeeManager is IFeeManager, Ownable{
    
    uint256 bp;

    mapping(address => uint256) tokenBP;

    mapping(address => mapping(address => uint256)) tokenUserBP;

    mapping(address => bool) tokenExempt;

    mapping(address => mapping(address => bool)) tokenUserExempt;

    mapping(address => bool) allowedTokens;

    mapping(address => address) tokenPriceFeed;

    constructor(uint256 _bp) public {
        bp = _bp;
    }

    event TokenEnabledOrDisabled(address indexed tokenAddress,address indexed actor, bool indexed newStatus);

    /**
     * @dev uses if statements to query the hierarchy (default --> token --> tokenUser) from bottom to top 
     * @dev goes up one level if current level's value = 0 and it is not exempt
     *
     * @param user : the address of the user that is requesting a meta transaction
     * @param token : the token that the user will be paying the fee in 
     *
     * @return basisPoints : the fee multiplier expressed in basis points (1.0000 = 10000 basis points)
     */
    function getFeeMultiplier(address user, address token) external override view returns (uint256 basisPoints){
        basisPoints = tokenUserBP[token][user];
        if (basisPoints == 0){
            if (!tokenUserExempt[token][user]){
                basisPoints = tokenBP[token];
                if (basisPoints == 0){
                    if(!tokenExempt[token]){
                        basisPoints = bp;
                    }
                }
            }
        }
    }

    function setDefaultFeeMultiplier(uint256 _bp) external onlyOwner{
        bp = _bp;
    }

    function setDefaultTokenFeeMultiplier(address token, uint256 _bp) external onlyOwner{
        tokenBP[token] = _bp;
        if (_bp == 0){
            tokenExempt[token] = true;
        }
    }

    function removeDefaultTokenFeeMultiplier(address token) external onlyOwner{
        tokenBP[token] = 0;
        tokenExempt[token] = false;
    }

    function setUserTokenFeeMultiplier(address token, address user, uint256 _bp) external onlyOwner{
        tokenUserBP[token][user] = _bp;
        if (_bp == 0){
            tokenUserExempt[token][user] = true;
        }
    }

    function removeUserTokenFeeMultiplier(address token, address user) external onlyOwner{
        tokenUserBP[token][user] = 0;
        tokenUserExempt[token][user] = false;
    }

    function getTokenAllowed(address token) external override view returns (bool allowed){
        allowed = allowedTokens[token];
    }

    function setTokenAllowed(address token, bool allowed) external onlyOwner{
        require(token != address(0), "supported token can not be zero address");
        allowedTokens[token] = allowed;
        emit TokenEnabledOrDisabled(token,msg.sender,allowed);
    }

    function getPriceFeedAddress(address token) external view returns (address priceFeed){
        priceFeed = tokenPriceFeed[token];
    }

    function setPriceFeedAddress(address token, address priceFeed) external onlyOwner {
        tokenPriceFeed[token] = priceFeed;
    }

}