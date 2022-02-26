//SPDX-License-Identifier: MIT

/******************************************************************************************************************************  
 _     _    _ _ _ _    _     _    _ _ _ _   (ᵔᴥᵔ)  _    __PP___    ___EE__    ┐__AA_┌_   __CC___   |       |   ┐__EE_┌_   __ 
| | _ | |  |       |  | | _ | |  |       |  |  |  | |  |       |  |       |  |       |  |       |  |       |  |       |  |  |
| || || |  |    ___|  | || || |  |   _   |  |   |_| |  8_     _8  |    _  |  |    ___|  |   _   |  |      _|  |    ___|  |  |
|       |  |   |___   |       |  |  |_|  |  |       |    |   |    |   |_| |  |   |___   |  |_|  |  |     |    |   |___   |  |
|       |  |    ___|  |       |  |       |  |  _    |    |   |    |    ___|  |    ___|  |       |  |     |_   |    ___|  |__|
|   _   |  |   |___   |   _   |  |   _   |  | | |   |    |   |    |   |      |   |___   |   _   |  |_______|  |   |___    __ 
|__| |__|  |_______|  |__| |__|  |__| |__|  |_|  |__|    |___|    |___|      |_______|  |__| |__|    \(●●)/   |_______|  |__|

 By CL 2022
********************************************************************************************************************************/

pragma solidity ^0.8.7;


import "./meta.sol";


contract WeWantPeaceNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public paused = false;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 15000;
    // 5 ethers means 5 matics on the Polygon.
    uint256 public cost = 5 ether;
    uint256 public earlybirdCost = 0 ether;
    uint256 public earlybirdAmount = 500;
    uint256 public displayAmount = 30;
    uint256 public maxMintAmount = 2;

    constructor(
        string memory _initBaseURI
    ) ERC721("WWP", "WeWantPeace") {
        setBaseURI(_initBaseURI);
        display(1, displayAmount);
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "Sorry, the supply is paused.");
        require(_mintAmount > 0, "Mint amount should be more than zero.");
        require(_mintAmount <= maxMintAmount, "Hey, mint amount is too large.");

        uint256 supply = totalSupply();
        uint256 wantEndIndex = supply + _mintAmount;
        require(wantEndIndex <= maxSupply, "Hey, we are running out of supply, please try a smaller mint amount?");
        uint256 earlybirdEndIndex = displayAmount + earlybirdAmount;

        if (supply >= earlybirdEndIndex) {
            uint256 nCost = cost * _mintAmount;
            string memory nCostStr = Strings.toString(nCost);
            require(msg.value >= nCost, string(abi.encodePacked("Not enough value for normal sale, needs ", nCostStr, " wei.")));
        } else {
            if (wantEndIndex <= earlybirdEndIndex) {
                uint256 pCost = earlybirdCost * _mintAmount;
                string memory pCostStr = Strings.toString(pCost);
                require(msg.value >= pCost, string(abi.encodePacked("Not enough value for earlybird sale, needs ", pCostStr, " wei.")));
            } else {
                uint256 mCost = (earlybirdEndIndex - supply) * earlybirdCost + (wantEndIndex - earlybirdEndIndex) * cost;
                string memory mCostStr = Strings.toString(mCost);
                require(msg.value >= mCost, string(abi.encodePacked("Sorry, not enough value..., needs ", mCostStr, " wei.")));
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint preIndex = totalSupply();
            require(preIndex < maxSupply, "Not enough supply...");
            if (preIndex < maxSupply) {
                _safeMint(msg.sender, preIndex + 1);
            }
        }
    }

    function display(uint256 _from, uint256 _to) public onlyOwner {
        for (uint256 i = _from; i <= _to; i++) {
            uint curSupply = totalSupply();
            require(curSupply < maxSupply, "Not enough supply...");
            _safeMint(msg.sender, i);
        }
    }

    function withdraw(address payable _to) public onlyOwner {
        require(_to != address(0));
        (bool success, ) = payable(_to).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed...");
    }

    // Setters, just in case.
    function setPause(bool _pause) public onlyOwner {
        paused = _pause;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtention(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setEarlybirdCost(uint256 _newCost) public onlyOwner {
        earlybirdCost = _newCost;
    }

    function setEarlybirdAmount(uint256 _newearlybirdAmount) public onlyOwner {
        earlybirdAmount = _newearlybirdAmount;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setDisplayAmount(uint256 _newDisplayAmount) public onlyOwner {
        displayAmount = _newDisplayAmount;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    // Override.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
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
}