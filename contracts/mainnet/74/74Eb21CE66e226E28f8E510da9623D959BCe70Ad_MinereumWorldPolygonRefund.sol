/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

pragma solidity ^0.8.0;

interface MinereumWorld {
  function balanceOf(address owner) external returns (uint256);  
  function ownerOf(uint256 tokenId) external returns (address);
}

contract MinereumWorldPolygonRefund {
	address public _owner;
	MinereumWorld public mnew;
	uint public tokenIdMax = 60;
	uint[] public paid;
	uint[] public removed;
  

  constructor()  {
    mnew = MinereumWorld(0x712382CAbBa567554E506c7CcFF28C129b37501A);
	_owner = msg.sender;
  }
  
  receive() external payable {}

	function refundMNEWorldPolygon(uint tokenId) public
	{
		uint cost = 100000000000000000000;
		if (mnew.balanceOf(msg.sender) == 0) revert('Your address has 0 Minereum World nft tokens');
		if (mnew.ownerOf(tokenId) != msg.sender) revert('Not owner');
		if (tokenId > tokenIdMax) revert('Token ID out of the refund range');
		
		for (uint i = 0; i < paid.length; i++)
		{
			if (paid[i] == tokenId)
				revert('already paid');
		}
		
		for (uint i = 0; i < removed.length; i++)
		{
			if (removed[i] == tokenId)
				revert('removed');
		}
		
		require(payable(msg.sender).send(cost));		
		paid.push(tokenId);
	}
	
	function viewPaid() public view returns (uint[] memory)
	{
		return paid;
	}
	
	function viewPaidRange(uint start, uint end) public view returns (uint[] memory)
	{
		uint count = end - start;
		uint[] memory result = new uint[](count);
        uint resultI = 0;
		for (uint i = start; i < end; i++)
		{
			result[resultI] = paid[i];
            resultI++;
		}
		return result;
	}
	
	function paidLength() public view returns (uint)
	{
		return paid.length;
	}
	
	function withdraw() public {
	
	if (msg.sender == _owner)	
	{ 
		require(payable(msg.sender).send(address(this).balance));
	}
	else
	{
		revert('no permissions');
	}
  }
  
  function viewRemoved() public view returns (uint[] memory)
	{
		return removed;
	}
	
	function viewRemovedRange(uint start, uint end) public view returns (uint[] memory)
	{
		uint count = end - start;
		uint[] memory result = new uint[](count);
        uint resultI = 0;
		for (uint i = start; i < end; i++)
		{
			result[resultI] = removed[i];
            resultI++;
		}
		return result;
	}
	
	function removedLength() public view returns (uint)
	{
		return removed.length;
	}
  
  function remove(uint tokenId, bool revoke) public {
	
	if (msg.sender == _owner)	
	{
		if (revoke == false)
		{
			removed.push(tokenId);
		}
		else
		{
		    for (uint i = 0; i < removed.length; i++)
			{
				if (removed[i] == tokenId)
				{
					removed[i] = 0;
				}
			}
		}			
	}
	else
	{
		revert('no permissions');
	}
  }
  
function setTokenIdMax(uint _max) public {
	
	if (msg.sender == _owner)	
	{
		tokenIdMax = _max;		
	}
	else
	{
		revert('no permissions');
	}
  }
  
  
}