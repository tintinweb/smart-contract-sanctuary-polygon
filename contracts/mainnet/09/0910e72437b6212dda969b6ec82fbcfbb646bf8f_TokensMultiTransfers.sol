/**
 *Submitted for verification at polygonscan.com on 2023-08-01
*/

// SPDX-License-Identifier: MIT

/**
 * VladimirGav
 * GitHub Website: https://vladimirgav.github.io/
 * GitHub: https://github.com/VladimirGav
 */

/**
 * It is example of a TokensMultiTransfers of Contract from VladimirGav
 * A smart contract allows anyone to send any tokens and cryptocurrencies of the network to many addresses. 
 * The amounts of tokens for distribution can be the same for all or different for each address.
 */

pragma solidity >=0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// @dev Wrappers over Solidity's arithmetic operations with added overflow * checks.
library SafeMath {
    // Counterpart to Solidity's `+` operator.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    // Counterpart to Solidity's `-` operator.
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    // Counterpart to Solidity's `*` operator.
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

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    // Counterpart to Solidity's `/` operator.
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    // Counterpart to Solidity's `%` operator.
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyOwner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Wallet is Ownable {
    receive() external payable {}
    fallback() external payable {}

    // Transfer Eth
    function transferEth(address _to, uint256 _amount) public onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // Transfer Tokens
    function transferTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20 contractToken = IERC20(_token);
        contractToken.transfer(_to, _amount);
    }

}

contract TokensMultiTransfers is Context, Ownable, Wallet {
    using SafeMath for uint256;

    function getSumByArr(uint256[] memory _uintArr) internal pure returns (uint256) {
        uint256 uintSum = 0;
        for (uint i; i < _uintArr.length; i++) {
            uintSum = uintSum.add(_uintArr[i]);
        }
        return uintSum;
    }

    // multiTransfersEth
    function multiTransfersEth(address[] memory  _addressesArray, uint256[] memory  _amountsArray) payable public returns (bool) {
        require(_addressesArray.length == _amountsArray.length, "_addressesArray.length != _amountsArray.length");
        require(msg.value >= getSumByArr(_amountsArray), "You must send eth");

        for (uint i; i < _addressesArray.length; i++) {
            payable(_addressesArray[i]).transfer(_amountsArray[i]);
        }

        // Refund
        uint256 amountRefund = msg.value.sub(getSumByArr(_amountsArray));
        if(amountRefund>0){
            (bool success, ) = msg.sender.call{value:amountRefund}("");
            require(success, "Transfer failed.");
        }

        return true;
    }

    // multiTransfersEth Equal Amount
    function multiTransfersEthEqualAmount(address[] memory  _addressesArray, uint256 _amount) payable public returns (bool) {
        require(msg.value >= _amount.mul(_addressesArray.length), "You must send eth");

        for (uint i; i < _addressesArray.length; i++) {
            payable(_addressesArray[i]).transfer(_amount);
        }

        // Refund
        uint256 amountRefund = msg.value.sub(_amount.mul(_addressesArray.length));
        if(amountRefund>0){
            (bool success, ) = msg.sender.call{value:amountRefund}("");
            require(success, "Transfer failed.");
        }

        return true;
    }

    // multiTransfersTokens
    function multiTransfersTokens(address _token, address[] memory  _addressesArray, uint256[] memory  _amountsArray) public returns (bool) {
        require(_addressesArray.length == _amountsArray.length, "_addressesArray.length != _amountsArray.length");

        IERC20 contractToken = IERC20(_token);
        for (uint i; i < _addressesArray.length; i++) {
            contractToken.transferFrom(_msgSender(), _addressesArray[i], _amountsArray[i]);
        }

        return true;
    }

    // multiTransfersTokens Equal Amount
    function multiTransfersTokensEqualAmount(address _token, address[] memory  _addressesArray, uint256 _amount) public returns (bool) {

        IERC20 contractToken = IERC20(_token);
        for (uint i; i < _addressesArray.length; i++) {
            contractToken.transferFrom(_msgSender(), _addressesArray[i], _amount);
        }
        
        return true;
    }

}