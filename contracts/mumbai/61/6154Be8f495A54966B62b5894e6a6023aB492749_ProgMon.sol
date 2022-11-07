//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 

import "./IProgressNFT.sol"; 

contract ProgMon is Ownable {

    uint constant public UNUSED_SKILL = 0xfff;
    uint constant public  N_MAX_MOVES = 10;
    uint constant public N_MONSTER_SKEW = 3;

    address public progressNFT;

    struct Skill {
        string name;
        uint damage;
    }

    struct Monster {
        string name;
        uint health;
        uint speed;
        uint stamina;
        uint [5] skillsIds;
    }

    struct MonsterState {
        uint health;
        uint speed;
        uint stamina;
    }

    struct Move {
        uint step;
        uint turn;
        uint skillId;
        MonsterState monster0;
        MonsterState monster1;
    }

    struct Match {
        uint progressNFT_Id;
        uint monster0_Id;
        uint[3][5] monster0_sequences;
        uint monster1_Id;
        uint[3][5] monster1_sequences;
        uint RNG;
    }

    uint public monsterCount;
    uint public skillCount;
    uint public matchCounter;
    mapping (uint => Skill) public skills;
    mapping (uint => Monster) public monsters;
    mapping (uint => Match) public matches;
    mapping (uint => uint[5]) public monsterIdToSkillIds;
    
    mapping (uint => uint) public matchIdToRandomnessRequest;

    constructor() Ownable () {

        uint[5] memory skillsIds0 = [uint(0),1 ,2, UNUSED_SKILL, UNUSED_SKILL];
        Monster memory m0 = Monster({name:"Azgar", health: 100, speed: 200, stamina: 313, skillsIds:skillsIds0});
        uint[5] memory skillsIds1 = [uint(0),2,UNUSED_SKILL, UNUSED_SKILL, UNUSED_SKILL];
        Monster memory m1 = Monster({name:"Grothem", health: 55, speed: 200, stamina: 313, skillsIds:skillsIds1});
        uint[5] memory skillsIds2 = [uint(0),1, UNUSED_SKILL, UNUSED_SKILL, UNUSED_SKILL];
        Monster memory m2 = Monster({name:"Drakl", health: 235, speed: 23200, stamina: 33, skillsIds:skillsIds2});


        addMonster(m0);        
        addMonster(m1);
        addMonster(m2);

        Skill memory s0 = Skill ({name: "fire", damage: 100});
        Skill memory s1 = Skill ({name: "laser", damage: 200});
        Skill memory s2 = Skill ({name: "bullet", damage: 300});


        addSkill(s0);
        addSkill(s1);
        addSkill(s2);
        
    }

    /* admin logic------------------------------------------------------------------------------------- */


    function setProgressNFT (address _progressNFT) public {
        // progressNFT = _progressNFT;
    }

    function addMonster (Monster memory _newMonster) public onlyOwner {

        //creates new monsters on upcoming levels ...

        monsters[monsterCount] = _newMonster;
        monsterIdToSkillIds[monsterCount] = _newMonster.skillsIds;
        monsterCount++;

    }


    function addSkill (Skill memory _newSkill) public onlyOwner {

        //creates new skilss for new monsters

        skills[skillCount] = _newSkill;
        skillCount++;

    }


    /* -------------------------------------------------------------------------------------admin logic */


    /* main logic------------------------------------------------------------------------------------- */

    function register () public returns (uint tokenId) {

        //buy/mint progress NFT

        tokenId = IProgressNFT(progressNFT).mint(msg.sender);
         
    }

    function battle (uint _progressNFT_Id, uint _monsterId, uint[3][5] memory _sequences) public returns (uint matchId){

        require(IProgressNFT(progressNFT).ownerOf(_progressNFT_Id) == msg.sender, "Only token owner can call this method!!!");

        uint monster0_Id = IProgressNFT(progressNFT).tokenIdToLevel(_progressNFT_Id);

        require(monster0_Id < monsterCount, "That level has not yet been created !!!");

        for(uint i = 0; i < 3; i++){
            for(uint j = 0; j < 5; j++){
                require(_sequences[i][j] == UNUSED_SKILL || 
                        _monsterHasThatSkill(_monsterId, _sequences[i][j]),
                        "Monster cannot use that skill !!!" );
            }
        }


        uint [3][5] memory monster0_sequences; // currently not used - later versions will have complex patterns

        matchId = matchCounter;

        matches[matchId] = Match({  progressNFT_Id: _progressNFT_Id,
                                    monster0_Id: monster0_Id, 
                                    monster0_sequences: monster0_sequences, 
                                    monster1_Id: _monsterId,
                                    monster1_sequences: _sequences,
                                    RNG:  0xaff2a1bcadeaaaaaaa // TODO: request from VRF - hardcoded for now
                                });

        matchCounter += 1;

        matchIdToRandomnessRequest[matchId] = 0x01; // TODO: request from VRF

    }

    function _monsterHasThatSkill (uint monsterId, uint skillId) internal view returns (bool hasIt) {
        hasIt = false;
        for(uint i = 0; i < 5; ++i){
            hasIt = monsterIdToSkillIds[monsterId][i] == skillId;
            if(hasIt) break;
        }
    }

    function claim (uint matchId) public {

        //play out the battle and if successfull, advance to the next level (progressNFT)

        (bool randomnessFullfiled, bool canClaim, , ) = viewPlayOut(matchId);

        require(IProgressNFT(progressNFT).ownerOf(matches[matchId].progressNFT_Id) == msg.sender, 
                "Only token's owner can call this method");

        require(randomnessFullfiled , "Randomness not fullfiled for this match !!!");

        require(canClaim , "Level not reached ; Cannot claim this Monster !!!");

        IProgressNFT(progressNFT).levelUp(matches[matchId].progressNFT_Id);

    }

    function viewPlayOut (uint matchId) public view returns (bool randomnessFullfiled, bool canClaim, Match memory matchInfo, Move[50] memory moves){

        //the meat of it all - on-chain battle rules

        uint RNG = matches[matchId].RNG;

        if(RNG == 0x0){
            randomnessFullfiled = false;
            canClaim = false;
            return (randomnessFullfiled, canClaim, matchInfo, moves);
        }

        matchInfo = matches[matchId];

        bool sequenceEnded = true;
        uint currentSeqId = 5;
        uint currentSeqElementId = 5;
        uint [3][5] memory sequences = matches[matchId].monster1_sequences;


        Monster memory monster0 = monsters[matches[matchId].monster0_Id];
        Monster memory monster1 = monsters[matches[matchId].monster1_Id];


        uint monter0_skillCount = 2;
        // for(uint i = 0; i < 5; ++i){
        //     if(monsterIdToSkillIds[matches[matchId].monster0_Id][i] != UNUSED_SKILL) monter0_skillCount += 1;
        // }

        MonsterState memory monster0_state = MonsterState({health: monster0.health, speed: monster0.speed, stamina: monster0.stamina});
        MonsterState memory monster1_state = MonsterState({health: monster1.health, speed: monster1.speed, stamina: monster1.stamina});

        bool matchEnded = false;

        for(uint i = 0; i < 50; ++i){

            // choosing who's turn it is
            uint turn = RNG >> i & 1;

            // choosing the skill of the sequence
            uint skillId;

            if(turn == 0){ 

                skillId = (RNG >> (i+1)) & (monter0_skillCount-1);
            } else { 

                if(sequenceEnded){
                    currentSeqId = ( (RNG >> i) & 3 ) % 3;
                    currentSeqElementId = 0;
                    sequenceEnded = false;
                }
                if(sequences[currentSeqId][currentSeqElementId] == UNUSED_SKILL ||
                    currentSeqElementId >= sequences[0].length){
                    sequenceEnded = true;
                }else{
                    currentSeqElementId += 1;
                }
            }

            // applying the choosen skill
            if(turn == 0) {
                if(monster1_state.health <= skills[skillId].damage){
                    matchEnded = true;
                }else{
                    monster1_state.health -= skills[skillId].damage;
                }
            } else {
                if(monster0_state.health <= skills[skillId].damage){
                    matchEnded = true;
                }else{
                    monster0_state.health -= skills[skillId].damage;
                }
            }

            moves[i] = Move({step: i, turn: turn, skillId: i%3, monster0: monster0_state, monster1: monster1_state}); 

            if(matchEnded == true){
                break;
            }
        }

        canClaim = (monster1_state.health > monster0_state.health);

    }

    function getAvailableMonster (uint _progressNFT_Id) public view returns (uint availableMonsterCount, Monster [1000] memory _monsters) {

        uint level = IProgressNFT(progressNFT).tokenIdToLevel(_progressNFT_Id);

        availableMonsterCount = level + N_MONSTER_SKEW;
        for(uint i = 0; i < availableMonsterCount; i++){
            _monsters[i] = monsters[i];
        }

    }

    /* -------------------------------------------------------------------------------------main logic */

    // function getMonster (uint _monsterId) returns (Monster memory monster) {

    //     //gets all info on a monster - stats & skills

    // }

    // function getSkill (uint _skillId) returns ()

  
}

// pragma solidity ^0.8.0;

// contract ProgMon {
//     uint constant N_MAX_MOVES = 10;
//     uint PLAYER = 1;
//     uint OPONNENT = 2;

//     struct Skill {
//         uint damage;
//     }

//     struct Monster {
//         uint health;
//         uint speed;
//         uint stamina;
//         uint [] skillsId;
//     }

//     struct MonsterState {
//         uint health;
//     }

//     struct Move {
//         uint step;
//         MonsterState player;
//         MonsterState oponnent;
//     }

//     struct Match {
//         uint playerId;
//         uint[] playerSkillSequences;
//         uint monsterId;
//         uint[] monsterSkillSequences;
//         uint RNG;
//     }

//     mapping(uint => Skill) skills;
//     mapping(uint => Monster) monsters;
//     mapping(uint => Match) matches;

//     constructor() {
//         skills[0] = Skill({damage: 10});
//         skills[1] = Skill({damage: 20});

//         monsters[0] = Monster({health: 100, speed: 10, stamina: 5, skillsId: new uint[](2)});
//         monsters[0].skillsId[0] = 0;  monsters[0].skillsId[1] = 1;

//         monsters[1] = Monster({health: 200, speed: 5, stamina: 5, skillsId: new uint[](1)});
//         monsters[1].skillsId[0] = 0; 

//         Match memory mec;
//         mec.playerId = 0;
//         mec.playerSkillSequences = new uint[](2);
//         mec.playerSkillSequences[0] = 0;
//         mec.playerSkillSequences[1] = 1;
//         mec.monsterId = 1;
//         mec.monsterSkillSequences = new uint[](3);
//         mec.monsterSkillSequences[0] = 1;
//         mec.monsterSkillSequences[1] = 0;
//         mec.monsterSkillSequences[2] = 0;

//         mec.RNG = 89712378971;

//         matches[0] = mec;


//         //matches[0] = Match({playerId: 0, playerSkillSequences: new uint[](2) monsterId: 0, RNG:786123861023});
//     }

//     function playOut (uint id) public {
//         viewPlayOut(id);
//     }

//     function viewPlayOut(uint id) public view returns (Move[500] memory matchSequence){

//         Match memory mec = matches[id];

//         uint playerSequenceStepId = 0;
//         uint monsterSequenceStepId = 0;

//         Move memory currMove;
//         currMove.step = 23;
//         currMove.player.health = monsters[mec.playerId].health;
//         currMove.oponnent.health = monsters[mec.monsterId].health;

//         for(uint i = 0; i < 500; ++i){

//             matchSequence[i] = currMove;

//             // uint whosTurn = (mec.RNG >> i) & 1 == 1 ? PLAYER : OPONNENT;

//             uint whosTurn = PLAYER;
//             if(whosTurn == PLAYER) {
//                 uint skillId = mec.playerSkillSequences[playerSequenceStepId];

//                 currMove = playerAttacks(skillId, currMove);
//                 //next step
//                 playerSequenceStepId = (playerSequenceStepId + 1 >= mec.playerSkillSequences.length) ? 0 : playerSequenceStepId + 1;

//             } else {

//             }
//         }

//     }

//     function playerAttacks (uint skillId, Move memory currMove) internal view returns ( Move memory nextMove ){

//         nextMove.step = currMove.step + 1;
//         if(currMove.oponnent.health > skills[skillId].damage) {
//             nextMove.oponnent.health = currMove.oponnent.health - skills[skillId].damage;
//         }else {
//             nextMove.oponnent.health = 0;
//         }

//     }

  
// }

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProgressNFT is IERC721 {

    
    function tokenIdToLevel (uint tokenId) external view returns (uint level);

    function setProgmon (address _progmon) external returns (bool success);

    function mint (address player) external returns (uint tokenId);
    
    function levelUp (uint tokenId) external returns (bool success);

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