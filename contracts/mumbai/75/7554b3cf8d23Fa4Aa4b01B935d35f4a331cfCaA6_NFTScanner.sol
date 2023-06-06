pragma solidity ^0.8.0;
interface INFT {
	function totalSupply() external view returns (uint256); 
	function ownerOf(uint256 tokenId) external view returns (address);
	function balanceOf(address owner) external view  returns (uint256);
	function tokenByIndex(uint256 index) external view returns (uint256);
}
contract NFTScanner {

	struct Res {
		address nft;
		uint tokenId;
		bool isOwner;
	}

	/**
	 *	tokenIdList struct is[[(index of nftList),(tokenId)],……]
	 */
	function scan(address account,INFT[] memory nftList,uint[2][] memory tokenIdList) external view returns(Res[] memory res) {
		res = new Res[](tokenIdList.length);
		for(uint i = 0; i < tokenIdList.length; i++){
			uint[2] memory token = tokenIdList[i];
			INFT nft = nftList[token[0]];
			uint tokenId = token[1];
			address owner = nft.ownerOf(tokenId);
			if(owner == account){
				res[i].nft = address(nft);
				res[i].tokenId = tokenId;
				res[i].isOwner = true;
			}
		}
		return res;
	}

	function specifiedScan(address account,INFT nft721) external view returns(uint[] memory res) {
		uint balance = nft721.balanceOf(account);
		res = new uint[](balance);
		uint totalSupply = nft721.totalSupply();
		uint8 index = 0;
		for(uint i = 0; i < totalSupply; i++){
			uint tokenId = nft721.tokenByIndex(i);
			address owner = nft721.ownerOf(tokenId);
			if(owner == account){
				res[index] = tokenId;
				index++;
			}
		}
	}	
}