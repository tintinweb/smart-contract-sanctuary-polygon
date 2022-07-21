// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract MinerioLand is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////                                                                                    ////////////////
    ////////////////     .88b  d88.   d888888b   d8b   db   d88888b   d8888b.   d888888b    .d88b.      ////////////////
    ////////////////     88'YbdP`88     `88'     888o  88   88'       88  `8D     `88'     .8P  Y8.     ////////////////
    ////////////////     88  88  88      88      88V8o 88   88ooooo   88oobY'      88      88    88     ////////////////
    ////////////////     88  88  88      88      88 V8o88   88~~~~~   88`8b        88      88    88     ////////////////
    ////////////////     88  88  88     .88.     88  V888   88.       88 `88.     .88.     `8b  d8'     ////////////////
    ////////////////     YP  YP  YP   Y888888P   VP   V8P   Y88888P   88   YD   Y888888P    `Y88P'      ////////////////
    ////////////////                                                                                    ////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     VARIABLES      /////////////////////
    ////////////////////////////////////////////////////////////////////


    string private baseURI;
    // Mapping from token ID to approved lands
    mapping(uint256 => LandInfo) private landInfo;


    constructor() ERC721("Minerio Land", "RioLand") {
        setBaseURI("https://minerio.net/api/token/get-info/");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    ////////////////////////////////////////////////////////////////////
    ///////////////////////////\     STRUCTS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    /**
     * the land info struct 
     */
    struct LandInfo {
        uint tokenId;
        uint cityCode;
        uint district;
        uint landType;
        uint blocksCount;
        uint number;
    }

    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     MODIFIERS      /////////////////////
    ////////////////////////////////////////////////////////////////////
    


    ////////////////////////////////////////////////////////////////////
    ///////////////////////\     Main Functions      ///////////////////
    ////////////////////////////////////////////////////////////////////


    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * the mint function which takes a land 
     * only called by owner
     */
    function safeMint(LandInfo memory _land ,address _to) public onlyOwner {
        require(validateLand(_land));
        _safeMint(_to, _land.tokenId);
        landInfo[_land.tokenId] = _land;
    }


    /**
     * the bulk mint function which takes array lands
     * only called by owner
     */
    function safeBulkMint(LandInfo[] memory _lands,address _to) public onlyOwner {
        for(uint i=0;i<_lands.length ;i++){
            require(validateLand(_lands[i]));
            _safeMint(_to, _lands[i].tokenId);
            landInfo[_lands[i].tokenId] = _lands[i];
        }
    }

    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
    }

    
    ////////////////////////////////////////////////////////////////////
    /////////////////////////\     INTERNALS      //////////////////////
    ////////////////////////////////////////////////////////////////////


    /**
     * validates the land to make sure the sent land from the owner is in currect format
     */
    function validateLand(LandInfo memory _land) internal pure returns(bool){
        return _land.tokenId!=0 && _land.cityCode!=0 &&  _land.district!=0 &&  _land.landType!=0 &&  _land.blocksCount!=0;
    }


    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     SETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
    
    ////////////////////////////////////////////////////////////////////
    //////////////////////////\     GETTEERS      //////////////////////
    ////////////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    /**
     * gets the id and returns the land info
     */
    function getLand(uint _id)external view returns(LandInfo memory){
        require(ownerOf(_id) != address(0), "ERC721: invalid token ID");
        return landInfo[_id];
    }

}