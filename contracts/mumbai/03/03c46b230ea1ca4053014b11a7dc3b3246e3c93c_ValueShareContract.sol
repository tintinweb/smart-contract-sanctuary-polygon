/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct metaDataProof {
    address validatorAddress;
    uint8 v; // v of validator signed message
    bytes32 r; // r of validator signed message
    bytes32 s; // s of validator signed message
}

interface IERC20 {
    function initialize(
        string calldata name,
        string calldata symbol,
        address minter,
        uint256 cap,
        string calldata blob,
        address collector
    ) external returns (bool);

    function mint(address account, uint256 value) external;
    function minter() external view returns(address);    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function cap() external view returns (uint256);
    function isMinter(address account) external view returns (bool);
    function isInitialized() external view returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function safeIncreaseAllowance(address router, uint256 amount ) external;
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function proposeMinter(address newMinter) external;
    function approveMinter() external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20Template {
    struct RolesERC20 {
        bool minter;
        bool feeManager;
    }
    struct providerFee{
        address providerFeeAddress;
        address providerFeeToken; // address of the token marketplace wants to add fee on top
        uint256 providerFeeAmount; // amount to be transfered to marketFeeCollector
        uint8 v; // v of provider signed message
        bytes32 r; // r of provider signed message
        bytes32 s; // s of provider signed message
        uint256 validUntil; //validity expresses in unix timestamp
        bytes providerData; //data encoded by provider
    }
    struct consumeMarketFee{
        address consumeMarketFeeAddress;
        address consumeMarketFeeToken; // address of the token marketplace wants to add fee on top
        uint256 consumeMarketFeeAmount; // amount to be transfered to marketFeeCollector
    }
    function initialize(
        string[] calldata strings_,
        address[] calldata addresses_,
        address[] calldata factoryAddresses_,
        uint256[] calldata uints_,
        bytes[] calldata bytes_
    ) external returns (bool);
    
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address account, uint256 value) external;
    
    function isMinter(address account) external view returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permissions(address user)
        external
        view
        returns (RolesERC20 memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cleanFrom721() external;

    function deployPool(
        uint256[] memory ssParams,
        uint256[] memory swapFees,
        address[] memory addresses 
    ) external returns (address);

    function createFixedRate(
        address fixedPriceAddress,
        address[] memory addresses,
        uint[] memory uints
    ) external returns (bytes32);
    function createDispenser(
        address _dispenser,
        uint256 maxTokens,
        uint256 maxBalance,
        bool withMint,
        address allowedSwapper) external;
        
    function getPublishingMarketFee() external view returns (address , address, uint256);
    function setPublishingMarketFee(
        address _publishMarketFeeAddress, address _publishMarketFeeToken, uint256 _publishMarketFeeAmount
    ) external;

     function startOrder(
        address consumer,
        uint256 serviceIndex,
        providerFee calldata _providerFee,
        consumeMarketFee calldata _consumeMarketFee
     ) external;

     function reuseOrder(
        bytes32 orderTxId,
        providerFee calldata _providerFee
    ) external;
  
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function getERC721Address() external view returns (address);
    function isERC20Deployer(address user) external view returns(bool);
    function getPools() external view returns(address[] memory);
    struct fixedRate{
        address contractAddress;
        bytes32 id;
    }
    function getFixedRates() external view returns(fixedRate[] memory);
    function getDispensers() external view returns(address[] memory);
    function getId() pure external returns (uint8);
    function getPaymentCollector() external view returns (address);
}

interface IERC721Template {
    enum RolesType {
        Manager,
        DeployERC20,
        UpdateMetadata,
        Store
    }

    struct metaDataAndTokenURI {
        uint8 metaDataState;
        string metaDataDecryptorUrl;
        string metaDataDecryptorAddress;
        bytes flags;
        bytes data;
        bytes32 metaDataHash;
        uint256 tokenId;
        string tokenURI;
        metaDataProof[] metadataProofs;
    }

    function balanceOf(address owner) external view returns (uint256 balance);
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isERC20Deployer(address acount) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function transferFrom(address from, address to) external;

    function initialize(
        address admin,
        string calldata name,
        string calldata symbol,
        address erc20Factory,
        address additionalERC20Deployer,
        address additionalMetaDataUpdater,
        string calldata tokenURI,
        bool transferable
    ) external returns (bool);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

     struct Roles {
        bool manager;
        bool deployERC20;
        bool updateMetadata;
        bool store;
    }
    function getPermissions(address user) external view returns (Roles memory);

    function setDataERC20(bytes32 _key, bytes calldata _value) external;
    function setMetaData(uint8 _metaDataState, string calldata _metaDataDecryptorUrl
        , string calldata _metaDataDecryptorAddress, bytes calldata flags, 
        bytes calldata data,bytes32 _metaDataHash, metaDataProof[] memory _metadataProofs) external;
    function setMetaDataAndTokenURI(metaDataAndTokenURI calldata _metaDataAndTokenURI) external;
    function setTokenURI(uint256 tokenId, string memory tokenURI) external;
    function getMetaData() external view returns (string memory, string memory, uint8, bool);

    function createERC20(
        uint256 _templateIndex,
        string[] calldata strings,
        address[] calldata addresses,
        uint256[] calldata uints,
        bytes[] calldata bytess
    ) external returns (address);


    function removeFromCreateERC20List(address _allowedAddress) external;
    function addToCreateERC20List(address _allowedAddress) external;
    function addToMetadataList(address _allowedAddress) external;
    function removeFromMetadataList(address _allowedAddress) external;
    function getId() pure external returns (uint8);
}

interface IERC721Factory {
    struct Template {
        address templateAddress;
        bool isActive;
    }
    struct NftCreateData{
        string name;
        string symbol;
        uint256 templateIndex;
        string tokenURI;
        bool transferable;
        address owner;
    }
    struct ErcCreateData{
        uint256 templateIndex;
        string[] strings;
        address[] addresses;
        uint256[] uints;
        bytes[] bytess;
    }
    struct FixedData{
        address fixedPriceAddress;
        address[] addresses;
        uint256[] uints;
    }
    struct DispenserData{
        address dispenserAddress;
        uint256 maxTokens;
        uint256 maxBalance;
        bool withMint;
        address allowedSwapper;
    }
    struct MetaData {
        uint8 _metaDataState;
        string _metaDataDecryptorUrl;
        string _metaDataDecryptorAddress;
        bytes flags;
        bytes data;
        bytes32 _metaDataHash;
        metaDataProof[] _metadataProofs;
    }
    struct PoolData{
        uint256[] ssParams;
        uint256[] swapFees;
        address[] addresses;
    }

    function deployERC721Contract(
        string memory name,
        string memory symbol,
        uint256 _templateIndex,
        address additionalERC20Deployer,
        address additionalMetaDataUpdater,
        string memory tokenURI,
        bool transferable,
        address owner
    ) external returns (address token);
    function getCurrentNFTCount() external view returns (uint256);
    function getNFTTemplate(uint256 _index)
        external
        view
        returns (Template memory);
    function add721TokenTemplate(address _templateAddress)
        external
        returns (uint256);
    function disable721TokenTemplate(uint256 _index) external;
    function getCurrentNFTTemplateCount() external view returns (uint256);
     function createToken(
        uint256 _templateIndex,
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory uints,
        bytes[] memory bytess
    ) external returns (address token);
    function getCurrentTokenCount() external view returns (uint256);
    function getTokenTemplate(uint256 _index)
        external
        view
        returns (Template memory);
    function addTokenTemplate(address _templateAddress) external returns (uint256);
    function createNftWithErc20(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData
    ) external returns (address erc721Address, address erc20Address);
    function createNftWithErc20WithPool(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        PoolData calldata _PoolData
    ) external returns (address erc721Address, address erc20Address, address poolAddress);
    function createNftWithErc20WithFixedRate(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        FixedData calldata _FixedData
    ) external returns (address erc721Address, address erc20Address, bytes32 exchangeId);
    function createNftWithErc20WithDispenser(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        DispenserData calldata _DispenserData
    ) external returns (address erc721Address, address erc20Address);
    function createNftWithMetaData(
        NftCreateData calldata _NftCreateData,
        MetaData calldata _MetaData
    ) external returns (address erc721Address);
}

contract ValueShareContract is IERC721Receiver {
    IERC721Factory _erc721Factory;
    address public _owner;
    bool private _initialized;

    address public _erc721FactoryAddress = 0x7d46d74023507D30ccc2d3868129fbE4e400e40B; // 0x03ABAd83b9f2F182D6C9d3FA70619Abc2edc8ccC
    address public _fixedExchangeAddress = 0x25e1926E3d57eC0651e89C654AB0FA182C6D5CF7;
    address public _oceanAddress = 0xd8992Ed72C445c35Cb4A2be468568Ed1079357c8;

    address public _nftAddress;
    address public _erc20Address;
    bytes32 public _exchangeId;

    struct ValueShareData {
        uint amount;
        uint8 flag;
    }

    struct ValueShare {
        address sharer;
        uint amount;
    }

    mapping(address => ValueShareData) _valueShare;
    uint public _totalValueShare;

    event NftCreated(address nftAddress);
    event DataTokenCreated(address dataTokenAddress);
    event FixedRateCreated(bytes32 exchangeId);
    event NftWithFixedRateCreated(address nftAddress, address dataTokenAddress, bytes32 exchangeId);
    event MetaDataSet();
    event ValueShareAdded();
    event ValueShareUpdated();
    event Claimed();


    modifier authSharer() {
        require(_valueShare[msg.sender].flag == 1, "Not sharer");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    constructor(address erc721FactoryAddress, address fixedExchangeAddress, address oceanAddress) {
        _initialized = true;
        _owner = msg.sender;
        _erc721FactoryAddress = erc721FactoryAddress;
        _fixedExchangeAddress = fixedExchangeAddress;
        _erc721Factory = IERC721Factory(_erc721FactoryAddress);
        _oceanAddress = oceanAddress;
    }

    function initialize(address erc721FactoryAddress, address fixedExchangeAddress, address oceanAddress, address deployer) public {
        require(!_initialized, "Contract instance has already been initialized");
        _initialized = true;
        _owner = deployer;
        _erc721FactoryAddress = erc721FactoryAddress;
        _fixedExchangeAddress = fixedExchangeAddress;
        _erc721Factory = IERC721Factory(_erc721FactoryAddress);
        _oceanAddress = oceanAddress;
    }

    function addValueShare(address sharer, uint amount) public onlyOwner returns (string memory) {
        if (_valueShare[sharer].flag == 1) {
            return "Already added!";
        }
        _valueShare[sharer] = ValueShareData(amount, 1);
        _totalValueShare += amount;
        emit ValueShareAdded();
        return "Added!";
    }

    function addValueShares(ValueShare[] memory valueShares) public onlyOwner returns (string memory) {
        for (uint i = 0; i < valueShares.length; ++i) {
            if (_valueShare[valueShares[i].sharer].flag == 1) {
                _totalValueShare -= _valueShare[valueShares[i].sharer].amount;
            }
            _valueShare[valueShares[i].sharer] = ValueShareData(valueShares[i].amount, 1);
            _totalValueShare += valueShares[i].amount;
        }
        emit ValueShareAdded();
        return "Added!";
    }

    function getValueShare(address sharer) public view onlyOwner returns (ValueShareData memory) {
        return _valueShare[sharer];
    }

    function updateValueShare(address sharer, uint amount) public onlyOwner returns (string memory) {
        if (_valueShare[sharer].flag == 1) {
            _totalValueShare -= _valueShare[sharer].amount;
            _valueShare[sharer] = ValueShareData(amount, 1);
            _totalValueShare += amount;
            emit ValueShareUpdated();
            return "Updated!";
        }
        return "Not added yet!";
    }

    function getValueShare() public view authSharer returns (ValueShareData memory) {
        return _valueShare[msg.sender];
    }

    function claim() public authSharer {
        IERC20 oceanToken = IERC20(_oceanAddress);
        uint256 balance = oceanToken.balanceOf(address(this));
        uint256 amount = balance * _valueShare[msg.sender].amount / _totalValueShare;
        oceanToken.transfer(msg.sender, amount);
        _totalValueShare -= _valueShare[msg.sender].amount;
        _valueShare[msg.sender].amount = 0;
        emit Claimed();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function deployERC721Contract(
        string memory name,
        string memory symbol,
        uint256 templateIndex, // 1
        address additionalERC20Deployer, // address(this)
        address additionalMetaDataUpdater, // address(this)
        string memory tokenURI,
        address nftOwner // Should be account address
    ) public onlyOwner {
        _nftAddress = _erc721Factory.deployERC721Contract(name, symbol, templateIndex, additionalERC20Deployer, additionalMetaDataUpdater, tokenURI, true, nftOwner);

        emit NftCreated(_nftAddress);
    }

    function createERC20(
        string memory name,
        string memory symbol,
        uint256 templateIndex,
        uint256 cap, // 10000000000000000000000
        uint256 feeAmount, // 0
        bytes[] calldata bytess // []
    ) public onlyOwner {
        string[] memory strings = new string[](2);
        strings[0] = name;
        strings[1] = symbol;

        address[] memory addresses = new address[](4);
        addresses[0] = address(this);
        addresses[1] = address(0);
        addresses[2] = address(0);
        addresses[3] = address(0);

        uint256[] memory uints = new uint256[](2);
        uints[0] = cap;
        uints[1] = feeAmount;

        _erc20Address = _createERC20(
            _nftAddress,
            templateIndex,
            strings,
            addresses,
            uints,
            bytess
        );
        emit DataTokenCreated(_erc20Address);
    }

    function _createERC20(
        address nftAddress,
        uint256 templateIndex,
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory uints,
        bytes[] calldata bytess
    ) public onlyOwner returns (address) {
        IERC721Template nft = IERC721Template(nftAddress);
        return nft.createERC20(templateIndex, strings, addresses, uints, bytess);
    }

    function createFixedRate(
        address[] memory addresses,
        uint[] memory uints
    ) public onlyOwner {
        _exchangeId = _createFixedRate(
            _erc20Address, _fixedExchangeAddress, addresses, uints
        );
        emit FixedRateCreated(_exchangeId);
    }

    function _createFixedRate(
        address erc20Address,
        address fixedPriceAddress,
        address[] memory addresses,
        uint[] memory uints
    ) public onlyOwner returns (bytes32) {
        IERC20Template erc20 = IERC20Template(erc20Address);
        return erc20.createFixedRate(fixedPriceAddress, addresses, uints);
    }

    function setMetaData(
        uint8 metaDataState,
        string calldata metaDataDecryptorUrl,
        string calldata metaDataDecryptorAddress,
        bytes calldata flags,
        bytes calldata data,
        bytes32 metaDataHash,
        metaDataProof[] memory metadataProofs
    ) public onlyOwner {
        _setMetaData(_nftAddress, metaDataState, metaDataDecryptorUrl, metaDataDecryptorAddress, flags, data, metaDataHash, metadataProofs);
        emit MetaDataSet();
    }

    function _setMetaData(
        address nftAddress,
        uint8 metaDataState, // 0
        string calldata metaDataDecryptorUrl, // https://v4.provider.mumbai.oceanprotocol.com
        string calldata metaDataDecryptorAddress, // address(this)
        bytes calldata flags, // 0x02
        bytes calldata data,  // 
        bytes32 metaDataHash, // 
        metaDataProof[] memory metadataProofs //
    ) public onlyOwner {
        IERC721Template nft = IERC721Template(nftAddress);
        nft.setMetaData(metaDataState, metaDataDecryptorUrl, metaDataDecryptorAddress, flags, data, metaDataHash, metadataProofs);   
    }

    function createNftWithErc20WithFixedRate(
        IERC721Factory.NftCreateData calldata _NftCreateData,
        IERC721Factory.ErcCreateData calldata _ErcCreateData,
        IERC721Factory.FixedData calldata _FixedData
    ) public onlyOwner {
        (address erc721Address, address erc20Address, bytes32 exchangeId) = _erc721Factory.createNftWithErc20WithFixedRate(_NftCreateData, _ErcCreateData, _FixedData);
        emit NftWithFixedRateCreated(erc721Address, erc20Address, exchangeId);
    }
}