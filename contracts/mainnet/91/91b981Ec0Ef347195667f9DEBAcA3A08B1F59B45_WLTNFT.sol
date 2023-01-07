// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauser.sol";

interface TokenLike {
    function transfer(address,uint) external;
}

contract WLTNFT is ERC1155PresetMinterPauser {

    string                           public symbol = "wltnft";
    string                           public name = "MicroLinkToken NFT"; 
    
    constructor() ERC1155PresetMinterPauser( "https://microlinktoken.com/1155/json/{id}.json") {
            wards[msg.sender] = 1;
    }

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "WLTNFT/not-authorized");
        _;
    }

    function setURI(string memory _baseURI) public auth {
         _setURI(_baseURI);      
    }
    
    function mintAuth(address to, uint256 _tokenid, uint256 amount) public auth {
        _mint(to, _tokenid, amount, "");
    }

    function withdraw(address asses,uint256 wad, address usr) public auth {
        TokenLike(asses).transfer(usr, wad);
    }

    function withdrawNFT(uint256 id, uint256 amount, address usr) public auth {
        safeTransferFrom(address(this),usr,id,amount,"");
    }

}