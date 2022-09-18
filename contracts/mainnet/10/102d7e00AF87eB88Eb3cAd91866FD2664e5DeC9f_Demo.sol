/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }


}


contract Demo {

    string public name = 'Demo';
    string public symbol = 'demo';
    uint8 public decimals = 18;
    address public owner;
    uint256 public totalSupply;
    uint256 private initialSupply = 100000000000000000000000000;
    ///100000000 000000000000000000
    //100000000000000000000000000
    //570000000000000

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    constructor (uint256 totalSupply_) {
        totalSupply = totalSupply_;
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function burnedSupply() public view returns (string memory) {
        return string(bytes.concat(bytes(Strings.toString(100 - initialSupply / (totalSupply * 100))), "", bytes('% of initial supply was burned due to rug pull.')));
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(msg.sender != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        uint256 rugpull = value;
        if(totalSupply >= 21000000000000000000000000) {
          rugpull = rugpull/2;
          _burn(rugpull);
        }
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], rugpull); 
        emit Transfer(msg.sender, to, rugpull);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(allowance[from][msg.sender] >= value);
        uint256 rugpull = value;
        if(totalSupply >= 21000000000000000000000000) {
          rugpull = rugpull/2;
          _burn(rugpull);
        }
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], rugpull);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        emit Transfer(from, to, rugpull);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(msg.sender != address(0));
        require(spender != address(0));
        require(value > 0);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _burn(uint256 value) private {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);
        totalSupply = safeSub(totalSupply, value);
        emit Burn(msg.sender, address(0), value);
    }

}