// SPDX-License-Identifier: MIT

pragma solidity  0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ResiklosDeployTest is ERC721A, Ownable {
    using Strings for uint256;

    enum SaleState {
        PAUSED,
        RSKWL,
        PUBLIC
    }

    uint256 public _currIndex = 1;
    uint256 public MAX_SUPPLY = 100;
    uint256 public MAX_LEGENDARY_SUPPLY = 10;
    uint256 public MAX_RARE_SUPPLY = 30;
    uint256 public MAX_COMMON_SUPPLY = 60;

    uint256 public MAX_COMMON_MINT = 3; 
    uint256 public MAX_RARE_MINT = 3; 
    uint256 public MAX_LEGENDARY_MINT = 3; 
    uint256 public MAX_WALLET_MINT = 5; 

    uint256 public LEGENDARY_PRICE = .00001 ether;
    uint256 public RARE_PRICE = .00001 ether;
    uint256 public COMMON_PRICE = .00001 ether;

    string private baseTokenUriCommon;
    string private baseTokenUriRare;
    string private baseTokenUriLegendary;

    SaleState public currState;

    bytes32 private merkleRootResiklos;

    mapping(address => uint256) public totalCommonMint;
    mapping(address => uint256) public totalRareMint;
    mapping(address => uint256) public totalLegendaryMint;
    mapping(address => uint256) public totalWalletMint;
    mapping(uint256 => string) public rarityMap;
    uint256 public legendaryMintedSupply;
    uint256 public rareMintedSupply;
    uint256 public commonMintedSupply;

    constructor() ERC721A("ResiklosDeployTest", "RSK") { }

    modifier correctState(SaleState _state) {
        require(currState == _state, "Incorrect state.");
        _;
    }

    function rskMint(bytes32[] memory _merkleProof, string calldata rarity, uint256 _quantity)  external payable correctState(SaleState.RSKWL) {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");

         if (MAX_WALLET_MINT > 0) {
            require((totalWalletMint[msg.sender] + _quantity) <= MAX_WALLET_MINT, "You have reach the maximum amount of Mints per Wallet");
        } 

        if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("legendary"))) {
            require((getLegendaryMintedSupply() + _quantity) <= MAX_LEGENDARY_SUPPLY, "Beyond max legendary supply.");
            if (MAX_LEGENDARY_MINT > 0) {
                require((totalLegendaryMint[msg.sender] + _quantity) <= MAX_LEGENDARY_MINT, "You have reached the maximum amount of Legendary mints.");   
            } 
            require(msg.value >= LEGENDARY_PRICE * _quantity, "Invalid Amount.");

            bytes32 sender = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRootResiklos, sender), "You are not an Resiklos WhiteList!");        
            
            legendaryMintedSupply += _quantity;
            totalLegendaryMint[msg.sender] += _quantity;
             _safeMint(msg.sender, _quantity);
            
        } else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("rare"))) {
            require((getRareMintedSupply() + _quantity) <= MAX_LEGENDARY_SUPPLY, "Beyond max rare supply.");
            if (MAX_RARE_MINT > 0) {
                require((totalRareMint[msg.sender] + _quantity) <= MAX_RARE_MINT, "You have reached the maximum amount of Rare mints.");
            }  

            require(msg.value >= RARE_PRICE * _quantity, "Invalid Amount.");

            bytes32 sender = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRootResiklos, sender), "You are not an Resiklos WhiteList!"); 

            rareMintedSupply += _quantity;
            totalRareMint[msg.sender] += _quantity;
             _safeMint(msg.sender, _quantity);  

        } else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("common"))) {
            require((getCommonMintedSupply() + _quantity) <= MAX_LEGENDARY_SUPPLY, "Beyond max common supply.");
            if (MAX_COMMON_MINT > 0) {
                require((totalCommonMint[msg.sender] + _quantity) <= MAX_COMMON_MINT, "You have reached the maximum amount of Common mints.");  
            }

            require(msg.value >= COMMON_PRICE * _quantity, "Invalid Amount.");

            bytes32 sender = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRootResiklos, sender), "You are not an Resiklos WhiteList!"); 

            commonMintedSupply += _quantity;
            totalCommonMint[msg.sender] += _quantity;
             _safeMint(msg.sender, _quantity);
        } 

        totalWalletMint[msg.sender] += _quantity;
        mapRarity(rarity, _quantity);
    }

    function publicMint(string calldata rarity,uint256 _quantity) external payable correctState(SaleState.PUBLIC) {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply.");
        
        if (MAX_WALLET_MINT > 0) {
            require((totalWalletMint[msg.sender] + _quantity) <= MAX_WALLET_MINT, "You have reach the maximum amount of Mints per Wallet");
        } 
       
        if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("legendary"))) {
            require((getLegendaryMintedSupply() + _quantity) <= MAX_LEGENDARY_SUPPLY, "Beyond max legendary supply.");
            if (MAX_LEGENDARY_MINT > 0) {
                require((totalLegendaryMint[msg.sender] + _quantity) <= MAX_LEGENDARY_MINT, "You have reached the maximum amount of Legendary mints.");   
            }
            require(msg.value >= LEGENDARY_PRICE * _quantity, "Invalid Amount.");

            legendaryMintedSupply += _quantity;
            totalLegendaryMint[msg.sender] += _quantity;
             _safeMint(msg.sender, _quantity);
            
        } else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("rare"))) {
            require((getRareMintedSupply() + _quantity) <= MAX_LEGENDARY_SUPPLY, "Beyond max rare supply.");
            if (MAX_RARE_MINT > 0) {
                require((totalRareMint[msg.sender] + _quantity) <= MAX_RARE_MINT, "You have reached the maximum amount of Rare mints.");
            }  

            require(msg.value >= RARE_PRICE * _quantity, "Invalid Amount.");

            rareMintedSupply += _quantity;
            totalRareMint[msg.sender] += _quantity;
             _safeMint(msg.sender, _quantity);  

        } else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("common"))) {
            require((getCommonMintedSupply() + _quantity) <= MAX_LEGENDARY_SUPPLY, "Beyond max common supply.");
            if (MAX_COMMON_MINT > 0) {
                require((totalCommonMint[msg.sender] + _quantity) <= MAX_COMMON_MINT, "You have reached the maximum amount of Common mints.");  
            }

            require(msg.value >= COMMON_PRICE * _quantity, "Invalid Amount.");

            commonMintedSupply += _quantity;
            totalCommonMint[msg.sender] += _quantity;
             _safeMint(msg.sender, _quantity);
        } 

        totalWalletMint[msg.sender] += _quantity;
        mapRarity(rarity, _quantity);   
    }
    
    function mapRarity(string memory rarity, uint256 _quantity) internal {
    
        for (uint256 i = 0; i < _quantity; i++) {
            rarityMap[_currIndex] = rarity;
            _currIndex += 1;
        }
    }

    function _baseURILegendary() internal view virtual returns (string memory) {
        return baseTokenUriLegendary;
    }

    function _baseURIRare() internal view virtual returns (string memory) {
        return baseTokenUriRare;
    }

    function _baseURICommon() internal view virtual  returns (string memory) {
        return baseTokenUriCommon;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory legendBaseURI = _baseURILegendary();
        string memory rareBaseURI = _baseURIRare();
        string memory commonBaseURI = _baseURICommon();
        string memory invalid = "tokenID is Invalid";
      
        string memory rarity = rarityMap[tokenId];

        if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("legendary"))) {
            return bytes(rarity).length > 0 ? string(abi.encodePacked(legendBaseURI)) : '';

        } else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("rare"))) {
             return bytes(rarity).length > 0 ? string(abi.encodePacked(rareBaseURI)) : '';

        } else if (keccak256(abi.encodePacked(rarity)) == keccak256(abi.encodePacked("common"))) {
            return bytes(rarity).length > 0 ? string(abi.encodePacked(commonBaseURI)) : '';

        } else {
            return invalid;
        }
    }

    function getRarity(uint256 tokenId) public view returns (string memory) {
        return rarityMap[tokenId];
    }

    function devMint(uint256 legendary, uint256 rare, uint256 common) external onlyOwner {
        uint256 quantity = legendary + rare + common; 
        require(quantity > 0, "No NFTs To Mint");
        require((totalSupply() + quantity) <= MAX_SUPPLY, "Beyond max supply.");

        if(legendary > 0) {
            totalLegendaryMint[msg.sender] += legendary;
        } 
        
        if(rare > 0) {
            totalRareMint[msg.sender] += rare;   
        }
        
        if(common > 0) {
            totalCommonMint[msg.sender] += common;
        }

        _safeMint(msg.sender, quantity);
        mapRarity("legendary", legendary);
        mapRarity("rare", rare);
        mapRarity("common", common);
        legendaryMintedSupply += legendary;
        rareMintedSupply += rare;
        commonMintedSupply += common;
    }

    function setBaseURI(string memory _uriLegendary, string memory _uriRare, string memory _uriCommon) public onlyOwner {
        baseTokenUriLegendary = _uriLegendary;
        baseTokenUriRare = _uriRare;
        baseTokenUriCommon = _uriCommon;  
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRootResiklos = _merkleRoot;
    }

    function setState(uint256 _state) external onlyOwner {
        require(_state <= uint256(SaleState.PUBLIC), "Invalid state.");

        currState = SaleState(_state);
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setMaxLegendarySupply(uint256 _newSupply) external onlyOwner {
        MAX_LEGENDARY_SUPPLY = _newSupply;
    }

    function setMaxRareSupply(uint256 _newSupply) external onlyOwner {
        MAX_RARE_SUPPLY = _newSupply;
    }

    function setMaxCommonSupply(uint256 _newSupply) external onlyOwner {
        MAX_COMMON_SUPPLY = _newSupply;
    }

    function getLegendaryMintedSupply() public view returns (uint256) {
        return legendaryMintedSupply;
    }

    function getRareMintedSupply() public view returns (uint256) {
        return rareMintedSupply;
    }

    function getCommonMintedSupply() public view returns (uint256) {
        return commonMintedSupply;
    }

    function setLegendaryPx(uint256 _newPx) external onlyOwner {
        LEGENDARY_PRICE = _newPx;
    }

    function setRarePx(uint256 _newPx) external onlyOwner {
        RARE_PRICE = _newPx;
    }

    function setCommonPx(uint256 _newPx) external onlyOwner {
        COMMON_PRICE = _newPx;
    }

    function setMaxMintLegendary(uint256 _maxMint) external onlyOwner {
        MAX_LEGENDARY_MINT = _maxMint;
    }

    function setMaxMintRare(uint256 _maxMint) external onlyOwner {
        MAX_RARE_MINT = _maxMint;
    }

    function setMaxMintCommon(uint256 _maxMint) external onlyOwner {
        MAX_COMMON_MINT = _maxMint;
    }

    function setMaxMintPerWallet(uint256 _maxMint) external onlyOwner {
        MAX_WALLET_MINT = _maxMint;
    }

    function withdrawMoney() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(0x08F12f80e689a91451B47b1B12585C8020D85863).transfer(balance);
    }
}