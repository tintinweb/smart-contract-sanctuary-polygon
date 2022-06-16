/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IFactory {
    function withdraw(uint256 salt, address token, address receiver) external returns (address wallet);
}

interface IERC20 {
    function transfer(address, uint256) external;
    function balanceOf(address) external returns(uint256);
}

contract MultV8 {

    address _ADMIN;
    mapping (address => bool) public Owners;

    event IncreaseBalance(address sender, uint256 amount);
    event DecreaseBalance(address target, uint256 amount);

    error InvalidBalance(uint256 currentBalance, uint256 amount, address tokenAddress);

    function modifyOwner(address _wallet, bool _enabled) external {
        require(_ADMIN == msg.sender, "Only for admin");

        Owners[_wallet]=_enabled;
    }

    function contains(address _wallet) public view returns (bool) {
        return Owners[_wallet];
    }

    modifier ownerOnly () {
      require(contains(msg.sender), "Only for owners");
         _;
    }

    constructor () {
        _ADMIN = msg.sender;
        Owners[msg.sender]=true;
    }

    receive () external payable {
        emit IncreaseBalance(msg.sender, msg.value);
    }

    function dumpFactory(address factory, uint[] memory salt, address[] memory token, address receiver) ownerOnly external {
        uint arrayLength = salt.length;

        for (uint i=0; i < arrayLength; i++) {
            IFactory(factory).withdraw(salt[i], token[i], receiver);
        }
    }

    function transferErc20(address[] memory token, address[] memory reciever, uint256[] memory amount) ownerOnly external {
        for (uint i=0; i < token.length; i++) {
            IERC20 ercToken = IERC20(token[i]);

            // string  memory errorMessage = string.concat("ERC20 insufficient funds ", toString(abi.encodePacked(token[i])));
            uint256 currentBalance = ercToken.balanceOf(address(this));

            if (currentBalance < amount[i]) {
                revert InvalidBalance(currentBalance, amount[i], token[i]);
            }

            ercToken.transfer(reciever[i], amount[i]);
        }
    }

    function withdrawAsset(address[] memory targets, uint256[] memory amounts) ownerOnly external {
        require(targets.length == amounts.length, "Invalid params length");

        uint256 amountSum = 0;

        for (uint i = 0; i < amounts.length; i++) {
            amountSum += amounts[i];
        }

        uint256 balance = address(this).balance;

        require(balance >= amountSum, "Invalid factory balance");

        for (uint i=0; i < targets.length; i++) {
            payable(targets[i]).transfer(amounts[i]);
            emit DecreaseBalance(targets[i], amounts[i]);
        }
    }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}