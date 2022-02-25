//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract FlashNFTs is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public cost = 175 ether;
    uint256 public maxSupply = 200;

    bool public paused = false;

    bool public revealed = false;
    string public notRevealedUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri

    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
                                    
        }
                    

        for (uint256 i = 1; i <= _mintAmount; i++) {
            if(_exists(i)){

                    _mintAmount++;

            }else {

              _safeMint(_to,i);

            }

        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
        return notRevealedUri;
    }

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

    //only owner

    function mintSpecificIDs(uint256[] calldata ID) public payable onlyOwner {
      require(!paused,"paused");
        
        for (uint256 x = 0; x < ID.length; x++) {

            uint256 supply = totalSupply();      
            require(supply + 1 <= maxSupply,"max Supply reached");
            _safeMint(msg.sender, ID[x]);

        }
  }

    function mintSpecificIDsforHolders(address[] calldata _holder ,uint256[] calldata ID) public payable onlyOwner {
      require(!paused,"paused");
      require(_holder.length == ID.length,"holder count and NFT count mismatch");

        
        for (uint256 x = 0; x < ID.length; x++) {

            uint256 supply = totalSupply();      
            require(supply + 1 <= maxSupply,"max Supply reached");
            _safeMint(_holder[x], ID[x]);

        }
  }

    function reveal() public onlyOwner {
    revealed = true;
    }


    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
    }


    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

       
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
     
  
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}