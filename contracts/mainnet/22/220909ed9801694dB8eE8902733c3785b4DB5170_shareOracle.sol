// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
interface PriceSource {
    function latestRoundData() external view returns (uint256);
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// contracts/shareOracle.sol
// SPDX-License-Identifier: UTD

pragma solidity 0.8.11;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
	function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

import "../interfaces/external/ChainlinkPrice.sol";

contract shareOracle {
	// this should just be vieweing a chainlink oracle's price
	// then it would check the balances of that contract in the token that its checking.
	// it should return the price per token based on the camToken's balance

    PriceSource public priceSource;
    ERC20 public underlying;
    ERC20 public shares; 

    uint256 public fallbackPrice;

    event FallbackPrice(int256 price);

// price Source gives underlying price per token
// shareToken should hold underlying and we need to calculate a PPS

    constructor(address _priceSource, address _underlying, address _shares) public {
    	priceSource = PriceSource(_priceSource);
    	underlying  = ERC20(_underlying);
    	shares 		= ERC20(_shares);
    }

    // to integrate we just need to inherit that same interface the other page uses.

	function latestAnswer() public view
		returns 
			(uint256 answer){

        int256 price = priceSource.latestAnswer();

        uint256 _price;

        if(price>0){
        	_price=uint256(price);
        } else {
	    	_price=fallbackPrice;
        }

		uint256 newPrice = ( underlying.balanceOf(address(shares))* _price ) / shares.totalSupply();
		
		return(newPrice);
	}

	function getUnderlying() public view returns (uint256, uint256) {
		return (underlying.balanceOf(address(shares)), shares.totalSupply());
	}

	function updateFallbackPrice() public {
        int256 price = priceSource.latestAnswer();

		if (price > 0) {
			fallbackPrice = uint256(price);
	        emit FallbackPrice(price);
        }
 	}
}