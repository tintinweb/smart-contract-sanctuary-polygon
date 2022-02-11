/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

pragma solidity ^0.8.2;
interface INftEmpresas{
    function newNFT(address add, uint i) external returns (bool);
}
contract BulkNFT {
    INftEmpresas empresa;
    uint[] public ids_NFT;
    mapping (address => bool) public permitedAddress;
    constructor() {
        permitedAddress[msg.sender]=true;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setAddressContratoNFT(address ad) public whenPermited{
        empresa=INftEmpresas(ad);
    }
    function setNfts(uint[] memory arr) public whenPermited {
        ids_NFT=arr;
    }
    function getNftsAvailable() public view returns (uint[] memory) {
        return ids_NFT;
    }
    function setPermitedAddress(address ad, bool permited) public whenPermited {
        permitedAddress[ad]=permited;
    }
    function sendBulkNFT(address[] memory wallets) public whenPermited{
        for(uint i=0;i<wallets.length;i++){
            sendNFT(wallets[i]);
        }
    }
    function sendNFT(address ad) private {
        empresa.newNFT(ad, ids_NFT[_createRandomNum(ids_NFT.length,ad)]);
    }
    function _createRandomNum(uint256 _mod,address ad) internal view returns (uint256) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, ad)));
        return randomNum % _mod; 
    }
}