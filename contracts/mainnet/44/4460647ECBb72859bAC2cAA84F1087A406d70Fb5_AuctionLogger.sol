/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

pragma solidity 0.8.11;


contract AuctionLogger {

	event eventAuctionChanged(address auctionAddress);

	function auctionChanged(address _auctionAddress) external {
		emit eventAuctionChanged(_auctionAddress);
	}


}