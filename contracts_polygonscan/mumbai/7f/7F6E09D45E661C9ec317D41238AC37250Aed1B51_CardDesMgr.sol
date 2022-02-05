/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

// SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
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
interface IAddrLib {
    //function canDo(bytes32 ContractName, bytes32 FuncName, address Sender) external view returns (bool);
    function get(bytes32 ContractName) external view returns (address);
}
interface ICardLib { function getCard(uint8 Epoch, uint8 Collection, uint16 CardId) external view returns (card memory); }
contract CardDesMgr {
    //using SWUtils for *;
    address constant internal AddrLib = 0xd6eEDE49893f4b361c0C5ac02D48EC686846A4b2;
    bytes32 constant internal SMName = "CardDesMgr";
    bytes32 constant internal SMCard = "CardMgr";
    bytes32[5] internal _Rarities = [bytes32("Common"),bytes32("Uncommon"),bytes32("Rare"),bytes32("Epic"),bytes32("Legendary")];
    bytes32[6] internal _Types = [bytes32("Shibatar"),bytes32("Equip"),bytes32("Artifact"),bytes32("Special Action"),bytes32("Land"),bytes32("Building")];
    bytes32[6] internal _Classes = [bytes32("None"),bytes32("Fighter"),bytes32("Explorer"),bytes32("Scientist"),bytes32("Wizard"),bytes32("Fluid")];
    bytes32[4] internal _Stats = [bytes32("Heart"),bytes32("Agi"),bytes32("Int"),bytes32("Mana")];
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
    function Rarity_Des(uint8 RarityId) external view modId(RarityId, _Rarities.length) returns (bytes32) { return _Rarities[RarityId]; }
    function Type_Des(uint8 TypeId) external view modId(TypeId, _Types.length) returns (bytes32) { return _Types[TypeId]; }
    function Class_Des(uint8 ClassId) external view modId(ClassId, _Classes.length) returns (bytes32) { return _Classes[ClassId]; }
    function Stat_Des(uint8 StatId) external view modId(StatId, _Stats.length) returns (bytes32) { return _Stats[StatId]; }
    function EpocRes_Des(uint8 EpocResId) public pure returns (bytes memory) { return EpocResId == 0 ? bytes.concat("All Epoch") : bytes.concat("Only Epoch ", toBytes(EpocResId) ); }
    function Restriction(uint8 Epoch, uint8 Collection, uint16 CardId) public view virtual modEpochCollectionCard(Epoch, Collection, CardId) returns (bytes memory) {
        card memory cds = getCard(Epoch, Collection, CardId);
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
        card memory cds = getCard(Epoch, Collection, CardId);
        bytes memory T1 = bytes.concat('"Epoch":', toBytes(cds.Epoch), ', "Collection":', toBytes(cds.Collection), ', "Level":', toBytes(cds.Level), ', "Id":', toBytes(CardId), ', "Rarity":"', _Rarities[cds.Rarity], '", "Restriction":"', Restriction(Epoch, Collection, CardId), '", "Epoc Restriction":"', EpocRes_Des(cds.EpocRes), '", "Type":"', _Types[cds.Type], '", "Class":"', _Classes[cds.Class], '"');
        bytes memory T2 = bytes.concat('"Heart":', toBytes(cds.Heart), ', "Agi":', toBytes(cds.Agi), ', "Int":', toBytes(cds.Int), ', "Mana":', toBytes(cds.Mana), '", "Name":', cds.Name, '", "Description":', bytes(cds.Description), '", "Picture":', bytes(cds.Picture), '"');
        return string(bytes.concat('{', bytes(T1), ', ', bytes(T2), '}'));
    }
    function toJson(uint8 Epoch, uint8 Collection, uint16 CardId) external view virtual modEpochCollectionCard(Epoch, Collection, CardId) returns (string memory) {
        card memory Ic = getCard(Epoch, Collection, CardId);
        bytes memory T1 = bytes.concat('"Epoch":', toBytes(Ic.Epoch), ', "Collection":', toBytes(Ic.Collection), ', "Level":', toBytes(Ic.Level), ', "Id":', toBytes(CardId), ', "Rarity":', toBytes(Ic.Rarity), ', "Res1":', toBytes(Ic.Res1), ', "Res2":', toBytes(Ic.Res2), ', "Epoc Restriction":', toBytes(Ic.EpocRes), ', "Type":', toBytes(Ic.Type), ', "Class":', toBytes(Ic.Class), '');
        bytes memory T2 = bytes.concat('"Heart":', toBytes(Ic.Heart), ', "Agi":', toBytes(Ic.Agi), ', "Int":', toBytes(Ic.Int), ', "Mana":', toBytes(Ic.Mana),'", "Name":', Ic.Name, '", "Description":', bytes(Ic.Description), '", "Picture":', bytes(Ic.Picture), '"');
        return string(bytes.concat('{', T1, ', ', T2, '}'));
    }
    function getCard(uint8 Epoch, uint8 Collection, uint16 CardId) internal view returns (card memory) {    //ToDo: Questa é la chiamata CORRETTA per i SubSmartContract !!!
        address destLib = IAddrLib(AddrLib).get(SMCard);
        require(destLib != address(0), "CardMgr Not Found!");
        return ICardLib(destLib).getCard(Epoch, Collection, CardId);
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
//TBD