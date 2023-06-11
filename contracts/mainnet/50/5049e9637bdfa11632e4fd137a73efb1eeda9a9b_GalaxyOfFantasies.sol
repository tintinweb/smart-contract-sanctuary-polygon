// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract GalaxyOfFantasies is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {

    uint256 private _tokenIdCounter;


    uint256 private maxTotalSupply;
    uint256 private nftPerAddressLimit;
    uint256 private maxMintAmount;
    uint256 private price;
    uint256 private whiteListPrice;
    bool private paused;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private owners;
    mapping(address => int) private operators;
    string public baseTokenURI; 
    string public baseExtension = ".json";
    constructor() ERC721("Passport Artaria","PA"){
        maxTotalSupply = 2023;
        nftPerAddressLimit = 1;
        maxMintAmount = 5;
        price = 50000000000000000000;
        whiteListPrice = 25000000000000000000;
        paused = false;
        baseTokenURI = "ipfs://QmTw3LtXmwATviPVSpfAsBKfqW2KAhNCKoG7VQAb3vYFBJ/";
        _tokenIdCounter = 1;
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }


    function setWhiteListPrice(uint256 _price) external onlyOwner {
        whiteListPrice = _price;
    }

    function getTotalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }


function transfer(address _to, uint256 _tokenId) external {
    require(_to != address(0), "Invalid recipient");
    require(_to != address(this), "Invalid recipient");
    require(msg.sender == owners[_tokenId], "Not token owner");

    emit Transfer(msg.sender, _to, _tokenId);
}

function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
    maxTotalSupply = _maxTotalSupply;
}

function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
    maxMintAmount = _maxMintAmount;
}

function setNftPerAddressLimit(uint256 _nftPerAddressLimit) external onlyOwner {
    nftPerAddressLimit = _nftPerAddressLimit;
}

function pause() external onlyOwner {
    paused = true;
}

function unpause() external onlyOwner {
    paused = false;
}

function isPaused() external view returns (bool) {
    return paused;
}

function withdrawMoney() external onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
}
function mint() external payable {
    //Самоминт
    require(!paused, "Sales have been paused");
    if (operators[msg.sender] == 2)
    {
        require(operators[msg.sender] == 1,"You have no access to buy another");
    }
    if (operators[msg.sender] == 1)
    {
        require(msg.value == whiteListPrice, "Incorrect value sent, please check the price");
    }
    else
    {
        require(msg.value == price, "Incorrect value sent, please check the price");
    }
    uint256 tokenId = _tokenIdCounter;
    require(tokenId < maxTotalSupply, "Max total supply reached");
    
    require(balances[msg.sender] < nftPerAddressLimit, "Exceeded balance limit per address");
    balances[msg.sender] = 1;
    _tokenIdCounter += 1;
    _mint(msg.sender, tokenId);
    _setTokenURI(tokenId, baseTokenURI);
}

function adminMint(address _to) external payable onlyOwner {
    require(!paused, "Sales have been paused");
    uint256 tokenId = _tokenIdCounter;
    _mint(_to, tokenId);
    _setTokenURI(tokenId, baseTokenURI);
    _tokenIdCounter +=1;

}



function whitelist(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
        operators[_addresses[i]] = 1;
    }
}

function blacklist(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
        operators[_addresses[i]] = 2;
    }
}

function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId),"Not exists");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension)) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}