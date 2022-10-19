// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";



contract Land is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    // Time of when the sale starts.
    uint256 public blockStart;

    // Maximum amount of Buffalos in existance. 
    uint256 public maxSupply;
    uint256 public cost;
    uint256 public maxMintAmount;
    
    address public artist;

    string public baseURI;
    // string public nftName;
    // string public nftUnit;
    string public uri;
    string public metaDataExt = ".json";

    bool public mintable = true;
    bool public publicSale = true;

    mapping(address => bool) public whitelisted;
    mapping(uint256 => bool) public costIsSet;
    mapping(uint256 => uint256) public costById;
    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public excludedList;

    event LandBought (address buyer, address receiver, uint256 id);

    constructor(
        string memory name,
        string memory symbol,
        string memory URI,
        uint256 initialSupply,
        uint256 startDate,
        address _artist,
        uint _txFeeAmount,
        uint256 _limitPerAddress
    ) ERC721(name, symbol) {
        setBaseURI(URI);
        setBlockStart(startDate);
        artist = _artist;
        cost = _txFeeAmount * 10 ** 15;
        maxMintAmount = _limitPerAddress;
        maxSupply = initialSupply;
    }

    function mint(address _address, uint256 _id) external payable {
        // Some exceptions that need to be handled.

        require(block.timestamp >= blockStart, "Exception 1: Sale has not started.");
        if(!publicSale) {
            require(whitelisted[_address], "Exception 2: Signer should be whitelisted.");
        }
        require(msg.value >= getNFTPrice(_id), "Exception 3: You aren't paying enough fund.");
        require(SafeMath.add(totalSupply(), 1) <= maxSupply, "Exception 4: Exceeds maximum supply.");
        require(tokenBalance[_address] < maxMintAmount, "Exception 5: Reached the limit for each user. You can't mint no more");
        require(mintable, "Exception 6: Minting is stopped.");

        _safeMint(_address, _id);
        tokenBalance[_address] = SafeMath.add(tokenBalance[_address], 1);
        
        emit LandBought(msg.sender, _address, _id);
    }

    function freemint(address _address, uint256 _id) external onlyOwner {
        _safeMint(_address, _id);
        emit LandBought(msg.sender, _address, _id);
    }

    function getNFTPrice(uint256 _id) public view returns (uint256) {
        if(costIsSet[_id]) {
            return costById[_id];
        }
        else {
            return cost;
        }
    }

    function setNFTPrice(uint256 _id, uint256 _price) onlyOwner external {
        costIsSet[_id] = true;
        costById[_id] = _price;
    }

    function setBlockStart(uint256 startDate) onlyOwner public {
        blockStart = startDate;
    }

    function setMaxSupply(uint256 supply) onlyOwner external {
        maxSupply = supply;
    }

    function canMint(bool mintFlag) onlyOwner external {
        mintable = mintFlag;
    }

    function withdraw(uint256 amount) onlyOwner external {
        payable(artist).transfer(amount);
    }

    function setPublicSaleState(bool flag) onlyOwner external {
        publicSale = flag;
    }

    function setCost(uint256 _newCost) onlyOwner external {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) onlyOwner external {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) onlyOwner public {
        baseURI = _newBaseURI;
    }

    function whitelistUser(address _user) onlyOwner external {
        if(!whitelisted[_user]) tokenBalance[_user] = 0;
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) onlyOwner external {
        whitelisted[_user] = false;
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

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metaDataExt))
            : "";
    }
}