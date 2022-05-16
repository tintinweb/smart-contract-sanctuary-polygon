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

// File: @openzeppelin\contracts\access\Ownable.sol

 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

 
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

// File: contracts\Multisigned.sol

 
pragma solidity ^0.8.1;
contract Allowance {
    
    event allowanceChanged(address _forWho, address _fromWho, uint _oldAmount, uint _newAmount, string currency);
    event addressValidated(address _byWho, address _forWHo);
    event validationIncreased(address _byWho, address _forWHo);
    mapping(address => bool) public validateMapping;
    mapping(address => uint) public allowance;
    mapping(address => uint) public usdAllowance;
    mapping(address => uint8) public  validations;
    mapping(address => mapping(address => bool)) validated;
    address usdAddress;
    uint8 validLength;

    constructor() {
        validateMapping[msg.sender] = true;
        validLength = 1;
    }

    modifier isAllowed {
        require(validateMapping[msg.sender] == true, "You are not allowed to access such feature");
        _;
    }

    function validateAddress(address _address) public isAllowed {
        require(validated[msg.sender][_address] == false, "You already added a validation to this address");
        if(validLength == 1){
        validateMapping[_address] = true;
        }else{
            validated[msg.sender][_address] == true;
            validations[_address]++;
            emit validationIncreased(msg.sender, _address);
            if(validations[_address] == validLength){
                validateMapping[_address] = true;
                emit addressValidated(msg.sender, _address);
            }
        }
    }

    function unvalidateAddress(address _address) public isAllowed {
        validateMapping[_address] = false;
    }

    function addAllowance(address _who, uint _amount) public isAllowed {
        require(msg.sender != _who, "You cant give allowance to yourself");
        allowance[_who] = _amount;
        emit allowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] + _amount, 'matic');
    }

    function addUsdAllowance(address _who, uint _amount) public isAllowed {
        require(msg.sender != _who, "You cant give allowance to yourself");
        allowance[_who] = _amount;
        emit allowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] + _amount, 'tether');
    }

    function removeAllowance(address _who, uint _amount) public isAllowed {
        require(msg.sender != _who, "You cant remove allowance to yourself");
        emit allowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount, 'matic');
        allowance[_who] -= _amount;
    }

    function removeAllowanceUsd(address _who, uint _amount) public isAllowed {
        require(msg.sender != _who, "You cant remove allowance to yourself");
        emit allowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount, 'usd');
        allowance[_who] -= _amount;
    }    

    function addressStatus(address _address) public view returns(bool) {
            return validateMapping[_address];
    }

    function addressRemainingValidation(address _address) public view returns(uint8){
        return validLength - validations[_address];
    }

    function addressAllowance(address _address) public view returns(uint){
        return allowance[_address];
    }

}

contract Multisigned is Allowance, Ownable {

    event moneySent(address _forWho, uint _amount, string currency);
    event moneyReceived(address _from, uint _amount, string received);

    constructor() {
        usdAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    }


    struct Payment {
        uint amount;
        uint timestamp;
    }

    IERC20 USD = IERC20(usdAddress);

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getUsdBalance() public view returns(uint){
        return USD.balanceOf(address(this));
    }

    function setUsdAddress(address _address) external onlyOwner {
        usdAddress = _address;
    }

    function withdrawMoney(address payable _to, uint _amount) public isAllowed {
        require(getBalance() >= _amount, "Not enough funds");
        if(msg.sender == owner()){
            _to.transfer(_amount);    
        }
        require(allowance[_to] >= _amount, "Higher then allowance");
        _to.transfer(_amount);
        emit moneySent(_to, _amount, 'matic');
    }

        function withdrawUSD(address _to, uint _amount) public isAllowed {
        require(getUsdBalance() >= _amount, "not enough funds to withdraw");
        if(msg.sender == owner()){
            USD.transferFrom(address(this), _to, _amount);    
        }
        require(allowance[_to] >= _amount, "The amount is higher then the address allowance");
        USD.transferFrom(address(this), _to, _amount);
        emit moneySent(_to, _amount, 'tether');
    }



   /* 
   function receiveMoney() public payable{
       balanceReceived[msg.sender].totalBalance += msg.value;
       Payment memory payment = Payment(msg.value, now);
       balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
       balanceReceived[msg.sender].numPayments++;
   }
   */

    receive() external payable {
        emit moneyReceived(msg.sender, msg.value, 'matic');
    }
}