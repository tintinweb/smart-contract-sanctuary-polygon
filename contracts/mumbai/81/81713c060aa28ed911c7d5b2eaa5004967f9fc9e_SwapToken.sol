/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

pragma solidity ^0.5.0;

contract TokenERC20 {
	function transferFrom(address from, address to, uint value) public returns (bool ok);
}

contract SwapToken{
	function swap(address[] memory _tokenAddress, address[] memory _from, address[] memory _to, uint256[] memory _value) public returns (bool) {
		require(_to.length == _value.length);
		require(_from.length == _to.length);
		for (uint8 i = 0; i < _to.length; i++){
			TokenERC20 token = TokenERC20(_tokenAddress[i]);
			require(token.transferFrom(_from[i], _to[i], _value[i]));
		}
		return true;
	}
}