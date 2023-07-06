/**
 *Submitted for verification at polygonscan.com on 2023-07-06
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

// File: contracts/newSwap/Copy_Vault.sol



pragma solidity ^0.8.0;



/**
 *Submitted for verification at BscScan.com on 2022-03-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol



// pragma solidity ^0.8.0;
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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




interface SwapRouter{
    function exchange_multiple(address[9] memory _route,uint256[3][4] memory _swap_params,uint256 _amount,uint256 _expected,address[4] memory _pools) external returns(uint256);

    function get_exchange_multiple_amount(address[9] memory _route,uint256[3][4] memory _swap_params,uint256 _amount,address[4] memory _pools) external view returns(uint256);
}


/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Vault is Ownable {
    address[9] private route = [
        	0x172370d5Cd63279eFa6d502DAB29171933a610AF,
            0x43910e07554312FC7A43e4B71D16A72dDCB5Ec5F,
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
    ];

    address[4] private pools = [
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000
    ];

    uint256[3][4] private swap_params;

    SwapRouter router;

    IERC20 cur  = IERC20(0x172370d5Cd63279eFa6d502DAB29171933a610AF);

    uint256 public swapAmount = 2 * 1e18;

    address payable public receiver;

    constructor(SwapRouter _router,address payable _receiver) {
        router = _router;
        receiver = _receiver;
    }


    function canSwap() public view returns(bool){
        if(cur.balanceOf(address(this)) >= swapAmount){
            return true;
        }else{
            return false;
        }
    }



    function swap() external  {
        if(canSwap()){
            interSwap();
        }
    }


    function interSwap() internal {
        uint256 balance = cur.balanceOf(address(this));
        uint256 outputAmount = router.get_exchange_multiple_amount(route,swap_params,balance,pools);
        router.exchange_multiple(route,swap_params,outputAmount,balance,pools);

        uint256 amount  = address(this).balance;
        receiver.transfer(amount);
    }


    function setSwapAmount(uint256 _swapAmount) external onlyOwner {
        swapAmount = _swapAmount;
    }


    function setReceiver(address payable _receiver) external onlyOwner{
        receiver = _receiver;
    }


    function withdraw(uint256 amount,address account) external onlyOwner{
        uint256 balance = cur.balanceOf(address(this));
        require(balance>= amount,"invalid amount");
        cur.transfer(account,amount);
    }




}