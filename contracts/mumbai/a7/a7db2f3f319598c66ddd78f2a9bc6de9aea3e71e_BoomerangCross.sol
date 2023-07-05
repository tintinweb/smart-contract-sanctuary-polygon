/*******************************************************************************************
██████╗  ██████╗  ██████╗ ███╗   ███╗███████╗██████╗  █████╗ ███╗   ██╗ ██████╗ .ART
██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║██╔════╝██╔══██╗██╔══██╗████╗  ██║██╔════╝ 
██████╔╝██║   ██║██║   ██║██╔████╔██║█████╗  ██████╔╝███████║██╔██╗ ██║██║  ███╗
██╔══██╗██║   ██║██║   ██║██║╚██╔╝██║██╔══╝  ██╔══██╗██╔══██║██║╚██╗██║██║   ██║
██████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║███████╗██║  ██║██║  ██║██║ ╚████║╚██████╔╝
╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ PFP•MSG
*******************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;
// https://mumbai.polygonscan.com/address/0xa7db2f3f319598c66ddd78f2a9bc6de9aea3e71e

import "./IERC721.sol";                      	// nft standard
import "./ERC721.sol";                       	// nft standard
import "./ERC721URIStorage.sol";  				// nft location
import "./ERC721Burnable.sol";    				// validating to burn items
import "./ERC2981.sol";                      	// royalty lib
import "./ReentrancyGuard.sol";                 // security reason
import "./Ownable.sol";                         // security reason
import "./Counters.sol";                        // itteration
import "./ECDSA.sol";                  			// cryptography for signature
import "./IERC721A.sol";        				// communicating by key

contract BoomerangCross is ERC721, ERC721URIStorage, ERC721Burnable, ERC2981, Ownable, ReentrancyGuard {

    // ******************************************
    // Dataset
    // ******************************************
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private price = 0.03 ether;         // 30000000000000000 wei, not cost for users, only newcommers pay for mint
    uint96  private __fee = 500;                // royalty fee
    
    address private creator;                    // income from royalty
    IERC721A BoomerangGenesis;                  // used for key to use this smartcontract

    // full ipfs uri here, example-> https://ipfs.io/ipfs/qm.... . this is json by simple data (look in the end of code)
    string private _iconUrl; 

    // ******************************************
    // Yelling
    // ******************************************
    event RoyaltyFee(uint96 fee, uint256 time);

    // ******************************************
    // Modifiers
    // ******************************************
    modifier theUser(bytes32 messageHash, bytes memory signature) {          // this is for not ETH network
        require(verifySignature(messageHash, signature) == msg.sender, "Only user");
        _;
    }
    
    // _when = x hours {[14400 = 4H], [28800 = 8H], [43200 = 12H], [86400 = 24H]}
    modifier WhenChecker(uint256 _when) {
        require(_when > 0 , "Not in time range");
        require(_when == 14400 || _when == 28800 || _when == 43200 || _when == 86400, "Not in time range");
        _;
    }

    function verifySignature(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        address signer = ECDSA.recover(messageHash, signature);
        return signer;          // use: [ verifySignature(x,y) == msg.sender ? return varA : return varB; ]
    }

    // ******************************************
    // Init
    // ******************************************
    constructor(string memory _name, string memory _symbol, string memory iconUrl_) ERC721(_name, _symbol) {
        creator = msg.sender;
        _setDefaultRoyalty(creator, __fee);
        _iconUrl = iconUrl_;
    }

    function setIconUrl(string memory iconUrl_) public onlyOwner {
        _iconUrl = iconUrl_;
    }

    function iconUrl() public view returns (string memory) {
        return _iconUrl;
    }

    receive() external payable {}

    // ******************************************
    // The following functions are overrides required by Solidity.
    // ******************************************
    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
        _resetTokenRoyalty(_tokenId);        // --> reset royality for burned item
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    // ******************************************
    // Communication
    // ******************************************
    function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC721, ERC2981) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721A).interfaceId ||
        interfaceId == type(ERC2981).interfaceId || 
        super.supportsInterface(interfaceId);
    }

    // ******************************************
    // Royalty
    // ******************************************
    function changeRoyalityFee(uint96 newFee) public onlyOwner returns (uint96) {
        __fee = newFee;
        _setDefaultRoyalty(creator, newFee);
        emit RoyaltyFee(__fee, block.timestamp);
        return __fee;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
        creator = newOwner;
    }

    function changeCreator(address _newCreator) public onlyOwner {
        require(_newCreator != address(0), "Only real address");
        creator = _newCreator;
        _setDefaultRoyalty(_newCreator, __fee);
    }

    // ******************************************
    // Claim
    // ******************************************
    // pfp only on eth - msg+pfp on polygon
    // msg page: check wallet address

    function msgMintBulk(address[] memory _to, string memory _uri, uint256 _when, bytes32 messageHash, bytes memory signature) 
    public theUser(messageHash, signature) returns (uint256 _tokenId, uint256 _destroy, address _sender) {
        uint _len = _to.length;
        for(uint i = 0; i <= _len; ++i){
            uint256 _id = _tokenIdCounter.current();
            (_tokenId, _destroy, _sender) = _msgMint(_to[i], _uri, _when);
            require(_tokenId > _id, "Mint not happend");
        }
    }

    function msgMintBulkClient(address[] memory _to, string memory _uri, uint256 _when) 
    public payable returns (uint256 _tokenId, uint256 _destroy, address _sender) {
        uint _len = _to.length;
        uint _prices = price * _len;
        require(msg.value >= _prices, "Check the price");
        for(uint i = 0; i <= _len; ++i){
            uint256 _id = _tokenIdCounter.current();
            (_tokenId, _destroy, _sender) = _msgMint(_to[i], _uri, _when);
            require(_tokenId > _id, "Mint not happend");
        }
        require(_withdraw(_prices), "Cost is not benefit");
    }

    // ====================================

    function pfpMint(string memory _uri, bytes32 messageHash, bytes memory signature) 
    public theUser(messageHash, signature) returns (uint256 _tokenId) {
        uint256 _id = _tokenIdCounter.current();
        _tokenId = _pfpMint(_uri);
        require(_tokenId > _id, "Mint not happend");
    }

    function msgMint(address _to, string memory _uri, uint256 _when, bytes32 messageHash, bytes memory signature) 
    public theUser(messageHash, signature) returns (uint256 _tokenId, uint256 _destroy, address _sender) {
        uint256 _id = _tokenIdCounter.current();
        (_tokenId, _destroy, _sender) = _msgMint(_to, _uri, _when);
        require(_tokenId > _id, "Mint not happend");
    }

    function pfpMintClient(string memory _uri) public payable returns (uint256 _tokenId) {
        require(msg.value >= price, "Check the price");
        uint256 _id = _tokenIdCounter.current();
        _tokenId = _pfpMint(_uri);
        require(_tokenId > _id, "Mint not happend");
        require(_withdraw(price), "Cost is not benefit");
    }

    function msgMintClient(address _to, string memory _uri, uint256 _when) 
    public payable returns (uint256 _tokenId, uint256 _destroy, address _sender) {
        require(msg.value >= price, "Check the price");
        uint256 _id = _tokenIdCounter.current();
        (_tokenId, _destroy, _sender) = _msgMint(_to, _uri, _when);
        require(_tokenId > _id, "Mint not happend");
        require(_withdraw(price), "Cost is not benefit");
    }

    // mint logics
    function _pfpMint(string memory _uri) internal returns (uint256 _tokenId) {
        uint256 _id = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _setMinter(msg.sender, _id, _uri);
        _tokenId = _tokenIdCounter.current();
    }

    // _when = x hours {[14400 = 4H], [28800 = 8H], [43200 = 12H], [86400 = 24H]}
    function _msgMint(address _to, string memory _uri, uint256 _when) internal WhenChecker(_when) returns (uint256 _tokenId, uint256 _destroy, address _sender) {
        // require((_when > 0 && (_when == 14400 || _when == 28800 || _when == 43200 || _when == 86400)), "Not in time range");
        require(_to != msg.sender, "Use PFP for your-self");
        uint256 _present = block.timestamp;
        // require((_when + _present) > _present, "Time travel not possible");
        uint256 _id = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _setMinterTo(_to, _id, _uri);
        _destroy = _present + _when;
        _sender = msg.sender;
        _tokenId = _tokenIdCounter.current();
    }

    function _setMinter(address _to, uint256 _id, string memory _uri) private {
        _safeMint(_to, _id); 
        _setTokenURI(_id, _uri);
    }

    function _setMinterTo(address _to, uint256 _id, string memory _uri) private {
        _safeMint(msg.sender, _id); 
        _setTokenURI(_id, _uri);
        approve(address(this), _id);
        setApprovalForAll(address(this), true);
        safeTransferFrom(msg.sender, _to, _id);
        /*
        approve(address(this), _id);
        setApprovalForAll(address(this), true);
        safeTransferFrom(msg.sender, _to, _id);
        
        // third-party, use js
            const contract = new ethers.Contract(
                '0x1234567890abcdef',
                'ERC721',
                provider
            );

            await contract.transferFrom(
                '0x1234567890abcdef',
                '0xdeadbeefdeadbeef',
                1
            );
        */
    }

    // ******************************************
    // Finance
    // ******************************************
    function getPrice() public view returns (uint256) {
        return price;
    }
    
    function setPrice(uint256 _price) public onlyOwner returns (uint256) {
        price = _price;
        return price;
    }

    function _withdraw(uint256 _val) private nonReentrant returns (bool) {
        (bool success, ) = payable(owner()).call{value: _val}("");
        /*
        // what to do:
        require(success);
        return success;
        */
        if (!success) {
            return false;
        } else {
            return true;
        }
    }


    // ******************************************
    // Ticket check
    // ******************************************
    /*function setTicket(address _boomerangGenesis) public onlyOwner {    // for ETH network only
        BoomerangGenesis = IERC721A(_boomerangGenesis);
    }

    function getTicket() public view returns (address) {                // for ETH network only
        // return address(IERC721A(BoomerangGenesis));
        return address(BoomerangGenesis);
    }

    function _isUser(address _user) public view returns (bool) {        // for ETH network only
        return BoomerangGenesis.balanceOf(_user) > 0;
    }*/
}

/*
==================================================================================

- icon uri
```
{
    "name": "Boomerang Cross",
    "symbol": "BNFT",
    "total": "max(uint256)",
    "tokenURI": "https://ipfs.io/ipfs/cid/BoomerangCross.json"
}
```

- BoomerangCross.json
```
{
    "name": "Boomerang Cross",
    "description": "A description of Cross",
    "image": "https://ipfs.io/ipfs/cid/BoomerangCross.png",
    "external_url": "https://boomerang.art/",
    "attributes": [
        {
            "trait_type": "Type",
            "value": "Utility Token"
        },
        {
            "trait_type": "Total Supply",
            "value": "max(uint256)"
        }
    ]
}
```

- uint256 maxUint = type(uint256).max;
- max: 115792089237316195423570985008687907853269984665640564039457584007913129639935

==================================================================================
*/