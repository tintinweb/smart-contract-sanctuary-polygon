pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ERC721 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);
}

contract Multicall {
    function viewBalance(address nft, address holder) external view returns (uint) {
        return ERC721(nft).balanceOf(holder);
    }

    //if collection size is too large. receiving context deadline exceeded (ie. arbitrum)
    function viewOwnedIdsBatch(address nft, address holder, uint startTokenId, uint endTokenId) external view returns (uint[] memory returnData) {
        uint balance = ERC721(nft).balanceOf(holder);
        returnData = new uint[](balance);
        uint pos = 0;
        for (uint i = startTokenId; i <= endTokenId; i++) {
            try ERC721(nft).ownerOf(i) returns (address owner) {
                if (owner == holder) {
                    returnData[pos] = i;
                    pos++;
                }
                if (pos >= balance) {
                    i = endTokenId + 1;
                }
            } catch {}
        }
    }

    function viewOwnedIds(address nft, address holder, uint supply) external view returns (uint[] memory returnData) {
        uint balance = ERC721(nft).balanceOf(holder);
        returnData = new uint[](balance);
        uint pos = 0;
        for (uint i = 0; i < supply; i++) {
            try ERC721(nft).ownerOf(i) returns (address owner) {
                if (owner == holder) {
                    returnData[pos] = i;
                    pos++;
                }
                if (pos >= balance) {
                    i = supply;
                }
            } catch {}
        }
    }
}