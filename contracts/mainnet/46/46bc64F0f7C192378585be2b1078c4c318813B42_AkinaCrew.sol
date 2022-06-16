//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract AkinaCrew is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public cost = 0.03 ether;
    uint256 public maxSupply = 5000;
    uint256 public maxSessionMintLimit = 100;
    uint256 public lastSessionMintLimit;
    uint256 public priceIncrement = 10; 
    uint256 public limitPerTxn = 5;

    bool public paused = true;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Mint amount is below 1");
        require(_mintAmount <= limitPerTxn);
        require(supply + _mintAmount <= maxSessionMintLimit);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {

           require(msg.value >= cost * _mintAmount);               
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
           uint256 random = randomNum(maxSessionMintLimit, block.timestamp + i, maxSessionMintLimit + i) + 1 + lastSessionMintLimit;
           

            if(!_exists(random)){
              _safeMint(msg.sender,random);
              cost = cost * (priceIncrement + 100) / 100;
            }else{
                _mintAmount++;
                 }    
        }
    }

    function randomNum(uint256 _mod, uint256 _seed, uint256 _salt) public view returns(uint256) {
      uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
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
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxSessionMintLimit(uint256 _newmaxSessionMintLimit) public onlyOwner {

        lastSessionMintLimit = maxSessionMintLimit;
        maxSessionMintLimit = _newmaxSessionMintLimit;

    }

    function setPriceIncrement(uint256 _newPriceIncrement) public onlyOwner {
        priceIncrement = _newPriceIncrement;
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