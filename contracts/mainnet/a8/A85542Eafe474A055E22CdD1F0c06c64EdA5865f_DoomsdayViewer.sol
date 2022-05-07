//SPDX-License-Identifier: A hedgehog wrote this contract
pragma solidity ^0.8.0;
import "./Doomsday.sol";
import "./survivors/IDoomsdaySurvivors.sol";

contract DoomsdayViewer{

    Doomsday __doomsday;
    IDoomsdayCollectibles __collectibles;
    IDoomsdaySurvivors __survivors;

    uint constant IMPACT_BLOCK_INTERVAL = 255;

    uint SALE_TIME = 14 days;
    uint EARLY_ACCESS_TIME = 2 days;

    constructor(address _doomsday, address _collectibles, address _survivors){
        __doomsday =      Doomsday(_doomsday);
        __collectibles =  IDoomsdayCollectibles(_collectibles);
        __survivors =     IDoomsdaySurvivors(_survivors);
    }

    function isEarlyAccess() public view returns(bool){
        return __doomsday.stage() == Doomsday.Stage.PreApocalypse && block.timestamp < __doomsday.startTime() + EARLY_ACCESS_TIME;
    }

    function nextImpactIn() public view returns(uint){
        uint eliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) - 1;

        return IMPACT_BLOCK_INTERVAL - ((block.number - 1) - eliminationBlock);
    }


    function contractState() public view returns(
        uint _totalSupply,
        uint _destroyed,
        uint _evacuatedFunds,
        Doomsday.Stage _stage,
        uint _currentPrize,
        bool _isEarlyAccess,
        uint _countdown,
        uint _nextImpactIn,
        bool _survivorsActive,
        uint _survivorsSupply,
        uint _blockNumber
    ){
        _survivorsActive = __survivors.saleActive();
        _stage = __doomsday.stage();

        _isEarlyAccess = isEarlyAccess();

        if(_isEarlyAccess){
            _countdown = __doomsday.startTime() + EARLY_ACCESS_TIME - block.timestamp;
        }else if(_stage == Doomsday.Stage.PreApocalypse){
            _countdown = __doomsday.startTime() + SALE_TIME - block.timestamp;
        }

        return (
            __doomsday.totalSupply(),
            __doomsday.destroyed(),
            __doomsday.evacuatedFunds(),
            _stage,
            __doomsday.currentPrize(),
            _isEarlyAccess,
            _countdown,
            nextImpactIn(),
            _survivorsActive,
            __survivors.totalSupply(),
            block.number
        );
    }

    function vulnerableCities(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = __doomsday.totalSupply();
        uint _maxId = _totalSupply + __doomsday.destroyed();
        if(_totalSupply == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }
        uint[] memory _tokenIds = new uint256[](sampleSize);
        uint _tokenId = startId;
        uint j = 0;
        for(uint i = 0; i < sampleSize; i++){
            try __doomsday.ownerOf(_tokenId) returns (address _owner) {
                _owner;
                try __doomsday.isVulnerable(_tokenId) returns (bool _isVulnerable) {
                    if(_isVulnerable){
                        _tokenIds[j] = _tokenId;
                        j++;
                    }
                } catch {

                }
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }

    function cityData(uint startId, uint limit) public view returns(uint[] memory _tokenIds, uint[] memory _cityIds, uint[] memory _reinforcement, uint[] memory _damage, uint blockNumber ){
        uint _totalSupply = __doomsday.totalSupply();
        uint _maxId = _totalSupply + __doomsday.destroyed();
        if(_totalSupply == 0){
            uint[] memory _none;
            return (_none,_none,_none,_none, block.number);
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        _tokenIds     = new uint256[](sampleSize);
        _cityIds      = new uint256[](sampleSize);
        _reinforcement = new uint256[](sampleSize);
        _damage        = new uint256[](sampleSize);


        uint _tokenId = startId;
        uint8 reinforcement; uint8 damage; bytes32 lastImpact;

        uint j;

        for(uint i = 0; i < sampleSize; i++){
            try __doomsday.ownerOf(_tokenId) returns (address owner) {
                owner;
                _tokenIds[j] = _tokenId;

                (reinforcement, damage, lastImpact) = __doomsday.getStructuralData(_tokenId);

                _cityIds[j]         = __doomsday.tokenToCity(_tokenId);
                _reinforcement[j]    = reinforcement;
                _damage[j]           = damage;

                j++;
            } catch {

            }
            _tokenId++;
        }
        return (_tokenIds, _cityIds, _reinforcement, _damage, block.number);
    }

    function bunker(uint16 _cityId) public view returns(uint _tokenId, address _owner, uint8 _reinforcement, uint8 _damage, bool _isVulnerable, bool _isUninhabited){
        _tokenId = __doomsday.cityToToken(_cityId);
        _isUninhabited = __doomsday.isUninhabited(_cityId);

        if(_tokenId == 0){
            return (0,address(0),uint8(0),uint8(0),false,_isUninhabited);
        }else{
            try __doomsday.ownerOf(_tokenId) returns ( address __owner) {
                _owner = __owner;
            } catch {

            }
            bytes32 _lastImpact;
            (_reinforcement, _damage, _lastImpact) = __doomsday.getStructuralData(_tokenId);
            _isVulnerable = __doomsday.isVulnerable(_tokenId);

            return (_tokenId,_owner,_reinforcement, _damage,_isVulnerable,false);
        }
    }

    function myCities(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = __doomsday.totalSupply();
        uint _myBalance = __doomsday.balanceOf(msg.sender);
        uint _maxId = _totalSupply + __doomsday.destroyed();
        if(_totalSupply == 0 || _myBalance == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds = new uint256[](sampleSize);

        uint _tokenId = startId;
        uint found = 0;
        for(uint i = 0; i < sampleSize; i++){
            try __doomsday.ownerOf(_tokenId) returns (address owner) {
                if(msg.sender == owner){
                    _tokenIds[found++] = _tokenId;
                }
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }

    function collectiblesData(uint startId, uint limit) public view returns(uint[] memory _tokenIds, uint[] memory _cityIds, uint blockNumber ){
        uint _totalSupply = __collectibles.totalSupply();
        uint _maxId = __collectibles.mintCount();

        if(_totalSupply == 0){
            uint[] memory _none;
            return (_none,_none, block.number);
        }
        require(startId <= _maxId,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        _tokenIds     = new uint256[](sampleSize);
        _cityIds      = new uint256[](sampleSize);

        uint _tokenId = startId;

        uint j;

        for(uint i = 0; i < sampleSize; i++){
            try __collectibles.ownerOf(_tokenId) returns (address owner) {
                owner;
                _tokenIds[j] = _tokenId;
                _cityIds[j] =__collectibles.cityIds(_tokenId);

                j++;
            } catch {

            }
            _tokenId++;
        }
        return (_tokenIds, _cityIds, block.number);
    }

    function survivorsData(uint startId, uint limit) public view returns(uint[] memory _survivorIds, bool[] memory _withdrawn, uint[] memory _locations, uint blockNumber ){
        uint _totalSupply = __survivors.totalSupply();
        uint _maxId = _totalSupply;
        if(_totalSupply == 0){
            uint[] memory _none;
            bool[] memory _bNone;
            return (_none,_bNone,_none, block.number);
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        _survivorIds    = new uint256[](sampleSize);
        _withdrawn      = new bool[](sampleSize);
        _locations      = new uint256[](sampleSize);


        uint _tokenId = startId;
        for(uint i = 0; i < sampleSize; i++){
            _survivorIds[i] = __survivors.tokenToSurvivor(_tokenId);
            _withdrawn[i]   = __survivors.withdrawn(_tokenId);
            _locations[i]   = __survivors.tokenToBunker(_tokenId);

            _tokenId++;
        }
        return (_survivorIds, _withdrawn, _locations, block.number);
    }

    function mySurvivors(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = __survivors.totalSupply();
        uint _myBalance = __survivors.balanceOf(msg.sender);
        uint _maxId = _totalSupply;

        if(_totalSupply == 0 || _myBalance == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds = new uint256[](sampleSize);

        uint _tokenId = startId;
        uint found = 0;
        for(uint i = 0; i < sampleSize; i++){
            address _owner = __survivors.ownerOf(_tokenId);
            if(msg.sender == _owner){
                _tokenIds[found++] = _tokenId;
            }
            _tokenId++;
        }
        return _tokenIds;
    }
}

//SPDX-License-Identifier: Cool kids only

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721TokenReceiver.sol";

import "./collectibles/IDoomsdayCollectibles.sol";
import "./access/DoomsdayAccess.sol";
import "./components/DoomsdayImpacts.sol";

contract Doomsday is IERC721, IERC165, IERC721Metadata{


    constructor(bytes32 _cityRoot, address _access, address _impacts){
        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        //        supportedInterfaces[0x780e9d63] = true; //ERC721Enumerable
        supportedInterfaces[0x01ffc9a7] = true; //ERC165

        owner = msg.sender;
        cityRoot = _cityRoot;
        access = _access;
        impacts = _impacts;
    }

    address public owner;
    address collectibles;
    address access;

    //////===721 Implementation
    mapping(address => uint256) internal balances;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) internal authorised;

    uint16[] tokenIndexToCity;  //Array of all tokens [cityId,cityId,...]
    mapping(uint256 => address) owners;  //Mapping of owners
    //  keep owners mapping
    //  use tokenIndexToCity for isValidToken

    //    METADATA VARS
    string private __name = "Doomsday NFT (Season 2)";
    string private __symbol = "BUNKER2";
    bytes private __uriBase;//
    bytes private __uriSuffix;//

    //  Game vars
    uint constant MAX_CITIES = 38611;       //from table

    int64 constant MAP_WIDTH         = 4320000;   //map units
    int64 constant MAP_HEIGHT        = 2588795;   //map units

    uint constant MINT_COST = 60 ether;

    uint constant MINT_PERCENT_WINNER       = 85;
    uint constant MINT_PERCENT_CALLER       = 1;
    uint constant MINT_PERCENT_CREATOR      = 14;

    uint constant REINFORCE_PERCENT_WINNER  = 90;
    uint constant REINFORCE_PERCENT_CREATOR = 10;

    uint public startTime;
    uint SALE_TIME = 14 days;
    uint EARLY_ACCESS_TIME = 2 days;


    mapping(uint16 => uint) public cityToToken;
    mapping(uint16 => int64[2]) coordinates;
    bytes32 cityRoot;
    bytes32 accessRoot;
    address impacts;

    event Inhabit(uint16 indexed _cityId, uint256 indexed _tokenId);
    event Reinforce(uint256 indexed _tokenId);
    event Impact(uint256 indexed _tokenId);

    mapping(uint => bytes32) structuralData;
    mapping(address => uint) lastConfirmedHit;

    function getStructuralData(uint _tokenId) public view returns (uint8 reinforcement, uint8 damage, bytes32 lastImpact){
        bytes32 _data = structuralData[_tokenId];

        reinforcement = uint8(uint(((_data << 248) >> 248)));
        damage = uint8(uint(((_data << 240) >> 240) >> 8));
        lastImpact = (_data >> 16);

        return (reinforcement, damage, lastImpact);
    }
    function setStructuralData(uint _tokenId, uint8 reinforcement, uint8 damage, bytes32 lastImpact) internal{
        bytes32 _reinforcement = bytes32(uint(reinforcement));
        bytes32 _damage = bytes32(uint(damage)) << 8;
        bytes32 _lastImpact = encodeImpact(lastImpact) << 16;

        structuralData[_tokenId] = _reinforcement ^ _damage ^ _lastImpact;
    }
    function encodeImpact(bytes32 _impact) internal pure returns(bytes32){
        return (_impact << 16) >> 16;
    }


    uint public reinforcements;
    uint public destroyed;
    uint public evacuatedFunds;
    uint ownerWithdrawn;
    bool winnerWithdrawn;

    function tokenToCity(uint _tokenId) public view returns(uint16){
        return tokenIndexToCity[_tokenId - 1];
    }


    function startPreApocalypse() public{
        require(msg.sender == owner,"owner");

        require(startTime == 0,"started");
        startTime = block.timestamp;
    }
    enum Stage {Initial,PreApocalypse,Apocalypse,PostApocalypse}
    function stage() public view returns(Stage){
        if(startTime == 0){
            return Stage.Initial;
        }else if(block.timestamp < startTime + SALE_TIME && tokenIndexToCity.length < MAX_CITIES){
            return Stage.PreApocalypse;
        }else if(destroyed < tokenIndexToCity.length - 1){
            return Stage.Apocalypse;
        }else{
            return Stage.PostApocalypse;
        }
    }

    function inhabit(uint16 _cityId, int64[2] calldata _coordinates, bytes32[] memory proof, bytes32[] memory accessProof) public payable{

        if(msg.sender != owner){
            require(stage() == Stage.PreApocalypse,"stage");
            if(block.timestamp < startTime + EARLY_ACCESS_TIME){
                //First day is insiders list
                require(DoomsdayAccess(access).hasAccess(accessProof,msg.sender),"permission");
            }
        }else{
            require(stage() == Stage.Initial || stage() == Stage.PreApocalypse,"stage");
            //Giveaways
        }



        bytes32 leaf = keccak256(abi.encodePacked(_cityId,_coordinates[0],_coordinates[1]));

        require(MerkleProof.verify(proof, cityRoot, leaf),"proof");

        require(cityToToken[_cityId] == 0 && coordinates[_cityId][0] == 0 && coordinates[_cityId][1] == 0,"inhabited");

        require(
            _coordinates[0] ** 2 <= (MAP_WIDTH/2) ** 2 &&

            _coordinates[1] ** 2 <= (MAP_HEIGHT/2) ** 2 &&

            !(_coordinates[0] == 0 && _coordinates[1] == 0),
            "position"
        );  //Not strictly necessary but proves the whitelist hasnt been fucked with


        require(msg.value == MINT_COST,"cost");

        coordinates[_cityId] = _coordinates;

        tokenIndexToCity.push(_cityId);

        uint _tokenId = tokenIndexToCity.length;

        balances[msg.sender]++;
        owners[_tokenId] = msg.sender;
        cityToToken[_cityId] = _tokenId;

        emit Inhabit(_cityId, _tokenId);
        emit Transfer(address(0),msg.sender,_tokenId);
    }

    function isUninhabited(uint16 _cityId) public view returns(bool){
        return coordinates[_cityId][0] == 0 && coordinates[_cityId][1] == 0;
    }

    function reinforce(uint _tokenId) public payable{

        Stage _stage = stage();

        require(_stage == Stage.PreApocalypse || _stage == Stage.Apocalypse,"stage");

        require(ownerOf(_tokenId) == msg.sender,"owner");

        //Covered by ownerOf
//        require(isValidToken(_tokenId),"invalid");

        (uint8 _reinforcement, uint8 _damage, bytes32 _lastImpact) = getStructuralData(_tokenId);

        if(_stage == Stage.Apocalypse){
            require(!checkVulnerable(_tokenId,_lastImpact),"vulnerable");
        }

        //   covered by isValidToken
            //require(_damage <= _reinforcement,"eliminated" );

        require(msg.value == (2 ** _reinforcement) *  MINT_COST,"cost");


        setStructuralData(_tokenId,_reinforcement+1,_damage,_lastImpact);

        reinforcements += msg.value - (MINT_COST * MINT_PERCENT_CALLER / 100);

        emit Reinforce(_tokenId);
    }
    function evacuate(uint _tokenId) public{
        Stage _stage = stage();
        require(_stage == Stage.PreApocalypse || _stage == Stage.Apocalypse,"stage");

        require(ownerOf(_tokenId) == msg.sender,"owner");

        // covered by isValidToken in ownerOf
//        require(_damage <= _reinforcement,"eliminated" );

        if(_stage == Stage.Apocalypse){
            require(!isVulnerable(_tokenId),"vulnerable");
        }

        uint cityCount = tokenIndexToCity.length;


        uint fromPool =
            //Winner fee from mints less evacuated funds
                ((MINT_COST * cityCount * MINT_PERCENT_WINNER / 100 - evacuatedFunds)
            //Divided by remaining tokens
                / totalSupply())
            //Multiplied by (3+(0.9 * (destroyed / cities)) /4
                * (10000000000 + ( 29000000000 * destroyed / cityCount  ))  / 40000000000;


        //Also give them the admin fee
        uint toWithdraw = fromPool + getEvacuationRebate(_tokenId);

        balances[owners[_tokenId]]--;
        delete cityToToken[tokenToCity(_tokenId)];
        destroyed++;

        //Doesnt' include admin fees in evacedFunds
        evacuatedFunds += fromPool;

        emit Transfer(owners[_tokenId],address(0),_tokenId);

        if(collectibles != address(0)){
            IDoomsdayCollectibles(collectibles).mint(owners[_tokenId],tokenToCity(_tokenId));
        }

        payable(msg.sender).transfer(toWithdraw);
    }


    function getEvacuationRebate(uint _tokenId) internal view returns(uint) {
        (uint8 _reinforcement, uint8 _damage, bytes32 _lastImpact) = getStructuralData(_tokenId);
        _lastImpact;
        return MINT_COST * (1 + _reinforcement - _damage) *  MINT_PERCENT_CALLER / 100;
    }

    function confirmHit(uint _tokenId) public{
        require(stage() == Stage.Apocalypse,"stage");
        require(isValidToken(_tokenId),"invalid");

        require(msg.sender == tx.origin,"no contracts");

        require(lastConfirmedHit[msg.sender] != block.number,"frequency");
        lastConfirmedHit[msg.sender] = block.number;

        (uint8 _reinforcement, uint8 _damage, bytes32 _lastImpact) = getStructuralData(_tokenId);

        //  covered by isValidToken
        //      require(_damage <= _reinforcement,"eliminated" );

        require(checkVulnerable(_tokenId,_lastImpact),"vulnerable");

        (int64[2] memory _coordinates, int64 _radius, bytes32 _impactId) = DoomsdayImpacts(impacts).currentImpact();
        _coordinates;_radius;

        _impactId = encodeImpact(_impactId);




        emit Impact(_tokenId);


        if(_damage < _reinforcement){
            _damage++;
            setStructuralData(_tokenId,_reinforcement,_damage,_impactId);
        }else{
            balances[owners[_tokenId]]--;
            delete cityToToken[tokenToCity(_tokenId)];
            destroyed++;

            emit Transfer(owners[_tokenId],address(0),_tokenId);

            if(collectibles != address(0)){
                IDoomsdayCollectibles(collectibles).mint(owners[_tokenId],tokenToCity(_tokenId));
            }
        }

        payable(msg.sender).transfer(MINT_COST * MINT_PERCENT_CALLER / 100);
    }


    function winnerWithdraw(uint _winnerTokenId) public{
        require(stage() == Stage.PostApocalypse,"stage");
        require(isValidToken(_winnerTokenId),"invalid");

        // Implicitly makes sure its the right token since all others don't exist
        require(msg.sender == ownerOf(_winnerTokenId),"ownerOf");
        require(!winnerWithdrawn,"withdrawn");

        winnerWithdrawn = true;

        uint toWithdraw = winnerPrize(_winnerTokenId);
        if(toWithdraw > address(this).balance){
            //Catch rounding errors
            toWithdraw = address(this).balance;
        }

        payable(msg.sender).transfer(toWithdraw);
    }

    function ownerWithdraw() public{
        require(msg.sender == owner,"owner");

        uint cityCount = tokenIndexToCity.length;

        // Dev and creator portion of all mint fees collected
        uint toWithdraw = MINT_COST * cityCount * (MINT_PERCENT_CREATOR) / 100
            //plus reinforcement for creator
            + reinforcements * REINFORCE_PERCENT_CREATOR / 100
            //less what has already been withdrawn;
            - ownerWithdrawn;

        require(toWithdraw > 0,"empty");

        if(toWithdraw > address(this).balance){
            //Catch rounding errors
            toWithdraw = address(this).balance;
        }
        ownerWithdrawn += toWithdraw;

        payable(msg.sender).transfer(toWithdraw);
    }




    function checkVulnerable(uint _tokenId, bytes32 _lastImpact) internal view returns(bool){
        (int64[2] memory _coordinates, int64 _radius, bytes32 _impactId) = DoomsdayImpacts(impacts).currentImpact();

        if(_lastImpact == encodeImpact(_impactId)) return false;

        uint16 _cityId = tokenToCity(_tokenId);

        int64 dx = coordinates[_cityId][0] - _coordinates[0];
        int64 dy = coordinates[_cityId][1] - _coordinates[1];

        return (dx**2 + dy**2 < _radius**2) ||
                ((dx + MAP_WIDTH )**2 + dy**2 < _radius**2) ||
                ((dx - MAP_WIDTH )**2 + dy**2 < _radius**2);
    }

    function isVulnerable(uint _tokenId) public  view returns(bool){

        (uint8 _reinforcement, uint8 _damage, bytes32 _lastImpact) = getStructuralData(_tokenId);
        _reinforcement;_damage;

        return checkVulnerable(_tokenId,_lastImpact);
    }


    function currentPrize() public view returns(uint){
        uint cityCount = tokenIndexToCity.length;
            // 85% of all mint fees collected
            return MINT_COST * cityCount * MINT_PERCENT_WINNER / 100
            //minus fees removed
            - evacuatedFunds
            //plus reinforcement * 90%
            + reinforcements * REINFORCE_PERCENT_WINNER / 100;
    }

    function winnerPrize(uint _tokenId) public view returns(uint){
        return currentPrize() + getEvacuationRebate(_tokenId);
    }



    ///ERC 721:
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        if(_tokenId == 0) return false;
        return cityToToken[tokenToCity(_tokenId)] != 0;
    }


    function balanceOf(address _owner) external override view returns (uint256){
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public override view returns(address){
        require(isValidToken(_tokenId),"invalid");
        return owners[_tokenId];
    }


    function approve(address _approved, uint256 _tokenId) external override {
        address _owner = ownerOf(_tokenId);
        require( _owner == msg.sender                    //Require Sender Owns Token
            || authorised[_owner][msg.sender]                //  or is approved for all.
        ,"permission");
        emit Approval(_owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) external override view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return allowance[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return authorised[_owner][_operator];
    }


    function setApprovalForAll(address _operator, bool _approved) external override {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public override {

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = ownerOf(_tokenId);

        require ( _owner == msg.sender             //Require sender owns token
        //Doing the two below manually instead of referring to the external methods saves gas
        || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[_owner][msg.sender]          //or is approved for all
        ,"permission");
        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        if(stage() == Stage.Apocalypse){
            require(!isVulnerable(_tokenId),"vulnerable");
        }

        emit Transfer(_from, _to, _tokenId);


        owners[_tokenId] =_to;

        balances[_from]--;
        balances[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


    // METADATA FUNCTIONS
    function tokenURI(uint256 _tokenId) public override view returns (string memory){
        //Note: changed visibility to public
        require(isValidToken(_tokenId),'tokenId');

        uint _cityId = tokenToCity(_tokenId);

        uint _i = _cityId;
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }



        return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }



    function name() external override view returns (string memory _name){
        return __name;
    }

    function symbol() external override view returns (string memory _symbol){
        return __symbol;
    }


    // ENUMERABLE FUNCTIONS
    function totalSupply() public view returns (uint256){
        return tokenIndexToCity.length - destroyed;
    }
    // End 721 Implementation

    ///////===165 Implementation
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external override view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    ///==End 165


    //Admin
    function setOwner(address newOwner) public{
        require(msg.sender == owner,"owner");
        owner = newOwner;
    }

    function setExternalData(string calldata _newBase, string calldata _newSuffix, address _collectibles) public{
        require(msg.sender == owner,"owner");

        __uriBase   = bytes(_newBase);
        __uriSuffix = bytes(_newSuffix);
        collectibles = _collectibles;
    }
}

// SPDX-License-Identifier: Shame

pragma solidity ^0.8.4;

interface IDoomsdaySurvivors {
    function balanceOf(address _owner) external view returns(uint);
    function ownerOf(uint _tokenId) external view returns(address);
    function saleActive() external view returns(bool);
    function totalSupply() external view returns(uint);

    function tokenToSurvivor(uint _tokenId) external view returns(uint);
    function tokenToBunker(uint _tokenId) external view returns(uint);
    function withdrawn(uint _tokenId) external view returns(bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Mustard

pragma solidity ^0.8.4;

interface IDoomsdayCollectibles {
    function mint(address _to, uint cityId) external;

    function totalSupply() external view returns (uint256);
    function mintCount() external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
    function cityIds(uint256 _tokenId) external view returns (uint);

}

//SPDX-License-Identifier: You smell
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../survivors/IDoomsdaySurvivors.sol";

contract DoomsdayAccess is Ownable{

    bytes32 merkleRoot;

    IDoomsdaySurvivors survivors;

    constructor(bytes32 _merkleRoot, address _survivors){
        merkleRoot = _merkleRoot;
        survivors = IDoomsdaySurvivors(_survivors);
    }

    function hasAccess(bytes32[] memory proof, address _address)  public view returns(bool){
        if(survivors.balanceOf(_address) > 0) return true;
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(proof,merkleRoot,leaf);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner{
        merkleRoot = _merkleRoot;
    }
    function updateSurvivors(address _survivors) public onlyOwner{
        survivors = IDoomsdaySurvivors(_survivors);
    }
}

//SPDX-License-Identifier: Cool kids only

import "../survivors/IDoomsday.sol";

pragma solidity ^0.8.4;

contract DoomsdayImpacts{

    int64 constant MAP_WIDTH         = 4320000;   //map units
    int64 constant MAP_HEIGHT        = 2588795;   //map units
    int64 constant BASE_BLAST_RADIUS = 80000;   //map units

    uint constant IMPACT_BLOCK_INTERVAL = 255;

    address doomsday;
    constructor(){
        doomsday = msg.sender;
    }

    function currentImpact() public view returns (int64[2] memory _coordinates, int64 _radius, bytes32 impactId){
        uint eliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) + 1;
        int hash = int(uint(blockhash(eliminationBlock))%uint(type(int).max) );

        uint _totalSupply = IDoomsday(doomsday).totalSupply();

        //Min radius is half map height divided by num
        int o = MAP_HEIGHT/2/int(_totalSupply+1);

        //Limited in smallness to about 3% of map height
        if(o < BASE_BLAST_RADIUS){
            o = BASE_BLAST_RADIUS;
        }
        //Max radius is twice this
        _coordinates[0] = int64(hash%MAP_WIDTH - MAP_WIDTH/2);
        _coordinates[1] = int64((hash/MAP_WIDTH)%MAP_HEIGHT - MAP_HEIGHT/2);
        _radius = int64((hash/MAP_WIDTH/MAP_HEIGHT)%o + o);

        return(_coordinates,_radius, blockhash(eliminationBlock));
    }

    function setDoomsday(address _doomsday) public{
        require(msg.sender == doomsday,"sender");
        doomsday = _doomsday;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: Fear

pragma solidity ^0.8.4;

interface IDoomsday {
    enum Stage {Initial,PreApocalypse,Apocalypse,PostApocalypse}
    function stage() external view returns(Stage);
    function totalSupply() external view returns (uint256);
    function isVulnerable(uint _tokenId) external view returns(bool);

    function ownerOf(uint256 _tokenId) external view returns(address);

    function confirmHit(uint _tokenId) external;
}