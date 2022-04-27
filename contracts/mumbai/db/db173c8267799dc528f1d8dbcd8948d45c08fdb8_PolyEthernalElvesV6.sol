// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./PolyElvesERC721.sol"; 
import "./../DataStructures.sol";
import "./../Interfaces.sol";
//import "hardhat/console.sol";

/*
███████╗████████╗██╗░░██╗███████╗██████╗░███╗░░██╗░█████╗░██╗░░░░░  ███████╗██╗░░░░░██╗░░░██╗███████╗░██████╗
██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗████╗░██║██╔══██╗██║░░░░░  ██╔════╝██║░░░░░██║░░░██║██╔════╝██╔════╝
█████╗░░░░░██║░░░███████║█████╗░░██████╔╝██╔██╗██║███████║██║░░░░░  █████╗░░██║░░░░░╚██╗░██╔╝█████╗░░╚█████╗░
██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██║╚████║██╔══██║██║░░░░░  ██╔══╝░░██║░░░░░░╚████╔╝░██╔══╝░░░╚═══██╗
███████╗░░░██║░░░██║░░██║███████╗██║░░██║██║░╚███║██║░░██║███████╗  ███████╗███████╗░░╚██╔╝░░███████╗██████╔╝
╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚══════╝  ╚══════╝╚══════╝░░░╚═╝░░░╚══════╝╚═════╝░
*/

// We are the Ethernal. The Ethernal Elves         
// Written by 0xHusky & Beff Jezos. Everything is on-chain for all time to come.
// Version 5.0.0
// Release notes: Adding moon and moon bridge

contract PolyEthernalElvesV6 is PolyERC721 {

    function name() external pure returns (string memory) { return "Polygon Ethernal Elves"; }
    function symbol() external pure returns (string memory) { return "pELV"; }
       
    
    using DataStructures for DataStructures.Elf;    

    IElfMetaDataHandler elfmetaDataHandler;
        
    using ECDSA for bytes32;

/*
█▀ ▀█▀ ▄▀█ ▀█▀ █▀▀   █░█ ▄▀█ █▀█ █▀
▄█ ░█░ █▀█ ░█░ ██▄   ▀▄▀ █▀█ █▀▄ ▄█
*/

    bool public isGameActive;
    bool public isTerminalOpen;
    bool private initialized;

    address operator;
   
    uint256 public INIT_SUPPLY; 
    uint256 public price;
    uint256 public MAX_LEVEL;
    uint256 public TIME_CONSTANT; 
    uint256 public REGEN_TIME; 
 
    bytes32 internal ketchup;
    
    mapping(uint256 => uint256) public sentinels; //memory slot for Elfs
    mapping(address => uint256) public bankBalances; //memory slot for bank balances
    mapping(uint256 => Camps) public camps; //memory slot for campaigns

    struct Camps {
                uint32 baseRewards; 
                uint32 creatureCount; 
                uint32 creatureHealth; 
                uint32 expPoints; 
                uint32 minLevel;
                uint32 campMaxLevel;
        }    
   
    mapping(address => bool)    public auth;  
    mapping(bytes => uint16)  public usedRenSignatures;
    address polyValidator;
    
   
    mapping(uint256 => Rampages) public rampages; //memory slot for campaigns
    bool private isRampageInit;
    struct Rampages {

                uint16 probDown; 
                uint16 probSame; 
                uint16 propUp; 
                uint16 levelsGained; 
                uint16 minLevel;
                uint16 maxLevel;
                uint16 renCost;     
                uint16 count; 

        }
    
    struct GameVariables {
                
                uint256 healTime; 
                uint256 instantKillModifier;     
                uint256 rewardModifier;     
                uint256 attackPointModifier;     
                uint256 healthPointModifier;     
                uint256 reward;
                uint256 timeDiff;
                uint256 traits; 
                uint256 class;  

    }
    
   
    mapping(uint256 => PawnItems) public pawnItems; //memory slot for campaigns
    
    struct PawnItems {
                
                uint256 buyPrice; 
                uint256 sellPrice;     
                uint256 maxSupply;     
                uint256 currentInventory;     
    }

    //CRUSADER NO REGRET// 
    ///////////////////////////////////////////////////////////////////////////////////////////
    mapping(address => uint256) public scrolls; //memory slot for scrolls to go on crusades////
    mapping(address => uint256) public artifacts; //memory slot for artifact mint           ///
    mapping(uint256 => uint256) public onCrusade;                                           /// 
    ///////////////////////////////////////////////////////////////////////////////////////////    
    mapping(address => uint256) public moonBalances;         
    //NewDataSlots from this deployment///
    uint256 public CREATURE_HEALTH; 


/*
█▀▀ █░█ █▀▀ █▄░█ ▀█▀ █▀
██▄ ▀▄▀ ██▄ █░▀█ ░█░ ▄█
*/

    event Action(address indexed from, uint256 indexed action, uint256 indexed tokenId);         
    event BalanceChanged(address indexed owner, uint256 indexed amount, bool indexed subtract);
    event MoonBalanceChanged(address indexed owner, uint256 indexed amount, bool indexed subtract);
    event Campaigns(address indexed owner, uint256 amount, uint256 indexed campaign, uint256 sector, uint256 indexed tokenId);
    
    event BloodThirst(address indexed owner, uint256 indexed tokenId); 
    event RollOutcome(uint256 indexed tokenId, uint256 roll, uint256 action);
    event ArtifactFound(address indexed from, uint256 artifacts, uint256 indexed tokenId);
    event ArtifactsMinted(address indexed from, uint256 artifacts, uint256 timestamp);

    event CheckIn(address indexed from, uint256 timestamp, uint256 indexed tokenId, uint256 indexed sentinel);      
    event RenTransferOut(address indexed from, uint256 timestamp, uint256 indexed renAmount);   
    event ElfTransferedIn(uint256 indexed tokenId, uint256 sentinel); 
    event RenTransferedIn(address indexed from, uint256 renAmount); 



/*
█▀▀ ▄▀█ █▀▄▀█ █▀▀ █▀█ █░░ ▄▀█ █▄█
█▄█ █▀█ █░▀░█ ██▄ █▀▀ █▄▄ █▀█ ░█░
*/


    function sendCampaign(uint256[] calldata ids, uint256 campaign_, uint256 sector_, bool rollWeapons_, bool rollItems_, bool useitem_, address owner) external {
                  
         onlyOperator();
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 2, owner, campaign_, sector_, rollWeapons_, rollItems_, useitem_, 1);
          }
    }


    function passive(uint256[] calldata ids, address owner) external {
                  
        onlyOperator();
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 3, owner, 0, 0, false, false, false, 0);
          }
    }

    function returnPassive(uint256[] calldata ids, address owner) external  {
               
         onlyOperator();
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 4, owner, 0, 0, false, false, false, 0);
          }
    }

    function forging(uint256[] calldata ids, address owner) external {
              
         onlyOperator();
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 5, owner, 0, 0, false, false, false, 0);
          }
    }

    function merchant(uint256[] calldata ids, address owner) external {
          
        onlyOperator();
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 6, owner, 0, 0, false, false, false, 0);
          }

    }

    function heal(uint256 healer, uint256 target, address owner) external {
        onlyOperator();
        _actions(healer, 7, owner, target, 0, false, false, false, 0);
    }

     function healMany(uint256[] calldata healers, uint256[] calldata targets, address owner) external {
        onlyOperator();
        
        for (uint256 index = 0; index < healers.length; index++) {  
            _actions(healers[index], 7, owner, targets[index], 0, false, false, false, 0);
        }
    }

    
     function synergize(uint256[] calldata ids, address owner) external {
        onlyOperator();
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 9, owner, 0, 0, false, false, false, 0);
          }

    }

    
 function bloodThirst(uint256[] calldata ids, bool rollItems_, bool useitem_, address owner) external {
          onlyOperator();       

          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 10, owner, 0, 0, false, rollItems_, useitem_, 2);
          }
    }
  
 function rampage(uint256[] calldata ids, uint256 campaign_, bool tryWeapon_, bool tryAccessories_, bool useitem_, address owner) external {
          onlyOperator();       
          //using items bool for try accessories
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 11, owner, campaign_, 0, tryWeapon_, tryAccessories_, useitem_, 0);
          }
    }

  function buyItem(uint256 id, uint256 itemIndex_,address owner) external {
          onlyOperator();       
         //using sector for item index. The item you want to buy.
          _actions(id, 12, owner, 0, itemIndex_, false,false,false, 0);
          
    }   

    function sellItem(uint256 id, address owner) external {
          onlyOperator();       
        
          _actions(id, 13, owner, 0, 0, false,false,false, 0);
          
    }

     function sendCrusade(uint256[] calldata ids, address owner, bool useMoon) external {
          onlyOperator();       
          //using items bool for try accessories
          for (uint256 index = 0; index < ids.length; index++) {  
            _actions(ids[index], 14, owner, 0, 0, false,false, useMoon, 0);
          }
    }

     function returnCrusade(uint256[] calldata ids, address owner, bool useMoon) external {
          onlyOperator();       

          for (uint256 index = 0; index < ids.length; index++) {  
                
                _returnCrusade(ids[index], owner, useMoon);
          }
    } 
 

/*
█ █▄░█ ▀█▀ █▀▀ █▀█ █▄░█ ▄▀█ █░░ █▀
█ █░▀█ ░█░ ██▄ █▀▄ █░▀█ █▀█ █▄▄ ▄█
*/

        function _actions(
            uint256 id_, 
            uint action, 
            address elfOwner, 
            uint256 campaign_, 
            uint256 sector_, 
            bool rollWeapons, 
            bool rollItems, 
            bool useItem, 
            uint256 gameMode_) 
        
        private {

            DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id_]);
            GameVariables memory actions;
            require(isGameActive);
            require(elf.owner == elfOwner, "notYourElf");
            require(onCrusade[id_] == 0, "onCrusade");
             
            
            //Set special abilities when we retrieve the elf so they can be used in the rest of the game loop.            
            (elf.attackPoints, actions) = _getAbilities(elf.attackPoints, elf.accessories, elf.sentinelClass);

            uint256 rand = _rand();
                
                if(action == 0){//Unstake in Eth, Return to Eth in Polygon
                    
                    require(elf.timestamp < block.timestamp, "elfBusy");
                    
                     if(elf.action == 3){
                     actions.timeDiff = (block.timestamp - elf.timestamp) / 1 days; //amount of time spent in camp CHANGE TO 1 DAYS!
                      _exitPassive(actions.timeDiff, elfOwner, elf.weaponTier, elf.level);
                    
                     }
                         

                }else if(action == 2){//campaign loop 

                    require(elf.timestamp < block.timestamp, "elfBusy");
                    require(elf.action != 3, "exitPassive"); 

                        (elf.level, actions.reward, elf.timestamp, elf.inventory) = _campaigns(campaign_, sector_, elf.level, elf.attackPoints, elf.healthPoints, elf.inventory, useItem);

                             if(rollWeapons) (elf.primaryWeapon, elf.weaponTier) = _rollWeapon(elf.level, id_, rand, 3);
                             if(rollItems) elf.inventory = _rollitems(id_);                       

                        emit Campaigns(elfOwner, actions.reward, campaign_, sector_, id_);                 

                     _setAccountBalance(elfOwner, actions.reward, false, 0);
                 
                
                }else if(action == 3){//passive campaign

                    require(elf.timestamp < block.timestamp, "elfBusy");
                    elf.timestamp = block.timestamp; //set timestamp to current block time

                }else if(action == 4){///return from passive mode
                    
                    require(elf.action == 3);                    

                    actions.timeDiff = (block.timestamp - elf.timestamp) / 1 days; 

                    _exitPassive(actions.timeDiff, elfOwner, elf.weaponTier, elf.level);
                   

                }else if(action == 5){//forging
                   
                    //require(bankBalances[elfOwner] >= 200 ether, "notEnoughRen");
                    checkRen(elfOwner, 200 ether);
                    require(elf.action != 3, "exitPassive");  //Cant roll in passve mode  

                    _setAccountBalance(elfOwner, 200 ether, true, 0);
                    (elf.primaryWeapon, elf.weaponTier) = _rollWeapon(elf.level, id_, rand, 3);
   
                
                }else if(action == 6){//item or merchant loop
                   
                    //require(bankBalances[elfOwner] >= 10 ether, "notEnoughRen");
                    checkRen(elfOwner, 10 ether);
                    require(elf.action != 3, "exitPassive");  //Cant roll in passve mode
                  
                    _setAccountBalance(elfOwner, 10 ether, true, 0);
                     elf.inventory = _rollitems(id_);
                    //(elf.weaponTier, elf.primaryWeapon, elf.inventory) = DataStructures.roll(id_, elf.level, rand, 2, elf.weaponTier, elf.primaryWeapon, elf.inventory);                      

                }else if(action == 7){//healing loop


                    require(elf.sentinelClass == 0, "notDruid"); 
                    require(elf.action != 3, "exitPassive");  //Cant heal in passve mode
                    require(elf.timestamp < block.timestamp, "elfBusy");

                    
                    elf.timestamp = block.timestamp + (actions.healTime);//change to healtime

                    elf.level = elf.level + 1;
                    
                    {   

                        DataStructures.Elf memory hElf = DataStructures.getElf(sentinels[campaign_]);//using the campaign varialbe for elfId here.
                        require(hElf.owner == elfOwner, "notYourElf");
                        //require(hElf.action != 14, "onCrusade"); //Cant heal a crusader
                        require(onCrusade[campaign_] == 0, "onCrusade");      //using the campaign varialbe for elfId here.
                                if(block.timestamp < hElf.timestamp){

                                        actions.timeDiff = hElf.timestamp - block.timestamp;
                
                                        actions.timeDiff = actions.timeDiff > 0 ? 
                                            
                                            hElf.sentinelClass == 0 ? 0 : 
                                            hElf.sentinelClass == 1 ? actions.timeDiff * 1/4 : 
                                            actions.timeDiff * 1/2
                                        
                                        : actions.timeDiff;
                                        
                                        hElf.timestamp = hElf.timestamp - actions.timeDiff;                        
                                        
                                }
                            
                        actions.traits = DataStructures.packAttributes(hElf.hair, hElf.race, hElf.accessories);
                        actions.class =  DataStructures.packAttributes(hElf.sentinelClass, hElf.weaponTier, hElf.inventory);
                                
                        sentinels[campaign_] = DataStructures._setElf(hElf.owner, hElf.timestamp, hElf.action, hElf.healthPoints, hElf.attackPoints, hElf.primaryWeapon, hElf.level, actions.traits, actions.class);

                }
                //Action 8 is move to polygon
                }else if(action == 9){//Re-roll cooldown aka Synergize

                    //require(bankBalances[elfOwner] >= 5 ether, "notEnoughRen");
                    checkRen(elfOwner, 5 ether);
                    require(elf.sentinelClass == 0, "notDruid"); 
                    require(elf.action != 3, "exitPassive"); //Cant heal in passve mode
                    
                    _setAccountBalance(elfOwner, 5 ether, true, 0);
                    elf.timestamp = _rollCooldown(elf.timestamp, id_, rand);

                }else if(action == 10){//Bloodthirst

                    require(elf.timestamp < block.timestamp, "elfBusy");
                    require(elf.action != 3, "exitPassive");  

                       (actions.reward, elf.timestamp, elf.inventory) = _bloodthirst(campaign_, sector_, elf.weaponTier, elf.level, elf.attackPoints, elf.healthPoints, elf.inventory, useItem);

                       if(rollItems){
                       
                       // (elf.weaponTier, elf.primaryWeapon, elf.inventory) = DataStructures.roll(id_, elf.level, _rand(), 2, elf.weaponTier, elf.primaryWeapon, elf.inventory);  
                        elf.inventory = _rollitems(id_);
                       }    

                        
                       if(elf.sentinelClass == 1){
                            
                                elf.timestamp = _instantKill(elf.timestamp, elf.weaponTier, elfOwner, id_, actions.instantKillModifier);
                
                       }
                

                       _setAccountBalance(elfOwner, actions.reward, false, 0);                 
                    
                
                }else if(action == 11){//Rampage
                        require(elf.action != 3, "exitPassive"); //Cant rampage in passve mode
                        require(elf.timestamp < block.timestamp, "elfBusy");
                        
                        //in rampage you can get accessories or weapons.
                       (elf, actions) = _rampage(elf, actions, campaign_, id_, elfOwner, rollWeapons, rollItems, useItem);                
                
                }else if(action == 12){//Buy Item - pawn shop is selling
                      require(elf.action != 3, "exitPassive");
                      //using sector for requested item
                        elf.inventory = _sellItem(sector_, elfOwner); 
                     
                }else if(action == 13){//Sell Item pawnshop is buying
                     require(elf.action != 3, "exitPassive"); 
                     elf.inventory = _buyItem(elf.inventory, elfOwner);                     

                }else if(action == 14){//Go on a Crusade
                     require(elf.action != 3, "exitPassive"); 
                     require(elf.timestamp < block.timestamp, "elfBusy");      
                     require(scrolls[elfOwner] > 0, "noScrolls");
                     uint256 crusadeCost = 1500 ether;
                      
                    if(useItem){
                      //used 5 moon to reduce the cost of crusade by 250 ren  
                      checkMoon(elfOwner, 5 ether);
                      _setAccountBalance(elfOwner, 5 ether, true, 1); 
                      crusadeCost = 1200 ether;
                    }
                    checkRen(elfOwner, crusadeCost);

                    
                     
                     _setAccountBalance(elfOwner, crusadeCost, true, 0); // take ren from buyer
                     scrolls[elfOwner] = scrolls[elfOwner] - 1;
                     onCrusade[id_] = 1;
                  
                             if(elf.level < 70){
                        
                                 elf.timestamp = block.timestamp + (9 days);
                     
                            }else if(elf.level >= 70 && elf.level <= 98){
                                
                                  elf.timestamp = block.timestamp + (7 days);

                            }else if(elf.level > 98){

                                elf.timestamp = block.timestamp + (5 days);

                        }

                  }
             
           
            actions.traits   = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
            actions.class    = DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
           
            //Buffer overun protection for Ranger 
            actions.class = actions.class == 256 ? 255 : actions.class;           
           

            elf.healthPoints = DataStructures.calcHealthPoints(elf.sentinelClass, elf.level); 
            elf.attackPoints = DataStructures.calcAttackPoints(elf.sentinelClass, elf.weaponTier);  
            elf.level        = elf.level > 100 ? 100 : elf.level; 
            elf.action       = action;

            sentinels[id_] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
            emit Action(elfOwner, action, id_); 
    }

    

function _campaigns(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) internal
 
 returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory){
  
  Camps memory camp = camps[_campId];  
  
  require(camp.minLevel <= _level, "levelLow");
  require(camp.campMaxLevel >= _level, "levelHigh"); 
  require(camp.creatureCount > 0, "noSupply");
  
  camps[_campId].creatureCount = camp.creatureCount - 1;  

  level = (uint256(camp.expPoints)/3); //convetrt xp to levels. Level here is the rewards level

  rewards = camp.baseRewards + (2 * (_sector - 1));
  rewards = rewards * (1 ether);      

  inventory = _inventory;
 
  if(_useItem){

       (inventory, level, _attackPoints, _healthPoints, rewards) = _useInventory(_inventory, level, _attackPoints, _healthPoints, rewards);

  }

  level = _level + level;  //add level to current level
  level = level < MAX_LEVEL ? level : MAX_LEVEL; //if level is greater than max level, set to max level
                             
  uint256 creatureHealth =  ((_sector - 1) * 12) + camp.creatureHealth; 
  uint256 attackTime = creatureHealth/_attackPoints;
  
  attackTime = attackTime > 0 ? attackTime * TIME_CONSTANT : 0;
  
  timestamp = REGEN_TIME/(_healthPoints) + (block.timestamp + attackTime);

}

function _instantKill(uint256 timestamp, uint256 weaponTier, address elfOwner, uint256 id, uint256 instantKillModifier) internal returns(uint256 timestamp_){

  uint16  chance = uint16(_randomize(_rand(), "InstantKill", id)) % 100;
  uint256 killChance = weaponTier == 3 ? 10 : weaponTier == 4 ? 15 : weaponTier == 5 ? 20 : 0;
  
  //Increasing kill chance if the right accessory is equipped
  killChance = killChance + instantKillModifier;       

    if(chance <= killChance){
      
        timestamp_ = block.timestamp + (4 hours);
        emit BloodThirst(elfOwner, id);
    }else{
        timestamp_ = timestamp;
    } 
    
    emit RollOutcome(id, chance, 10);
    

 }


function _bloodthirst(uint256 _campId, uint256 _sector, uint256 weaponTier, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) internal view
 
 returns(uint256 rewards, uint256 timestamp, uint256 inventory){
  
  uint256 creatureHealth = CREATURE_HEALTH; 

  rewards = weaponTier == 3 ? 80 ether : weaponTier == 4 ? 95 ether : weaponTier == 5 ? 110 ether : 0;  

  inventory = _inventory;
 
  if(_useItem){

     (inventory, , _attackPoints, _healthPoints, rewards) = _useInventory(_inventory, 1, _attackPoints, _healthPoints, rewards);

  }                            
  
  uint256 attackTime = creatureHealth/_attackPoints;
  
  attackTime = attackTime > 0 ? attackTime * TIME_CONSTANT : 0;
  
  timestamp = REGEN_TIME/(_healthPoints) + (block.timestamp + attackTime);


}

function _rampage(

    DataStructures.Elf memory _elf, 
    GameVariables memory _actions, 
    uint256 _campId, 
    uint256 _id, 
    address elfOwner, 
    bool tryWeapon, 
    bool tryAccessories,
    bool _useItem
    ) internal  
    returns(
            DataStructures.Elf memory elf, 
            GameVariables memory actions
            ){

        Rampages memory rampage = rampages[_campId];  
         
        uint256 rampageCost = uint256(rampage.renCost); //needed to
        rampageCost = rampageCost * (1 ether);
       
        elf = _elf;
        actions = _actions;        

        require(rampage.minLevel <= elf.level, "levelLow");
        require(rampage.maxLevel >= elf.level, "levelHigh"); 
        require(rampage.count > 0, "noSupply");
        //require(bankBalances[elfOwner] >= rampageCost, "notEnoughRen");
        checkRen(elfOwner, rampageCost);
        
       
         rampages[_campId].count = rampage.count - 1;
        _setAccountBalance(elfOwner, rampageCost, true, 0);

        uint256 cooldown = 36 hours;
        uint256 levelsGained = rampage.levelsGained;

        uint256  chance = uint256(_randomize(_rand(), "Rampage", _id)) % 100;

        if(_campId == 6 || _campId == 7){
            //Untamed Ether for DRUID Morphs
           require(elf.sentinelClass == 0, "notDruid");
           if(chance <= 50){
               elf.accessories = 1;
             
           }else{
               elf.accessories = 2;
              
           }
        }

        if(_useItem && elf.inventory == 4){
            //only spiritBand can be used in rampage

            levelsGained = levelsGained * 2;
            elf.inventory = 0;
           

        }     
  
  if(_campId > 2)
  {
            if(tryAccessories){

             //   console.log("here");

                    if(elf.accessories <= 3 && elf.sentinelClass != 0){
                        //enter accessories upgrade loop. Not allowed for >3 (one for ones) or druids

                            //if try accessories is true, try to get accessories
                            if(chance > 0 && chance <= rampage.probDown){
                                //downgrade
                                //dont downgrade if already 0
                                //console.log("downgrade: ", chance);
                                
                                elf.accessories = elf.accessories == 0 ? 0 : elf.accessories - 1;

                            }else if(chance > rampage.probDown && chance <= (rampage.probDown + rampage.probSame)){
                                    //same
                                    // console.log("same: ", chance);
                                  
                                    elf.accessories = elf.accessories;

                            }else if(chance > (rampage.probDown + rampage.probSame) && chance <= 100){
                                    //upgrade
                                   //   console.log("upgrade: ", chance);
                                    elf.accessories = elf.accessories + 1;

                            }

                        //prevent accessories from being upgraded if the elf has >3 accessories        
                        elf.accessories = elf.accessories > 3 ? 3 : elf.accessories;
                    }   

            }else{
                  
                    if(tryWeapon){

                      
                                    if(chance > 0 && chance <= rampage.probDown){
                                        //downgrade
                                        
                                        elf.weaponTier = elf.weaponTier - 1 < 1 ? 1 : elf.weaponTier - 1;       

                                    }else if(chance > rampage.probDown && chance <= (rampage.probDown + rampage.probSame)){
                                        //same
                                       
                                        elf.weaponTier = elf.weaponTier;

                                    }else if(chance > (rampage.probDown + rampage.probSame) && chance <= 100){
                                        //upgrade
                                      
                                        elf.weaponTier = elf.weaponTier + 1;
                                    }

                        elf.weaponTier = elf.weaponTier > 4 ? 4 : elf.weaponTier;
                        elf.primaryWeapon = ((elf.weaponTier - 1) * 3) + ((chance +1) % 3);        

                        }

            }
  }
        
      elf.timestamp = block.timestamp + cooldown;
      elf.level = elf.level + levelsGained;

     emit RollOutcome(_id, chance, 11);
                   
}

function _useInventory(uint256 _inventory, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _rewards) internal pure   
    returns(uint256 inventory_, uint256 level_, uint256 attackPoints_, uint256 healthPoints_, uint256 rewards_){

         attackPoints_ = _inventory == 1 ? _attackPoints * 2   : _inventory == 6 ? _attackPoints * 3   : _attackPoints;
         healthPoints_ = _inventory == 2 ? _healthPoints * 2   : _inventory == 5 ? _healthPoints + 200 : _healthPoints; 
         rewards_      = _inventory == 3 ? _rewards * 2        : _rewards;
         level_        = _inventory == 4 ? _level * 2          : _level; 
         
         inventory_ = 0;
}


function _getAbilities(uint256 _attackPoints, uint256 _accesssories, uint256 sentinelClass) 
        private view returns (uint256 attackPoints_, GameVariables memory actions_) {

 attackPoints_ = _attackPoints;
 actions_.healTime = 12 hours;
 actions_.instantKillModifier = 0;      

 _accesssories = ((7 * sentinelClass) + _accesssories) + 1;


        //if Druid 
        if(_accesssories == 2){
        //Bear
            attackPoints_ = _attackPoints + 30;

        }else if (_accesssories == 3){
        //Liger
            actions_.healTime = 4 hours;        
        
        }else if(_accesssories == 10){
        //if Assassin 3 Crown of Dahagon 
            actions_.instantKillModifier = 15;

        }else if(_accesssories == 11){
        //if Assassin 4 Mechadon's Vizard
            actions_.instantKillModifier = 25;              

        } else if(_accesssories == 17){
        //if Ranger 3 Azrael's Crest
            
            attackPoints_ = _attackPoints * 115/100;
     

        }else if(_accesssories == 18){
        //if Ranger 4 El Machina
            attackPoints_ = _attackPoints * 125/100;             

        }

        if(_accesssories == 6){
            //Druid 1/1
            attackPoints_ = _attackPoints + 20;
            actions_.healTime = 4 hours;        

        }        

        //1 for 1 special abilities
        if(_accesssories == 12 || _accesssories == 13 || _accesssories == 14){
            //Assassin
            actions_.instantKillModifier = 35;
        }else if(_accesssories == 19 || _accesssories == 20 || _accesssories == 21){
            //Ranger
            attackPoints_ = _attackPoints * 135/100;
        }  

}


function _exitPassive(uint256 timeDiff, address _owner, uint256 _weaponTier, uint256 _level) private {
            
            uint256 rewards;
            uint256 reward;
            uint256 levelTier =  _level == 100 ? 5 : uint256((_level/20) + 1);
            uint16[6] memory levelMultiplier = [10000,10000,12000,12500,13200,15000];
            uint8[6] memory weaponTierReward = [0,10,15,20,25,30];

                    reward = weaponTierReward[_weaponTier];
                    reward = reward * levelMultiplier[levelTier]/10000;
                    rewards = timeDiff * reward * 1 ether;
                    
                    _setAccountBalance(_owner, rewards, false, 0);

                    /*  console.log("weapontier reward: ", weaponTierReward[_weaponTier]);
                        console.log("weapontier: ", _weaponTier);
                        console.log("levelTier: ", levelTier); 
                        console.log("levelMultiplier :", levelMultiplier[levelTier]/10000);
                        console.log("daily reward: ", reward);
                        console.log("total rewards: ", rewards);
                    */
    }


    function _rollWeapon(uint256 level, uint256 id, uint256 rand, uint256 maxTierWeapon) internal returns (uint256 newWeapon, uint256 newWeaponTier) {
    
        uint256 levelTier = level == 100 ? 5 : uint256((level/20) + 1);
                
                uint256  chance = _randomize(rand, "Weapon", id) % 100;
      
                if(chance > 10 && chance < 80){
        
                             newWeaponTier = levelTier;
        
                        }else if (chance > 80 ){
        
                             newWeaponTier = levelTier + 1 > 4 ? 4 : levelTier + 1;
        
                        }else{
                             newWeaponTier = levelTier - 1 < 1 ? 1 : levelTier - 1;          
                        }
                         
                newWeaponTier = newWeaponTier > maxTierWeapon ? maxTierWeapon : newWeaponTier;

                newWeapon = ((newWeaponTier - 1) * 3) + (rand % 3);   

                 emit RollOutcome(id, chance, 5);           
        
    }

     function _rollitems(uint256 id_) internal returns (uint256 newInventory) {
        
        uint16 morerand = uint16(_randomize(_rand(), "Inventory", id_));
        uint16 diceRoll = uint16(_randomize(_rand(), "Dice", id_));
        
        diceRoll = (diceRoll % 100);
        
        if(diceRoll <= 20){

            newInventory = morerand % 6 + 1;//MAX VALUE 6. Min VALUE: 1
     
        }

        emit RollOutcome(id_, diceRoll, 6);       
         
        
    }



    function _rollCooldown(uint256 _timestamp, uint256 id, uint256 rand) internal returns (uint256 timestamp_) {

        uint16 chance = uint16 (_randomize(rand, "Cooldown", id) % 100); //percentage chance of re-rolling cooldown
        uint256 cooldownLeft = _timestamp - block.timestamp; //time left on cooldown
        timestamp_ = _timestamp; //initialize timestamp to old timestamp

            if(cooldownLeft > 0){
                    
                    if(chance > 10 && chance < 70){
                    
                        timestamp_ = block.timestamp + (cooldownLeft * 2/3);
                    
                    }else if (chance > 70 ){
                    
                        timestamp_ = timestamp_ + 5 minutes;
                    
                    }else{
                            
                        timestamp_ = block.timestamp + (cooldownLeft * 1/2);
                        
                        }
            }

             emit RollOutcome(id, chance, 9);

        return timestamp_;    
                
    }

    /////FUNCTIONS THAT IMPACT STATE ///////////////

    function _buyItem(uint buyItemIndex, address elfOwner) internal returns (uint256 newInventory) {
            //SHOP IS BUYING
            PawnItems memory _pawnItemsBuy = pawnItems[buyItemIndex]; //get item being sold
            require(_pawnItemsBuy.currentInventory < _pawnItemsBuy.maxSupply, "tooHigh");  //check if we will accept
            require(buyItemIndex != 0, "noItem"); //check if we have an item to trade
            require(buyItemIndex != 6, "noItem"); //cannot trade this item           

            uint256 buyPrice = uint256(_pawnItemsBuy.buyPrice); 
            buyPrice = buyPrice * (1 ether); 
 
            _setAccountBalance(elfOwner, buyPrice, false, 0); // pay the seller
            newInventory = 0; // take their item
       
            pawnItems[buyItemIndex].currentInventory = _pawnItemsBuy.currentInventory + 1; //add item to elf pawn stock

                   
        return newInventory;      
        
    }

    

    function _sellItem(uint sellItemIndex, address elfOwner) internal returns (uint256 newInventory) {
               //SHOP IS SELLING
               require(sellItemIndex != 0, "noItem"); //check if we have an item to trade
               PawnItems memory _pawnItems = pawnItems[sellItemIndex];  
         
               uint256 salePrice = uint256(_pawnItems.sellPrice);         
               salePrice = salePrice * (1 ether);

            require(_pawnItems.currentInventory > 0, "noSupply");
            //require(bankBalances[elfOwner] >= salePrice, "notEnoughRen");
             checkRen(elfOwner, salePrice);
            

            _setAccountBalance(elfOwner, salePrice, true, 0); // take ren from buyer
            newInventory = sellItemIndex; //give item to buyer
            
            pawnItems[sellItemIndex].currentInventory = _pawnItems.currentInventory - 1; //reduce our stocks        
                   
        return newInventory;      
        
    }

    function _returnCrusade(uint256 id_, address elfOwner, bool useMoon) private {
            onCrusade[id_] = 0;//reset elf on crusade
            DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id_]);
            
            GameVariables memory actions;
            require(isGameActive);
            require(elf.owner == elfOwner, "notYourElf");
            require(elf.timestamp < block.timestamp, "elfBusy");
            require(elf.action == 14, "!onCruasde"); 
           
            elf.action = 15;
            //add MOON reduction here

            uint256 chance = _randomize(_rand(), "Crusade", id_) % 100;
            uint256 artifactsReceived = 1;
            uint256 artifactsChance = 10;

            if(useMoon){
               //used 15 moon to increase odds  
                checkMoon(elfOwner, 15 ether);
                _setAccountBalance(elfOwner, 15 ether, true, 1); 
                artifactsChance = 20;
                }

            if(chance < artifactsChance){
                artifactsReceived = 2;
            }

            artifacts[elfOwner] = artifactsReceived + artifacts[elfOwner];

            actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
            actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
                       
            sentinels[id_] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
            
            emit Action(elfOwner, 15, id_); 
            emit ArtifactFound(elfOwner, artifactsReceived, id_);
            emit RollOutcome(id_, chance, 15);
    }

    function _setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) private {
            
            if(_index == 0){
                //0 = REN
                _subtract ? bankBalances[_owner] -= _amount : bankBalances[_owner] += _amount;
                emit BalanceChanged(_owner, _amount, _subtract);

            }else if(_index == 1){
                //1 = MOON
                _subtract ? moonBalances[_owner] -= _amount : bankBalances[_owner] += _amount;
                emit MoonBalanceChanged(_owner, _amount, _subtract);

            }
            
    }


    function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}

    function _rand() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, block.basefee, block.coinbase)));}

/*
█▀█ █░█ █▄▄ █░░ █ █▀▀   █░█ █ █▀▀ █░█░█ █▀
█▀▀ █▄█ █▄█ █▄▄ █ █▄▄   ▀▄▀ █ ██▄ ▀▄▀▄▀ ▄█
*/

    function tokenURI(uint256 _id) external view returns(string memory) {
    return elfmetaDataHandler.getTokenURI(uint16(_id), sentinels[_id]);
    }

    function attributes(uint256 _id) external view returns(uint hair, uint race, uint accessories, uint sentinelClass, uint weaponTier, uint inventory){
    uint256 character = sentinels[_id];

    uint _traits =        uint256(uint8(character>>240));
    uint _class =         uint256(uint8(character>>248));

    hair           = (_traits / 100) % 10;
    race           = (_traits / 10) % 10;
    accessories    = (_traits) % 10;
    sentinelClass  = (_class / 100) % 10;
    weaponTier     = (_class / 10) % 10;
    inventory      = (_class) % 10; 

}

function getSentinel(uint256 _id) external view returns(uint256 sentinel){
    return sentinel = sentinels[_id];
}


function elves(uint256 _id) external view returns(address owner, uint timestamp, uint action, uint healthPoints, uint attackPoints, uint primaryWeapon, uint level) {

    uint256 character = sentinels[_id];

    owner =          address(uint160(uint256(character)));
    timestamp =      uint(uint40(character>>160));
    action =         uint(uint8(character>>200));
    healthPoints =   uint(uint8(character>>208));
    attackPoints =   uint(uint8(character>>216));
    primaryWeapon =  uint(uint8(character>>224));
    level =          uint(uint8(character>>232));   

}

/*

█▀▄▀█ █▀█ █▀▄ █ █▀▀ █ █▀▀ █▀█ █▀
█░▀░█ █▄█ █▄▀ █ █▀░ █ ██▄ █▀▄ ▄█
*/

    function onlyOperator() internal view {    
       require(msg.sender == operator || auth[msg.sender] == true);

    }

    function onlyOwner() internal view {    
        require(admin == msg.sender);
    }

    function checkRen(address elfOwner, uint256 amount) internal view {    
        require(bankBalances[elfOwner] >= amount, "notEnoughRen");        
    }
    
    function checkMoon(address elfOwner, uint256 amount) internal view {    
        require(moonBalances[elfOwner] >= amount, "notEnoughMoon");        
    }
    function checkArtifacts(address elfOwner, uint256 amount) internal view {    
        require(artifacts[elfOwner] >= amount, "notEnoughArtifacts");        
    }


/*
▄▀█ █▀▄ █▀▄▀█ █ █▄░█   █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
█▀█ █▄▀ █░▀░█ █ █░▀█   █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
*/




function setCreatureHealth(uint256 creatureHealth) external {
        onlyOwner();
        CREATURE_HEALTH = creatureHealth;
}

function addScrolls(uint256[] calldata qty, address[] memory owners) external {
        onlyOwner();
        for(uint256 i = 0; i < qty.length; i++) {
            if(qty[i] > 0) {
                 scrolls[owners[i]] = qty[i];
            }
        }
}

function addCamp(uint256 id, uint16 baseRewards_, uint16 creatureCount_, uint16 expPoints_, uint16 creatureHealth_, uint16 minLevel_, uint16 maxLevel_) external      
    {
        onlyOwner();
        
        Camps memory newCamp = Camps({
            baseRewards:    baseRewards_, 
            creatureCount:  creatureCount_, 
            expPoints:      expPoints_,
            creatureHealth: creatureHealth_, 
            minLevel:       minLevel_,
            campMaxLevel:   maxLevel_
            });
        
        camps[id] = newCamp;        
        
    }


function addRampage(uint256 id, uint16 probDown_, uint16 probSame_, uint16 propUp_, uint16 levelsGained_, uint16 minLevel_, uint16 maxLevel_, uint16 renCost_, uint16 count_) external      
    {
        onlyOwner();

            Rampages memory newRampage = Rampages({
                
                probDown: probDown_, 
                probSame: probSame_, 
                propUp: propUp_, 
                levelsGained: levelsGained_, 
                minLevel: minLevel_, 
                maxLevel: maxLevel_, 
                renCost: renCost_, 
                count: count_
                
                }); 
            
        
            rampages[id] = newRampage;        
       
    }

function addPawnItem(uint256 id, uint16 buyPrice_, uint16 sellPrice_, uint16 maxSupply_, uint16 currentInventory_) external      
    {
        onlyOwner();

            PawnItems memory newPawnItem = PawnItems({
                
                buyPrice: buyPrice_, 
                sellPrice: sellPrice_, 
                maxSupply: maxSupply_, 
                currentInventory: currentInventory_
                
                }); 
            
        
            pawnItems[id] = newPawnItem;        
       
    }


   function adminSetAccountBalance(address _owner, uint256 _amount) public {                
        onlyOwner();
        bankBalances[_owner] += _amount;
    }

    function setElfManually(uint id, uint8 _primaryWeapon, uint8 _weaponTier, uint8 _attackPoints, uint8 _healthPoints, uint8 _level, uint8 _inventory, uint8 _race, uint8 _class, uint8 _accessories, address _elfOwner) external {
        onlyOwner();
        DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id]);
        GameVariables memory actions;

        elf.owner           = _elfOwner;
        elf.timestamp       = elf.timestamp;
        elf.action          = elf.action;
        elf.healthPoints    = _healthPoints;
        elf.attackPoints    = _attackPoints;
        elf.primaryWeapon   = _primaryWeapon;
        elf.level           = _level;
        elf.weaponTier      = _weaponTier;
        elf.inventory       = _inventory;
        elf.race            = _race;
        elf.sentinelClass   = _class;
        elf.accessories     = _accessories;

        actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
        actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
                       
        sentinels[id] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
        
    }

        function changeElfAccessory(uint8 accessoryIndex, uint id) external {
       
        onlyOwner();
        DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id]);
        GameVariables memory actions;
        require(accessoryIndex <=7, "outOfRange");

        elf.accessories = accessoryIndex;
       
        actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
        actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
                       
        sentinels[id] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
        
    }
    
    function setAddresses(address _inventory, address _operator)  public {
       onlyOwner();
       elfmetaDataHandler   = IElfMetaDataHandler(_inventory);
       operator             = _operator;
    }


    function setValidator(address _validator)  public {
       onlyOwner();
       polyValidator = _validator;
    }
    
    function setAuth(address[] calldata adds_, bool status) public {
       onlyOwner();
       
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }     
    
    //Bridge

    function prismBridge(uint256[] calldata ids, uint256[] calldata sentinel, address owner) external {
      onlyOperator();
        
        for(uint i = 0; i < ids.length; i++){           
            
            DataStructures.Elf memory elf = DataStructures.getElf(sentinels[ids[i]]);            
            require(elf.owner == address(0), "Already in Polygon");
            
            sentinels[ids[i]] = sentinel[i];
            emit ElfTransferedIn(ids[i], sentinel[i]);
        }
        //emit event to        sentinelTransfers ids 
        
    }

    function exitElf(uint256[] calldata ids, address owner) external {
      onlyOperator();
      uint256 action = 0;
          
        for(uint i = 0; i < ids.length; i++){
            
           _actions(ids[i], 0, owner, 0, 0, false, false, false, 0);
           emit CheckIn(owner, block.timestamp, ids[i], sentinels[ids[i]]);
           sentinels[ids[i]] = 0; //scramble their bwainz.. muahaha.
         
        }        
         
    } 

     
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external {
            
            onlyOperator();
            if(_subtract){
               
                    if(_index == 0){
                        checkRen(_owner, _amount);
                        bankBalances[_owner] -= _amount;                     
                        emit RenTransferOut(_owner,block.timestamp,_amount);

                    }else if (_index == 1){
                        checkMoon(_owner, _amount);
                        moonBalances[_owner] -= _amount; 

                    }else if (_index == 2){
                        checkArtifacts(_owner, _amount);
                        artifacts[_owner] -= _amount; 
                    }
                    

            }else{
                
                    if(_index == 0){
                        //0 = REN
                        bankBalances[_owner] += _amount;                       
                        emit RenTransferedIn(_owner, _amount);        

                    }else if(_index == 1){
                        //1 = Moon
                        moonBalances[_owner] += _amount;
                        
                    }else if(_index == 2){
                        //2 = Artifacts
                        artifacts[_owner] += _amount;
                        
                    }   

            }

            
            
    }

    function getAllAccountBalances(address _owner) external returns (uint256 ren_, uint256 moon_, uint256 artifacts_, uint256 scrolls_) {

           ren_ = bankBalances[_owner];                
           moon_ = moonBalances[_owner];                
           artifacts_ = artifacts[_owner];
           scrolls_ = scrolls[_owner];

    }

        function _mintArtifact (address _owner, uint256 _artifacts) internal {
        //make sure we have enough artifacts to mint
        require(artifacts[_owner] >= _artifacts, "notEnoughArtifacts");
        //remove minted amount from artifacts memory
        artifacts[_owner] = artifacts[_owner] - _artifacts;
        //emit message to dApp to prepare signatures for eth Minting
        emit ArtifactsMinted(_owner, _artifacts, block.timestamp);
        
    }


    ///////////////////////////////////////////////////////////////////
    //TESTNET FUNCTIONS///////////////////////////////////////////////
    //COMMENT OUT BEFORE DEPLOYMENT//////////////////////////////////
    function mintZombie(uint256 qty) external {
              for(uint i = 1; i <= qty; i++){        
                    _mint(address(this), i);     
              }              
    }    

    function initialize() public {
    
       require(!initialized, "Already initialized");
       admin                = msg.sender;   
       initialized          = true;
       operator             = 0x5707FF21A520BEEBcCdAD13dF292576e7FbE4cB4; 
       elfmetaDataHandler   = IElfMetaDataHandler(	0x5707FF21A520BEEBcCdAD13dF292576e7FbE4cB4);
       auth[0xe2ae5460b5796e2800C064Fae2A4caB347A1447B] = true;
       auth[0x1653FeA0EAb46A843239f3993EFFc4Cc0B6706DE] = true; 
       camps[1] = Camps({baseRewards: 10, creatureCount: 1000, creatureHealth: 120,  expPoints:6,   minLevel:1, campMaxLevel:100});
       CREATURE_HEALTH = 420; 
       MAX_LEVEL = 100;
       TIME_CONSTANT = 1 hours; 
       REGEN_TIME = 300 hours; 
       isGameActive = true;
       isTerminalOpen = true;

    }

    function setAllBalances(address _owner, uint256 _ren, uint256 _moon, uint256 _scrolls, uint256 _artifacts) external {
        onlyOwner();
        bankBalances[_owner] = _ren;
        moonBalances[_owner] = _moon;          
        scrolls[_owner] = _scrolls;
        artifacts[_owner] = _artifacts;
    }
    


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract PolyERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    // function transfer(address to, uint256 tokenId) external {
    //     require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
    //     _transfer(msg.sender, to, tokenId);
        
    // }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    // function approve(address spender, uint256 tokenId) external {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
    //     getApproved[tokenId] = spender;
        
    //     emit Approval(owner_, spender, tokenId); 
    // }
    
    // function setApprovalForAll(address operator, bool approved) external {
    //     isApprovedForAll[msg.sender][operator] = approved;
        
    //     emit ApprovalForAll(msg.sender, operator, approved);
    // }

    // function transferFrom(address, address to, uint256 tokenId) public {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(
    //         msg.sender == owner_ 
    //         || msg.sender == getApproved[tokenId]
    //         || isApprovedForAll[owner_][msg.sender], 
    //         "NOT_APPROVED"
    //     );
        
    //     _transfer(owner_, to, tokenId);
        
    // }
    
    // function safeTransferFrom(address, address to, uint256 tokenId) external {
    //     safeTransferFrom(address(0), to, tokenId, "");
    // }
    
    // function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
    //     transferFrom(address(0), to, tokenId); 
        
    //     if (to.code.length != 0) {
    //         // selector = `onERC721Received(address,address,uint,bytes)`
    //         (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
    //             msg.sender, address(0), tokenId, data));
                
    //         bytes4 selector = abi.decode(returned, (bytes4));
            
    //         require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    //     }
    // }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "not owner");

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint supply = oldSupply + minted;
        uint maxSupply = 6666;
        require(supply <= maxSupply, "MAX SUPPLY REACHED");
        totalSupply++;
                
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;
//import "hardhat/console.sol"; ///REMOVE BEFORE DEPLOYMENT
//v 1.0.3

library DataStructures {

/////////////DATA STRUCTURES///////////////////////////////
    struct Elf {
            address owner;  
            uint256 timestamp; 
            uint256 action; 
            uint256 healthPoints;
            uint256 attackPoints; 
            uint256 primaryWeapon; 
            uint256 level;
            uint256 hair;
            uint256 race; 
            uint256 accessories; 
            uint256 sentinelClass; 
            uint256 weaponTier; 
            uint256 inventory; 
    }

    struct Token {
            address owner;  
            uint256 timestamp; 
            uint8 action; 
            uint8 healthPoints;
            uint8 attackPoints; 
            uint8 primaryWeapon; 
            uint8 level;
            uint8 hair;
            uint8 race; 
            uint8 accessories; 
            uint8 sentinelClass; 
            uint8 weaponTier; 
            uint8 inventory; 
    }

    struct ActionVariables {

            uint256 reward;
            uint256 timeDiff;
            uint256 traits; 
            uint256 class;  
    }

    struct Camps {
            uint32 baseRewards; 
            uint32 creatureCount; 
            uint32 creatureHealth; 
            uint32 expPoints; 
            uint32 minLevel;
            uint32 itemDrop;
            uint32 weaponDrop;
            uint32 spare;
    }

    /*Dont Delete, just keep it for reference

    struct Attributes { 
            uint256 hair; //MAX 3 3 hair traits
            uint256 race;  //MAX 6 Body 4 for body
            uint256 accessories; //MAX 7 4 
            uint256 sentinelClass; //MAX 3 3 in class
            uint256 weaponTier; //MAX 6 5 tiers
            uint256 inventory; //MAX 7 6 items
    }

    */

/////////////////////////////////////////////////////
function getElf(uint256 character) internal pure returns(Elf memory _elf) {
   
    _elf.owner =          address(uint160(uint256(character)));
    _elf.timestamp =      uint256(uint40(character>>160));
    _elf.action =         uint256(uint8(character>>200));
    _elf.healthPoints =       uint256(uint8(character>>208));
    _elf.attackPoints =   uint256(uint8(character>>216));
    _elf.primaryWeapon =  uint256(uint8(character>>224));
    _elf.level    =       uint256(uint8(character>>232));
    _elf.hair           = (uint256(uint8(character>>240)) / 100) % 10;
    _elf.race           = (uint256(uint8(character>>240)) / 10) % 10;
    _elf.accessories    = (uint256(uint8(character>>240))) % 10;
    _elf.sentinelClass  = (uint256(uint8(character>>248)) / 100) % 10;
    _elf.weaponTier     = (uint256(uint8(character>>248)) / 10) % 10;
    _elf.inventory      = (uint256(uint8(character>>248))) % 10; 

} 

function getToken(uint256 character) internal pure returns(Token memory token) {
   
    token.owner          = address(uint160(uint256(character)));
    token.timestamp      = uint256(uint40(character>>160));
    token.action         = (uint8(character>>200));
    token.healthPoints   = (uint8(character>>208));
    token.attackPoints   = (uint8(character>>216));
    token.primaryWeapon  = (uint8(character>>224));
    token.level          = (uint8(character>>232));
    token.hair           = ((uint8(character>>240)) / 100) % 10; //MAX 3
    token.race           = ((uint8(character>>240)) / 10) % 10; //Max6
    token.accessories    = ((uint8(character>>240))) % 10; //Max7
    token.sentinelClass  = ((uint8(character>>248)) / 100) % 10; //MAX 3
    token.weaponTier     = ((uint8(character>>248)) / 10) % 10; //MAX 6
    token.inventory      = ((uint8(character>>248))) % 10; //MAX 7

    token.hair = (token.sentinelClass * 3) + (token.hair + 1);
    token.race = (token.sentinelClass * 4) + (token.race + 1);
    token.primaryWeapon = token.primaryWeapon == 69 ? 69 : (token.sentinelClass * 15) + (token.primaryWeapon + 1);
    token.accessories = (token.sentinelClass * 7) + (token.accessories + 1);

}

function _setElf(
                address owner, uint256 timestamp, uint256 action, uint256 healthPoints, 
                uint256 attackPoints, uint256 primaryWeapon, 
                uint256 level, uint256 traits, uint256 class )

    internal pure returns (uint256 sentinel) {

    uint256 character = uint256(uint160(address(owner)));
    
    character |= timestamp<<160;
    character |= action<<200;
    character |= healthPoints<<208;
    character |= attackPoints<<216;
    character |= primaryWeapon<<224;
    character |= level<<232;
    character |= traits<<240;
    character |= class<<248;
    
    return character;
}

//////////////////////////////HELPERS/////////////////

function packAttributes(uint hundreds, uint tens, uint ones) internal pure returns (uint256 packedAttributes) {
    packedAttributes = uint256(hundreds*100 + tens*10 + ones);
    return packedAttributes;
}

function calcAttackPoints(uint256 sentinelClass, uint256 weaponTier) internal pure returns (uint256 attackPoints) {

        attackPoints = ((sentinelClass + 1) * 2) + (weaponTier * 2);
        
        return attackPoints;
}

function calcHealthPoints(uint256 sentinelClass, uint256 level) internal pure returns (uint256 healthPoints) {

        healthPoints = (level/(3) +2) + (20 - (sentinelClass * 4));
        
        return healthPoints;
}

function calcCreatureHealth(uint256 sector, uint256 baseCreatureHealth) internal pure returns (uint256 creatureHealth) {

        creatureHealth = ((sector - 1) * 12) + baseCreatureHealth; 
        
        return creatureHealth;
}

function roll(uint256 id_, uint256 level_, uint256 rand, uint256 rollOption_, uint256 weaponTier_, uint256 primaryWeapon_, uint256 inventory_) 
internal pure 
returns (uint256 newWeaponTier, uint256 newWeapon, uint256 newInventory) {

   uint256 levelTier = level_ == 100 ? 5 : uint256((level_/20) + 1);

   newWeaponTier = weaponTier_;
   newWeapon     = primaryWeapon_;
   newInventory  = inventory_;


   if(rollOption_ == 1 || rollOption_ == 3){
       //Weapons
      
        uint16  chance = uint16(_randomize(rand, "Weapon", id_)) % 100;
       // console.log("chance: ", chance);
                if(chance > 10 && chance < 80){
        
                              newWeaponTier = levelTier;
        
                        }else if (chance > 80 ){
        
                              newWeaponTier = levelTier + 1 > 5 ? 5 : levelTier + 1;
        
                        }else{

                                newWeaponTier = levelTier - 1 < 1 ? 1 : levelTier - 1;          
                        }

                                         
        

        newWeapon = newWeaponTier == 0 ? 0 : ((newWeaponTier - 1) * 3) + (rand % 3);  
        

   }
   
   if(rollOption_ == 2 || rollOption_ == 3){//Items Loop
      
       
        uint16 morerand = uint16(_randomize(rand, "Inventory", id_));
        uint16 diceRoll = uint16(_randomize(rand, "Dice", id_));
        
        diceRoll = (diceRoll % 100);
        
        if(diceRoll <= 20){

            newInventory = levelTier > 3 ? morerand % 3 + 3: morerand % 6 + 1;
            //console.log("Token#: ", id_);
            //console.log("newITEM: ", newInventory);
        } 

   }
                      
              
}


function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}



}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

/*
interface ITunnel {
    function sendMessage(bytes calldata message_) external;
}

interface ITerminus {
    function pullCallback(address owner, uint256[] calldata ids) external;
    
}
*/

interface IElders {


}

interface IArtifacts {

    
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

/*
interface IEthernalElves {
function presale(uint256 _reserveAmount, address _whitelister) external payable returns (uint256 id);
}
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}