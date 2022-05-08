// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "../base/Ownable.sol";

import { Helpers } from "../base/Helpers.sol";
import { Fish_Species_01 } from "../creatures/Fish_Species_01.sol";

/**
 * @title Fish_Species_01
 * @dev Useed to generate Fish_Species_01 NFT's
 */
contract Fish_Species_01_Extension is Ownable {

    event LogRequestRandom(string message);
    event LogRandomRequestResponse(bytes32 tokenId);
    event ExtensionMintComplete(uint256 tokenId);
    event ExtensionBreedComplete(uint256 tokenId);
        
    event ItemSet(uint16 val);

    mapping(uint256 => string) public transactionStatus;

    mapping(uint256 => bool) public cashedOutCreatures;
    mapping(uint256 => bool)  public killedCreatures;
    mapping(uint256 => bool) public creatureAlive;
    mapping(uint256 => uint16) public creatureBreedCounter;

    uint256 public totalActiveCreatureCount;

    mapping(uint256 => uint16) internal creature_total_points;
    mapping(uint256 => uint16) internal creature_part_rare_count;

    mapping(uint256 => mapping(uint16 => uint16)) internal _creaturesPoints;

    mapping(uint256 => uint256) internal creature_KilledBy;
    mapping(uint256 => bool) internal creature_Killed_parents;
    
    mapping(uint256 => uint256) private _code1;
    mapping(uint256 => uint256) private _code2;
    mapping(uint256 => uint256) private _code3;

    uint16 public valueType;
    uint16 maxBreedCount;

    constructor(uint16 _valueType) 
    {
        valueType = _valueType;
        maxBreedCount = 5;
    }

    address public _fish_Species_01_ContractAddress;
    event Fish_Species_01_ContractAddressUpdated(address fish_Species_01_ContractAddress);
    function setFish_Species_01_ContractAddress(address fish_Species_01_ContractAddress)
        public 
        onlyOwner
    {
        _fish_Species_01_ContractAddress = fish_Species_01_ContractAddress;
        emit Fish_Species_01_ContractAddressUpdated(fish_Species_01_ContractAddress);
    }

    function setMaxBreedCount(uint16 _maxBreedCount) public
        noReEntry
        onlyOwner
    {
        maxBreedCount = _maxBreedCount;
    }

    /**
     * modifier used by safeMint to prevent re-entry attacks
     */
    bool internal locked;
    modifier noReEntry() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function getCode(uint8 code, uint256 tokenId) public view returns (uint256 returnCode) {
        if(code == 1) return _code1[tokenId];
        if(code == 2) return _code2[tokenId];
        if(code == 3) return _code3[tokenId];
    }

    mapping(uint16 => mapping(uint256 => uint256)) internal partId_variationIdCount_all_creatures;
    mapping(uint16 => mapping(uint256 => uint256)) public point_allocations_all_creatures_partId_variationId;
    mapping(uint256 => mapping(uint8 => uint8)) internal creature_points_partId_variationId;
    mapping(uint256 => mapping(uint8 => mapping(uint16 => uint16))) public creature_randomSet_randomKey_randomValue;
    mapping(uint256 => mapping(uint8 => uint8)) public creature_partId_parent;

    mapping(uint256 => mapping(uint8 => uint256)) internal _tokenRandomness;

    uint256 public contract_points_value_balance;

    uint256 creatureCount;
    address private _owner;
    address private _creatureContractAddress;

    uint256 public _totalActivePoints; 

    mapping(uint256 => uint32) public creature_generationCount_parent_1;
    mapping(uint256 => uint32) public creature_generationCount_parent_2;

    mapping(uint256 => uint256) public creature_parent_1;
    mapping(uint256 => uint256) public creature_parent_2;

    function mint(uint16 _valueType, uint256 tokenId, uint256 creature_valueType_balance, uint256 randomness) 
        noReEntry
        onlyOwner
        public 
    {

        preCreate(_valueType, tokenId, creature_valueType_balance, true);  

        _tokenRandomness[tokenId][1] = randomness;
        _tokenRandomness[tokenId][2] = uint256(keccak256(abi.encode(randomness, 2)));
        _tokenRandomness[tokenId][3] = uint256(keccak256(abi.encode(randomness, 3)));

        postCreate(tokenId, false);
    }

    function mintTest(uint16 _valueType, uint256 tokenId, uint256 creature_valueType_balance, uint256 rand1, uint256 rand2, uint256 rand3) 
        noReEntry
        onlyOwner
        public {

        preCreate(_valueType, tokenId, creature_valueType_balance, true);  

        if(rand1 == 0) rand1 = 53452236467721590622799751259924910047686185017518078278932746526520972949066;
        if(rand2 == 0) rand2 = 11967070308067328897688358059678933681529223792157646869956368742894562417192;
        if(rand3 == 0) rand3 = 11967070308067328897688358059678933681529223792157646869956368742894562417192;

        _tokenRandomness[tokenId][1] = rand1;
        _tokenRandomness[tokenId][2] = rand2;
        _tokenRandomness[tokenId][3] = rand3;

        postCreate(tokenId, false);
    }

    function breed(uint16 _valueType, uint256 tokenId, uint256 parent1TokenId, uint256 parent2TokenId, bool kill, uint256 creature_valueType_balance, uint256 randomness) 
        noReEntry
        onlyOwner
        public 
    {
        preBreed(_valueType, tokenId, creature_valueType_balance, parent1TokenId, parent2TokenId, kill); 

        _tokenRandomness[tokenId][1] = randomness;
        _tokenRandomness[tokenId][2] = uint256(keccak256(abi.encode(randomness, 2)));
        _tokenRandomness[tokenId][3] = uint256(keccak256(abi.encode(randomness, 3)));

        transactionStatus[tokenId] = "Randomness assigned";

        postCreate(tokenId, true);
    }

    function preBreed(uint16 _valueType, uint256 tokenId, uint256 creature_valueType_balance, uint256 parent1TokenId, uint256 parent2TokenId, bool kill) private {    
        require(creatureAlive[parent1TokenId] == true, "Creature isDead");
        require(creatureAlive[parent2TokenId] == true, "Creature isDead");
        require(creatureBreedCounter[parent1TokenId] <= maxBreedCount, "Creature 1 maxBreedCount Reached");
        require(creatureBreedCounter[parent2TokenId] <= maxBreedCount, "Creature 2 maxBreedCount Reached");
        
        preCreate(_valueType, tokenId, creature_valueType_balance, true);

        creature_generationCount_parent_1[tokenId] = creature_generationCount_parent_1[parent1TokenId] + 1; 
        creature_generationCount_parent_2[tokenId] = creature_generationCount_parent_2[parent2TokenId] + 1; 

        creature_parent_1[tokenId] = parent1TokenId; 
        creature_parent_2[tokenId] = parent2TokenId;

        creatureBreedCounter[parent1TokenId] += 1;
        creatureBreedCounter[parent2TokenId] += 1;

        if(kill == true)
        {
            creature_Killed_parents[tokenId] = true;
            killCreature(parent1TokenId, tokenId);
            killCreature(parent2TokenId, tokenId);
        }
    }

    function preCreate(uint16 _valueType, uint256 tokenId, uint256 creature_valueType_balance, bool breeding) private {
        require(valueType == _valueType, "Fish_Species_01_Extension: Invalid Value Type - mismatch");
        creatureAlive[tokenId] = true; 
        _totalActivePoints += 1000;
        contract_points_value_balance = creature_valueType_balance;  
        if(breeding == false){
           creature_generationCount_parent_1[tokenId] = 1; 
           creature_generationCount_parent_2[tokenId] = 1;   
        }
    }

    function postCreate(uint256 tokenId, bool breeding) private {
        setCreatureParts(tokenId, breeding);
        setCreatureColors(tokenId, breeding);
        assignPoints();
        totalActiveCreatureCount = totalActiveCreatureCount + 1;
        cashedOutCreatures[tokenId] = false;
        killedCreatures[tokenId] = false;
        transactionStatus[tokenId] = "Create (Mint) Complete";
        emit ExtensionMintComplete(tokenId);
    }

    /**
     * @dev setCreatureParts
     */
    function setCreatureParts(uint256 tokenId, bool breeding) private {

       uint8 code1 = 1;
       uint256 pointsVariations = 1000;
        
        getRandom(code1, 1, tokenId, pointsVariations, 1, breeding); //anal_fin:
        getRandom(code1, 2, tokenId, pointsVariations, 2, breeding); // body_pattern
        getRandom(code1, 3, tokenId, pointsVariations, 3, breeding); // dorsal_fin
        getRandom(code1, 4, tokenId, 4, 0, breeding); //eyes_open
        getRandom(code1, 5, tokenId, 4, 0, breeding); //head_piece
        getRandom(code1, 6, tokenId, pointsVariations, 4, breeding); //mouth
        getRandom(code1, 7, tokenId, pointsVariations, 5, breeding); //pectoral_fin
        getRandom(code1, 8, tokenId, pointsVariations, 6, breeding); // tail_fin

        transactionStatus[tokenId] = "Parts Set";  
    } 

    /**
     * @dev setCreatureColors
     */
    function setCreatureColors(uint256 tokenId, bool breeding) private {

                uint256 toneColorVariations = 2;
                uint256 baseVariations = 10;

                uint256 pointsVariations = 1000;

                uint8 code2 = 2;
                uint8 code3 = 3;

                getRandom(code2, 1,  tokenId, toneColorVariations, 0, breeding); //toneColorId
                getRandom(code2, 2,  tokenId, pointsVariations, 7, breeding); //body_color
                getRandom(code2, 3,  tokenId, pointsVariations, 8, breeding); //eye_color
                getRandom(code2, 4,  tokenId, pointsVariations, 9, breeding); //face_color
                getRandom(code2, 5,  tokenId, pointsVariations, 10, breeding);//mouth_color
                getRandom(code2, 6,  tokenId, baseVariations, 0, breeding); // anal_fin color - 1
                getRandom(code2, 7,  tokenId, baseVariations, 0, breeding); // anal_fin color - 2
                getRandom(code2, 8,  tokenId, baseVariations, 0, breeding); // anal_fin color - 3
                getRandom(code2, 9,  tokenId, baseVariations, 0, breeding); // body color - 1
                getRandom(code2, 10, tokenId, baseVariations, 0, breeding); // body color - 2
                getRandom(code2, 11, tokenId, baseVariations, 0, breeding); // body color - 3
                getRandom(code2, 12, tokenId, baseVariations, 0, breeding); // body_pattern color - 1
                getRandom(code2, 13, tokenId, baseVariations, 0, breeding); // body_pattern color - 2
                getRandom(code2, 14, tokenId, baseVariations, 0, breeding); // body_pattern color - 3
                getRandom(code2, 15, tokenId, baseVariations, 0, breeding); // dorsal_fin color - 1
                getRandom(code2, 16, tokenId, baseVariations, 0, breeding); // dorsal_fin color - 2
                getRandom(code2, 17, tokenId, baseVariations, 0, breeding); // dorsal_fin color - 3
                getRandom(code2, 18, tokenId, baseVariations, 0, breeding); // eyes_open color - 1 
                getRandom(code2, 19, tokenId, baseVariations, 0, breeding); // eyes_open color - 2
                getRandom(code2, 20, tokenId, baseVariations, 0, breeding); // eyes_open color - 3
                getRandom(code2, 21, tokenId, baseVariations, 0, breeding);  // face color - 1
                getRandom(code2, 22, tokenId, baseVariations, 0, breeding);  // face color - 2
                getRandom(code2, 23, tokenId, baseVariations, 0, breeding);  // face color - 3

                //  CODE 3 STARTS HERE
                //  CODE 3 STARTS HERE
                //  CODE 3 STARTS HERE

                getRandom(code3, 1, tokenId, baseVariations, 0, breeding); // head_piece color - 1
                getRandom(code3, 2, tokenId, baseVariations, 0, breeding); // head_piece color - 1 
                getRandom(code3, 3, tokenId, baseVariations, 0, breeding); // head_piece color - 1
                getRandom(code3, 4, tokenId, baseVariations, 0, breeding); // mouth color - 1
                getRandom(code3, 5, tokenId, baseVariations, 0, breeding); // mouth color - 2
                getRandom(code3, 6, tokenId, baseVariations, 0, breeding); // mouth color - 3
                getRandom(code3, 7, tokenId, baseVariations, 0, breeding); // pectoral color - 1
                getRandom(code3, 8, tokenId, baseVariations, 0, breeding); // pectoral color - 2
                getRandom(code3, 9, tokenId, baseVariations, 0, breeding); // pectoral color - 3
                getRandom(code3, 10, tokenId, baseVariations, 0, breeding); // pectoral_fin color - 1
                getRandom(code3, 11, tokenId, baseVariations, 0, breeding); // pectoral_fin color - 2
                getRandom(code3, 12, tokenId, baseVariations, 0, breeding); // pectoral_fin color - 3
                getRandom(code3, 13, tokenId, baseVariations, 0, breeding); // pupil color - 1
                getRandom(code3, 14, tokenId, baseVariations, 0, breeding); // pupil color - 2
                getRandom(code3, 15, tokenId, baseVariations, 0, breeding); // pupil color - 3
                getRandom(code3, 16, tokenId, baseVariations, 0, breeding); // tail color - 1
                getRandom(code3, 17, tokenId, baseVariations, 0, breeding); // tail color - 2
                getRandom(code3, 18, tokenId, baseVariations, 0, breeding); // tail color - 3
                getRandom(code3, 19, tokenId, baseVariations, 0, breeding); // tail_fin color - 1
                getRandom(code3, 20, tokenId, baseVariations, 0, breeding); // tail_fin color - 2
                getRandom(code3, 21, tokenId, baseVariations, 0, breeding); // tail_fin color - 3

                transactionStatus[tokenId] = "Set Colors";
    } 


    // Used for testing purposes
    mapping(uint256 => uint256) public _codeTest; 
    // uint256 public val1;
    // uint256 public val2;
    // uint256 public val3;
    // uint256 public val4;
    // uint256 public val5;
    // uint256 public val6;

    // uint256 public wval1;
    // uint256 public wval2;
    // uint256 public wval3;
    // uint256 public wval4;
    // uint256 public wval5;ac
    // uint256 public wval6;

    mapping(uint256 => mapping(uint16 => uint16)) public creature_partInitalRandomValue;

    function getRandom(uint8 randomSet, uint16 randomKey, uint256 tokenId, uint256 maxValue, uint8 partIdForPoints, bool breeding) private returns (uint16) {
        // note ajust 100 for lager base 10 sample sizes i.e. 1000. Must be base 10
        uint16 randomValue;

        // if(randomSet == 1) return 0;
        // if(randomKey <= 10) return 0;

        if(maxValue == 1000) {
            if(randomSet == 1) randomValue = uint16((((_tokenRandomness[tokenId][1] / (100 ** randomKey)) % 1000) % maxValue) + 1);
            if(randomSet == 2) randomValue = uint16((((_tokenRandomness[tokenId][2] / (100 ** randomKey)) % 1000) % maxValue) + 1);
            if(randomSet == 3) randomValue = uint16((((_tokenRandomness[tokenId][3] / (100 ** randomKey)) % 1000) % maxValue) + 1);
        } else {
            if(randomSet == 1) randomValue = uint16((((_tokenRandomness[tokenId][1] / (10 ** randomKey)) % 100) % maxValue) + 1);
            if(randomSet == 2) randomValue = uint16((((_tokenRandomness[tokenId][2] / (10 ** randomKey)) % 100) % maxValue) + 1);
            if(randomSet == 3) randomValue = uint16((((_tokenRandomness[tokenId][3] / (10 ** randomKey)) % 100) % maxValue) + 1);
        }

        // if(randomSet == 1){

        //     if(randomKey == 1) val1 = randomValue;
        //     if(randomKey == 2) val2 = randomValue;
        //     if(randomKey == 3) val3 = randomValue;
        //     if(randomKey == 4) val4 = randomValue;
        //     if(randomKey == 5) val5 = randomValue;
        //     if(randomKey == 6) val6 = randomValue;

        //     if(randomKey == 1) wval1 = (randomValue * (100 ** randomKey)) / 100;
        //     if(randomKey == 2) wval2 = (randomValue * (100 ** randomKey)) / 100;
        //     if(randomKey == 3) wval3 = (randomValue * (100 ** randomKey)) / 100;
        //     if(randomKey == 4) wval4 = (randomValue * (100 ** randomKey)) / 100;
        //     if(randomKey == 5) wval5 = (randomValue * (100 ** randomKey)) / 100;
        //     if(randomKey == 6) wval6 = (randomValue * (100 ** randomKey)) / 100;

        //     if(randomKey <= 6){
        //         _codeTest[tokenId] = _codeTest[tokenId] + (randomValue * (100 ** randomKey)) / 100;
        //     }
        // }
        creature_partInitalRandomValue[tokenId][partIdForPoints] = randomValue;

        if(maxValue == 1000) {
           randomValue = randomValueBase1000_ProbabilityScore(randomValue);
        }

        if(breeding == true) {
            randomValue = getBreedingRandom(randomSet, randomKey, tokenId, partIdForPoints, randomValue);
        }

        if(randomSet == 1) _code1[tokenId] = _code1[tokenId] + ((randomValue * (100 ** randomKey)) / 100);
        if(randomSet == 2) _code2[tokenId]  = _code2[tokenId] + ((randomValue * (100 ** randomKey)) / 100);
        if(randomSet == 3) _code3[tokenId]  = _code3[tokenId] + ((randomValue * (100 ** randomKey)) / 100);

        if(partIdForPoints > 0) {
            setCreaturePoints(tokenId, partIdForPoints, randomValue);
        } 

        creature_randomSet_randomKey_randomValue[tokenId][randomSet][randomKey] = randomValue;

        return randomValue;
    }


    mapping(uint256 => mapping(uint16 => uint16)) public creature_breedingProbabilitySelector;

    mapping(uint256 => mapping(uint16 => uint16)) public creature_partDefaultRandomValue;
    mapping(uint256 => mapping(uint16 => uint16)) public creature_partDefaultRandomValue2;

    mapping(uint256 => Creature) public test;

    event DebugHelper(uint256 tokenId);

    function getBreedingRandom(uint8 randomSet, uint16 randomKey, uint256 tokenId, uint8 partId, uint16 defaultRandomValue) private returns(uint16 value) {
        uint16 randomValue;

        // test[tokenId] = getCreature(1);

        transactionStatus[tokenId] = "Breed -> Got here";

        creature_partDefaultRandomValue[tokenId][partId] = defaultRandomValue;

        FamilyCompact memory family = getFamilyCompact(tokenId);

        // these are the random values, there are 3 because of the number of random base 10 / 100 / 1000 is needed to fill up 256 uints
        if(randomSet == 1) randomValue = uint16((((_tokenRandomness[tokenId][1] / (10 ** randomKey)) % 100) % 100) + 1);
        if(randomSet == 2) randomValue = uint16((((_tokenRandomness[tokenId][2] / (10 ** randomKey)) % 100) % 100) + 1);
        if(randomSet == 3) randomValue = uint16((((_tokenRandomness[tokenId][3] / (10 ** randomKey)) % 100) % 100) + 1);

        // store the random value for reference to proove rnadomness
        creature_breedingProbabilitySelector[tokenId][partId] = randomValue;

        bool mutatate = false;
        bool inheritFromParent = false;
        bool inheritFromGrandParent = false;

        if(creature_Killed_parents[tokenId] == true) {
            if(randomValue >= 1 && randomValue <= 11) mutatate = true;
            if(randomValue > 11 && randomValue <= 66) inheritFromParent = true;
            if(randomValue > 66) inheritFromGrandParent = true;
        } else {
            // use mutated part 10% chance
            if(randomValue >= 1 && randomValue <= 11) mutatate = true;
            // 55% chance of inheriting part from a parent 
            if(randomValue > 11 && randomValue <= 66) inheritFromParent = true;
            // 35% chance of inheriting part from a grandprent 
            if(randomValue > 66) inheritFromGrandParent = true;
        }

        // this will only happen if any of the parents have no parents themselfs (so no grandparents)
        // So gen 1 and 2
        // Will force the genes to be use to only come from the parents (no grandparents)
        if(family.parent1_parent1.tokenId == 0) inheritFromParent = true;
        if(family.parent1_parent2.tokenId == 0) inheritFromParent = true;
        if(family.parent2_parent1.tokenId == 0) inheritFromParent = true;
        if(family.parent2_parent2.tokenId == 0) inheritFromParent = true;

        if(mutatate) {
            // means there was a mutation
            creature_partId_parent[tokenId][partId] = 0;

            // this checks to ensure that that the mutation value is not less than the parents parts. 
            // So will always use the highest between the parents and the mutation
            if(family.parent1.tokenId != 0) {
                if(defaultRandomValue > creature_randomSet_randomKey_randomValue[family.parent1.tokenId][randomSet][randomKey]) defaultRandomValue = creature_randomSet_randomKey_randomValue[family.parent1.tokenId][randomSet][randomKey];
            }
            if(family.parent2.tokenId != 0) {
                if(defaultRandomValue > creature_randomSet_randomKey_randomValue[family.parent2.tokenId][randomSet][randomKey]) defaultRandomValue = creature_randomSet_randomKey_randomValue[family.parent2.tokenId][randomSet][randomKey];
            }

            creature_partDefaultRandomValue2[tokenId][partId] = defaultRandomValue;
            return defaultRandomValue;
        }
    
        // if there is no mutation the following will proceed;
        // inheritFromParent
        if(inheritFromParent) {
            // this needs to stay here - if this is not a first generation the defaultRandomValue will be returned (later)
            if(family.parent1.tokenId != 0) {
                uint16 parent2use = uint16((((_tokenRandomness[tokenId][1] / (10 ** randomKey)) % 100) % 100) + 1);
                
                // 50/50 chance from which parent the part will be inherited
                
                // inherit part from parent 1
                if(parent2use >= 1 && parent2use <= 50) {
                    // parent 1 -> (parentId = 1)
                    creature_partId_parent[tokenId][partId] = 1;
                    return creature_randomSet_randomKey_randomValue[family.parent1.tokenId][randomSet][randomKey];
                }
                // inherit part from parent 2
                if(parent2use > 50) {
                    // parent 1 -> (parentId = 2)
                    creature_partId_parent[tokenId][partId] = 2;
                    return creature_randomSet_randomKey_randomValue[family.parent2.tokenId][randomSet][randomKey];
                }
            }
        }

        // inheritFromGrandParent
        if(inheritFromGrandParent) {
            uint16 parent2use = uint16((((_tokenRandomness[tokenId][1] / (10 ** randomKey)) % 100) % 100) + 1);
            uint16 grandParent2use = uint16((((_tokenRandomness[tokenId][1] / (10 ** randomKey)) % 100) % 100) + 1);
            // first 50/50 as to which parent to inherit from
            if(parent2use >= 1 && parent2use <= 50) {
                // use parent 1
                // 50/50 which of parent 1's parents (which grandparent to use)
                if(grandParent2use >= 1 && grandParent2use <= 50) {
                    // use parent1 -> parent 1 (parentId = 3)
                    creature_partId_parent[tokenId][partId] = 3;
                    return creature_randomSet_randomKey_randomValue[family.parent1_parent1.tokenId][randomSet][randomKey];
                }
                if(grandParent2use > 50) {
                    // use parent1 -> parent 2 (parentId = 4)
                    creature_partId_parent[tokenId][partId] = 4;
                    return creature_randomSet_randomKey_randomValue[family.parent1_parent2.tokenId][randomSet][randomKey];
                }
            }

            if(parent2use > 50) {
                // use parent 2
                // 50/50 which of parent 2's parents (which grandparent to use)
                if(grandParent2use >= 1 && grandParent2use <= 50) {
                    // use parent2 -> parent 1 (parentId = 5)
                    creature_partId_parent[tokenId][partId] = 5;
                    return creature_randomSet_randomKey_randomValue[family.parent2_parent1.tokenId][randomSet][randomKey];
                }
                if(grandParent2use > 50) {
                    // use parent2 -> parent 1 (parentId = 6)
                    creature_partId_parent[tokenId][partId] = 6;
                    return creature_randomSet_randomKey_randomValue[family.parent2_parent2.tokenId][randomSet][randomKey];
                }
            }
        }

        creature_partId_parent[tokenId][partId] = 99;
        // this should hopefully never happen but adding a fallback in anycase.
        return defaultRandomValue;
    }
    

    function randomValueBase1000_ProbabilityScore(uint16 randomValue) public pure returns (uint16 randomValueBase1000) {
        if(randomValue >= 1 && randomValue <= 2) return 1;
        if(randomValue > 2 && randomValue <= 7) return 2;
        if(randomValue > 7 && randomValue <= 17) return 3;
        if(randomValue > 17 && randomValue <= 37) return 4;
        if(randomValue > 37 && randomValue <= 137) return 5;    
        if(randomValue > 137 && randomValue <= 267) return 6;  
        if(randomValue > 267 && randomValue <= 407) return 7;
        if(randomValue > 407 && randomValue <= 571) return 8;
        if(randomValue > 571 && randomValue <= 751) return 9;  
        if(randomValue > 751) return 10;    
    }

  
    function setCreaturePoints(uint256 tokenId, uint8 partId, uint16 variationId) internal {

        partId_variationIdCount_all_creatures[partId][variationId] += 1;

        creature_points_partId_variationId[tokenId][partId] = uint8(variationId);

        uint8 score;

        if(variationId == 1) score = 34;
        if(variationId == 2) score = 24; 
        if(variationId == 3) score = 20;       
        if(variationId == 4) score = 16;
        if(variationId == 5) score = 0;
        if(variationId == 6) score = 0;
        if(variationId == 7) score = 0;
        if(variationId == 8) score = 0;
        if(variationId == 9) score = 0;
        if(variationId == 10) score = 0;

        if(variationId == 1) creature_part_rare_count[tokenId] += 1;
      
        creature_total_points[tokenId] += score;

        _creaturesPoints[tokenId][partId] = score;
    
        // keep in this order
        bool bonusAwarded = false;
        if(creature_part_rare_count[tokenId] == 10){
            bonusAwarded == true;
            _creaturesPoints[tokenId][uint8(Helpers.PointAllocationTypes.head_bonus)] = 10;
        }

        if(creature_part_rare_count[tokenId] >= 9 && bonusAwarded == false){
            bonusAwarded == true;
            _creaturesPoints[tokenId][uint8(Helpers.PointAllocationTypes.head_bonus)] = 20;
        }

        if(creature_part_rare_count[tokenId] >= 3 && bonusAwarded == false){
            bonusAwarded == true;
            _creaturesPoints[tokenId][uint8(Helpers.PointAllocationTypes.head_bonus)] = 30;
        }

        transactionStatus[tokenId] = "Set Points";
    }

    uint8[10] internal pointsToDistribute = [34,24,20,16,0,0,0,0,0,0];

    function assignPoints() internal {
        for (uint8 i=1; i <= 10; i++) {
            for (uint8 j=1; j <= 10; j++) {
                point_allocations_all_creatures_partId_variationId[j][i] += pointsToDistribute[i - 1];
            }
        }

        point_allocations_all_creatures_partId_variationId[11][3] += 10;
        point_allocations_all_creatures_partId_variationId[11][2] += 20;
        point_allocations_all_creatures_partId_variationId[11][1] += 30;

        //_totalActivePoints += 1000; // needs to happen ealier for breeding
    }

    struct Variation { 
            uint8 partId;
            uint8 variationId;
            uint16 partAllocatedPoints;
            uint256 totalVariationCount;
            uint256 totalVariationPoints;
            uint256 creatureVariationPoints;
            uint256 partValue;
    }

    struct CreatureParts {
        Variation part_1;
        Variation part_2;
        Variation part_3;
        Variation part_4;
        Variation part_5;
        Variation part_6;
        Variation part_7;
        Variation part_8;
        Variation part_9;
        Variation part_10;
    }

    struct CreatureBonusParts {
        Variation part_11;
    }

    struct Family {
        uint256 tokenId;
        Creature parent1;
        Creature parent2;
        Creature parent1_parent1;
        Creature parent1_parent2;
        Creature parent2_parent1;
        Creature parent2_parent2;
    }

      struct FamilyCompact {
        uint256 tokenId;
        CreatureCompact parent1;
        CreatureCompact parent2;
        CreatureCompact parent1_parent1;
        CreatureCompact parent1_parent2;
        CreatureCompact parent2_parent1;
        CreatureCompact parent2_parent2;
    }

    struct CreatureCompact {
        uint256 tokenId;
        bool alive;
        uint16 valueType;
    }

    struct Creature {
        uint256 tokenId;
        bool alive;
        uint16 valueType;
        CreatureParts creatureParts;
        CreatureBonusParts creatureBonusParts;
        uint16 creatureAllocatedPoints;
        uint16 creaturePartRareCount;
        uint256 creatureValuePoints;
        uint256 creatureValue;
        uint256 contract_points_value_balance;
        uint256 creatureTreasureCount;
        uint256 creatureTreasureValue;
    }


    function _getCretureParts(uint256 tokenId) private view returns (CreatureParts memory creatureParts) {
        return CreatureParts(
                    _getVariation(tokenId, 1),
                    _getVariation(tokenId, 2),
                    _getVariation(tokenId, 3),
                    _getVariation(tokenId, 4),
                    _getVariation(tokenId, 5),
                    _getVariation(tokenId, 6),
                    _getVariation(tokenId, 7),
                    _getVariation(tokenId, 8),
                    _getVariation(tokenId, 9),
                    _getVariation(tokenId, 10)
                );
    }

    function _getCretureBonusParts(uint256 tokenId) private view returns (CreatureBonusParts memory creatureBonusParts) {
        return CreatureBonusParts(
                    _getVariation(tokenId, 11)
                );
    }

    function _getVariation(uint256 tokenId, uint8 partId) private view returns (Variation memory variation) {

        uint256 creaturePartPoints = 0;

        if(partId_variationIdCount_all_creatures[partId][creature_points_partId_variationId[tokenId][partId]] > 0) {
            creaturePartPoints = point_allocations_all_creatures_partId_variationId[partId][creature_points_partId_variationId[tokenId][partId]] / partId_variationIdCount_all_creatures[partId][creature_points_partId_variationId[tokenId][partId]];
        } 

        return Variation(partId, 
                                creature_points_partId_variationId[tokenId][partId],
                                _creaturesPoints[tokenId][partId],
                                partId_variationIdCount_all_creatures[partId][creature_points_partId_variationId[tokenId][partId]],
                                point_allocations_all_creatures_partId_variationId[partId][creature_points_partId_variationId[tokenId][partId]],
                                creaturePartPoints,
                                _getCreaturePartPoints(tokenId, partId)
        );
    }

    function getCreatureCompact(uint256 tokenId) public view returns (CreatureCompact memory) {

        CreatureCompact memory creature = CreatureCompact(
                        tokenId,
                        creatureAlive[tokenId],
                        valueType
        );
        return creature;
    }

    function getCreature(uint256 tokenId) public view returns (Creature memory) {
       
        uint256 activePointValue = contract_points_value_balance / _totalActivePoints;
        uint256 creaturePoints = getCreaturePoints(tokenId);

        Fish_Species_01 fish_Species_01 = Fish_Species_01(_fish_Species_01_ContractAddress);

         Creature memory creature = Creature(
            tokenId,
            creatureAlive[tokenId],
            valueType,
            _getCretureParts(tokenId),
            _getCretureBonusParts(tokenId),
            creature_total_points[tokenId],
            creature_part_rare_count[tokenId],
            creaturePoints,
            creaturePoints * activePointValue,
            contract_points_value_balance,
            fish_Species_01.getCreatureTreasureCount(tokenId),
            fish_Species_01.getCreatureTreasureValue(tokenId)
        );

         return creature;
    }

    function getFamilyCompact(uint256 tokenId) public view returns (FamilyCompact memory) {

        FamilyCompact memory family = FamilyCompact(
            tokenId,
            getCreatureCompact(creature_parent_1[tokenId]),
            getCreatureCompact(creature_parent_2[tokenId]),
            getCreatureCompact(creature_parent_1[creature_parent_1[tokenId]]),
            getCreatureCompact(creature_parent_1[creature_parent_2[tokenId]]),
            getCreatureCompact(creature_parent_2[creature_parent_1[tokenId]]),
            getCreatureCompact(creature_parent_2[creature_parent_2[tokenId]])
        );

         return family;
    }

    function getFamily(uint256 tokenId) public view returns (Family memory) {

        Family memory family = Family(
            tokenId,
            getCreature(creature_parent_1[tokenId]),
            getCreature(creature_parent_2[tokenId]),
            getCreature(creature_parent_1[creature_parent_1[tokenId]]),
            getCreature(creature_parent_1[creature_parent_2[tokenId]]),
            getCreature(creature_parent_2[creature_parent_1[tokenId]]),
            getCreature(creature_parent_2[creature_parent_2[tokenId]])
        );

         return family;
    }


    function getCreaturePoints(uint256 tokenId) public view returns (uint256) {
        uint256 creaturePoints = 0;

        creaturePoints += _getCreaturePartPoints(tokenId, 1);
        creaturePoints += _getCreaturePartPoints(tokenId, 2);
        creaturePoints += _getCreaturePartPoints(tokenId, 3);
        creaturePoints += _getCreaturePartPoints(tokenId, 4);
        creaturePoints += _getCreaturePartPoints(tokenId, 5);
        creaturePoints += _getCreaturePartPoints(tokenId, 6);
        creaturePoints += _getCreaturePartPoints(tokenId, 7);
        creaturePoints += _getCreaturePartPoints(tokenId, 8);
        creaturePoints += _getCreaturePartPoints(tokenId, 9);
        creaturePoints += _getCreaturePartPoints(tokenId, 10);
        creaturePoints += _getCreaturePartPoints(tokenId, 11);

        return creaturePoints;
    }


    function getCreatureValue(uint256 tokenId) public view returns (uint256) {
        uint256 activePointValue = contract_points_value_balance / _totalActivePoints;
        uint256 creaturePoints = getCreaturePoints(tokenId);
        return creaturePoints * activePointValue;
    }

    function _getCreaturePartPoints(uint256 tokenId, uint8 partId) private view returns (uint256) {

        uint256 creaturePartPoints = 0;

        if(partId_variationIdCount_all_creatures[partId][creature_points_partId_variationId[tokenId][partId]] > 0) {   
           creaturePartPoints = point_allocations_all_creatures_partId_variationId[partId][creature_points_partId_variationId[tokenId][partId]] / partId_variationIdCount_all_creatures[partId][creature_points_partId_variationId[tokenId][partId]];
        } 

        return creaturePartPoints;
    }

    function getCreaturePartValue(uint8 partId, uint16 variationId) public view returns (uint256) {

        uint256 creaturePartPoints = 0;

        if(partId_variationIdCount_all_creatures[partId][variationId] > 0) {   
           creaturePartPoints = point_allocations_all_creatures_partId_variationId[partId][variationId] / partId_variationIdCount_all_creatures[partId][variationId];
        } else {
           creaturePartPoints = point_allocations_all_creatures_partId_variationId[partId][variationId] / 1; 
        }

        uint256 activePointValue = contract_points_value_balance / _totalActivePoints;

        uint256 partValue = creaturePartPoints * activePointValue;

        return partValue;
    }

      function getCreatureValueForVariation(uint16 variationId) public view returns (uint256) {

        uint256 allValue = 0;

        allValue += getCreaturePartValue(1,variationId);
        allValue += getCreaturePartValue(2,variationId);
        allValue += getCreaturePartValue(3,variationId);
        allValue += getCreaturePartValue(4,variationId);
        allValue += getCreaturePartValue(5,variationId);
        allValue += getCreaturePartValue(6,variationId);
        allValue += getCreaturePartValue(7,variationId);
        allValue += getCreaturePartValue(8,variationId);
        allValue += getCreaturePartValue(9,variationId);
        allValue += getCreaturePartValue(10,variationId);
        allValue += getCreaturePartValue(11,variationId);

        return allValue;
    }


    function killCreature(uint256 tokenIdToKill, uint256 killerTokenId) 
        onlyOwner
        private 
        returns (bool killed)
    {
        require(killedCreatures[tokenIdToKill] == false, "Already Killed");

        totalActiveCreatureCount = totalActiveCreatureCount -1;
        Creature memory creature = getCreature(tokenIdToKill);
        _reducePartIdVaiationIdCount(creature);
        killedCreatures[tokenIdToKill] = true;
        creatureAlive[tokenIdToKill] = false;

        creature_KilledBy[tokenIdToKill] = killerTokenId;

        return true;
    }

    function _reducePartIdVaiationIdCount(Creature memory creature) private 
    {
        partId_variationIdCount_all_creatures[1][creature.creatureParts.part_1.variationId] -= 1;
        partId_variationIdCount_all_creatures[2][creature.creatureParts.part_2.variationId] -= 1;
        partId_variationIdCount_all_creatures[3][creature.creatureParts.part_3.variationId] -= 1;
        partId_variationIdCount_all_creatures[4][creature.creatureParts.part_4.variationId] -= 1;
        partId_variationIdCount_all_creatures[5][creature.creatureParts.part_5.variationId] -= 1;
        partId_variationIdCount_all_creatures[6][creature.creatureParts.part_6.variationId] -= 1;
        partId_variationIdCount_all_creatures[7][creature.creatureParts.part_7.variationId] -= 1;
        partId_variationIdCount_all_creatures[8][creature.creatureParts.part_8.variationId] -= 1;
        partId_variationIdCount_all_creatures[9][creature.creatureParts.part_9.variationId] -= 1;
        partId_variationIdCount_all_creatures[10][creature.creatureParts.part_10.variationId] -= 1;

        if(creature.creatureBonusParts.part_11.variationId > 0) partId_variationIdCount_all_creatures[11][creature.creatureBonusParts.part_11.variationId] -= 1;
    }

    function cashoutCreature(uint256 tokenId) 
        noReEntry
        onlyOwner
        public 
        returns (uint256 creatureValue)
    {
        require(cashedOutCreatures[tokenId] == false, "Already Cashed Out");

        Creature memory creature  = getCreature(tokenId);

        point_allocations_all_creatures_partId_variationId[1][creature.creatureParts.part_1.variationId] -= creature.creatureParts.part_1.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[2][creature.creatureParts.part_2.variationId] -= creature.creatureParts.part_2.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[3][creature.creatureParts.part_3.variationId] -= creature.creatureParts.part_3.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[4][creature.creatureParts.part_4.variationId] -= creature.creatureParts.part_4.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[5][creature.creatureParts.part_5.variationId] -= creature.creatureParts.part_5.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[6][creature.creatureParts.part_6.variationId] -= creature.creatureParts.part_6.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[7][creature.creatureParts.part_7.variationId] -= creature.creatureParts.part_7.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[8][creature.creatureParts.part_8.variationId] -= creature.creatureParts.part_8.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[9][creature.creatureParts.part_9.variationId] -= creature.creatureParts.part_9.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[10][creature.creatureParts.part_10.variationId] -= creature.creatureParts.part_10.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[11][creature.creatureBonusParts.part_11.variationId] -= creature.creatureBonusParts.part_11.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[11][creature.creatureBonusParts.part_11.variationId] -= creature.creatureBonusParts.part_11.creatureVariationPoints;
        point_allocations_all_creatures_partId_variationId[11][creature.creatureBonusParts.part_11.variationId] -= creature.creatureBonusParts.part_11.creatureVariationPoints;

        _reducePartIdVaiationIdCount(creature);

        _totalActivePoints -= creature.creatureValuePoints;

        transactionStatus[tokenId] = "Cashout Creature";

        cashedOutCreatures[tokenId] = true;
        creatureAlive[tokenId] = false;

        contract_points_value_balance -= creature.creatureValue;

        totalActiveCreatureCount = totalActiveCreatureCount - 1;

        return creature.creatureValue;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import { GameBase } from "../base/GameBase.sol";
import { NftMinter } from  "../base/NftMinter.sol";
import { Helpers } from "../base/Helpers.sol";

import { Fish_Species_01_Extension } from "../creatures/Fish_Species_01_Extension.sol";

/**
 * @title Fish_Species_01
 * @dev Useed to generate Fish_Species_01 NFT's
 */
contract Fish_Species_01 is GameBase {

    /**
     * modifier to check that valueType is valid
     */
    modifier validValueType(uint16 valueType) {
        uint256 price = spawnPrice[valueType];
        require(price >= 0, "Invalid Value Type");
        _;
    }

    uint256 public totalActiveCreatureCount;

    mapping(uint256 => uint256) internal requestIdToTokenId;
    mapping(uint256 => uint16) public creature_valueType;

    mapping(uint16 => uint256) public treasure_itemValue;

    event MintComplete(uint256 tokenId);
    event RandomnessComplete(uint256 tokenId);

    constructor() 
    {
        /**
        * #########################################
        * Set SpawnPrices for Value Types
        * ##########################################
        */ 

        spawnPrice[0] = 2 * 10**14; // value type = 0
        treasure_itemValue[0] = 1 * 10**13;

        spawnPrice[1] = 2 * 10**16; // value type = 1
        treasure_itemValue[1] = 1 * 10**15;

        spawnPrice[2] = 2 * 10**18;
        treasure_itemValue[2] = 1 * 10**17;

        spawnPrice[3] = 20 * 10**18;
        treasure_itemValue[3] = 10 * 10**17;

        spawnPrice[4] = 200 * 10**18;
        treasure_itemValue[4] = 100 * 10**17;

        spawnPrice[5] = 2000 * 10**18;
        treasure_itemValue[5] = 1000 * 10**17;

        spawnPrice[6] = 20000 * 10**18;
        treasure_itemValue[6] = 10000 * 10**17;        
    }
    
    address public _fish_Species_01_ExtensionContractAddress;
    event Fish_Species_01_ExtensionContractAddressUpdated(address fish_Species_01_ExtensionContractAddress);
    function setFish_Species_01_ExtensionContractAddress(address fish_Species_01_ExtensionContractAddress)
        public 
        onlyRole(ADMIN_ROLE) 
    {
        _fish_Species_01_ExtensionContractAddress = fish_Species_01_ExtensionContractAddress;
        emit Fish_Species_01_ExtensionContractAddressUpdated(fish_Species_01_ExtensionContractAddress);
    }

    address _gameExtensionContractAddresses;
    event GameExtensionContractAddressesUpdated(address gameExtensionContractAddresses);
    function setGameExtensionContractAddressesUpdated(address gameExtensionContractAddresses)
        public 
        onlyRole(ADMIN_ROLE) 
    {
        _gameExtensionContractAddresses = gameExtensionContractAddresses;
        emit GameExtensionContractAddressesUpdated(gameExtensionContractAddresses);
    }

     /**
     * Used to mint the NFT - This will bypass Oracle
     *                      - Is there a better way to do this?
     */
    function safeMintTest(uint16 valueType, uint256 rand1, uint256 rand2, uint256 rand3) public payable noReEntry validValueType(valueType) paidEnough(valueType) refundExcess(valueType) {
        require(_isTestMode == true, "Required for test mode");
        uint256 tokenId = _callSafeMint(valueType);
        Fish_Species_01_Extension fish_Species_01_Extension = Fish_Species_01_Extension(_fish_Species_01_ExtensionContractAddress);
        fish_Species_01_Extension.mintTest(valueType, tokenId, contract_points_value_balance_forType[valueType], rand1, rand2, rand3); 
        emit MintComplete(tokenId);
    }
    
    /**
     * Used to mint the NFT
     */
    function safeMint(uint16 valueType) public payable noReEntry validValueType(valueType) paidEnough(valueType) refundExcess(valueType) {
        //require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK for Randomness");
        uint256 tokenId = _callSafeMint(valueType);
        getRandomNumber(tokenId);
    }

    function _callSafeMint(uint16 valueType) private returns (uint256) {
        uint256 tokenId = _safeMintNft(valueType);

        creature_valueType[tokenId] = valueType;

        creature_treasure_count[tokenId] += 10;
        creature_breedCount[tokenId] = 8;

        // contract_treasure_value_balance_forType[valueType] do not set this here its set in nftMinter
        transactionStatus[tokenId] = "minted";

        totalActiveCreatureCount = totalActiveCreatureCount + 1;
        
        return tokenId;
    }

     /**
     * Requests randomness - production
     */
    function getRandomNumber(uint256 tokenId) private {
        uint256 requestId = requestRandomWords();
        requestIdToTokenId[requestId] = tokenId;
        transactionStatus[tokenId] = "Waiting for Randomness";
    }


     function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override(GameBase) {
        // s_randomWords = randomWords;

        uint256 tokenId;
        tokenId = requestIdToTokenId[requestId];

        emit RandomnessComplete(tokenId);

        transactionStatus[tokenId] = "Randomness Fulfilled"; 

        if(gameRandomnessToGameResult[requestId].gameId != 0) {
            completeGame(tokenId, requestId, randomWords[0]);
            return;
        }

        Fish_Species_01_Extension fish_Species_01_Extension = Fish_Species_01_Extension(_fish_Species_01_ExtensionContractAddress);

        if(tokenIdBreedingRandomId[requestId] != 0) {
            transactionStatus[tokenId] = "Breeding -> Randomness Returned";

            bool kill = false;
            if(creature_parentNo_parentsKilled[tokenId][1] != 0) kill = true;

            fish_Species_01_Extension.breed(creature_valueType[tokenId], tokenId, creature_parentNo_parent[tokenId][1], creature_parentNo_parent[tokenId][2], kill, contract_points_value_balance_forType[creature_valueType[tokenId]], randomWords[0]);

            emit BreedComplete(tokenId);
            return;
        }

        transactionStatus[tokenId] = "Randomness Returned";

        fish_Species_01_Extension.mint(creature_valueType[tokenId], tokenId, contract_points_value_balance_forType[creature_valueType[tokenId]], randomWords[0]);

        emit MintComplete(tokenId);
    }

    // Used for testing
    function creaturesDnaCode(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        Fish_Species_01_Extension fish_Species_01_Extension = Fish_Species_01_Extension(_fish_Species_01_ExtensionContractAddress);

        return string(abi.encodePacked(Helpers.uint2str(tokenId) ,'&', Helpers.uint2str(fish_Species_01_Extension.getCode(1, tokenId)),'&', Helpers.uint2str(fish_Species_01_Extension.getCode(2, tokenId)),'&', Helpers.uint2str(fish_Species_01_Extension.getCode(3, tokenId))));                     
    }

    /**
     * Overridden from NFTMinter // override(ERC721)
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(NftMinter)
        returns (string memory)
    {
        string memory tokenIdString = Helpers.uint2str(tokenId);

        Fish_Species_01_Extension fish_Species_01_Extension = Fish_Species_01_Extension(_fish_Species_01_ExtensionContractAddress);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Helpers.Base64Encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Evolutioneerd NFT F1 - ', tokenIdString , '","description":"https://consensys.evolutioneerd.com/", "attributes": "","animation_url":"', _baseURI() ,'?', tokenIdString ,'&', Helpers.uint2str(fish_Species_01_Extension.getCode(1, tokenId)),'&', Helpers.uint2str(fish_Species_01_Extension.getCode(2, tokenId)),'&', Helpers.uint2str(fish_Species_01_Extension.getCode(3, tokenId)),'"}'
                            )
                        )
                    )
                )
            );
    }

    mapping(uint256 => address) public creature_cashoutAddress;
    mapping(uint256 => uint256) public creature_pointsCashedoutAmount;
    mapping(uint256 => uint256) public creature_treasureCashedoutAmount;
    mapping(uint256 => uint256) public creature_treasureKilledAmount;
    mapping(uint256 => uint256) public creature_totalCashedoutAmount;

    function cashOut(uint256 tokenId)
        public
        payable 
        noReEntry
        ownerOfToken(tokenId)
        returns (bool)
    {  
        require(creature_cashoutAddress[tokenId] == address(0));
        _burn(tokenId);

        Fish_Species_01_Extension fish_Species_01_Extension = Fish_Species_01_Extension(_fish_Species_01_ExtensionContractAddress);

        uint256 pointCashoutAmount = fish_Species_01_Extension.cashoutCreature(tokenId);

        totalActiveCreatureCount = totalActiveCreatureCount -1;

        address payable _tokenOwner = payable(_owners[tokenId]);

        creature_cashoutAddress[tokenId] = _tokenOwner;
        
        uint256 treasure_CashoutAmount = getCreatureTreasureValue(tokenId);
        creature_treasure_count[tokenId] = 0;
    
        creature_treasureCashedoutAmount[tokenId] = treasure_CashoutAmount;
        creature_pointsCashedoutAmount[tokenId] = pointCashoutAmount;

        creature_totalCashedoutAmount[tokenId] = (treasure_CashoutAmount + pointCashoutAmount);
        _tokenOwner.transfer(creature_totalCashedoutAmount[tokenId]);

        contract_points_value_balance_forType[creature_valueType[tokenId]] -= pointCashoutAmount;
        contract_treasure_value_balance_forType[creature_valueType[tokenId]] -= treasure_CashoutAmount;

        return true;
    }

    function getCreatureTreasureCount(uint256 tokenId) public view returns (uint256)  {
        return creature_treasure_count[tokenId];
    }

    function getCreatureTreasureValue(uint256 tokenId) public view returns (uint256)  {
        return creature_treasure_count[tokenId] * treasure_itemValue[creature_valueType[tokenId]];
    }

    event BreedComplete(uint256 tokenId);
    mapping(uint256 => uint256) private creature_breedCount;
    mapping(uint256 => uint256) internal tokenIdBreedingRandomId;
    mapping(uint256 => mapping(uint8 => uint256)) internal creature_parentNo_parent;
    mapping(uint256 => mapping(uint8 => uint256)) internal creature_parentNo_parentsKilled;

    modifier canBreed(uint256 parent1TokenId, uint256 parent2TokenId) {
         require(creature_valueType[parent1TokenId] == creature_valueType[parent2TokenId], "Creature Value Types are not the same");
         require(creature_breedCount[parent1TokenId] > 0, "0 Breeds remaining");
         require(creature_breedCount[parent2TokenId] > 0, "0 Breeds remaining");
         require(parent1TokenId > 0, "Invalid Token");
         require(parent2TokenId > 0, "Invalid Token");
         require(ownerOf(parent1TokenId) == msg.sender, "Not Owner");
         require(ownerOf(parent2TokenId) == msg.sender, "Not Owner");
        _;
    } 

     function breedTestKill(uint256 parent1TokenId, uint256 parent2TokenId, uint256 rand1) public payable noReEntry canBreed(parent1TokenId, parent2TokenId) paidEnough(creature_valueType[parent1TokenId]) refundExcess(creature_valueType[parent2TokenId]) {
        require(_isTestMode == true, "Required for test mode");
        _breedtest(parent1TokenId, parent2TokenId, rand1, true);
    }

    function breedTestDontKill(uint256 parent1TokenId, uint256 parent2TokenId, uint256 rand1) public payable noReEntry canBreed(parent1TokenId, parent2TokenId) paidEnough(creature_valueType[parent1TokenId]) refundExcess(creature_valueType[parent2TokenId]) {
        require(_isTestMode == true, "Required for test mode");
        _breedtest(parent1TokenId, parent2TokenId, rand1, false);
    }

    function _breedtest(uint256 parent1TokenId, uint256 parent2TokenId, uint256 rand1, bool kill) private {
        uint16 valueType = creature_valueType[parent1TokenId];

        uint256 tokenId = _callSafeBreed(parent1TokenId, parent2TokenId, kill);

        Fish_Species_01_Extension fish_Species_01_Extension = Fish_Species_01_Extension(_fish_Species_01_ExtensionContractAddress);
        fish_Species_01_Extension.breed(valueType, tokenId, parent1TokenId, parent2TokenId, kill, contract_points_value_balance_forType[valueType], rand1); 

        transactionStatus[tokenId] = "test breeding -> complete";
    }

    function breed(uint256 parent1TokenId, uint256 parent2TokenId, bool kill) public payable noReEntry canBreed(parent1TokenId, parent2TokenId) paidEnough(creature_valueType[parent1TokenId]) refundExcess(creature_valueType[parent1TokenId]) {
        //require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK for Randomness");

        uint256 tokenId = _callSafeBreed(parent1TokenId, parent2TokenId, kill);

        uint256 requestId = requestRandomWords();
        tokenIdBreedingRandomId[requestId] = tokenId;

        transactionStatus[tokenId] = "breeding -> waiting for randomness";
    }


    function _callSafeBreed(uint256 parent1TokenId, uint256 parent2TokenId, bool kill) private returns (uint256) {
        uint16 valueType = creature_valueType[parent1TokenId];

        creature_breedCount[parent1TokenId] -= 1;
        creature_breedCount[parent2TokenId] -= 1;

        uint256 tokenId = _callSafeMint(valueType);

        creature_parentNo_parent[tokenId][1] = parent1TokenId;
        creature_parentNo_parent[tokenId][2] = parent2TokenId;

        if(kill == true) {
            creature_treasure_count[tokenId] += creature_treasure_count[parent1TokenId];
            creature_treasure_count[tokenId] += creature_treasure_count[parent2TokenId];

            creature_treasure_count[parent1TokenId] = 0;
            creature_treasure_count[parent2TokenId] = 0;

            creature_parentNo_parentsKilled[tokenId][1] = parent1TokenId;
            creature_parentNo_parentsKilled[tokenId][2] = parent2TokenId;
        }

        transactionStatus[tokenId] = "breeding -> mint complete";
        
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RandomBase is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Polygon (Matic) Mumbai Testnet
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 5000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  2;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() internal onlyOwner returns (uint256) {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    return s_requestId;
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) virtual internal override {
    s_randomWords = randomWords;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
  }

  function getOwner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "Not Owner");
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


import { Helpers } from "./Helpers.sol";

contract NftMinter is
    ERC721,
    Pausable,
    AccessControl
{
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    Counters.Counter internal _tokenIdCounter;

    mapping(uint16 => uint256) public spawnPrice;
    address payable public _bank;
    address payable public _contractBank;
    string private __baseURI;

    event LogNftMinted(uint256 tokenId);
    event BankAddressUpdated(address bankAddress);
    event SpawnPriceUpdated(uint256 newSpawnPrice);
    event TestModeUpdatedTo(bool active);
    event BaseUriUpdated(string baseURI);

    bool internal _isTestMode = false;

    mapping(uint16 => uint256) public contract_points_value_balance_forType; //note this is for value type not tokenId
    mapping(uint16 => uint256) public contract_treasure_value_balance_forType;

    mapping(uint256 => string) public transactionStatus;
    
    /**
     * modifier used by safeMint to prevent re-entry attacks
     */
    bool internal locked;
    modifier noReEntry() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /**
     * modifier to check that enough has been paid
     */
    modifier paidEnough(uint16 valueType) {
        require(msg.value >= spawnPrice[valueType], "Have not paid enough. (contract msg)");
        _;
    }

    modifier ownerOfToken(uint256 tokenId) {
         require(tokenId > 0, "Invalid Token");
         require(ownerOf(tokenId) == msg.sender);
        _;
    }   

    /**
     * modifier used refund excess
     */
    modifier refundExcess(uint16 valueType) {
        _;
        uint256 amountToRefund = msg.value - spawnPrice[valueType];
        payable(msg.sender).transfer(amountToRefund);
    }

    /**
     *  @param bankAddress - initial bank address
    */
    constructor(address bankAddress) ERC721("Spawner", "SPAWN") {
        _setupRole(ADMIN_ROLE, msg.sender);
        __baseURI = "https://consensys-nft.evolutioneerd.com/";
        _bank = payable(bankAddress);
    }

    /**
     * public function used to check if a spcific address has a specified role on the contract
     * @param role - role key to check
     * @param add - address to check
     */
    function checkRole(string memory role, address add)
        public
        view
        returns (bool)
    {
        bytes32 ROLE = keccak256(abi.encodePacked(role));
        return this.hasRole(ROLE, add);
    }

    /**
     * public function used to update the bank account of the contract
     * @param bankAddress - address to check
     */
    function updateBankAddress(address bankAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _bank = payable(bankAddress);
        emit BankAddressUpdated(_bank);
    }

    /**
     * public function used to update the spawn price
     * @param newSpawnPrice - new price
     */
    function updateSpawnPrice(uint16 valueType, uint256 newSpawnPrice) public onlyRole(ADMIN_ROLE) {
        spawnPrice[valueType] = newSpawnPrice;
        emit SpawnPriceUpdated(newSpawnPrice);
    }

    /**
     * public function used to set the contract to test mode. Test mode bypasses chainlink VFR
     * @param value true | false
     */
    function updateTestMode(bool value) public onlyRole(ADMIN_ROLE) {
        _isTestMode = value;
        emit TestModeUpdatedTo(value);
    }

    /**
     * public function used to set the contract to test mode. Test mode bypasses chainlink VFR
     * @param value true | false
     */
    function updateBaseURI(string memory value) public onlyRole(ADMIN_ROLE) {
        __baseURI = value;
        emit BaseUriUpdated(value);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }


    uint256 totalBanked;

    function _safeMintNft(uint16 valueType) internal returns(uint256 tokenId) {
        uint256 contractPointsSplit = ((spawnPrice[valueType] / 2) / 100) * 80;
        uint256 bankSplit = ((spawnPrice[valueType] / 2) / 100) * 20;

        contract_points_value_balance_forType[valueType] += contractPointsSplit;
        contract_treasure_value_balance_forType[valueType] += spawnPrice[valueType] / 2;

        totalBanked += bankSplit;

        _bank.transfer(bankSplit);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        emit LogNftMinted(_tokenIdCounter.current());
        return _tokenIdCounter.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721)
    {
        super._burn(tokenId);
    }

    /**
     * This will be overridden in the inheriting class
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked("This should be overridden, tokenId:", Helpers.uint2str(tokenId)));                          
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "base64-sol/base64.sol";

library  Helpers {

    // /**
    // * ###########################################
    // * @dev Helper functions for functions that inherit from this contract:
    // * ###########################################
    // */ 
    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
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
        return string(bstr);
    }

    function Base64Encode(bytes memory data) public pure returns (string memory) {
        return Base64.encode(data);
    }

    enum PointAllocationTypes {
        NONE,
        anal_fin_points,
        body_pattern_points,
        dorsal_fin_points,
        mouth_points,
        pectoral_fin_points,
        tail_fin_points,
    
        body_color_points,
        eye_color_points,
        face_color_points,
        mouth_color_points,

        head_bonus
    }

        enum TreasureSize {
            ONE,
            TWO,
            FIVE,
            TEN, 
            TWENTY_FIVE,
            FIFTY,
            ONE_HUNDRED,
            ONE_THOUSAND,
            TEN_THOUSAND,
            ONE_HUNDRED_THOUSAND,
            ONE_MILLION,
            TEN_MILLION,
            ONE_HUNDRED_MILLION
        }

        function getTreasureSize(TreasureSize treasureSize) public pure returns(uint256) {
            if(treasureSize == TreasureSize.ONE) return 1;
            if(treasureSize == TreasureSize.TWO) return 2;
            if(treasureSize == TreasureSize.FIVE) return 5;
            if(treasureSize == TreasureSize.TEN) return 10;
            if(treasureSize == TreasureSize.TWENTY_FIVE) return 25;
            if(treasureSize == TreasureSize.FIFTY) return 50;
            if(treasureSize == TreasureSize.ONE_HUNDRED) return 100;
            if(treasureSize == TreasureSize.ONE_THOUSAND) return 1000;
            if(treasureSize == TreasureSize.TEN_THOUSAND) return 10000;
            if(treasureSize == TreasureSize.ONE_HUNDRED_THOUSAND) return 100000;
            if(treasureSize == TreasureSize.ONE_MILLION) return 1000000;
            if(treasureSize == TreasureSize.TEN_MILLION) return 10000000;
            if(treasureSize == TreasureSize.ONE_HUNDRED_MILLION) return 100000000;
            return 0;
        }

        function validTreasureCount(uint16 gameTreasureStake) public pure returns(bool) {
            bool valid = false;

            if(gameTreasureStake == 1) valid = true;
            if(gameTreasureStake == 2) valid = true;
            if(gameTreasureStake == 5) valid = true;
            if(gameTreasureStake == 10) valid = true;
            if(gameTreasureStake == 25) valid = true;
            if(gameTreasureStake == 50) valid = true;
            if(gameTreasureStake == 100) valid = true;
            if(gameTreasureStake == 1000) valid = true;
            if(gameTreasureStake == 10000) valid = true;
            if(gameTreasureStake == 100000) valid = true;
            if(gameTreasureStake == 1000000) valid = true;
            if(gameTreasureStake == 10000000) valid = true;
            if(gameTreasureStake == 100000000) valid = true;

            return valid;
        }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./RandomBase.sol";
import "./NftMinter.sol";
import { Helpers } from "./Helpers.sol";

contract Game {
    function playGame(uint256 gameDataPlayer1, uint256 gameDataPlayer2) public returns (uint8) {}
    function validateGameData(uint256 gameData) public returns (bool) {}
}

abstract contract GameBase is RandomBase, NftMinter
{
    constructor() 
        RandomBase(148) // this needs to change - make configurable
        NftMinter(msg.sender) // Initial Bank Address
        {

        } 

    modifier validTreasureCount(uint16 gameTreasureStake) {
        require(Helpers.validTreasureCount(gameTreasureStake) == true, "Invalid Tresure Size");
        _;
    }

    modifier noActiveGames(uint256 tokenId) {
        require(_creature_activeGame[tokenId] == 0, "Cannot proceed, active game");
        _;
    }   

    modifier validGameId(uint64 gameId) {
        require(_gameContractAddresses[gameId] != address(0), "gameId is not valid");
        _;
    }  

    modifier validGameData(uint64 gameId, uint256 gameData) {
        game = Game(_gameContractAddresses[gameId]);
        require(game.validateGameData(gameData) == true, "gameData is not valid");
        _;
    }   
 
    mapping(uint256 => uint256) public creature_treasure_count;

    mapping(uint256 => uint16) internal _creature_gameTreasureStake;
    mapping(uint64 => mapping(uint16 => uint256)) internal _gameId_gameTreasureStake; // this stores the token bet 

    mapping(uint256 => uint64) _creature_activeGame;
    mapping(uint256 => uint256) _creature_gameData_player_1;

    mapping(uint64 => address) _gameContractAddresses;

    mapping(uint64 => uint64) _gameId_counter;
    uint64 _gameCounter;

    mapping(uint64 => mapping(uint64 => GameResult)) _gameId_counter_result;
    mapping(uint64 => GameResult) _gameCounter_result;

    mapping(uint256 => mapping(uint64 => uint64)) _creature_gameId_counter;
    mapping(uint256 => uint64) _creature_gameCounter;

    event GameContractAddressUpdated(uint64 gameId, address gameContractAddress);

    function setGameContractAddress(uint64 gameId, address gameContractAddress)
        internal 
        onlyRole(ADMIN_ROLE) 
    {
        _gameContractAddresses[gameId] = gameContractAddress;
        emit GameContractAddressUpdated(gameId, gameContractAddress);
    }

    Game game;

    mapping(uint256 => GameResult) internal gameRandomnessToGameResult;

    struct GameResult {
        uint64 gameCounter;
        uint64 gameIdCounter;
        uint64 gameId;
        uint256 player1_tokenId;
        uint256 player2_tokenId;
        uint64 player1_gameCounter;
        uint64 player2_gameCounter;
        uint256 player1_gameData;
        uint256 player2_gameData;
        bool switched;
        bool complete;
        uint8 tempWinner; // this is before randomness is generated
        uint8 winner; // this is after randomness is decided
    }

    event GameRequested(uint256 tokenId, uint64 gameId, uint16 gameTreasureStake);
    event GameMatched(uint256 tokenId, uint64 gameId, uint16 gameTreasureStake, uint256 tokenId_player1);
    
    function gameRequest(uint256 tokenId, uint64 gameId, uint256 gameData, uint16 gameTreasureStake) 
        noReEntry 
        ownerOfToken(tokenId) 
        noActiveGames(tokenId)
        validTreasureCount(gameTreasureStake)
        validGameId(gameId)
        validGameData(gameId, gameData)
        public
        returns (bool)
    {
        //require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK for Randomness");
        require(creature_treasure_count[tokenId] >= gameTreasureStake, "Not Enough Treasure");

        return processGameRequest(tokenId, gameId, gameData, gameTreasureStake);
    }

    function processGameRequest(uint256 tokenId, uint64 gameId, uint256 gameData, uint16 gameTreasureStake) internal returns (bool) {
        if(_gameId_gameTreasureStake[gameId][gameTreasureStake] == 0){
            // no match
            _gameId_gameTreasureStake[gameId][gameTreasureStake] = tokenId;
            _creature_gameTreasureStake[tokenId] = gameTreasureStake;
            _creature_activeGame[tokenId] = gameId;
            _creature_gameData_player_1[tokenId] = gameData;

            emit GameRequested(tokenId, gameId, gameTreasureStake);

        } else {
            //match found
            _creature_activeGame[tokenId] = gameId;

            game = Game(_gameContractAddresses[gameId]);

            uint256 tokenIdPlayer1 = _gameId_gameTreasureStake[gameId][gameTreasureStake];
            uint256 tokenIdPlayer2 = tokenId;

            _creature_gameCounter[tokenIdPlayer1] += 1;
            _creature_gameCounter[tokenIdPlayer2] += 1;
            _creature_gameId_counter[tokenIdPlayer1][gameId] += 1;
            _creature_gameId_counter[tokenIdPlayer2][gameId] += 1;

            _gameId_counter[gameId] += 1;
            _gameCounter += 1;

            uint256 requestId = requestRandomWords();
            
            GameResult memory gameResult = GameResult(
                _gameCounter,
                _gameId_counter[gameId],
                gameId,
                tokenIdPlayer1,
                tokenIdPlayer2,
                _creature_gameCounter[tokenIdPlayer1],
                _creature_gameCounter[tokenIdPlayer2],
                _creature_gameData_player_1[tokenId],
                gameData,
                false,
                false,
                game.playGame(_creature_gameData_player_1[tokenIdPlayer1], gameData), // player2 Data = gameData
                0
            );

            gameRandomnessToGameResult[requestId] = gameResult;

            _gameId_gameTreasureStake[gameId][gameTreasureStake] = 0;

            emit GameMatched(tokenId, gameId, gameTreasureStake, tokenIdPlayer1);
        }

        return false;
    }

    event GameComplete(uint256 tokenId, uint64 gameId, uint64 player1_transactionId);

    function completeGame(uint256 tokenId, uint256 requestId, uint256 randomness) internal {

        transactionStatus[tokenId] = "completeGame -> starting";

        GameResult memory gameResult = gameRandomnessToGameResult[requestId];
        uint256 randomResult = (randomness % 2) + 1;

        if(randomResult == 1) { // flip
            if(gameResult.tempWinner == 1) {
                gameResult.winner = 2;
            }
            if(gameResult.tempWinner == 2) {
                gameResult.winner = 1;
            }
            gameResult.switched = true;
        }
        gameResult.complete = true;

        // _gameId_gameTreasureStake[gameId][gameTreasureStake] = 0; needs to happen after match
        _creature_gameTreasureStake[gameResult.player1_tokenId] = 0;
        _creature_activeGame[gameResult.player1_tokenId] = 0;
        _creature_activeGame[gameResult.player2_tokenId] = 0;
        _creature_gameData_player_1[gameResult.player1_tokenId] = 0;

        _gameId_counter_result[gameResult.gameId][gameResult.gameIdCounter] = gameResult;
        _gameCounter_result[gameResult.gameCounter]= gameResult;

        emit GameComplete(gameResult.player1_tokenId, gameResult.gameId, gameResult.gameCounter);
        emit GameComplete(gameResult.player2_tokenId, gameResult.gameId, gameResult.gameCounter);
    } 

    function cancelRequest(uint256 tokenId, uint64 gameId, uint16 gameTreasureStake) 
        noReEntry 
        ownerOfToken(tokenId)
        noActiveGames(tokenId)
        public
        returns (bool)
    {
        if(_gameId_gameTreasureStake[gameId][gameTreasureStake] == tokenId){
            // no match
            _gameId_gameTreasureStake[gameId][gameTreasureStake] = 0;
            return true;
        }
        return false;
    }

    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
    ) virtual internal override(RandomBase) {
        s_randomWords = randomWords;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

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
    mapping(uint256 => address) internal _owners;

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}