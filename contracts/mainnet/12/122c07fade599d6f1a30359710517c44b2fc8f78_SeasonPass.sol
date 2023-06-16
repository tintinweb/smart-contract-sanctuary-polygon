// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./ERC2981.sol";


contract SeasonPass is  ERC1155Supply,Ownable,Pausable,ERC2981  {
    using Strings for uint256;

    uint256 public constant S1_TOKEN_ID = 1;

    uint256 public constant S2_TOKEN_ID = 2;

    string public name = "Remparts de Tours NFT";

    string public symbol = "RDT4";

    //SUPPLIES
    uint256 public s1MaxSupply = 25;

    uint256 public s2MaxSupply = 25;

    constructor()
    ERC1155("")
      {
      }
 
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function mint(address to,uint256 s1Count,uint256 s2Count ) external onlyOwner {
        require(!paused(),"Contract is paused");
        _checkMaxSupply(s1Count, s2Count);        
        if(s1Count > 0 ){
            _mint(to, S1_TOKEN_ID, s1Count, "");
        }
        if(s2Count > 0 ){
            _mint(to, S2_TOKEN_ID, s2Count, "");
        }
        

    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }
    
    //SUPPLY CHECKERR
    function _checkMaxSupply(uint256 s1Count, uint256 s2Count) private view {
        require(s1Count>=0&&s2Count>=0, "quantity must be positive");
        require(totalSupply(S1_TOKEN_ID) + s1Count <= s1MaxSupply, "s1 supply reached");
        require(totalSupply(S2_TOKEN_ID) + s2Count <= s2MaxSupply, "s2 supply reached");        
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(super.uri(0), "contract.json"));
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}