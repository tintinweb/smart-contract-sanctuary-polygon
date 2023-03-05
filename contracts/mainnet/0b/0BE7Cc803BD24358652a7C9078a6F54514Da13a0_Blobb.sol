// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SVGChunksTool.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title Blobb
 * @author Sawyheart
 * @notice A BLOBB is a Dynamic On-Chain NFT that will change in its metadata and graphics based on the 
 * owner and other players Actions. Try to be the last standing BLOBB and win a unique item and a cash prize.
 */
contract Blobb is ERC721URIStorage, Ownable {
  using Strings for uint256;
  using Strings for address;
  using SVGChunksTool for SVGChunksTool.SVGChunks;
  using Counters for Counters.Counter;

  /// @dev Value that stops all the Contract functions except for the transfer() and withdraw().
  bool public isContractEnabled;

  /// @dev Where all the SVG chunks are stored and correctly and neatly separated to be merged with the proper values.
  SVGChunksTool.SVGChunks private _svgChunks;

  /// @dev Counter of the IDs minted to date.
  Counters.Counter private _blobIDs;

  /// @notice All the Actions prices.
  uint256 constant public mintPrice = 15 ether; //15 MATIC * blobType (1.5 MATIC)
  uint256 constant public attackPrice = 5 ether; //+ 2.5 MATIC if killing
  uint256 constant public healPrice = 2.5 ether; //0.001
  uint256 constant public maxSupply = 1000;

  /// @dev Event emitted when a new BLOBB is minted.
  event NewBlobb(uint indexed newBlobID, address indexed newOwner);

  /// @dev Event emitted when a BLOBB performs any action. 
  event Action(uint indexed toBlobID, uint indexed madeFrom, uint newHP, uint newTotAttks, uint kingOfBlobbs);
  
  /// @dev The BLOBB structure.
  struct Blob {
    uint256 blobID;
    uint256 birthday;
    uint256 hp;
    uint256 totalActions; /// @dev As the IDX of the blobbHistory mapping.
    uint256 totalAttacks; /// @dev To take track of the level of the BLOBB.
    uint256 kills;
    uint256 deathDate; 
    address creator;
    address owner;
    address lastHit;
    uint blobType;
    mapping(uint => bytes) values; /// @dev Ordered values to be inserted in the RAW SVG.
  }

  /// @dev A mapping of all BLOBBs.
  mapping(uint256 => Blob) public blobs;

  /// @dev A mapping of all BLOBBs' owners.
  mapping(address => uint256) public ownedBlob;

  /// @dev The number of all dead BLOBBs.
  uint public totalDeadBlobs;

  /// @dev A mapping of all dead BLOBBs in chronological order using totalDeadBlobs.
  mapping(uint => uint) public deadBlobs;

  /// @dev A mapping of the colors of all BLOBBs. [0-2]: start color, [3-5]: end color.
  mapping(uint256 => uint[6]) public blobbColors;

  /// @dev A mapping to reconstruct the action history of each BLOBB. id => idx => actorID: actorId == id -> HEAL Action, ATTACK instead. 
  mapping(uint256 => mapping(uint256 => uint256)) public blobbHistory;

  /// @dev Where the blobID of the KING OF BLOBBs will be stored.
  uint public theKingOfBlobbs;

  /// @dev amount of MATIC which will be withdrawn by the KING OF BLOBBs.
  uint public kingsTreasure;

  /// @dev A different constructor without the SVG chunks to stored: BETTER IN DEPLOY COSTS.
  // constructor() ERC721 ("BLOBB", "BLOBB") {}

  /** 
   * @dev Initializes the BLOBB contract by passing the SVG chunks to store in the SVGChunksTool instance _svgChunks.
   * BETTER IN CONTRACT SIZE.
   * @param _svg the SVG string chunks correctly separated and converted into Bytes in the deploy.js script.
   */
  constructor(bytes[] memory _svg) ERC721 ("BLOBB", "BLOBB") { 
    _svgChunks.uploadSVG(_svg);
  }

  // function uploadSVG(bytes[] memory _svg) external onlyOwner { _svgChunks.uploadSVG(_svg); }

  /**
   * @dev It allows me to replace a specific SVG chunk of SVGChunksTool instance _svgChunks.
   * @param _nChunkIDX The specific chunk that I will update.
   * @param _nChunk The new chunk that now will be used.
   */
  function updateSVGChunk(uint _nChunkIDX, bytes memory _nChunk) external onlyOwner { 
    _svgChunks.updateSVGChunk(_nChunkIDX, _nChunk);
  }

  /**
   * @dev Setter of isContractEnabled value.
   * @param _isContractEnabled New value to assign to the storage variable isContractEnabled.
   */
  function setIsContractEnabled(bool _isContractEnabled) external onlyOwner { 
    isContractEnabled = _isContractEnabled;
  }

  /// @dev Function to get the total BLOBBs number from the Counter.
  function getTotalBlobbsNumber() public view returns(uint) { 
    return _blobIDs.current();
  }

  /// @dev Common conditions to be met when a BLOBB invoke an action.
  function checkActionsConditions() private view {
    require(isContractEnabled); // "Contract is stopped!"
    require(theKingOfBlobbs == 0); // "The Battle is over!"
    ownerOf(ownedBlob[msg.sender]);
  }

  /// @dev Commmon conditions to be met when a user mint a new BLOBB.
  function checkMintConditions(address _blobCreator, uint[6] memory _colors) private view {
    require(isContractEnabled); // "Contract is stopped!"
    require(_blobIDs.current() < maxSupply); // "Max exceeded!"
    for(uint256 i = 0; i < _colors.length; i++) { require(_colors[i] <= 255); } // "Invalid colors!"
    require(ownedBlob[_blobCreator] == 0); // "You already OWN a Blobb!"
  }

  /**
   * @dev Where the SVG chunks are merged whit the BLOBB's values creating a single RAW SVG file and a full image URI.
   * @param _blobID The BLOBB id from which we will take the values.
   * @return string The new updated image URI for the BLOBB _blobID is returned in form of string. 
   */
  function getImageURI(uint256 _blobID) public view returns(string memory) {
    bytes memory svg = _svgChunks.getSVGChunk(0);
    for(uint i = 1; i < _svgChunks.getTotalChunksNumber(); i++) {
      svg = abi.encodePacked(svg, blobs[_blobID].values[i-1], _svgChunks.getSVGChunk(i));
    }
    return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
  }

  /**
   * @dev The initialization of a BLOBB when is just minted, where all the Blob struct values are set up.
   * @param _blobID The ID of the new BLOBB. 
   * @param _creator The creator address of the new BLOBB. 
   * @param _colors The colors in RGB formats that the user choose for the BLOBB. 
   * @param _blobType The type of BLOBB that the user choose. 
   */
  function _newDefaultBlob(uint256 _blobID, address _creator, uint[6] memory _colors, uint _blobType) internal {
    Blob storage blob = blobs[_blobID];
    blob.blobID = _blobID;
    blob.birthday = block.timestamp;
    blob.hp = 10;
    blob.totalAttacks = 10;
    blob.creator = _creator;
    blob.owner = _creator;
    blob.blobType = _blobType;
    if(_blobType == 4) _colors[0] = 256; // TO EASILY UNDERSTAND IF IT IS MULTICOLOR IN MY DAPP.
    blobbColors[_blobID] = _colors;

    bytes memory _startRGB = abi.encodePacked(_colors[0].toString(), ",", _colors[1].toString(), ",", _colors[2].toString());
    bytes memory _endRGB = abi.encodePacked(_colors[3].toString(), ",", _colors[4].toString(), ",", _colors[5].toString());
    bytes memory _b1 = bytes("1");
    
    blob.values[0] = _startRGB; // FIRST COLOR
    blob.values[1] = _endRGB; // SECOND COLOR
    blob.values[2] = _b1; // HP TO ALPHA VALUE
    blob.values[3] = _blobID > 50 ? bytes("T") : bytes("C"); // GOLD OR WHITE GRADIENT
    if(_blobType < 4) blob.values[4] = _b1; // MULTI COLOR BLOBB ANIMATION
    if(_blobType == 0 || _blobType == 2) blob.values[5] = _b1; // CIRCLE LEVEL ANIMATED
    blob.values[6] = _b1; // VERIFIED OPACITY
    blob.values[7] = bytes("0"); // CROWN OPACITY
    blob.values[8] = bytes("10"); // EXP CIRCLE BAR
    blob.values[9] = _b1; // LEVEL NUMBER
    blob.values[10] = bytes(_blobID.toString()); // BLOB ID
    blob.values[11] = abi.encodePacked(SVGChunksTool.substring(_creator.toHexString(), 0, 5), "...", SVGChunksTool.substring(_creator.toHexString(), 38, 42)); // OWNER ADDRESS
    if(_blobType < 2) blob.values[12] = _b1; // STROKE GRADIENT ANIMATED
  }

  /**
   * @dev Update the values of a specific BLOBB, values that will update the graphic of the BLOBB when getImageURI() rebuild the new URI.
   * @param _blobID The ID of the BLOBB whose value we want to update.
   * @param _vIDX The index (key) of the mapping whose value is to be changed.
   * @param _value The new value we're going to put in the values mapping.
   */
  function _updateValue(uint _blobID, uint _vIDX, bytes memory _value) internal {
    blobs[_blobID].values[_vIDX] = _value;
  }

  /**
   * @dev Create the full URI to assign it to the token to properly diplay the NFT with its attributes.
   * @param _blobID The BLOBB for which and from which the URI is built. 
   */
  function getBlobURI(uint256 _blobID) public view returns(string memory) {
    Blob storage blob = blobs[_blobID];
    return string(abi.encodePacked("data:application/json;base64,",Base64.encode(abi.encodePacked(
      '{"name":"BLOBB #', _blobID.toString(), '","description":"BLOBBs On-Chain Battle!","attributes":[{"trait_type":"HP","value":', blob.hp.toString(), '},{"trait_type":"LEVEL","max_value":99,"value":', blob.totalAttacks < 1000 ? (blob.totalAttacks/10).toString() : "99", '},{"trait_type":"TYPE","value":"', blob.blobType == 4 ? "MULTI-COLOR" : blob.blobType.toString() ,'"},{"trait_type":"TEXT","value":"', _blobID > 50 ? "DEFAULT" : "GOLD" ,'"},{"trait_type":"STATUS","value":"', blob.hp == 0 ? "DEAD" : theKingOfBlobbs == _blobID ? "KING" : "ALIVE" ,'"},{"trait_type":"KILLS","value":"', blob.kills.toString() ,'"}],"image":"', getImageURI(_blobID), '"}'
    ))));
  }

  /**
   * @dev The mint public function callable by the users.
   * @param _colors The colors the user choose for the BLOBB.
   * @param _blobType The type the user choose for the BLOBB.
   */
  function mintBlob(uint[6] memory _colors, uint _blobType) public payable {
    checkMintConditions(msg.sender, _colors);
    require(msg.value == mintPrice + (1.5 ether * _blobType)); // "Wrong MINT value!"
    require(_blobType < 4); // The multicolor BLOBB is only giftable by me.
    kingsTreasure += 5 ether; // 5 MATIC will be saved for the KING OF BLOBBs.
    _mintBlob(msg.sender, _colors, _blobType);
  }

  /**
   * @dev My mint function where i can gift some BLOBBs.
   * @param _creatorAddress The address to which I'll gift the BLOBB.
   * @param _colors The colors of the BLOBB I'll gift.
   * @param _blobType The type of the BLOBB I'll gift.
   */
  function mintGiftBlob(address _creatorAddress, uint[6] memory _colors, uint _blobType) external onlyOwner {
    checkMintConditions(_creatorAddress, _colors);
    _mintBlob(_creatorAddress, _colors, _blobType);
  }

  /**
   * @dev The actual minting function, where all operations to mint a new NFT are performed:
   * -Incrementing the ID;
   * -Set all the BLOBB information we mentioned before;
   * -Build the URI of the new BLOBB and set it with the _setTokenURI() function of the ERC721 Smart Contract. 
   */
  function _mintBlob(address _creatorAddress, uint[6] memory _colors, uint _blobType) internal {
    _blobIDs.increment();
    uint256 newBlobID = _blobIDs.current();
    _safeMint(_creatorAddress, newBlobID);

    _newDefaultBlob(newBlobID, _creatorAddress, _colors, _blobType);
    ownedBlob[_creatorAddress] = newBlobID;

    _setTokenURI(newBlobID, getBlobURI(newBlobID));
    emit NewBlobb(newBlobID, _creatorAddress);
  }

  /**
   * @dev Attack the BLOBB, one of the action that a BLOBB NFT could perform. The attack involves changes to:
   * -The Blob struct;
   * -The BLOBB values with which we will build the RAW SVG and the image URI;
   * -The token URI where: image, attributes ecc will be updated.
   * And this is for both sides, the Attacker and the Attacked.
   * @param _blobID Which BLOBB ID the caller is directing the attack to. 
   */
  function attackBlob(uint256 _blobID) public payable {
    checkActionsConditions();
    Blob storage blob = blobs[_blobID];
    uint attackerBlobID = ownedBlob[msg.sender];
    Blob storage attackerBlob = blobs[attackerBlobID];

    require(ownedBlob[msg.sender] != _blobID); // "You can't ATTACK your own Blobb!"
    require(attackerBlob.hp != 0); // "Your Blobb is dead!"
    require(blob.hp != 0); // "Blobb is dead!"

    // Checking if the Attacker is killing the Attacked BLOBB.
    uint killing = blob.hp == 1 ? 1 : 0;
    require(msg.value >= attackPrice + (2.5 ether * killing), "Wrong ATTACK value!");

    blob.hp -= 1;
    blob.lastHit = msg.sender;
    blob.totalActions++;
    
    attackerBlob.totalAttacks++;

    if(killing == 1) {
      attackerBlob.kills++;
      attackerBlob.totalAttacks += 9;
      blob.deathDate = block.timestamp;
      totalDeadBlobs++;
      deadBlobs[totalDeadBlobs] = _blobID;
    }

    bytes memory _b1 = bytes("1");

    // If totalDeadBlobs == maxSupply-1 it means that the Attacker kill the last BLOBB. Attacker BLOBB is the KING OF BLOBBs.
    if(totalDeadBlobs == maxSupply-1) { 
      theKingOfBlobbs = attackerBlobID;

      // CROWN OPACITY -> values[7]
      _updateValue(attackerBlobID, 7, _b1);
    }

    // ATTACKED BLOBB METADATA UPDATE
    bytes memory _hpToAlpha = blob.hp == 10 ? _b1 : abi.encodePacked(".", blob.hp.toString());

    // HP TO ALPHA VALUE -> values[2]
    _updateValue(_blobID, 2, _hpToAlpha);


    // ATTACKER BLOBB METADATA UPDATE
    
    // EXP CIRCLE BAR -> values[8]
    _updateValue(attackerBlobID, 8, attackerBlob.totalAttacks < 1000 ? abi.encodePacked((10 - attackerBlob.totalAttacks % 10).toString()) : bytes("0"));
    // LEVEL NUMBER -> values[9]
    _updateValue(attackerBlobID, 9, attackerBlob.totalAttacks < 1000 ? abi.encodePacked((attackerBlob.totalAttacks/10).toString()) : bytes("99"));


    blobbHistory[_blobID][blob.totalActions] = attackerBlobID;

    _setTokenURI(_blobID, getBlobURI(_blobID));
    _setTokenURI(attackerBlobID, getBlobURI(attackerBlobID));

    emit Action(_blobID, attackerBlobID, blob.hp, attackerBlob.totalAttacks, theKingOfBlobbs);
  }

  /**
   * @dev Heal the BLOBB, one of the action that a BLOBB NFT could perform. The Heal involves changes to:
   * -The Blob struct;
   * -The BLOBB values with which we will build the RAW SVG and the image URI;
   * -The token URI where: image, attributes ecc will be updated.
   * @param _blobID The BLOBB ID that will be Healed. 
   */
  function healBlob(uint256 _blobID) public payable {
    checkActionsConditions();
    Blob storage blob = blobs[_blobID];
    require(ownedBlob[msg.sender] == _blobID); // "Not your BLOBB!"
    require(blob.hp != 0); // "Your Blobb is dead!"
    require(blob.hp < 10); // "Your Blobb has FULL HP!"
    require(msg.value == healPrice, "Wrong HEAL value!");

    blob.hp++;
    blob.totalActions++;

    // HEALED BLOBB METADATA UPDATE
    bytes memory _hpToAlpha = blob.hp == 10 ? bytes("1") : abi.encodePacked(".", blob.hp.toString());

    // HP TO ALPHA VALUE -> values[2]
    _updateValue(_blobID, 2, _hpToAlpha);

    blobbHistory[_blobID][blob.totalActions] = ownedBlob[msg.sender];

    _setTokenURI(_blobID, getBlobURI(_blobID));

    emit Action(_blobID, 0, blob.hp, blob.totalAttacks, theKingOfBlobbs);
  }

  /**
   * @dev Handle the transfer of a BLOBB. All the information of a BLOBB will change to fit the new owner.
   * @param from The address from which the BLOBB originated.
   * @param to The new owner that will own the BLOBB.
   * @param tokenId The blobID which will be transferred.
   */
  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    require(balanceOf(to) == 0, "Blobb Owner!");
    super._transfer(from, to, tokenId);

    delete ownedBlob[from];
    ownedBlob[to] = tokenId;

    Blob storage blob = blobs[tokenId];
    blob.owner = to;

    // TRANSFERED BLOBB METADATA UPDATE

    // VERIFIED OPACITY -> values[6]
    _updateValue(tokenId, 6, blob.owner == blob.creator ? bytes("1") : bytes("0"));
    // OWNER ADDRESS -> values[11]
    _updateValue(tokenId, 11, abi.encodePacked(SVGChunksTool.substring(to.toHexString(), 0, 5), "...", SVGChunksTool.substring(to.toHexString(), 38, 42))); //OWNER ADDRESS

    _setTokenURI(tokenId, getBlobURI(tokenId));
  }

  /**
   * @dev The withdraw function.
   * @param _forTheKing To enable the king to obtain his prize. 
   */
  function withdraw(uint _forTheKing) external onlyOwner {
    require(theKingOfBlobbs != 0 || _forTheKing == 0);
    (bool success, ) = payable(_forTheKing == 1 ? blobs[theKingOfBlobbs].owner : owner()).call{value: _forTheKing == 1 ? kingsTreasure : address(this).balance - kingsTreasure}("");
    require(success);
    kingsTreasure = _forTheKing == 1 ? 0 : kingsTreasure; 
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title SVGChunksTool
 * @author Sawyheart
 * @notice The library where all the SVG chunks are sotred, managed and easily accessible. 
 */
library SVGChunksTool {
  /// @dev Struct to be instantiated in the Blobb.sol contract. It will contain all the SVG chunks informations.
  struct SVGChunks {
    uint totalChunks; // Total SVG chunks counter and index to access the chunks in their correct order. 
    mapping(uint => bytes) chunks; // A Mapping containing the ordered SVG chunks.
  }

  /**
   * @dev Getter of the total SVG chunks number. Useful for iterating over all individual chunks.
   * @param _svgChunks The SVGChunks struct instance in the Blobb.sol contract.
   */
  function getTotalChunksNumber(SVGChunks storage _svgChunks) internal view returns(uint) {
    return _svgChunks.totalChunks;
  }

  /**
   * @dev Function to upload all the SVG chunks at the time of deployment.
   * @param _svgChunks The SVGChunks struct instance in the Blobb.sol contract.
   * @param _chunks All the SVG chunks in an array of bytes.
   */
  function uploadSVG(SVGChunks storage _svgChunks, bytes[] memory _chunks) internal {
    for(uint i = 0; i < _chunks.length; i++) {
      _svgChunks.chunks[i] = _chunks[i];
    }
    _svgChunks.totalChunks = _chunks.length;
  }

  /**
   * @dev Allow the owner to replace a single chunk. To simply update it or to correct some error.
   * @param _svgChunks The SVGChunks struct instance in the Blobb.sol contract.
   * @param _chunkIDX The index of the chunk we want to replace.
   * @param _chunk The new SVG chunk information in bytes that you want to store.
   */
  function updateSVGChunk(SVGChunks storage _svgChunks, uint _chunkIDX, bytes memory _chunk) internal {
    _svgChunks.chunks[_chunkIDX] = _chunk;
  }

  /**
   * @dev Getter of a single chunk informations.
   * @param _svgChunks The SVGChunks struct instance in the Blobb.sol contract.
   * @param _chunkIDX The IDX of the chunk you want to get.
   */
  function getSVGChunk(SVGChunks storage _svgChunks, uint _chunkIDX) internal view returns(bytes memory) {
    return _svgChunks.chunks[_chunkIDX];
  }

  //UTILS

  /**
   * @dev Utility function to trim a string.
   * @param str The full string you want to trim.
   * @param beginIDX The index from which the new string will starts, removing all the previous chars.
   * @param endIDX The index from which the new string will ends, removing all the next chars.
   */
  function substring(string memory str, uint beginIDX, uint endIDX) internal pure returns(string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIDX-beginIDX);
    for(uint i = beginIDX; i < endIDX; i++) {
      result[i-beginIDX] = strBytes[i];
    }
    
    return string(result);
  }
  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}