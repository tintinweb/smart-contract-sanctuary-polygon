//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*$$$$$$$ /$$                            /$$$$$$  /$$   /$$              
|__  $$__/| $$                           /$$__  $$|__/  | $$              
   | $$   | $$$$$$$  /$$   /$$  /$$$$$$ | $$  \__/ /$$ /$$$$$$   /$$   /$$
   | $$   | $$__  $$| $$  | $$ /$$__  $$| $$      | $$|_  $$_/  | $$  | $$
   | $$   | $$  \ $$| $$  | $$| $$  \ $$| $$      | $$  | $$    | $$  | $$
   | $$   | $$  | $$| $$  | $$| $$  | $$| $$    $$| $$  | $$ /$$| $$  | $$
   | $$   | $$  | $$|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$  |  $$$$/|  $$$$$$$
   |__/   |__/  |__/ \______/  \____  $$ \______/ |__/   \___/   \____  $$
                               /$$  \ $$                         /$$  | $$
                              |  $$$$$$/                        |  $$$$$$/
                               \______/                          \______*/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ThugCityNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI; // set as generic first and then update to correct ipfs
    string public baseExtension = ".json";
    uint256 public cost = 0.1 ether;
    uint256 public presaleCost = 0.1 ether; // update to 0.08
    uint256 public maxSupply = 100; // update to 10000
    uint256 public maxMintAmount = 5;
    uint256 public maxWhitelistSupply = 100; // change to 1000
    address public thugCity; // update to City contract address
    bool public paused = false;
    bool public whitelistOnly = true;
    mapping(uint16 => bool) private _isCop; // update cops after reveal

    mapping(address => uint256) public whitelistUsers;

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

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Minting is not available at this time");
        require(_mintAmount > 0, "Must mint more than 0 NFTs!");
        require(
            _to == msg.sender,
            "Your address doesn't match the address to mint to"
        );

        require(
            supply + _mintAmount <= maxSupply,
            "Max supply has been reached"
        );

        if (msg.sender != owner()) {
            if (whitelistOnly) {
                // whitelist sale
                require(
                    whitelistUsers[msg.sender] > 0,
                    "Only whitelist users may perform this action!"
                );
                require(
                    _mintAmount <= whitelistUsers[msg.sender],
                    "You cannot mint this many NFTS!"
                );
                require(
                    supply + _mintAmount <= maxWhitelistSupply,
                    "Max whitelist supply reached"
                );
                require(
                    msg.value >= presaleCost * _mintAmount,
                    "Must send more ETH!"
                );
                for (uint256 i = 1; i <= _mintAmount; i++) {
                    _safeMint(_to, supply + i);
                }
                whitelistUsers[msg.sender] =
                    whitelistUsers[msg.sender] -
                    _mintAmount;
            } else {
                // regular sale
                require(
                    _mintAmount <= maxMintAmount,
                    "You cannot mint this many NFTs"
                );
                require(msg.value >= cost * _mintAmount, "Must send more ETH!");
                for (uint256 i = 1; i <= _mintAmount; i++) {
                    _safeMint(_to, supply + i);
                }
            }
        } else {
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
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

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setCopId(uint16 id, bool special) external onlyOwner {
        _isCop[id] = special;
    }

    function setCopIds(uint16[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            _isCop[ids[i]] = true;
        }
    }

    function isCop(uint16 id) public view returns (bool) {
        return _isCop[id];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (_msgSender() != address(thugCity))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function setThugCity(address _addr) public onlyOwner {
        thugCity = _addr;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
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

    function whitelistSaleOnly(bool _state) public onlyOwner {
        // rewrite so that true means not whitelist only
        whitelistOnly = _state;
    }

    function whitelistUser(address _user, uint256 maxMint) public onlyOwner {
        // add user to whitelist
        whitelistUsers[_user] = maxMint;
    }

    function getWhitelistUser(address _user) public view returns (uint256) {
        uint256 result = whitelistUsers[_user];
        return result;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        // remove user from whitelist
        whitelistUsers[_user] = 0;
    }

    function addManyWhitelistUsers(
        address[] memory users,
        uint256[] memory maxMint,
        uint256 total
    ) public onlyOwner {
        // add 100 users to whitelist
        for (uint256 i = 0; i < total; i++) {
            whitelistUsers[users[i]] = maxMint[i];
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}