// SPDX-License-Identifier: MIT

// title: KatMonstarz
// author: sadat.pk

pragma solidity ^0.8.4;

import "./ERC721A.sol"; // importing some amazing standard contracts
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract KatMonstarz is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256; 

    uint256 public maxSupply = 7777; // strange creatures aka KatMonstarz to ever exist
    uint256 private reservedSupply = 77; // for the team and marketing
    uint256 public price = 7 ether; // matic basically, yes we need to get them out of polygon
    uint256 public maxPerWallet = 5; // because you can't handle more Monstarz
    string private katsExperimentLab = "ipfs://QmVZ3ZTLJQ1Vx6Z9R3ntsdcwEJ8oNsYWSuK4AQKYrEse8w/"; // cute cats fell in toxic thing here
    string private monstarzBase; // minted KatMonstarz will all meet here
    string private openseaInfo = "ipfs://QmV8dM1QKJ7PCU2vWxLzEkeSTPtST3KihdXZ7MjJsAC6MB/"; // they will have their own OS page
    bool public callMonstarz = false; // after mint, they will be called to reveal themselves
    address private mintPassAddr; // mint pass contract address
    address private rewardAddr; // nothing... what? ok there will be amazing rewards
    address private splitter; // to distribute funds b/w team and community vault
    address private royaltyAddress = 0x2d4d806b60737422b66Dae8D83b60912e11821B3; // katmonstarz.eth
    uint96 private royaltyBasisPoints = 770; // 7.7%
    bytes4 private constant IERC2981 = 0x2a55205a; // royalty standard
    mapping(address => uint256) public minted; // some paperwork to keep records
    enum Switch { PRESALE, PUBLICSALE, BURNING } // three phases here and a lot more coming
    Switch public salePhase;
    bool public SOS = false; // this will stop some functions in-case of emergency
    constructor() ERC721A("KatMonstarz", "KM") { }
    
    // Phase 1 or Presale, only wallets with mint passes can mint

    function mintWithPass(uint256[] memory _passes) external payable ok() {
        require(salePhase == Switch.PRESALE, "mint with pass not started");
        require(_passes.length + totalSupply() <= maxSupply, "supply not enough");
        IMonstarzMintPass mintPassContract = IMonstarzMintPass(mintPassAddr);
        for (uint256 i; i < _passes.length; i++) {
            uint256 mintPass = _passes[i];
            require(msg.sender == mintPassContract.ownerOf(mintPass), "caller not owner");
            require(!mintPassContract.isUsed(mintPass), "pass already used");
            mintPassContract.setAsUsed(mintPass);
        }
       _safeMint(msg.sender, _passes.length);
    }

    // Phase 2 or Public sale, public can mint

    function mintPublic(uint256 qty) external payable ok() {
        require(salePhase == Switch.PUBLICSALE, "public sale not started");
        require(totalSupply() + qty <= maxSupply - reservedSupply, "supply not enough!");
        require(minted[msg.sender] + qty <= maxPerWallet, "max minted, can't handle more");
        require(msg.value >= price * qty, "not enough balance!"); 
        _safeMint(msg.sender, qty);
        minted[msg.sender] += qty;
    }

    // Phase 3 or Buring, when this starts, everyone can burn for rewards

    function burnForReward(uint256[] memory tokenIds) external payable ok() {
        require(salePhase == Switch.BURNING, "burning not started");
        IKatMonstarzReward rewardContract = IKatMonstarzReward(rewardAddr);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_isApprovedOrOwner(msg.sender, tokenId), "you can't burn this");
            _burn(tokenId);
            rewardContract.getReward(msg.sender);
        }
    }

    // Custom functions, to manage and configure stuff only be dev

    // mint free for address from remaining reserved supply
    function mintReservedMonstarz(address _to, uint256 qty) external onlyOwner ok() {
        require(qty <= reservedSupply, "reserve not enough!");
        _safeMint(_to, qty);
        reservedSupply -= qty;
    }

    // set un-minted KatMonstarz free, locking the supply to current
    function setFreeUnmintedMonstarz() public onlyOwner ok() {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }

    // call all KatMonstarz to reveal themselves
    function callAllMonstarz(string memory _URI) public onlyOwner ok() {
        monstarzBase = _URI;
        callMonstarz = true;
    }

    function switchPresale() public onlyOwner {
        salePhase = Switch.PRESALE;
    }

    function switchPublicsale() public onlyOwner {
        salePhase = Switch.PUBLICSALE;
    }

    function switchBurning() public onlyOwner {
        salePhase = Switch.BURNING;
    }

    function freezeContract() public onlyOwner {
        SOS = !SOS;
    }

    function setPayments(address _splitterWallet, address _royaltyAddress, uint96 _royaltyBasisPoints) external onlyOwner {
        splitter = _splitterWallet;
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setMintPass(address _mintPassAddr) external onlyOwner {
        mintPassAddr = _mintPassAddr;
    }

    function setReward(address _rewardAddr) external onlyOwner {
        rewardAddr = _rewardAddr;
    }

    function setOpenseaInfo(string memory _URI) internal virtual onlyOwner {
        openseaInfo = _URI;
    }

    function setMonstarzNewBase(string memory _URI) public onlyOwner {
        monstarzBase = _URI;
    }

    function setNewPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxMints(uint256 _newmaxPerWallet) public onlyOwner {
        maxPerWallet = _newmaxPerWallet;
    }

    function splitBalance() public onlyOwner nonReentrant ok() {
        (bool os, ) = payable(splitter).call{value: address(this).balance}("");
        require(os);
    }

    // Standard contract functions for marketplaces and dapps

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if (interfaceId == IERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (callMonstarz == false) {
            return katsExperimentLab;
        }
        return string(abi.encodePacked(monstarzBase, tokenId.toString(), ".json"));
    }
    
    function contractURI() public view returns (string memory) {
        return openseaInfo;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply) {
        address currentTokenOwner = ownerOf(currentTokenId);
        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;
            ownedTokenIndex++;
        }
        currentTokenId++;
        }
        return ownedTokenIds;
    }

    // Custom internal functions for contract

    modifier ok() {
        require(SOS = false, "contract in SOS mode! relax... devs working...");
        _;
    } 

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}

interface IMonstarzMintPass {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isUsed(uint256 tokenId) external view returns (bool);
    function setAsUsed(uint256 tokenId) external;
}

interface IKatMonstarzReward {
    function getReward(address _address) external;
}