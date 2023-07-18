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
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
}

contract PeterICO is Ownable {

    IERC20 MDSE_token;
    uint public startTime;
    uint public endTime;
    uint public presaleRate;
    uint public hardCap;
    uint public fundRaised;
    //uint MAX_BPS = 10_000;
    address public MDSE;
    address[] public allBuyerAddress;
    address deployer;

    struct TokenSale{
        uint soldToken;
        uint tokenForSale;
    }
    TokenSale public tokenSale;

    struct UserInfo{
        uint MDSE_Token;
        uint investDollar;
    }
    mapping (address=> UserInfo) public userInfo;

    enum currencyType {
        native,
        token
    }

    constructor(address _MDSE,uint _startTime,uint _endTime){

        require(_endTime > _startTime,"End Time should be greater than Start Time");
        require(_startTime > block.timestamp,"Start time should be greater than current time");
        MDSE = _MDSE;
        MDSE_token = IERC20(MDSE);
        startTime = _startTime;
        endTime = _endTime;
        deployer = msg.sender;
        presaleRate = 500; // 0.05 * MAX_BPS
        tokenSale.tokenForSale = 40000000 * 10**18;
        hardCap = tokenSale.tokenForSale;
    }
   
    modifier onlyowner() {
        require(owner() == msg.sender || deployer == msg.sender, "Caller is not the owner");
        _;
    }
    //==================================================================================

    function buy(uint256 _dollar, currencyType CurrencyType, address _tokenContractAddress, uint _tokenValue) public payable returns(bool){

        uint256 buyToken = (_dollar * 10**18) / presaleRate;

        require(isICOOver()==false,"ICO already end");
        
        require(block.timestamp >= startTime,"Out of time window");

        require(tokenSale.tokenForSale >= buyToken,"No enough token for sale");
      
        if (userInfo[msg.sender].MDSE_Token == 0) {
                userInfo[msg.sender] = UserInfo(buyToken,_dollar );
                allBuyerAddress.push(msg.sender);
        } else {
                userInfo[msg.sender].MDSE_Token += buyToken;
                userInfo[msg.sender].investDollar += _dollar;
               
        }

        tokenSale.tokenForSale -= buyToken;
        tokenSale.soldToken += buyToken;

        if (CurrencyType == currencyType.native) {
            payable(owner()).call{value: _tokenValue};
        } else {
            IERC20_USDT(_tokenContractAddress).transferFrom(msg.sender, owner(), _tokenValue);
        }

        MDSE_token.transfer(msg.sender, buyToken);

        fundRaised += _dollar;

        return true;
        
    }

    //=========================================Admin Functions===========================

    function retrieveStuckedERC20Token( address _tokenAddr, uint256 _amount, address _toWallet ) public onlyowner returns (bool) {
        IERC20(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }

    function updateTime(uint256 _startTime, uint256 _endTime) public onlyowner returns (bool) {
        require( _startTime < _endTime, "End Time should be greater than start time");
        require( startTime > block.timestamp, "Can not change time after ICO starts" );      
        require(_startTime > block.timestamp,"Start time should be greater than current time" );
        
        startTime = _startTime;
        endTime = _endTime;
        return true;
    }

    //==================================================================================

    function isICOOver() public view returns (bool) {
        if (
            block.timestamp > endTime ||
            tokenSale.tokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isHardCapReach() public view returns(bool){
        if(hardCap == tokenSale.soldToken){
            return true;
        }else{
            return false;
        }
    }

    //==================================================================================
    
}