// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./Meta.sol";


contract CarchainNFT is ERC721Enumerable, Pausable, AccessControlMixin, NativeMetaTransaction, ContextMixin {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(string=>uint256) public vins;
    mapping(string=>uint256) public hashToTokenID;
    mapping(string=>uint256[]) public hashToTokenIDs;

    event CarCreated(uint256 indexed _id, address indexed sender, string hash, string make, string model, uint256 year, string vin, string engine, string colour, string plate, uint256 mileage, uint256 c02);
    event MileageUpdated(uint256 indexed _id, address indexed sender, uint256 mileage, string hash);
    event MileageUpdatedBatch(uint256[] indexed _id, address indexed sender, uint256[] mileages, string hash);
    event ColourUpdated(uint256 indexed _id, address indexed sender, string colour, string hash);
    event C02Updated(uint256 indexed _id, address indexed sender, uint256 c02, string hash);
    event C02UpdatedBatch(uint256[] indexed _id, address indexed sender, uint256[] c02s, string hash);
    event PlateUpdated(uint256 indexed _id, address indexed sender, string plate, string hash);
    event EngineUpdated(uint256 indexed _id, address indexed sender, string engine, string hash);
    event EventStated(uint256 indexed _id, address indexed sender, string details, string hash);
    event CarBurnt(uint256 indexed _id, address indexed sender);

    constructor() ERC721("Carchain", "CAR") {
        _setupContractId("CarchainNFT");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _initializeEIP712('CarchainNFT');
        _tokenIdCounter.increment();
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.carchain.app/api/erc721/token/";
    }

    function pause() public only(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public only(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public only(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }


    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    struct Properties {
        string hash;
        string make;
        string model;
        uint256 year;
        string vin;
        string engine;
        string colour;
        string plate;
        uint256 mileage;
        uint256 c02;
    }
    
    mapping(uint256 => Properties) metadata;

    function getMetadata(uint256 _id) external view returns (address owner, string memory hash, string memory make, string memory model, uint256 year, string memory vin, string memory engine, string memory colour, string memory plate, uint256 mileage, uint256 c02) {
        Properties memory data = metadata[_id];
        return (ownerOf(_id), data.hash, data.make, data.model, data.year, data.vin, data.engine, data.colour, data.plate, data.mileage, data.c02);
    }
    
    function mintAndSet(address _to, string memory _hash, string memory _make, string memory _model, uint256 _year, string memory _vin, string memory _engine, string memory _colour, string memory _plate, uint256 _mileage, uint256 _c02) public only(MINTER_ROLE) {
        require(vins[_vin] == 0, "VIN already exists");
        require(hashToTokenID[_vin] == 0, "Hash already exists");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        vins[_vin] = tokenId;
        hashToTokenID[_hash] = tokenId;

        metadata[tokenId].hash = _hash;
        metadata[tokenId].make = _make;
        metadata[tokenId].model = _model;
        metadata[tokenId].year = _year;
        metadata[tokenId].vin = _vin;
        metadata[tokenId].engine = _engine;
        metadata[tokenId].colour = _colour;
        metadata[tokenId].plate = _plate;
        metadata[tokenId].mileage = _mileage;
        metadata[tokenId].c02 = _c02;
        
        _safeMint(_to, tokenId);

        emit CarCreated(tokenId, _msgSender(), _hash, _make, _model, _year, _vin, _engine, _colour, _plate, _mileage, _c02);
    }
    
    /**
     * @dev Throws if called by any account other than the token or the contract owner.
     */
    modifier onlyCarOwner(uint256 _id) {
        require(ownerOf(_id) == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Invalid owner");
        _;
    }
    
    function updatePlate(uint256 _id, string memory _plate, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].plate = _plate;
        hashToTokenID[_hash] = _id;

        emit PlateUpdated(_id, _msgSender(), _plate, _hash);
    }
    
    function updateEngine(uint256 _id, string memory _engine, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].engine = _engine;
        hashToTokenID[_hash] = _id;

        emit EngineUpdated(_id, _msgSender(), _engine, _hash);
    }
    
    function updateMileage(uint256 _id, uint256 _mileage, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].mileage = _mileage;
        hashToTokenID[_hash] = _id;

        emit MileageUpdated(_id, _msgSender(), _mileage, _hash);
    }

    function updateMileageBatch(uint256[] memory _ids, uint256[] memory _mileages, string memory _hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_ids.length == _mileages.length, 'Invalid lists');

        for (uint i=0; i<_ids.length; i++) {
            metadata[_ids[i]].mileage = _mileages[i];
        }

        hashToTokenIDs[_hash] = _ids;

        emit MileageUpdatedBatch(_ids, _msgSender(), _mileages, _hash);
    }
    
    function updateColour(uint256 _id, string memory _colour, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].colour = _colour;
        hashToTokenID[_hash] = _id;

        emit ColourUpdated(_id, _msgSender(), _colour, _hash);
    }

    function updateC02(uint256 _id, uint256 _c02, string memory _hash) public onlyCarOwner(_id) {
        metadata[_id].c02 = _c02;
        hashToTokenID[_hash] = _id;

        emit C02Updated(_id, _msgSender(), _c02, _hash);
    }

    function updateC02Batch(uint256[] memory _ids, uint256[] memory _c02s, string memory _hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_ids.length == _c02s.length, 'Invalid lists');

        for (uint i=0; i<_ids.length; i++) {
            metadata[_ids[i]].c02 = _c02s[i];
        }

        hashToTokenIDs[_hash] = _ids;

        emit C02UpdatedBatch(_ids, _msgSender(), _c02s, _hash);
    }
    
    function stateEvent(uint256 _id, string memory _details, string memory _hash) public onlyCarOwner(_id) {
        hashToTokenID[_hash] = _id;

        emit EventStated(_id, _msgSender(), _details, _hash);
    }

    function burn(uint256 _id) public onlyCarOwner(_id) {
        _burn(_id);

        vins[metadata[_id].vin] = 0;

        emit CarBurnt(_id, _msgSender());
    }
}