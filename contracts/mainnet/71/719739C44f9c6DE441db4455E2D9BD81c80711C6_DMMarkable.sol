//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// store who is targeting which NFT 
contract DMMarkable
{
    mapping (bytes32 => address[]) internal markerOwners;  // mapping from (collection,tokenId) to addresses targeting it (markers)

    constructor() { 
    }

   /* return number of markers on tokenHash*/
    function numMarkers(bytes32 tokenHash) public view returns (uint256)
    { 
       return markerOwners[tokenHash].length;
    }
    /* retrieve the list of all targeters of this NFT */
    function getMarkerOwnersFor(uint chainId, address nftCollection, uint256 tokenId) public view returns (address[] memory)
    {
        return getMarkerOwners(getTokenHash(chainId, nftCollection,tokenId)); // who is targeting
    }
    /* mark any NFT */
    function addMarker(uint chainId, address nftCollection, uint256 tokenId) public returns (bytes32)
    {
       bytes32 tokenHash = getTokenHash(chainId, nftCollection,tokenId);
       return addMarkerTo(tokenHash);
    }  
    /* only owners of marker can remove themselfs*/
    function removeMarker(uint chainId, address nftCollection, uint256 tokenId, uint index) public returns (bool)
    { 
       bytes32 tokenHash = getTokenHash(chainId,nftCollection,tokenId);
       require(markerOwners[tokenHash][index] == msg.sender,"!owner"); 
       remove(tokenHash, index); 
       return true;
    }
    /* NFT owner can eliminate marker */
    function eliminateMarker(uint chainId, address nftCollection, uint256 tokenId, uint index) public returns (bool)
    {
       bytes32 tokenHash = getTokenHash(chainId,nftCollection,tokenId);
       require( IERC721(nftCollection).ownerOf(tokenId) == msg.sender, "!targetOwner"); 
       remove(tokenHash, index); 
       return true;
    }    
    // mark any NFT 
    function addMarkerTo(bytes32 tokenHash) public returns (bytes32)
    {
       markerOwners[tokenHash].push(msg.sender);
       return tokenHash;
    }
    // return all targeting tokenHash
    function getMarkerOwners(bytes32 tokenHash) public view returns (address[] memory)
    {
        return markerOwners[tokenHash]; // who is targeting
    }
    // get token hash for collection and tokenId
    function getTokenHash(uint chainId, address nftCollection, uint256 tokenId) public pure returns (bytes32)
    {
        return  keccak256(abi.encodePacked(chainId,nftCollection,tokenId));
    }
    /* dev internal, removes mapping */
    function remove(bytes32 tokenHash, uint index) internal returns(address[] memory) {
        address[] storage targeters = markerOwners[tokenHash]; 

        if (index >= targeters.length) return targeters;

        for (uint i = index; i<targeters.length-1; i++){
            targeters[i] = targeters[i+1];
        }
        delete targeters[targeters.length-1];
        targeters.pop();
        return targeters;
    }
}