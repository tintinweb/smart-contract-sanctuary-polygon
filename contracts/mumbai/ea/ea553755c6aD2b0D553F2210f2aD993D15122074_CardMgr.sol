/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

pragma solidity >=0.8.11 <0.9.0;
// SPDX-License-Identifier: No License
interface IAddrLib { function canDo(string memory ContractName, string memory FuncName, address Sender) external view returns (bool); }
contract CardMgr {
    //using SWUtils for *;
    string constant internal SMName = "CardMgr";
    address AddrLib = 0x00ac05E240A73B249171bF0a234EB84C72c4d218;
    uint EpochsCount;
    uint[17] CollectionsCount;
    uint[17][100] CardsCount;
    //mapping(string => card) internal AddrDB;
    struct Icard {
        bool valid;
        uint Epoch;
        uint Collection;
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
        string Name;
        string Description;
        address owner;              //Address of Modifier Wallet
        uint256 timestamp;          //Last Update
    }
    struct card {
        uint Epoch;
        uint Collection;
        uint Id;
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
        string Name;
        string Description;
    }
    //Icard[Epoch][Collection][CardId]
    Icard[17][100][1000] Cards;
    bool[2][2] flags;
    string[5] _Rarities = ["Common","Uncommon","Rare","Epic","Legendary"];
    string[6] _Types = ["Shibatar","Equip","Artifact","Special Action","Land","Building"];
    string[6] _Classes = ["None","Fighter","Explorer","Scientist","Wizard","Fluid"];
    string[4] _Stats = ["Heart","Agi","Int","Mana"];
    function getEpoch(uint Epoch) external view returns (Icard[17][100] memory) {
        require(canDo("getEpoch", msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        return Cards[Epoch]; //ToDo: Verificare cosa restituisce. Credo sia l'array Sbagliato!
    }
    function getCollection(uint Epoch, uint Collection) external view returns (Icard[17] memory) {
        require(canDo("getCollection", msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        return Cards[Epoch][Collection]; //ToDo: Verificare cosa restituisce. Credo sia l'array Sbagliato!
    }
    function getCard(uint Epoch, uint Collection, uint CardId) external view returns (card memory) {
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        require(CardId < 1000, "CardId too big.");
        card memory crd;
        if(Cards[Epoch][Collection][CardId].valid == false) { return crd; }
        return toCard(Cards[Epoch][Collection][CardId], CardId);
    }
    // function setCard(uint Epoch, uint Collection, uint CardId, uint8 Level, uint8 Rarity, uint8 Res1, uint8 Res2, uint8 EpocRes, uint8 Type, uint8 Class, uint8 Heart, uint8 Agi, uint8 Int, uint8 Mana, string memory Name, string memory Description) external {    //ToDo: ...
    //     card memory crd;
    //     crd.Epoch = Epoch;
    //     crd.Collection = Collection;
    //     crd.Id = CardId;
    //     crd.Level = Level;
    //     crd.Rarity = Rarity;
    //     crd.Res1 = Res1;
    //     crd.Res2 = Res2;
    //     crd.EpocRes = EpocRes;
    //     crd.Type = Type;
    //     crd.Class = Class;
    //     crd.Heart = Heart;
    //     crd.Agi = Agi;
    //     crd.Int = Int;
    //     crd.Mana = Mana;
    //     crd.Name = Name;
    //     crd.Description = Description;
    //     setCard(crd);
    // }
    function setCard(card memory Card) internal {
        require(canDo("setCard", msg.sender), "Not Authorized.");
        require(Card.Epoch < 17, "Epoch too big.");
        require(Card.Collection < 100, "Collection too big.");
        require(Card.Id < 1000, "Id too big.");
        require(bytes(Card.Name).length < 256, "Name too long.");
        require(bytes(Card.Description).length < 256, "Description too long.");
        if(Card.Epoch >= EpochsCount) { EpochsCount = (Card.Epoch + 1) ;}
        if(Card.Collection >= CollectionsCount[Card.Epoch]) { CollectionsCount[Card.Epoch] = (Card.Collection + 1); }
        if(Card.Id >= CardsCount[Card.Epoch][Card.Collection]) { CardsCount[Card.Epoch][Card.Collection] = (Card.Id + 1); }
        Cards[Card.Epoch][Card.Collection][Card.Id] = toICard(Card, true);
    }
    function Remove(uint Epoch, uint Collection, uint CardId) external {
        require(canDo("Remove", msg.sender), "Not Authorized.");
        Cards[Epoch][Collection][CardId].valid = false;
    }
    function canDo(string memory FuncName, address Sender) internal view returns (bool) {
        try IAddrLib(AddrLib).canDo(SMName, FuncName, Sender) returns (bool res) { return res; }
        catch { return false; }
    }
    function getEpochsCount() external view returns (uint) {
        require(canDo("getEpochsCount", msg.sender), "Not Authorized.");
        return EpochsCount;
    }
    function getCollectionsCount(uint Epoch) external view returns (uint) {
        require(canDo("getCollectionsCount", msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        return CollectionsCount[Epoch];
    }
    function getCardsCount(uint Epoch, uint Collection) external view returns (uint) {
        require(canDo("getCardsCount", msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        return CardsCount[Epoch][Collection];
    }

    function calcEpochsCount() external returns (uint) {
        require(canDo("calcEpochsCount", msg.sender), "Not Authorized.");
        if(EpochsCount <= 0) { return EpochsCount; }
        uint Cc = (EpochsCount - 1);
        uint CcNew;
        for(uint i = Cc; i >= 0; i++) {
            if(CollectionsCount[Cc] == 0) { CcNew = Cc; }
        }
        if(CcNew != EpochsCount) { EpochsCount = CcNew; }
        return EpochsCount;
    }
    function calcCollectionsCount(uint Epoch) external returns (uint) {
        require(canDo("calcCollectionsCount", msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        if(CollectionsCount[Epoch] <= 0) { return CollectionsCount[Epoch]; }
        uint Cc = (CollectionsCount[Epoch] - 1);
        uint CcNew;
        for(uint i = Cc; i >= 0; i++) {
            if(CardsCount[Epoch][Cc] == 0) { CcNew = Cc; }
        }
        if(CcNew != CollectionsCount[Epoch]) { CollectionsCount[Epoch] = CcNew; }
        return CollectionsCount[Epoch];
    }
    function calcCardsCount(uint Epoch, uint Collection) external returns (uint) {
        require(canDo("calcCardsCount", msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        if(CardsCount[Epoch][Collection] <= 0) { return CardsCount[Epoch][Collection]; }
        uint Cc = (CardsCount[Epoch][Collection] - 1);
        uint CcNew;
        for(uint i = Cc; i >= 0; i++) {
            if(Cards[Epoch][Collection][Cc].valid == false) { CcNew = Cc; }
        }
        if(CcNew != CardsCount[Epoch][Collection]) { CardsCount[Epoch][Collection] = CcNew; }
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
        Ic.valid = valid;
        Ic.owner = msg.sender;
        Ic.timestamp = block.timestamp;
        return Ic;
    }
    function toCard(Icard memory Ic, uint CardId) internal pure returns (card memory) {
        card memory crd;
        crd.Epoch = Ic.Epoch;
        crd.Collection = Ic.Collection;
        crd.Id = CardId;
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
        crd.Description = Ic.Description;
        return crd;
    }
    function Rarity_Des(uint8 RarityId) external view returns (string memory) { return _Rarities[RarityId]; }
    function Type_Des(uint8 TypeId) external view returns (string memory) { return _Types[TypeId]; }
    function Class_Des(uint8 ClassId) external view returns (string memory) { return _Classes[ClassId]; }
    function Stat_Des(uint8 StatId) external view returns (string memory) { return _Stats[StatId]; }
    function EpocRes_Des(uint8 EpocResId) public pure returns (string memory) {
        return EpocResId == 0 ? "All Epoch" : string(bytes.concat("Only Epoch ", bytes(toStr(EpocResId)) ) );
    }
    function Restriction(uint Epoch, uint Collection, uint CardId) public view returns (string memory) {
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        require(CardId < 1000, "CardId too big.");
        string[3] memory _Restrictions = ["None","Only Card:","Only"];
        Icard memory cds = Cards[Epoch][Collection][CardId];
        if (cds.Res1 == 0) {
            return _Restrictions[0];
        } else if (cds.Res1 == 1) {
            return string(bytes.concat(bytes(_Restrictions[1]), " ", bytes( toStr(cds.Res2) ) ) );
        } else if (cds.Res1 == 2) {
            return string(bytes.concat(bytes(_Restrictions[2]), " Rarity: '", bytes(_Rarities[cds.Res2]), "'"));
        } else if (cds.Res1 == 3) {
            return string(bytes.concat(bytes(_Restrictions[2]), " Type: '", bytes(_Types[cds.Res2]), "'"));
        } else if (cds.Res1 == 4) {
            return string(bytes.concat(bytes(_Restrictions[2]), " Class: '", bytes(_Classes[cds.Res2]), "'"));
        } else if (cds.Res1 > 4 && cds.Res1 < 9) {
            return string(bytes.concat(bytes(_Restrictions[2]), " ", bytes(_Stats[(cds.Res1 - 5)]), " > ", bytes(toStr(cds.Res2)) ) );
        } else if (cds.Res1 > 8 && cds.Res1 < 13) {
            return string(bytes.concat(bytes(_Restrictions[2]), " ", bytes(_Stats[(cds.Res1 - 9)]), " > ", bytes(toStr(cds.Res2)) ) );
        } else { return _Restrictions[0]; } //Unhandled value
    }
    function toJson_Des(uint Epoch, uint Collection, uint CardId) external view returns (string memory) {
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        require(CardId < 1000, "CardId too big.");
        Icard memory cds = Cards[Epoch][Collection][CardId];
        string memory T1 = string(bytes.concat('"Epoch":', bytes(toStr(cds.Epoch)), ', "SubCollection":', bytes(toStr(cds.Collection)), ', "Level":', bytes(toStr(cds.Level)), ', "Id":', bytes(toStr(CardId)), ', "Rarity":"', bytes(_Rarities[cds.Rarity]), '", "Restriction":"', bytes(Restriction(Epoch, Collection, CardId)), '", "Epoc Restriction":"', bytes(EpocRes_Des(cds.EpocRes)), '", "Type":"', bytes(_Types[cds.Type]), '", "Class":"', bytes(_Classes[cds.Class]), '"'));
        string memory T2 = string(bytes.concat('"Heart":', bytes(toStr(cds.Heart)), ', "Agi":', bytes(toStr(cds.Agi)), ', "Int":', bytes(toStr(cds.Int)), ', "Mana":', bytes(toStr(cds.Mana)), '"'));
        string memory T3 = string(bytes.concat('{', bytes(T1), ', ', bytes(T2), '}'));
        return T3;
    }
    function toJson(uint Epoch, uint Collection, uint CardId) external view returns (string memory) {
        require(Epoch < 17, "Epoch too big.");
        require(Collection < 100, "Collection too big.");
        require(CardId < 1000, "CardId too big.");
        Icard memory Ic = Cards[Epoch][Collection][CardId];
        string memory T1 = string(bytes.concat('"Epoch":', bytes(toStr(Ic.Epoch)), ', "SubCollection":', bytes(toStr(Ic.Collection)), ', "Level":', bytes(toStr(Ic.Level)), ', "Id":', bytes(toStr(CardId)), ', "Rarity":', bytes(toStr(Ic.Rarity)), ', "Res1":', bytes(toStr(Ic.Res1)), ', "Res2":', bytes(toStr(Ic.Res2)), ', "Epoc Restriction":', bytes(toStr(Ic.EpocRes)), ', "Type":', bytes(toStr(Ic.Type)), ', "Class":', bytes(toStr(Ic.Class)), ''));
        string memory T2 = string(bytes.concat('"Heart":', bytes(toStr(Ic.Heart)), ', "Agi":', bytes(toStr(Ic.Agi)), ', "Int":', bytes(toStr(Ic.Int)), ', "Mana":', bytes(toStr(Ic.Mana)), '"'));
        string memory T3 = string(bytes.concat('{', bytes(T1), ', ', bytes(T2), '}'));
        return T3;
    }
    function toStr(uint256 value) internal pure returns (string memory) {
        if (value == 0) { return "0"; }
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
}