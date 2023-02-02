/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

pragma solidity ^0.8.17;
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

// File: @openzeppelin/contracts/metatx/ERC2771Context.sol


// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)




/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// File: contracts/Floxy.sol

/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

pragma solidity ^0.8.17;



//SPDX-License-Identifier: MIT Licensed

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = payable(_msgSender());
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}


// ERC20 standards for token creation

contract Floxy is IERC20,Ownable{
    
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address=>bool) public frozenAccount;
    event frozenfunds(address target,bool frozen);
    constructor(address _trustedForwarder){

        _trustedForwarder = _trustedForwarder;
        _name = "Floxy";
        _symbol = "FXY";
        _decimals = 18;
        _totalSupply = 10000000000;   
        _totalSupply = _totalSupply.mul(10**_decimals);
        balances[owner()] = _totalSupply;
    }

    function name() view public virtual override returns (string memory) {
        return _name;
    }

    function symbol() view public virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() view public virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() view public virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) view public virtual override returns (uint256) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256) {
      return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        require (balances[_msgSender()] >= _amount, "ERC20: user balance is insufficient");
        require(_amount > 0, "ERC20: amount can not be zero");
        require(!frozenAccount[_msgSender()]);
        
        balances[_msgSender()]=balances[_msgSender()].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_msgSender(),_to,_amount);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool) {
        require(_amount > 0, "ERC20: amount can not be zero");
        require (balances[_from] >= _amount ,"ERC20: user balance is insufficient");
        require(allowed[_from][_msgSender()] >= _amount, "ERC20: amount not approved");
        require(!frozenAccount[_msgSender()]);
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][_msgSender()]=allowed[_from][_msgSender()].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        require(_spender != address(0), "ERC20: address can not be zero");
        require(balances[_msgSender()] >= _amount ,"ERC20: user balance is insufficient");
        
        allowed[_msgSender()][_spender]=_amount;
        emit Approval(_msgSender(), _spender, _amount);
        return true;
    }
    
    function freezeAccount(address target, bool freeze)public onlyOwner{
        frozenAccount[target]=freeze;
        emit frozenfunds(target,freeze);
    }

}
 
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}