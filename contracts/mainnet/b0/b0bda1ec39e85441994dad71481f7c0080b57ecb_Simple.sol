/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

pragma solidity ^0.8.4;

struct Sale
{
	uint256		tokenId;
	address 	buyer;
	uint256		price;
	uint256		expires;
}

contract Simple
{
	mapping(uint256 => Sale)	tokenSales;

	constructor()
    {}

	function acceptSale(uint256 tokenId, uint256 salePrice, address buyer, uint256 agreementLifetime) external
	{
		Sale memory sale;
		sale.tokenId = tokenId;
		sale.price = salePrice;
		sale.buyer = buyer;
		sale.expires = block.timestamp + agreementLifetime;

		tokenSales[tokenId] = sale;
	}

    function getAcceptedSale(uint256 tokenId) view external returns (Sale memory)
	{
		return tokenSales[tokenId];
	}
}