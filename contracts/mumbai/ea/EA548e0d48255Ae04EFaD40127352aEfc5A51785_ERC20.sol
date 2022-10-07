// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

/**
    @dev implementation of the IERC20 interface.
 */
contract ERC20 is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    uint256 private _totalSupply;
    uint8 public decimals = 18;

    string public name;
    string public symbol;

    /**
        @dev sets values for _name, _symbol and _totalSupply.
        _totalSupply is allocated to the owner of this contract.
        @param name_ future name of the contract.
        @param symbol_ future symbol if the  contract.
        @param totalSupply_ future total supply of the contract.
        @notice total supply is calculated by multiplying totalSupply_ by 10 in power of _decimals.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        name = name_;
        symbol = symbol_;
        _totalSupply = totalSupply_ * 10**decimals;
        _balances[msg.sender] = _totalSupply;
    }

    /**
        @dev see IERC20-totalSupply.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
        @dev see IERC20-balanceOf.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
        @dev see IERC20-transfer.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
        @dev see IERC20-allowance.
     */
    function allowance(
        address owner,
        address spender
    ) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
        @dev see IERC20-approve.
     */
    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
        require(spender != address(0), "Zero address can not be allowed to spend tokens");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
        @dev see IERC20-transferFrom.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Your allowance is less than amount you try to send");

        _allowances[sender][msg.sender] -= amount;

        return true;
    }

    /**
        @dev internal transfer to decrease amount of bytecode in contract
     */
     function _transfer(
         address _from,
         address _to,
         uint256 _amount
    ) internal virtual {
        require(_to != address(0), "Transfer to zero address is not allowed");
        require(_from != address(0), "Transfer from zero address is not allowed");
        require(_balances[_from] >= _amount, "Sender does not have enough balance");

        _beforeTokenTransfer(_from, _to, _amount);

        _balances[_from] -= _amount;
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }

    /**
    
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {
        
    }

    function mint(address to, uint256 value) public onlyOwner {
        _balances[to] += value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title ERC20 interface.
    @author @farruhsydykov.
 */
interface IERC20 {
    /**
        @dev returns the amount of tokens that currently exist.
     */
    function totalSupply() external view returns (uint256);

    /**
        @dev returns the amount of tokens owned by account.
        @param account is the account which's balance is checked
     */
    function balanceOf(address account) external view returns (uint256);

    /**
        @dev sends caller's tokens to the recipient's account.
        @param recipient account that will recieve tokens in case of transfer success
        @param amount amount of tokens being sent
        @return bool representing success of operation.
        @notice if success emits transfer event
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
        @dev returns the remaining amount of tokens that spender is allowed
        to spend on behalf of owner.
        @param owner is the account which's tokens are allowed to be spent by spender.
        @param spender is the account which is allowed to spend owners tokens.
        @return amount of tokens in uint256 that are allowed to spender.
        @notice allowance value changes when aprove or transferFrom functions are called.
        @notice allowance is zero by default.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
        @dev allowes spender to spend a set amount of caller's tokens throught transferFrom.
        @param spender is the account which will be allowed to spend owners tokens.
        @param amount is the amount of caller's tokens allowed to be spent by spender.
        @return bool representing a success or failure of the function call.
        @notice emits and Approval event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
        @dev sends amount of allowed tokens from the sender's account to recipient'saccount.
        amount is then deducted from the caller's allowance.
        @param sender is the account which's tokens are allowed to and sent by the caller.
        @param recipient is the account which will receive tokens from the sender.
        @param amount is the amount of tokens sent from the sender.
        @return bool representing a success or a failure of transaction.
        @notice emits Transfer event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
        @dev emitted when a transfer occures. Notifies about the value sent from which to which account.
        @param from acccount that sent tokens.
        @param to account that received tokens.
        @param value value sent from sender to receiver.
        @notice value may be zero
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
        @dev emitted when an account allowed another account to spend it's tokens on it's behalf.
        @param owner owner of tokens which allowed it's tokens to be spent.
        @param spender account who was allowed to spend tokens on another's account behalf.
        @param value amount of tokens allowed to spend by spender from owner's account.
        @notice value is always the allowed amount. It does not accumulated with calls to approve.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    /**
        @dev emitted when ownership is transfered 
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        @dev creates a contract instance and sets deployer as its _owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
        @dev returns address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
        @dev checks if caller of the function is _owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "You are not the owner");
        _;
    }

    /**
       @dev transfers the ownership to 0x00 address.
       @notice after renouncing contract ownership functions with onlyOwner modifier will not be accessible.
       @notice can be called only be _owner
    */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
        @dev transfers ownership to newOwner.
        @notice can not be transfered to 0x00 addres.
        @notice can be called only be _owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "zero address can not be owner");
        _transferOwnership(newOwner);
    }

    /**
        @dev internal function to transfer ownership.
        @notice can only be called internally and only by _owner.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}