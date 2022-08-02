// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IHolder.sol";
import "./IParts.sol";

contract Parts is ERC721, AccessControl, IParts {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    IHolder public holderContract;
    
    mapping(uint256 => uint) private _partsInfo;    
    mapping(address => SeasonLog) private _mintedPerAddress;
    mapping (uint256 => bool) public withdrawnTokens;

    uint256 private _tokenIds;
    address public paymentToken;
    string private baseURI;
    bytes32 public whiteListMerkleRoot;
    uint256 public season;
    uint256 public mintingPrice;
    uint public maxMintingCountPerTransaction;
    uint public maxMintingCountPerAddressPerSeason;

    bool public checkWhitelist;
    bool public mintingEnabled;

    struct SeasonLog {
        uint256 season;
        uint256 count;
    }

    constructor(string memory name, string memory symbol, address adminAddress, address operatorAddress, address holderContractAddress, address tokenAddress, address depositor, uint256 price) ERC721(name, symbol) {
        _tokenIds = 0;
        holderContract = IHolder(holderContractAddress);
        paymentToken = tokenAddress;
        mintingPrice = price;
        mintingEnabled = false;

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
        _setupRole(DEPOSITOR_ROLE, depositor);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not an admin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not an operator");
        _;
    }
    
    modifier onlyDepositor() {
        require(hasRole(DEPOSITOR_ROLE, _msgSender()), "Caller is not an depositor");
       _;
    }

    modifier checkSeason(uint256 count) {
        if (_mintedPerAddress[_msgSender()].season < season) {
            _mintedPerAddress[_msgSender()].count = 0;
            _mintedPerAddress[_msgSender()].season = season;
        }

        require(_mintedPerAddress[_msgSender()].count + count <= maxMintingCountPerAddressPerSeason, "Total count of minting is exceeded the max");
        _mintedPerAddress[_msgSender()].count += count;
        _;
    }

    // viewers
    function getPartNumber(uint256 tokenId) external view override returns (uint) {
        return _partsInfo[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    // external
    function mintParts(uint256 count, bytes32[] calldata merkleProof) external checkSeason(count) {
        require(count >= 1, "Minting count cannot be zero");
        require(count <= maxMintingCountPerTransaction, "Minting count per transaction has exceeded the max count");

        if(checkWhitelist) {
            require(MerkleProof.verifyCalldata(merkleProof, whiteListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Sender address is not in whitelist");
        } else {
            require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
        }

        SafeERC20.safeTransferFrom(IERC20(paymentToken), _msgSender(), address(this), mintingPrice * count);
        for (uint i = 0; i<count; i++) {
            _tokenIds++;
            _safeMint(_msgSender(), _tokenIds);
            emit PartCreated(_msgSender(), _tokenIds, IHolder.NFT_TYPE.NONE);
        }
    }
    
    // only for Ape token owners
    function mintPartsByApeTokenOwner(uint8 nftType, uint256[] calldata tokenIds) external {
        require(nftType > 0, "Invalid mintType");
        require(nftType < uint8(IHolder.NFT_TYPE.MAX), "Invalid mintType");
        require(tokenIds.length >= 1, "Empty tokenIds");
        
        uint mintingCount = 0;
        address claimer;
        IHolder.APE_NFT_STATUS status;
        for(uint i=0; i< tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            mintingCount += holderContract.getMintingCountPerToken(IHolder.NFT_TYPE(nftType));
            require(mintingCount <= maxMintingCountPerTransaction, "Minting count per transaction has exceeded the max count");

            (claimer, status) = holderContract.getNFTStatus(IHolder.NFT_TYPE(nftType), tokenId);
            require(status == IHolder.APE_NFT_STATUS.CLAIMABLE, "One of the tokenIds is not claimable");
            require(claimer == _msgSender(), "Caller is not the claimer of the token");
            holderContract.setNFTStatus(IHolder.NFT_TYPE(nftType), tokenId, IHolder.APE_NFT_STATUS.CLAIMED);
        }

        // mint
        for (uint i=0; i<mintingCount; i++) {
            _tokenIds++;
            _safeMint(_msgSender(), _tokenIds);
            emit PartCreated(_msgSender(), _tokenIds, IHolder.NFT_TYPE(nftType));    
        }
    }

    // operator
    function setParts(uint256[] calldata parts, uint[] calldata partNumbers) external onlyOperator {
        require(parts.length == partNumbers.length, "Invalid parameters");
        for(uint256 i = 0; i < parts.length; i++) {
            _partsInfo[parts[i]] = partNumbers[i];
        }
    }
    
    function setOperatingSettings(uint256 currentSeason, uint maxCountPerAddress, uint maxCountPerTransaction, bool enableWhiteList, bytes32 merkleRoot) external onlyOperator {
        season = currentSeason;
        maxMintingCountPerAddressPerSeason = maxCountPerAddress;
        maxMintingCountPerTransaction = maxCountPerTransaction;
        checkWhitelist = enableWhiteList;
        whiteListMerkleRoot = merkleRoot;
    }
    
    function setMintingEnabled(bool enableMinting) external onlyOperator {
        mintingEnabled = enableMinting;
    }

    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }

    // admin
    function setPaymentToken(address tokenAddress) external onlyAdmin {
        paymentToken = tokenAddress;
    }

    function updatePrice(uint256 price) external onlyAdmin {
        mintingPrice = price;
    }

    function withdrawPaymentTokens(address recipient, uint256 amount) external onlyAdmin {
        SafeERC20.safeTransfer(IERC20(paymentToken), recipient, amount);
    }
    
    // supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // for bridge
    /**
    * @notice called when token is deposited on root chain
    * @dev Should be callable only by ChildChainManager
    * Should handle deposit by minting the required tokenId(s) for user
    * Should set `withdrawnTokens` mapping to `false` for the tokenId being deposited
    * Minting can also be done by other functions
    * @param user user address for whom deposit is being done
    * @param depositData abi encoded tokenIds. Batch deposit also supported.
    */
    function deposit(address user, bytes calldata depositData)
        external
        onlyDepositor
    {

        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            withdrawnTokens[tokenId] = false;
            _mint(user, tokenId);

        // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                withdrawnTokens[tokenIds[i]] = false;
                _mint(user, tokenIds[i]);
            }
        }
    }

    /**
    * @notice called when user wants to withdraw token back to root chain
    * @dev Should handle withraw by burning user's token.
    * Should set `withdrawnTokens` mapping to `true` for the tokenId being withdrawn
    * This transaction will be verified when exiting on root chain
    * @param tokenId tokenId to withdraw
    */
    function withdraw(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "ChildMintableERC721: INVALID_TOKEN_OWNER");
        withdrawnTokens[tokenId] = true;
        _burn(tokenId);
    }

    /**
    * @notice Example function to handle minting tokens on matic chain
    * @dev Minting can be done as per requirement,
    * This implementation allows only admin to mint tokens but it can be changed as per requirement
    * Should verify if token is withdrawn by checking `withdrawnTokens` mapping
    * @param user user for whom tokens are being minted
    * @param tokenId tokenId to mint
    */
    function mint(address user, uint256 tokenId) public onlyDepositor {
        require(!withdrawnTokens[tokenId], "ChildMintableERC721: TOKEN_EXISTS_ON_ROOT_CHAIN");
        _mint(user, tokenId);
    }

    // events
    event PartCreated(address owner, uint256 tokenId, IHolder.NFT_TYPE mintType);
}