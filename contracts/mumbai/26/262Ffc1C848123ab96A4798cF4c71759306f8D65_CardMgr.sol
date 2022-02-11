/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
interface IAddrLib { function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool); }
contract CardMgr {
    //using SWUtils for *;
    bytes32 constant internal SMName = "CardMgr";
    address constant internal AddrLib = 0xd6eEDE49893f4b361c0C5ac02D48EC686846A4b2;
    uint8 EpochsCount;
    uint8[17] CollectionsCount;
    uint16[17][100] CardsCount;
    struct Icard {
        bool valid;
        uint8 Epoch;
        uint8 Collection;
        uint8 Level;
        uint8 Rarity;
        uint8 Res1;
        uint8 Res2;
        uint8 EpocRes;
        uint8 Type;
        uint8 Class;
        uint8 Heart;
        uint8 Agi;
        uint8 Int;
        uint8 Mana;
        bytes32 Name;
        string Description;
        string Picture;
        address owner;              //Address of Modifier Wallet
        uint256 timestamp;          //Last Update
    }
    struct card {
        uint8 Epoch;
        uint8 Collection;
        uint16 Id;
        uint8 Level;
        uint8 Rarity;
        uint8 Res1;
        uint8 Res2;
        uint8 EpocRes;
        uint8 Type;
        uint8 Class;
        uint8 Heart;
        uint8 Agi;
        uint8 Int;
        uint8 Mana;
        bytes32 Name;
        string Description;
        string Picture;
    }
    //Icard[Epoch][Collection][CardId]
    Icard[17][100][1000] Cards;
    bytes32[5] internal _Rarities = [bytes32("Common"),bytes32("Uncommon"),bytes32("Rare"),bytes32("Epic"),bytes32("Legendary")];
    bytes32[6] internal _Types = [bytes32("Shibatar"),bytes32("Equip"),bytes32("Artifact"),bytes32("Special Action"),bytes32("Land"),bytes32("Building")];
    bytes32[6] internal _Classes = [bytes32("None"),bytes32("Fighter"),bytes32("Explorer"),bytes32("Scientist"),bytes32("Wizard"),bytes32("Fluid")];
    bytes32[4] internal _Stats = [bytes32("Heart"),bytes32("Agi"),bytes32("Int"),bytes32("Mana")];
    //bytes32[3] internal _Restrictions = [bytes32("None"),bytes32("Only Card:"),bytes32("Only")];
    event SecurityLog(bytes32 indexed SCMgr, bytes32 indexed Action, uint indexed timestamp, address sender);
    modifier modcanDo(bytes32 FuncName) {
        require(canDo(FuncName, msg.sender), "Not Authorized.");
        _;
    }
    modifier modEpoch(uint8 Epoch, bytes32 FuncName) {
        require(canDo(FuncName, msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        _;
    }
    modifier modEpochCollection(uint8 Epoch, uint8 Collection, bytes32 FuncName) {
        require(canDo(FuncName, msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        _;
    }
    modifier modEpochCollectionCard(uint8 Epoch, uint8 Collection, uint16 CardId) {
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        require(CardId < 1000, "CardId too big.");
        _;
    }
    modifier modId(uint8 Id, uint Id2) {
        require(Id < Id2, "Id too big.");
        _;
    }
    function canDo(bytes32 FuncName, address Sender) internal view returns (bool) {
        try IAddrLib(AddrLib).canDo(SMName, FuncName, Sender) returns (bool res) { return res; }
        catch { return false; }
    }
    function getEpoch(uint8 Epoch) external view virtual modEpoch(Epoch, "getEpoch") returns (Icard[17][100] memory) {
        return Cards[Epoch]; //ToDo: Verificare cosa restituisce. Credo sia l'array Sbagliato!
    }
    function getCollection(uint8 Epoch, uint8 Collection) external view virtual modEpochCollection(Epoch, Collection, "getCollection") returns (Icard[17] memory) {
        return Cards[Epoch][Collection]; //ToDo: Verificare cosa restituisce. Credo sia l'array Sbagliato!
    }
    function getCard(uint8 Epoch, uint8 Collection, uint16 CardId) external view virtual modEpochCollectionCard(Epoch, Collection, CardId) returns (card memory) {
        card memory crd;
        if(Cards[Epoch][Collection][CardId].valid == false) { return crd; }
        return toCard(Cards[Epoch][Collection][CardId], CardId);
    }
    function setCard(card memory Card) external virtual modEpochCollectionCard(Card.Epoch, Card.Collection, Card.Id) {  // returns (bool)
        require(canDo("setCard", msg.sender), "Not Authorized.");
        require(bytes.concat(Card.Name).length <= 30, "Name too long.");    //ToDo: Verificare se il Controllo Funziona
        //require(toBytes(Card.Name).length <= 30, "Name too long.");
        require(bytes(Card.Description).length < 256, "Description too long.");
        if(Card.Epoch >= EpochsCount) { EpochsCount = (Card.Epoch + 1) ;}
        if(Card.Collection >= CollectionsCount[Card.Epoch]) { CollectionsCount[Card.Epoch] = (Card.Collection + 1); }
        if(Card.Id >= CardsCount[Card.Epoch][Card.Collection]) { CardsCount[Card.Epoch][Card.Collection] = (Card.Id + 1); }
        Cards[Card.Epoch][Card.Collection][Card.Id] = toICard(Card, true);
        emit SecurityLog(SMName, "setCard", block.timestamp, msg.sender);
        //return true;
    }
    function Remove(uint8 Epoch, uint8 Collection, uint16 CardId) external virtual modcanDo("Remove") { // returns (bool)
        Cards[Epoch][Collection][CardId].valid = false;
        emit SecurityLog(SMName, "Remove", block.timestamp, msg.sender);
        //return true;
    }
    function getEpochsCount() external view virtual modcanDo("getEpochsCount") returns (uint8) { return EpochsCount; }
    function getCollectionsCount(uint8 Epoch) external view virtual modEpoch(Epoch, "getCollectionsCount") returns (uint8) { return CollectionsCount[Epoch]; }
    function getCardsCount(uint8 Epoch, uint8 Collection) external view virtual modEpochCollection(Epoch, Collection, "getCardsCount") returns (uint16) { return CardsCount[Epoch][Collection]; }
    function calcEpochsCount() external virtual modcanDo("calcEpochsCount") returns (uint8) {
        if(EpochsCount <= 0) { return EpochsCount; }
        uint8 Cc = (EpochsCount - 1);
        uint8 CcNew;
        for(uint8 i = Cc; i >= 0; i++) {
            if(CollectionsCount[Cc] == 0) { CcNew = Cc; }
        }
        if(CcNew != EpochsCount) { EpochsCount = CcNew; }
        emit SecurityLog(SMName, "calcEpochsCount", block.timestamp, msg.sender);
        return EpochsCount;
    }
    function calcCollectionsCount(uint8 Epoch) external virtual modEpoch(Epoch, "calcCollectionsCount") returns (uint8) {
        if(CollectionsCount[Epoch] <= 0) { return CollectionsCount[Epoch]; }
        uint8 Cc = (CollectionsCount[Epoch] - 1);
        uint8 CcNew;
        for(uint i = Cc; i >= 0; i++) {
            if(CardsCount[Epoch][Cc] == 0) { CcNew = Cc; }
        }
        if(CcNew != CollectionsCount[Epoch]) { CollectionsCount[Epoch] = CcNew; }
        emit SecurityLog(SMName, "calcCollectionsCount", block.timestamp, msg.sender);
        return CollectionsCount[Epoch];
    }
    function calcCardsCount(uint8 Epoch, uint8 Collection) external virtual modEpochCollection(Epoch, Collection, "calcCardsCount") returns (uint16) {
        if(CardsCount[Epoch][Collection] <= 0) { return CardsCount[Epoch][Collection]; }
        uint16 Cc = (CardsCount[Epoch][Collection] - 1);
        uint16 CcNew;
        for(uint16 i = Cc; i >= 0; i++) {
            if(Cards[Epoch][Collection][Cc].valid == false) { CcNew = Cc; }
        }
        if(CcNew != CardsCount[Epoch][Collection]) { CardsCount[Epoch][Collection] = CcNew; }
        emit SecurityLog(SMName, "calcCardsCount", block.timestamp, msg.sender);
        return CardsCount[Epoch][Collection];
    }
    function toICard(card memory crd, bool valid) internal view returns (Icard memory) {
        Icard memory Ic;
        Ic.Epoch = crd.Epoch;
        Ic.Collection = crd.Collection;
        Ic.Level = crd.Level;
        Ic.Rarity = crd.Rarity;
        Ic.Res1 = crd.Res1;
        Ic.Res2 = crd.Res2;
        Ic.EpocRes = crd.EpocRes;
        Ic.Type = crd.Type;
        Ic.Class = crd.Class;
        Ic.Heart = crd.Heart;
        Ic.Agi = crd.Agi;
        Ic.Int = crd.Int;
        Ic.Mana = crd.Mana;
        Ic.Name = crd.Name;
        Ic.Description = crd.Description;
        Ic.Picture = crd.Picture;
        Ic.valid = valid;
        Ic.owner = msg.sender;
        Ic.timestamp = block.timestamp;
        return Ic;
    }
    function toCard(Icard memory Ic, uint16 CardId) internal pure returns (card memory) {
        card memory crd;
        crd.Epoch = Ic.Epoch;
        crd.Collection = Ic.Collection;
        crd.Id = uint16(CardId);
        crd.Level = Ic.Level;
        crd.Rarity = Ic.Rarity;
        crd.Res1 = Ic.Res1;
        crd.Res2 = Ic.Res2;
        crd.EpocRes = Ic.EpocRes;
        crd.Type = Ic.Type;
        crd.Class = Ic.Class;
        crd.Heart = Ic.Heart;
        crd.Agi = Ic.Agi;
        crd.Int = Ic.Int;
        crd.Mana = Ic.Mana;
        crd.Name = Ic.Name;
        crd.Picture = Ic.Picture;
        crd.Description = Ic.Description;
        return crd;
    }
    function Rarity_Des(uint8 RarityId) external view modId(RarityId, _Rarities.length) returns (bytes32) { return _Rarities[RarityId]; }
    function Type_Des(uint8 TypeId) external view modId(TypeId, _Types.length) returns (bytes32) { return _Types[TypeId]; }
    function Class_Des(uint8 ClassId) external view modId(ClassId, _Classes.length) returns (bytes32) { return _Classes[ClassId]; }
    // function Stat_Des(uint8 StatId) external view modId(StatId, _Stats.length) returns (bytes32) { return _Stats[StatId]; }
    function EpocRes_Des(uint8 EpocResId) public pure returns (bytes memory) { return EpocResId == 0 ? bytes.concat("All Epoch") : bytes.concat("Only Epoch ", toBytes(EpocResId) ); }
    function Restriction(uint8 Epoch, uint8 Collection, uint16 CardId) public view virtual modEpochCollectionCard(Epoch, Collection, CardId) returns (bytes memory) {
        Icard memory cds = Cards[Epoch][Collection][CardId];
        if (cds.Res1 == 0) { return bytes.concat("None"); }
        else if (cds.Res1 == 1) { return bytes.concat("Only Card:", " ", toBytes(cds.Res2) ); }
        else if (cds.Res1 == 2) { return bytes.concat("Only", " Rarity: '", _Rarities[cds.Res2], "'"); }
        else if (cds.Res1 == 3) { return bytes.concat("Only", " Type: '", _Types[cds.Res2], "'"); }
        else if (cds.Res1 == 4) { return bytes.concat("Only", " Class: '", _Classes[cds.Res2], "'"); }
        else if (cds.Res1 > 4 && cds.Res1 < 9) { return bytes.concat("Only", " ", _Stats[(cds.Res1 - 5)], " > ", toBytes(cds.Res2) ); }
        else if (cds.Res1 > 8 && cds.Res1 < 13) { return bytes.concat("Only", " ", _Stats[(cds.Res1 - 9)], " > ", toBytes(cds.Res2) ); }
        else { return bytes.concat("None"); } //Unhandled value
    }
    function toJson_Des(uint8 Epoch, uint8 Collection, uint16 CardId) external view virtual modEpochCollectionCard(Epoch, Collection, CardId) returns (string memory) {
        Icard memory cds = Cards[Epoch][Collection][CardId];
        bytes memory T1 = bytes.concat('"Epoch":', toBytes(cds.Epoch), ', "Collection":', toBytes(cds.Collection), ', "Level":', toBytes(cds.Level), ', "Id":', toBytes(CardId), ', "Rarity":"', _Rarities[cds.Rarity], '", "Restriction":"', Restriction(Epoch, Collection, CardId), '", "Epoc Restriction":"', EpocRes_Des(cds.EpocRes), '", "Type":"', _Types[cds.Type], '", "Class":"', _Classes[cds.Class], '"');
        bytes memory T2 = bytes.concat('"Heart":', toBytes(cds.Heart), ', "Agi":', toBytes(cds.Agi), ', "Int":', toBytes(cds.Int), ', "Mana":', toBytes(cds.Mana), '", "Name":', cds.Name, '", "Description":', bytes(cds.Description), '", "Picture":', bytes(cds.Picture), '"');
        return string(bytes.concat('{', bytes(T1), ', ', bytes(T2), '}'));
    }
    function toJson(uint8 Epoch, uint8 Collection, uint16 CardId) external view virtual modEpochCollectionCard(Epoch, Collection, CardId) returns (string memory) {
        Icard memory Ic = Cards[Epoch][Collection][CardId];
        bytes memory T1 = bytes.concat('"Epoch":', toBytes(Ic.Epoch), ', "Collection":', toBytes(Ic.Collection), ', "Level":', toBytes(Ic.Level), ', "Id":', toBytes(CardId), ', "Rarity":', toBytes(Ic.Rarity), ', "Res1":', toBytes(Ic.Res1), ', "Res2":', toBytes(Ic.Res2), ', "Epoc Restriction":', toBytes(Ic.EpocRes), ', "Type":', toBytes(Ic.Type), ', "Class":', toBytes(Ic.Class), '');
        bytes memory T2 = bytes.concat('"Heart":', toBytes(Ic.Heart), ', "Agi":', toBytes(Ic.Agi), ', "Int":', toBytes(Ic.Int), ', "Mana":', toBytes(Ic.Mana),'", "Name":', Ic.Name, '", "Description":', bytes(Ic.Description), '", "Picture":', bytes(Ic.Picture), '"');
        return string(bytes.concat('{', T1, ', ', T2, '}'));
    }
    // function toBytes(uint256 value) internal pure returns (bytes memory) {
    //     if (value == 0) { return "0"; }
    //     uint256 temp = value;
    //     uint256 digits;
    //     while (temp != 0) {
    //         digits++;
    //         temp /= 10;
    //     }
    //     bytes memory buffer = new bytes(digits);
    //     while (value != 0) {
    //         digits -= 1;
    //         buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
    //         value /= 10;
    //     }
    //     return buffer;
    // }
    function toBytes(uint x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}
//[Funzioni Utente x ShibaWorldsMgr.sol]
//getCard
//toJson
//toJson_Des