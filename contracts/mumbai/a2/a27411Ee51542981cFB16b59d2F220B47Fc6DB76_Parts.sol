// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IHolder.sol";
import "./IParts.sol";

contract Parts is ERC721Enumerable, AccessControl, IParts {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    uint256 public constant BATCH_LIMIT = 20;    
    bytes32 public whiteListMerkleRoot;
    SeasonLog public currentSeason;
    uint public maxMintingCountPerTransaction;
    uint public maxMintingCountPerSeason;
    uint public maxMintingCountPerAddress;
    uint public maxBoxACountPerAddress;
    uint public maxBoxBCountPerAddress;
    bool public checkWhitelist;
    bool public mintingEnabled;
    address public paymentToken;
    IHolder public holderContract;
    MintingBox public boxTypeA;
    MintingBox public boxTypeB;
    
    mapping(uint256 => bool) public withdrawnTokens;
    
    mapping(uint256 => uint) private _partsInfo;
    mapping(uint256 => uint) private _skllInfo;        
    mapping(address => SeasonLog) private _mintedPerAddress;
    mapping(uint256 => string) private _tokenURIs;
    uint256 private _tokenIds;
    string private baseURI;
    using Strings for uint256;

    struct SeasonLog {
        uint256 season;
        uint256 countA;
        uint256 countB;
        uint256 minted;
    }
    
    struct MintingBox {
        uint boxType;
        uint mintingCount;
        uint256 price;
    }

    constructor(
        string memory name, 
        string memory symbol, 
        address adminAddress, 
        address operatorAddress, 
        address depositor,
        address holderContractAddress, 
        address tokenAddress) ERC721(name, symbol) {
        _tokenIds = 0;
        holderContract = IHolder(holderContractAddress);
        paymentToken = tokenAddress;
        mintingEnabled = false;
        
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
        _setupRole(DEPOSITOR_ROLE, depositor);
    }
    
    // modifiers
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not an admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not an operator");
        _;
    }
    
    modifier onlyDepositor() {
        require(hasRole(DEPOSITOR_ROLE, _msgSender()), "Caller is not a depositor");
       _;
    }

    // internal
    function _checkSeason(uint boxType, uint256 boxCount) internal returns (uint mintingCount) {
        if (_mintedPerAddress[_msgSender()].season < currentSeason.season) {
            _mintedPerAddress[_msgSender()].countB = 0;
            _mintedPerAddress[_msgSender()].countA = 0;
            _mintedPerAddress[_msgSender()].minted = 0;
            _mintedPerAddress[_msgSender()].season = currentSeason.season;
        }
        
        if (boxType == boxTypeA.boxType) {
            require(_mintedPerAddress[_msgSender()].countA + boxCount <= maxBoxACountPerAddress, 
            "Open Count of BoxA is exceeded the season max");
            currentSeason.countA += boxCount;
            _mintedPerAddress[_msgSender()].countA += boxCount;
            mintingCount = boxCount * boxTypeA.mintingCount;
        } else {
            require(_mintedPerAddress[_msgSender()].countB + boxCount <= maxBoxBCountPerAddress, 
            "Open Count of BoxB is exceeded the season max");
            currentSeason.countB += boxCount;
            _mintedPerAddress[_msgSender()].countB += boxCount;
            mintingCount = boxCount * boxTypeB.mintingCount;
        }
        
        require(currentSeason.minted + mintingCount <= maxMintingCountPerSeason, 
            "Total count of minting is exceeded the season max");
        require(_mintedPerAddress[_msgSender()].minted + mintingCount <= maxMintingCountPerAddress, 
            "Total count of minting is exceeded the personal max in this season");
        _mintedPerAddress[_msgSender()].minted += mintingCount;
        currentSeason.minted += mintingCount;
        return mintingCount;
    }
    
    // viewers
    function getPartNumber(uint256 tokenId) external view override returns (uint) {
        return _partsInfo[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    // external
    function mintPartsFromBoxA(uint count, bytes32[] calldata merkleProof) external {
        require(count >= 1, "Zero Box count is not available");
        require(boxTypeA.mintingCount >= 1, "BoxA is not initialized");
        uint mintingCount = _checkSeason(boxTypeA.boxType, count);

        if(checkWhitelist) {
            require(
                MerkleProof.verifyCalldata(merkleProof, whiteListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), 
                "Sender address is not in whitelist");
        } else {
            require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
        }
        
        // payment
        SafeERC20.safeTransferFrom(IERC20(paymentToken), _msgSender(), address(this), boxTypeA.price * count);
                
        //mint
        for (uint i = 0; i<mintingCount; i++) {
            _tokenIds++;
            _safeMint(_msgSender(), _tokenIds);
            emit PartMinted(_msgSender(), _tokenIds, boxTypeA.boxType);
        }
    }
    
    function mintPartsFromBoxB(uint count, bytes32[] calldata merkleProof) external {
        require(count >= 1, "Zero Box count is not available");
        require(boxTypeB.mintingCount >= 1, "BoxB is not initialized");
        uint mintingCount = _checkSeason(boxTypeB.boxType, count);

        if(checkWhitelist) {
            require(
                MerkleProof.verifyCalldata(merkleProof, whiteListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), 
                "Sender address is not in whitelist");
        } else {
            require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
        }
        
        // payment
        SafeERC20.safeTransferFrom(IERC20(paymentToken), _msgSender(), address(this), boxTypeB.price * count);
                
        //mint
        for (uint i = 0; i<mintingCount; i++) {
            _tokenIds++;
            _safeMint(_msgSender(), _tokenIds);
            emit PartMinted(_msgSender(), _tokenIds, boxTypeB.boxType);
        }
    }
    
    // only for Ape NFT owners
    function mintPartsByApeNFTOwner(uint8 nftType, uint256[] calldata tokenIds) external {
        require(nftType > 0, "Invalid mintType");
        require(nftType < uint8(IHolder.APE_TOKEN_TYPE.MAX), "Invalid mintType");
        require(tokenIds.length >= 1, "Empty tokenIds");
        
        uint mintingCountPerNFT = holderContract.getMintingCountPerToken(IHolder.APE_TOKEN_TYPE(nftType));
        uint mintingCount = mintingCountPerNFT * tokenIds.length;
        require(mintingCount <= maxMintingCountPerTransaction, 
                "Minting count per transaction has exceeded the max count");
        
        // verification
        bool success = holderContract.setNFTStatusClaimed(_msgSender(), IHolder.APE_TOKEN_TYPE(nftType), tokenIds);
        require(success, "Invalid tokenIds");

        // mint
        for (uint i=0; i<mintingCount; i++) {
            _tokenIds++;
            _safeMint(_msgSender(), _tokenIds);
            emit PartMintedByNFTHolder(_msgSender(), _tokenIds, tokenIds[i/mintingCountPerNFT], IHolder.APE_TOKEN_TYPE(nftType));    
        }
    }

    // operator
    function setParts(uint256[] calldata parts, uint[] calldata partNumbers) external onlyOperator {
        require(parts.length == partNumbers.length, "Invalid parameters");
        for(uint256 i = 0; i < parts.length; i++) {
            _partsInfo[parts[i]] = partNumbers[i];
            _skllInfo[parts[i]] = partNumbers[i];
        }
    }
    
    function setOperatingSettings(
        uint256 season,
        uint maxCountPerAddress, 
        uint maxCountPerTransaction, 
        uint maxCountPerSeason,
        uint maxCountForBoxA,
        uint maxCountForBoxB,
        bool enableWhiteList, 
        bytes32 merkleRoot) external onlyOperator {
        if (currentSeason.season < season) {
            currentSeason.season = season;
            currentSeason.minted = 0;
            currentSeason.countA = 0;
            currentSeason.countB = 0;            
        }

        maxMintingCountPerAddress = maxCountPerAddress;
        maxMintingCountPerTransaction = maxCountPerTransaction;
        maxMintingCountPerSeason = maxCountPerSeason;
        maxBoxACountPerAddress = maxCountForBoxA;
        maxBoxBCountPerAddress = maxCountForBoxB;
        checkWhitelist = enableWhiteList;
        whiteListMerkleRoot = merkleRoot;
    }
    
    function setBoxSettings(uint typeA, uint countA, uint256 priceA, uint typeB, uint countB, uint256 priceB) external onlyOperator {
        require(typeA != typeB, "Box types should be different");
        boxTypeA.boxType = typeA;
        boxTypeA.mintingCount = countA;
        boxTypeA.price = priceA;
        
        boxTypeB.boxType = typeB;
        boxTypeB.mintingCount = countB;
        boxTypeB.price = priceB;
    }
    
    function setMintingEnabled(bool enableMinting) external onlyOperator {
        mintingEnabled = enableMinting;
    }

    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOperator {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
    }

    // admin
    function setPaymentToken(address tokenAddress) external onlyAdmin {
        paymentToken = tokenAddress;
    }

    function withdrawPaymentTokens(address recipient, uint256 amount) external onlyAdmin {
        SafeERC20.safeTransfer(IERC20(paymentToken), recipient, amount);
    }
    
    // for bridge
    // bridge L1 -> L2
    function deposit(address user, bytes calldata depositData) external onlyDepositor {
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            require(withdrawnTokens[tokenId], "Parts: TOKEN_EXISTS_ON_ROOT_CHAIN");
            withdrawnTokens[tokenId] = false;
            _mint(user, tokenId);

        // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                require(withdrawnTokens[tokenIds[i]], "Parts: TOKEN_EXISTS_ON_ROOT_CHAIN");
                withdrawnTokens[tokenIds[i]] = false;
                _mint(user, tokenIds[i]);
            }
        }
    }

    // bridge L2 -> L1
    function withdraw(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "Parts: INVALID_TOKEN_OWNER");
        withdrawnTokens[tokenId] = true;
        _burn(tokenId);
    }

    // bridge L2 -> L1, batch
    function withdrawBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        require(length <= BATCH_LIMIT, "Parts: EXCEEDS_BATCH_LIMIT");

        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("Parts: INVALID_TOKEN_OWNER ", tokenId)));
            withdrawnTokens[tokenId] = true;
            _burn(tokenId);
        }

        emit WithdrawnBatch(_msgSender(), tokenIds);
    }

    // bridge L2 -> L1, with metadata
    function withdrawWithMetadata(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "Parts: INVALID_TOKEN_OWNER");
        withdrawnTokens[tokenId] = true;

        emit TransferWithMetadata(ownerOf(tokenId), address(0), tokenId, encodeTokenMetadata(tokenId));
        _burn(tokenId);
    }

    function encodeTokenMetadata(uint256 tokenId) public view virtual returns (bytes memory) {
        return abi.encode(tokenURI(tokenId));
    }

    // supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // events
    event PartMinted(address owner, uint256 tokenId, uint boxType);
    event PartMintedByNFTHolder(address owner, uint256 tokenId, uint256 apeTokenId, IHolder.APE_TOKEN_TYPE apeTokenType);
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);
    event TransferWithMetadata(address indexed from, address indexed to, uint256 indexed tokenId, bytes metaData);
}