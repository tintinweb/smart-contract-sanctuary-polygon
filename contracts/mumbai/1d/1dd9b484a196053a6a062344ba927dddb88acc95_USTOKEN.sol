/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;



interface USToken {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function mint(address, uint) external;
    function minter() external returns (address);
    function claim(address, uint) external returns (bool);
}

contract USTOKEN is USToken {

    string public name ;
    string public symbol ;
    uint8 public constant decimals = 18;
    uint public totalSupply ;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bool public initialMinted;
    address public minter;
    address public redemptionReceiver;
    address public merkleClaim;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(
        string memory _name, string memory _symbol, uint  _totalSupply
    ) {
        minter = msg.sender;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
    }

    // No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    }

    function setRedemptionReceiver(address _receiver) external {
        require(msg.sender == minter);
        redemptionReceiver = _receiver;
    }

    function setMerkleClaim(address _merkleClaim) external {
        require(msg.sender == minter);
        merkleClaim = _merkleClaim;
    }

    // Initial mint: total 5M
function initialMint(address _recipient) external {
        require(msg.sender == minter && !initialMinted);
        initialMinted = true;
        _mint(_recipient, 5_000_000 * 1e18);
    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint _amount) internal returns (bool) {
        totalSupply += _amount;
        unchecked {
            balanceOf[_to] += _amount;
        }
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function mint(address account, uint amount) public  {
        require(msg.sender == minter);
        _mint(account, amount);
        
    }

    function claim(address account, uint amount) external returns (bool) {
        require(msg.sender == redemptionReceiver || msg.sender == merkleClaim);
        _mint(account, amount);
        return true;
    }


}