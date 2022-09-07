// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./AccessControl.sol";
import "./IERC721Receiver.sol";
import "./SafeERC20.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract Mech is ERC721Enumerable, AccessControl, IERC721Receiver {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    uint256 public constant BATCH_LIMIT = 20;
    address public paymentToken;
    ERC721Enumerable public partsContract;
    uint256 public maxPartsIdToMintMech;
    uint256 public requiredPartsCountPerMech;
    uint256 public mintingPrice;
    uint256 public destroyingPrice;
    mapping (uint256 => bool) public withdrawnTokens;
        
    mapping(uint256 => MechMetaData) private _mechMetaData;
    mapping(string => uint256) private _mechs;
    mapping(uint256 => string) private _tokenURIs;
    string private baseURI;
    uint256 private _tokenIds;
    address public encryptor;
    
    using Strings for uint256;
    
    struct MechMetaData {
        uint256[] parts;
    }

    constructor(string memory name, string memory symbol, address adminAddress, address operatorAddress, address encryptorAddress, address partsAddress, address tokenAddress, address depositor, uint256 priceForMinting, uint256 priceForDestroying) ERC721(name, symbol) {
        _tokenIds = 0;
        maxPartsIdToMintMech = 0;
        mintingPrice = priceForMinting;
        destroyingPrice = priceForDestroying;
        paymentToken = tokenAddress;
        encryptor = encryptorAddress;
        partsContract = ERC721Enumerable(partsAddress);

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

    // external
    function assemble(uint256 blockNumberLimit, uint256[] calldata parts, bytes calldata signature) external {
        require(msg.sender == tx.origin, "Minting from smart contracts is disallowed");
        require(validateTokenIds(blockNumberLimit, _msgSender(), parts, signature), "Invalid signature");
        require(parts.length == requiredPartsCountPerMech, "Invalid parts count for minting");

        // payment
        SafeERC20.safeTransferFrom(IERC20(paymentToken), _msgSender(), address(this), mintingPrice);

        for(uint i=0; i<parts.length; i++) {
            uint256 partsTokenId = parts[i];
            require(partsTokenId <= maxPartsIdToMintMech, "One of the parts token has not been enabled to mint mech");
            require(partsContract.ownerOf(partsTokenId) == _msgSender(), "Sender is not parts' owner");
            
            partsContract.safeTransferFrom(_msgSender(), address(this), partsTokenId);
        }

        uint256 tokenId;
        string memory partsKey = generateUniqueString(parts);

        if (_mechs[partsKey] > 0) {
            tokenId = _mechs[partsKey];
            require(!_exists(tokenId), "Mech has been already owned to other user");
        } else {
            _tokenIds++;
            tokenId = _tokenIds;
            _mechMetaData[tokenId] = MechMetaData(parts);
            _mechs[partsKey] = tokenId;
        }

        _safeMint(_msgSender(), tokenId);
        emit Assembled(_msgSender(), tokenId, parts);
    }

    function disassemble(uint256 blockNumberLimit, uint256 tokenId, bytes calldata signature) external {
        require(ownerOf(tokenId) == _msgSender(), "Sender is not mech owner");
        require(validateTokenId(blockNumberLimit, _msgSender(), tokenId, signature), "Invalid signature");
        require(_mechMetaData[tokenId].parts.length > 0, "The mech NFT is not initialized");

        // payment
        SafeERC20.safeTransferFrom(IERC20(paymentToken), _msgSender(), address(this), destroyingPrice);

        _burn(tokenId);

        MechMetaData memory data = _mechMetaData[tokenId];
        for (uint i=0; i< data.parts.length; i++) {
            partsContract.safeTransferFrom(address(this), _msgSender(), data.parts[i]);
        }
        
        emit Disassembled(_msgSender(), tokenId, data.parts);
    }

    // viewer
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
    
    // operator
    function setMintingSettings(uint256 maxPartsId, uint256 requiredPartsCount) external onlyOperator {
        maxPartsIdToMintMech = maxPartsId;
        requiredPartsCountPerMech = requiredPartsCount;
        emit MaxPartsIdChanged(maxPartsId);
    }

    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOperator {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
    }

    // admin
    function setEncryptor(address encryptorAddress) external onlyAdmin {
        encryptor = encryptorAddress;
    }
    
    function setPaymentToken(address tokenAddress) external onlyAdmin {
        paymentToken = tokenAddress;
    }

    function updatePrice(uint256 priceForMinting, uint256 priceForDestroying) external onlyAdmin {
        mintingPrice = priceForMinting;
        destroyingPrice = priceForDestroying;
    }

    function withdrawPaymentTokens(address recipient, uint256 amount) external onlyAdmin {
        SafeERC20.safeTransfer(IERC20(paymentToken), recipient, amount);
    }

    // libraries
    function generateUniqueString(uint256[] memory parts) public pure returns (string memory) {
        require(parts.length > 0, "Input should have elements");
        sortUint256Array(parts);
        string memory v;
        for (uint i=0; i<parts.length; i++){
            if (i==0) {
                v = string(abi.encodePacked(Strings.toString(parts[i])));
            } else {
                v = string(abi.encodePacked(v, ".", Strings.toString(parts[i])));
            }
        }

        return v;
    }

    function sortUint256Array(uint256[] memory arr) internal pure {
        uint length = arr.length;
        for(uint i=0; i<length-1; i++) {
            for(uint j=0; j<length-1; j++) {
                if(arr[j] > arr[j+1]) {
                    uint256 tmp = arr[j];
                    arr[j] = arr[j+1];
                    arr[j+1] = tmp;
                }
            }
        }
    }
    
    function validateTokenId(
        uint256 blockNumberLimit,
        address owner,
        uint256 tokenId,
        bytes calldata signature
    ) internal returns (bool) {
        bytes32 hashed = keccak256(abi.encode(blockNumberLimit, owner, tokenId));
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hashed, signature);

        if (error == ECDSA.RecoverError.NoError && recovered == encryptor ) {
            return true;
        }

        return false;
    }
    
    function validateTokenIds(
        uint256 blockNumberLimit,
        address owner,
        uint256[] calldata tokenIds,
        bytes calldata signature
    ) internal returns (bool) {
        bytes32 hashed = keccak256(abi.encode(blockNumberLimit, owner, tokenIds));
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hashed, signature);

        if (error == ECDSA.RecoverError.NoError && recovered == encryptor ) {
            return true;
        }

        return false;
    }

    // this is required from IERC721Receiver spec.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    // supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // for bridge
    // bridge L1 -> L2
    function deposit(address user, bytes calldata depositData) external onlyDepositor {
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            require(withdrawnTokens[tokenId], "Mech: TOKEN_EXISTS_ON_ROOT_CHAIN");
            withdrawnTokens[tokenId] = false;
            _mint(user, tokenId);

        // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                require(withdrawnTokens[tokenIds[i]], "Mech: TOKEN_EXISTS_ON_ROOT_CHAIN");
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
    
    // events
    event Assembled(address owner, uint256 tokenId, uint256[] parts);
    event Disassembled(address owner, uint256 tokenId, uint256[] parts);
    event MaxPartsIdChanged(uint256 tokenId);
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);
    event TransferWithMetadata(address indexed from, address indexed to, uint256 indexed tokenId, bytes metaData);
}