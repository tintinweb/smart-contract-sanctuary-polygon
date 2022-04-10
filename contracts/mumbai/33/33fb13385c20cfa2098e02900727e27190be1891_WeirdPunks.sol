// SPDX-License-Identifier: MIT

/*
 __    __    ___  ____  ____   ___        ____  __ __  ____   __  _  _____
|  |__|  |  /  _]|    ||    \ |   \      |    \|  |  ||    \ |  |/ ]/ ___/
|  |  |  | /  [_  |  | |  D  )|    \     |  o  )  |  ||  _  ||  ' /(   \_ 
|  |  |  ||    _] |  | |    / |  D  |    |   _/|  |  ||  |  ||    \ \__  |
|  `  '  ||   [_  |  | |    \ |     |    |  |  |  :  ||  |  ||     \/  \ |
 \      / |     | |  | |  .  \|     |    |  |  |     ||  |  ||  .  |\    |
  \_/\_/  |_____||____||__|\_||_____|    |__|   \__,_||__|__||__|\_| \___|
                                                                          
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ERC20.sol";
import "./ERC1155Tradable.sol";
import "./AccessControlMixin.sol";
import "./IChildToken.sol";

contract WeirdPunks is ERC721Enumerable, Ownable, AccessControlMixin, IChildToken {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '.json';
  mapping(uint256 => uint256) public weirdMapping;
  mapping(uint256 => bool) internal isMinted;
  ERC1155Tradable public openseaContract;
  uint256 public maxSupply = 1000;
  bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
  bytes32 public constant ORACLE = keccak256("ORACLE");
  mapping (uint256 => bool) public withdrawnTokens;
  address public oracleAddress;
  ERC20 public WETH = ERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  uint256 public gasETH;
  bool public allowMigration = true;
  bool public allowBridging = true;
  bool public allowPolyBridging = true;
  address public delistWallet;
  mapping(uint256 => uint256) internal migrateTimestamp;

  // limit batching of tokens due to gas limit restrictions
  uint256 public constant BATCH_LIMIT = 20;

  event WithdrawnBatch(address indexed user, uint256[] tokenIds);
  event startBatchBridge(address user, uint256[] IDs);

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  constructor(
    string memory _initBaseURI,
    address _openseaContract,
    address childChainManager,
    address _oracleAddress,
    address _delistWallet
  ) ERC721("Weird Punks", "WP") {
    setBaseURI(_initBaseURI);
    openseaContract = ERC1155Tradable(_openseaContract);
    setOracleAddress(_oracleAddress);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEPOSITOR_ROLE, childChainManager);
    _setupRole(ORACLE, _oracleAddress);
    setDelistWallet(_delistWallet);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // external for mapping
  function deposit(address user, bytes calldata depositData) external override only(DEPOSITOR_ROLE) {
    if (depositData.length == 32) {
      uint256 tokenId = abi.decode(depositData, (uint256));
      withdrawnTokens[tokenId] = false;
      _mint(user, tokenId);

    } else {
      uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
      uint256 length = tokenIds.length;
      for (uint256 i; i < length; i++) {
        withdrawnTokens[tokenIds[i]] = false;
        _mint(user, tokenIds[i]);
      }
    }
  }

  function withdrawBatch(uint256[] calldata tokenIds) external {
    require(allowPolyBridging);
    uint256 length = tokenIds.length;
    require(length <= BATCH_LIMIT, "WeirdPunks: Exceeds batch limit");

    for (uint256 i; i < length; i++) {
      uint256 tokenId = tokenIds[i];

      require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("WeirdPunks: Invalid owner of ", tokenId)));
      withdrawnTokens[tokenId] = true;
      _burn(tokenId);
  }
    emit WithdrawnBatch(_msgSender(), tokenIds);
  }

  function depositBridge(address user, uint256[] memory IDs) public only(ORACLE) {
    for (uint256 i; i < IDs.length; i++) {
      _mint(user, IDs[i]);
    }
  }

  // public
  function batchBridge(uint256[] memory IDs, uint256 gas) public {
    require(allowBridging);
    uint256 payableGas = gasETH + (IDs.length - 1) * (gasETH / 2);
    require(WETH.allowance(msg.sender, address(this)) >= payableGas, "WeirdPunks: Not enough polygon eth");
    require(gas >= payableGas, "WeirdPunks: Not enough gas");
    WETH.transferFrom(msg.sender, oracleAddress, gas);
    require(IDs.length <= BATCH_LIMIT, "WeirdPunks: Exceeds limit");
    for (uint256 i; i < IDs.length; i++) {
      require(msg.sender == ownerOf(IDs[i]), string(abi.encodePacked("WeirdPunks: Invalid owner of ", IDs[i])));
      _burn(IDs[i]);
    }
    emit startBatchBridge(msg.sender, IDs);
  }

  function burnAndMint(address _to, uint256[] memory _IDs) public {
    require(allowMigration, "WeirdPunks: Migration is currently closed");
    require(openseaContract.isApprovedForAll(_to, address(this)), "WeirdPunks: Not approved for burn");
    require(totalSupply() + _IDs.length <= maxSupply, "WeirdPunks: Exceeds max supply");
    

    for(uint256 i = 0; i < _IDs.length; i++) {
      require(!withdrawnTokens[_IDs[i]], "WeirdPunks: Token exists on root chain");
      require(!isMinted[_IDs[i]], string(abi.encodePacked("WeirdPunks: Already Minted ID #", _IDs[i])));
      uint256 openseaID = weirdMapping[_IDs[i]];
      bytes memory _data;
      openseaContract.safeTransferFrom(_to, delistWallet, openseaID, 1, _data);
      migrateTimestamp[_IDs[i]] = block.timestamp;

      _mint(_to, _IDs[i]);
      isMinted[_IDs[i]] = true;
    }
  } 
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "WeirdPunks: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function getMigrateTimestamp(uint256 _id) public view returns(uint256) {
    return migrateTimestamp[_id];
  }
 
  //only owner
  function overrideMint(address[] memory _to, uint256[] memory _IDs) public onlyOwner {
    require(!allowMigration, "WeirdPunks: Migration is currently open");
    require(totalSupply() + _IDs.length <= maxSupply, "WeirdPunks: Exceeds max supply");
    for(uint256 i = 0; i < _IDs.length; i++) {
        require(!isMinted[_IDs[i]], string(abi.encodePacked("WeirdPunks: Already Minted ID #", _IDs[i])));
        
        _mint(_to[i], _IDs[i]);
        isMinted[_IDs[i]] = true;
    }
  }

  function addSingleWeirdMapping(uint256 ID, uint256 OSID) private returns(bool success) {
    weirdMapping[ID] = OSID;
    success = true;
  }
 
  function addWeirdMapping(uint256[] memory IDs, uint256[] memory OSIDs) public onlyOwner returns(bool success) {
    require(IDs.length == OSIDs.length, "WeirdPunks: IDs and OSIDs must be the same length");
    for (uint256 i = 0; i < IDs.length; i++) {
      if (addSingleWeirdMapping(IDs[i], OSIDs[i])) {
        success = true;
      }
    }    
  }

  function setGasEth(uint256 _gas) public only(ORACLE) {
    gasETH = _gas;
  }
 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setOpenseaContract(address _openseaContract) public onlyOwner {
    openseaContract = ERC1155Tradable(_openseaContract);
  }

  function setOracleAddress(address _oracleAddress) public onlyOwner {
    oracleAddress = _oracleAddress;
  }

  function setAllowMigration(bool allow) public onlyOwner {
    allowMigration = allow;
  }

  function setAllowPolyBridging(bool allow) public onlyOwner {
    allowPolyBridging = allow;
  }

  function setAllowBridging(bool allow) public onlyOwner {
    allowBridging = allow;
  }

  function setDelistWallet(address _delistWallet) public onlyOwner {
    delistWallet = _delistWallet;
  }
}