// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract ZAMNFT is ERC721Enumerable, IERC2981, Ownable {
    using Strings for uint256;
    address public royaltyAddress;
    uint256 public royaltyPercent;
    bool public paused = false;
    bool public presale = true;
    uint256 level1 = 1;
    uint256 level2 = 7001;
    uint256 level3 = 8501;
    uint256 public cost = 0.18 ether;
    uint256 public presaleprice = 0.15 ether;
    uint256 public presaleAmount = 2000;
    uint256 public maxSupply = 8000;
    uint256 public maxMintAmount = 3;
    string public baseURI;
    string public baseExtension = ".json";

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public secondLevel;
    mapping(address => bool) public thirdLevel;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        royaltyAddress = owner();
        royaltyPercent = 5;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (presale) {
            _presale(msg.sender, _mintAmount, msg.value);
        } else {
            require(msg.value >= cost * _mintAmount, "Add Funds");
            if (!secondLevel[msg.sender] && !thirdLevel[msg.sender]) {
                require(level1 <= 7000, "NFT LEVEL 1 SOLD OUT");
                require(
                    _mintAmount + level1 <= 7000,
                    "NFT is left or mint amount is too big"
                );
                for (uint256 i = 0; i < _mintAmount; i++) {
                    _safeMint(msg.sender, level1 + i);
                }
                level1 += _mintAmount;
            }
            if (secondLevel[msg.sender]) {
                require(level2 <= 8500, "NFT LEVEL 2 SOLD OUT");
                require(
                    _mintAmount + level2 <= 8500,
                    "NFT is left or mint amount is too big"
                );
                for (uint256 i = 0; i < _mintAmount; i++) {
                    _safeMint(msg.sender, level2 + i);
                }
                level2 += _mintAmount;
            }
            if (thirdLevel[msg.sender]) {
                require(level3 <= 8870, "NFT LEVEL 3 SOLD OUT");
                require(
                    _mintAmount + level3 <= 8870,
                    "NFT is left or mint amount is too big"
                );
                for (uint256 i = 0; i < _mintAmount; i++) {
                    _safeMint(msg.sender, level3 + i);
                }
                level3 += _mintAmount;
            }
        }
    }

    function _presale(
        address account,
        uint256 _mintAmount,
        uint256 value
    ) private {
        if (account != owner()) {
            require(whitelisted[account], "Sorry, but you can't buy NFT");
            require(value >= presaleprice * _mintAmount, "Add Funds");
            require(value != 0);
        }
        if (!secondLevel[account] && !thirdLevel[account]) {
            require(level1 <= 1401, "NFT LEVEL 1 SOLD OUT");
            require(
                _mintAmount + level1 <= 1400,
                "NFT is left or mint amount is too big"
            );
            for (uint256 i = 0; i < _mintAmount; i++) {
                _safeMint(msg.sender, level1 + i);
            }
            level1 += _mintAmount;
        }
        if (secondLevel[account]) {
            require(level2 <= 7501, "NFT LEVEL 2 SOLD OUT");
            require(
                _mintAmount + level2 <= 7501,
                "NFT is left or mint amount is too big"
            );

            for (uint256 i = 0; i < _mintAmount; i++) {
                _safeMint(msg.sender, level2 + i);
            }
            level2 += _mintAmount;
        }
        if (thirdLevel[account]) {
            require(level3 <= 8601, "NFT LEVEL 3 SOLD OUT");
            require(
                _mintAmount + level3 <= 8601,
                "NFT is left or mint amount is too big"
            );

            for (uint256 i = 0; i < _mintAmount; i++) {
                _safeMint(msg.sender, level3 + i);
            }
            level3 += _mintAmount;
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

    function setEndPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setWhitelistUsers(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelisted[users[i]] = true;
        }
    }

    function setSecondLeveluser(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            secondLevel[users[i]] = true;
        }
    }

    function setThirdLevelUsers(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            thirdLevel[users[i]] = true;
        }
    }

    function removeWhitelistUsers(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external payable onlyOwner {
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }
        function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, salePrice * royaltyPercent / 100);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}