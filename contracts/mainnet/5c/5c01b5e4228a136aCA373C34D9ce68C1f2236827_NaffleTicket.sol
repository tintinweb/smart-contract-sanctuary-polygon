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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NaffleTicket is Ownable {

    uint256 public ticketsDollar = 1;
    bool usdtContract = true;
    bool usdcContract = true;
    bool busdContract = true; 
    bool daiContract = true;

    mapping(address => uint256) public _balanceTickets;

    event BuyTickets(address indexed buyer, uint256 indexed amountOfTickets);
    event SwapTickets(address indexed seller, uint256 indexed amountOfTickets);

    constructor() payable{}

    receive() external payable {}

    function BuyTicket(uint256 _amountDollar, address _addressDollar, uint256 tax) public payable returns (uint256 ticketAmount) {
       require(msg.value >= tax, "You must submit transaction gas");

       IERC20 contractDollar = IERC20(_addressDollar);
       uint256 BuyerBalance = contractDollar.balanceOf(msg.sender);
       _balanceTickets[msg.sender] = 0;
       
       require(_addressDollar == 0xc2132D05D31c914a87C6611C10748AEb04B58e8F && usdtContract == true
       || _addressDollar == 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 && usdcContract  == true
       || _addressDollar == 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39 && busdContract  == true
       || _addressDollar == 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 && daiContract  == true,
       "Choose a valid token");

       require(BuyerBalance >= _amountDollar, "Your balance is not enough");
       require(contractDollar.allowance(msg.sender, address(this)) >= _amountDollar, "Approve the quantity required for this contract");
       require(contractDollar.transferFrom(msg.sender, address(this), _amountDollar), "The transfer was not completed");
      
       emit BuyTickets(msg.sender, _amountDollar);
       return _amountDollar;
    }

    function setUsdt(bool _status) public onlyOwner {
        usdtContract = _status;
    }

    function setUsdc(bool _status) public onlyOwner {
        usdcContract = _status;
    }

    function setBusd(bool _status) public onlyOwner {
        busdContract = _status;
    }

    function setDai(bool _status) public onlyOwner {
        daiContract = _status;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "The withdrawal amount is greater than the Contract balance");
        payable(msg.sender).transfer(amount);
    }

    function withdrawDollar(uint256 _amount, address _addressDollar) public onlyOwner{
        IERC20 contractDollar = IERC20(_addressDollar);
        (bool sent) = contractDollar.transfer(msg.sender, _amount);
        require(sent, "Failed to transfer token to Owner");
    }
    
    function setBalance(address _user, uint256 _ticktes) public onlyOwner {
        _balanceTickets[_user] = _ticktes;
    }

    function getBalance(address user, uint256 _decimals) public view returns (uint256){
        uint256 balance = _balanceTickets[user] * (10**_decimals);
        return balance;
    }

    function swap(address _addressDollar, uint256 tax) public payable {
        require(msg.value >= tax, "You must submit transaction gas");

        require(_addressDollar == 0xc2132D05D31c914a87C6611C10748AEb04B58e8F && usdtContract == true
        || _addressDollar == 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 && usdcContract  == true
        || _addressDollar == 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39 && busdContract  == true
        || _addressDollar == 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 && daiContract  == true,
        "Choose a valid token");

        uint256 decimals;
        IERC20 contractDollar = IERC20(_addressDollar);

        if(_addressDollar == 0xc2132D05D31c914a87C6611C10748AEb04B58e8F || _addressDollar == 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174){
            decimals = 6;
        }

        decimals = 18;

        uint256 balanceFrom = getBalance(msg.sender, decimals);
        _balanceTickets[msg.sender] = 0;
        
        (bool sent) = contractDollar.transfer(msg.sender, balanceFrom);
        require(sent, "Failed to transfer tickets");

        emit SwapTickets(msg.sender, balanceFrom);
    }
}