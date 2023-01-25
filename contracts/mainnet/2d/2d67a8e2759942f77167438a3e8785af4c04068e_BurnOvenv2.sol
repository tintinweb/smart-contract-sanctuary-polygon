/**
 *Submitted for verification at polygonscan.com on 2023-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract E1155 {
    function burn(address _from, uint256 _id, uint256 _quantity) public {}
	function batchBurn(address _from, uint256[] memory _ids, uint256[] memory _quantities) public {}
    
}

contract E20 {
    function proxyMint(address reciever, uint256 amount) public {}
    function proxyBurn(address sender, uint256 amount) public {}
    function proxyTransfer(address from, address to, uint256 amount) public {}
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BurnOvenv2 is Ownable{
	// We take from the Pizzas and give to the Coins
	E1155 NewPizza;
	E20 PizzaCoin;
	
	mapping(uint256 => uint256) private _pizzaValue;
	
	constructor() {
		NewPizza = E1155(0xf829FDF890B800d2be08BEA228142726FeD3E71d); // Polygon OS Address
		PizzaCoin = E20(0xb8e57A05579b1F4c42DEc9e18E0b665B0dB5277f); // NEEDS TO BE SET
		
		
	}
	
	function burnPizza( uint256 pizzaId, uint256 amount) public {
		uint256 payout = amount * _pizzaValue[pizzaId];
		NewPizza.burn(_msgSender(), pizzaId, amount);
		PizzaCoin.proxyMint(_msgSender(), payout);	
	}
	
	function burnPizzaBatch( uint256[] memory pizzaIds, uint256[] memory amounts) public {
		uint256 payout = 0;
		
		for (uint256 i=0; i < pizzaIds.length; i++){
			payout += amounts[i] * _pizzaValue[pizzaIds[i]];
		}
		
		NewPizza.batchBurn(_msgSender(), pizzaIds, amounts);
		PizzaCoin.proxyMint(_msgSender(), payout);	
	}

    function setPizzaContract( address newContractAddress ) external onlyOwner {
        NewPizza = E1155( newContractAddress );
    }
	
	function declarePizzaValue( uint256 pizzaId, uint256 pizzaValue) external onlyOwner {
		_pizzaValue[pizzaId] = pizzaValue;
	}
	
    /**
     * @dev Returns the WEI COIN amount the submitted pizza tokenId is valued at
     */
	function getPizzaValue( uint256 pizzaId ) public view returns (uint256) {
		return _pizzaValue[pizzaId];
	}
    
}