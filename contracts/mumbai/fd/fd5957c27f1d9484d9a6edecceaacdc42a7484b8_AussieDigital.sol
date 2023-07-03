/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     event Burn(address indexed from, uint256 value);
     
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address public owner=msg.sender;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor (address _tokenOwner) {
        owner = _tokenOwner;
        emit OwnershipTransferred(address(0), owner);
    }


    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

//Token 
contract AussieDigital is Context, IBEP20, Ownable 
{


     mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

    string private constant _name = "Aussie Digital";
    string private constant _symbol = "AUDE";
    uint256 _totalSupply;
     uint constant _myinitialSupply =25000000000;
         uint8 constant _myDecimal = 18;

   
    constructor() Ownable(owner) {
       
        _totalSupply = _myinitialSupply * 10 ** uint256(_myDecimal);  // Update total supply with the decimal amount
        balanceOf[owner] = _totalSupply; 
        emit Transfer(address(0) , owner, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function burn(uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value, "Not enough balance");
    balanceOf[msg.sender] -= _value;
    _totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balanceOf[_from] >= _value, "Not enough balance");
    require(allowance[_from][msg.sender] >= _value, "Not enough allowance");

    balanceOf[_from] -= _value;
    allowance[_from][msg.sender] -= _value;
    _totalSupply -= _value;

    emit Burn(_from, _value);
    emit Transfer(_from, address(0), _value);

    return true;
  }

   
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        require(allowance[sender][_msgSender()] >= amount, "BEP20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance[sender][_msgSender()] - amount);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
         require(balanceOf[sender]  >= amount, "BEP20: transfer amount exceeds balance");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);

    }
      function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

      
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 

       
   
        
}