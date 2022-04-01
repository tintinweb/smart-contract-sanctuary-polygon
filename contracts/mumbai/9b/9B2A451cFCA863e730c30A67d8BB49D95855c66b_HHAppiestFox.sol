//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./LiveSale.sol";
import "./PreSale.sol";
import "./WhiteList.sol";
/*
             -#%%+.                        :#%#*:           
            =%@@@%#:                      [email protected]@@%%%+          
           +%@@@@@@%=                   .#@@@@@@%%+         
          *%@@@@@@@@%*                 -%@@@@@@@@%%-        
         -%@@@@@@@@@@%+               [email protected]@@@@@@@@@%%%        
         *@@@@@@@@@@@@%-             *@@@@@@@@@@@@%%+       
        .%@@@@@@@@@@@@@%:-=+*####*+=*@@@@@@@@@@@@@%%#       
        [email protected]@@@@@@@@@@@@@%%%%@@@@@@%%%@@@@@@@@@@@@@@@%%.      
        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%.      
        :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%       
        :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#       
..=++*#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%#*=. 
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%
 #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%
  *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*
   -%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%= 
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*.  
      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*:    
        .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.      
          *%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%:       
         +%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%       
         #%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%       
         =%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*       
        .+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#-      
       +%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#:    */

contract HHAppiestFox is WhiteList,PreSale,LiveSale {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)     {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner     {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

}