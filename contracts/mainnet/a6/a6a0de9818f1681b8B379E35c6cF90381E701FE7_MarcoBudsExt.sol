/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
/*

    __  ___                           __                __     
   /  |/  /____ _ _____ _____ ____   / /_   __  __ ____/ /_____
  / /|_/ // __ `// ___// ___// __ \ / __ \ / / / // __  // ___/
 / /  / // /_/ // /   / /__ / /_/ // /_/ // /_/ // /_/ /(__  ) 
/_/  /_/ \__,_//_/    \___/ \____//_.___/ \__,_/ \__,_//____/  
   ______                                                      
  / ____/____ _ ____ ___   ___                                 
 / / __ / __ `// __ `__ \ / _ \                                
/ /_/ // /_/ // / / / / //  __/                                
\____/ \__,_//_/ /_/ /_/ \___/                                 
                                                               

Discord: https://discord.io/Marcobuds
Twitter: https://twitter.com/MarcobudsNft
Website: https://marcobuds.io

This is a MarcoBuds Extension used to save additional info of racers.
*/


interface ERC721Interface{
      function ownerOf(uint256) external view returns (address);
}


contract MarcoBudsExt {

    // Mapping MB token Id to names  save names 
    mapping(uint256 => string) public nicknames;

    // Mapping MB token Id to additional extra field in case is needed in future
    mapping(uint256 => string) public extrafield_1;

    // NFT MarcoBuds Contract . Used to check ownership of a token
    ERC721Interface internal MARCOBUDS_CONTRACT;

    uint256 constant public MAX_NFT_SUPPLY = 2200;
    uint256 constant public MAX_NAME_LENGTH = 30;


      constructor(address MarcoBudsContractAddress) {
        require(MarcoBudsContractAddress != address(0), "MarcoBudsContractAddress can not be zero");
        MARCOBUDS_CONTRACT = ERC721Interface(MarcoBudsContractAddress);
      }


        function updateMBName(uint256 _tokenId,string memory _name) external {
            require(bytes(_name).length >= 3 && bytes(_name).length <= MAX_NAME_LENGTH, "name should be between 2 and 30 characters");
            require (_tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY, "MarcoBuds token Id must be between 1 and 2200");
            require (ownerOfMarcoBuds(_tokenId) , "Please make sure you own this MarcoBuds token");
            nicknames[_tokenId] = _name;        
        }

        function updateMBField1(uint256 _tokenId,string memory _field1) external {
            require(bytes(_field1).length >= 3, "field1  should be longer than 2 characters");
            require (_tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY, "MarcoBuds token Id must be between 1 and 2200");
            require (ownerOfMarcoBuds(_tokenId) , "Please make sure you own this MarcoBuds token");
            extrafield_1[_tokenId] = _field1;        
        }


        function ownerOfMarcoBuds(uint256 _tokenId) internal view returns (bool){
                address tokenOwnerAddress = MARCOBUDS_CONTRACT.ownerOf(_tokenId);
                return (tokenOwnerAddress == msg.sender);
        }

  
}