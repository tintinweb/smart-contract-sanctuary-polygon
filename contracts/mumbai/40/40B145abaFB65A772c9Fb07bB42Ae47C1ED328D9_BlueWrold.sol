// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract BlueWrold is ERC721URIStorage, ERC721Enumerable {
    // string public baseURI;
    address owner;
    mapping(address => uint256) minter;

    constructor() ERC721("Blue World", "BW") {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner,"you are not contract creator");
        _;
    }


     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //ipfs://QmRrSmPhMMX5ASXwRB8tpo4qB8eM247X5fPHQ3j6vm9P3q
    function mintBW(
        address caster,
        uint256 tokenId,
        string memory _tokenURI
    ) public payable {
        require(tokenId > 0, "tokenId must exceed 0");
 
        _mint(caster, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    // 获取合约账户余额 
    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }


    //  fallback() external payable {}
    
    //  receive() external payable {}

    //   function _baseURI() internal view override returns (string memory) {
    //          return baseURI;
    //    } 

    //    function setBaseURI(string memory uri) public onlyOwner {
    //          baseURI = uri;
    //    }



}