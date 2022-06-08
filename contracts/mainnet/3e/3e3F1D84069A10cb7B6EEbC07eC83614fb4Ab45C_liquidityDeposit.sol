/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT

//Evolve coin is official token by Evolve, first sport federation of E2, expanding onto the metaverse. Please for more information visit , or you can reach us here https://discord.gg/bsGeU7rMK6
//go Shane! Go E2, The Metaverse!

pragma solidity ^ 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^ 0.8.0;

interface LiquidityInterface {
    function transferForLiquidity() external payable;
}

contract liquidityDeposit is Ownable {

    bool public liquidityDecided = false;
    address public poolAddress;
    LiquidityInterface liquidityInstance;

    function decidePool(address _poolAddress) public onlyOwner{   // this callable once in a life

        require(liquidityDecided == false);
        poolAddress = _poolAddress;
        liquidityDecided = true;
        liquidityInstance = LiquidityInterface(poolAddress);

    }

    function withdraw() public payable onlyOwner {
        liquidityInstance.transferForLiquidity{value: (address(this).balance)}();
    }

    function transferForLiquidity() public payable {}

}