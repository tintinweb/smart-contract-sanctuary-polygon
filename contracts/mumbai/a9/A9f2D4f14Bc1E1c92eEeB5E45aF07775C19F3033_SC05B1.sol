/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISC05A{
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address operator);

}

interface ISC05B{
    function mint(address to) external;
}

contract SC05B1 {

    /**  _nextToken para saber el siguiente token a transferir */
    uint public _nextToken;
    address private dead = 0x000000000000000000000000000000000000dEaD;
    
    // Creo una variable tipo IAUX llamada tokenContract
    ISC05A tokenContractSC05A;
    ISC05B tokenContractSC05B;

    /**ADDRESS DEL OWNER DE TODOS LOS TOKENS AL MOMENTO DE DEPLOYAR */
    address private _deployer;

    // EVENTOS
    event BurnedToken(address indexed owner, uint256 tokenId);
    event MixedToken(address to, uint256 tokenId0, uint256 tokenId1);


    /**AL CONSTRUCTOR LE PASO EL ADDRESS DEL SC QUE TIENE EL NFT (SC04) LUEGO DEL DEPLOY*/
    constructor(address tokenSC05A_,address tokenSC05B_) {
      
        _nextToken = 0;
        tokenContractSC05A = ISC05A(tokenSC05A_);
        tokenContractSC05B = ISC05B(tokenSC05B_);
    }

    function burnNFT(uint256 tokenId_) internal {
        
        /**
            -> tiene que chequear que el SC005b1 sea approvval de los tokens (eso lo deberia chequear transfer from)
        */

        tokenContractSC05A.transferFrom(msg.sender , dead, tokenId_ );
    
        emit BurnedToken(msg.sender, tokenId_);

    }
    
    function mixNFT(uint256 tokenId0_, uint256 tokenId1_) public {

        require(tokenContractSC05A.ownerOf(tokenId0_) == msg.sender , 'not owner');
        require(tokenContractSC05A.ownerOf(tokenId1_) == msg.sender , 'not owner');
        require(tokenContractSC05A.isApprovedForAll(msg.sender, address(this)) == true , 'SC05B1 not approved');
        
        burnNFT(tokenId0_);
        burnNFT(tokenId1_);

        tokenContractSC05B.mint(msg.sender);

        emit MixedToken(msg.sender, tokenId0_, tokenId1_);

    }

}