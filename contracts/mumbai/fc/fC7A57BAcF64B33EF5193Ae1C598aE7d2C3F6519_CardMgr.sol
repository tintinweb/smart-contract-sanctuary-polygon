// SPDX-License-Identifier: No License
pragma solidity >=0.8.11 <0.9.0;
import "SWImport.sol";
import "SWUtils.sol";
contract CardMgr {
    using SWUtils for *;
    bytes32 constant internal SMName = "CardMgr";
    uint8 EpochsCount;
    uint8[17] CollectionsCount;
    uint16[17][100] CardsCount;
    //Icard[Epoch][Collection][CardId]
    Icard[17][100][1000] Cards;
    modifier modcanDo(bytes32 FuncName) {
        require(SMName.IcanDo(FuncName, msg.sender), "Not Authorized.");
        _;
    }
    modifier modEpoch(uint8 Epoch, bytes32 FuncName) {
        require(SMName.IcanDo(FuncName, msg.sender), "Not Authorized.");
        require(Epoch < 17, "Epoch too big.");
        _;
    }
    modifier modEpochCollection(uint8 Epoch, uint8 Collection, bytes32 FuncName) {
        require(SMName.IcanDo(FuncName, msg.sender), "Not Authorized.");
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
    function getEpoch(uint8 Epoch) external view virtual modEpoch(Epoch, "getEpoch") returns (Icard[17][100] memory) {
        return Cards[Epoch]; //ToDo: Verificare cosa restituisce. Credo sia l'array Sbagliato!
    }
    function getCollection(uint8 Epoch, uint8 Collection) external view virtual modEpochCollection (Epoch, Collection, "getCollection") returns (Icard[17] memory) {
        return Cards[Epoch][Collection]; //ToDo: Verificare cosa restituisce. Credo sia l'array Sbagliato!
    }
    function getCard(uint24 uid) external view returns (card memory) {
        cUID memory gC = uid.UID();
        return getCard(gC.Epoch, gC.Collection, gC.CardId);
    }
    function getCard(uint8 Epoch, uint8 Collection, uint16 CardId) public view virtual modEpochCollectionCard (Epoch, Collection, CardId) returns (card memory) {
        card memory crd;
        if(Cards[Epoch][Collection][CardId].valid == false) { return crd; }
        return toCard(Cards[Epoch][Collection][CardId], CardId);
    }
    function setCard(card memory Card) external virtual modEpochCollectionCard(Card.Epoch, Card.Collection, Card.Id) {
        require(SMName.IcanDo("setCard", msg.sender), "Not Authorized.");
        require(bytes.concat(Card.Name).length <= 30, "Name too long.");    //ToDo: Verificare se il Controllo Funziona
        require(bytes(Card.Description).length < 256, "Description too long.");
        if(Card.Epoch >= EpochsCount) { EpochsCount = (Card.Epoch + 1) ;}
        if(Card.Collection >= CollectionsCount[Card.Epoch]) { CollectionsCount[Card.Epoch] = (Card.Collection + 1); }
        if(Card.Id >= CardsCount[Card.Epoch][Card.Collection]) { CardsCount[Card.Epoch][Card.Collection] = (Card.Id + 1); }
        Cards[Card.Epoch][Card.Collection][Card.Id] = toICard(Card, true);
        SMName.LogSecurity("setCard", msg.sender);
    }
    function Remove(uint8 Epoch, uint8 Collection, uint16 CardId) external virtual modcanDo("Remove") {
        Cards[Epoch][Collection][CardId].valid = false;
        SMName.LogSecurity("Remove", msg.sender);
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
        SMName.LogSecurity("calcEpochsCount", msg.sender);
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
        SMName.LogSecurity("calcCollectionsCount", msg.sender);
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
        SMName.LogSecurity("calcCardsCount", msg.sender);
        return CardsCount[Epoch][Collection];
    }
    function toICard(card memory crd, bool valid) internal view returns (Icard memory) {
        Icard memory Ic;
        Ic.Epoch = crd.Epoch;
        Ic.Collection = crd.Collection;
        Ic.Level = crd.Level;
        Ic.Rarity = crd.Rarity;
        Ic.Unlocked = crd.Unlocked;
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
        crd.Unlocked = Ic.Unlocked;
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
}
//ToDo: Splittare il Contratto in N sotto Contratti, 1 per ogni Collezione di ogni Epoca, onde evitare i costi dello Spazio della BlockChain che aumentano 'Quadratically'

//[Funzioni Utente x ShibaWorldsMgr.sol]
//getCard
//