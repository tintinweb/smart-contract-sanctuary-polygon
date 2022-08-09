// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "hardhat/console.sol";

import "./interfaces/ICourtExt.sol";
import "../abstract/GameExtension.sol";
import "../libraries/DataTypes.sol";
import "../interfaces/ICTXEntityUpgradable.sol";
import "../interfaces/IClaim.sol";
import "../interfaces/IProcedure.sol";

/**
 * @title Game Extension: Court of Law 
 */
contract CourtExt is ICourtExt, GameExtension {

    function _caseMake(
        string calldata name_, 
        string calldata uri_
    ) internal returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address claimContract = hub().claimMake("CLAIM", name_, uri_);
        //Register New Contract
        _registerNewClaim(claimContract);
        //Create Custom Roles
        ICTXEntityUpgradable(claimContract).roleCreate("witness");     //Witnesses
        ICTXEntityUpgradable(claimContract).roleCreate("affected");    //Affected Party (For reparations)
        
        //Return new Contract Address
        return claimContract;
    }

    function _onCreation(
        address newContract, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) private {
        //Assign Roles
        for (uint256 i = 0; i < assignRoles.length; ++i) {
            ICTXEntityUpgradable(newContract).roleAssignToToken(assignRoles[i].tokenId, assignRoles[i].role);
        }
        //Add Rules
        for (uint256 i = 0; i < rules.length; ++i) {
            IClaim(newContract).ruleRefAdd(rules[i].game, rules[i].ruleId);
        }
        //Post Posts
        for (uint256 i = 0; i < posts.length; ++i) {
            IProcedure(newContract).post(posts[i].entRole, posts[i].tokenId, posts[i].uri);
        }

    }

    /// Make a new Case
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function caseMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) public override returns (address) {
        /* MOVED OUT
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address claimContract = hub().claimMake(name_, uri_);
        //Register New Contract
        _registerNewClaim(claimContract);
        //Create Custom Roles
        ICTXEntityUpgradable(claimContract).roleCreate("witness");     //Witnesses
        ICTXEntityUpgradable(claimContract).roleCreate("affected");    //Affected Party (For reparations)
        */
        address claimContract =_caseMake(name_, uri_);
        _onCreation(claimContract, rules, assignRoles, posts);
        //Return new Contract Address
        return claimContract;
    }

    /// Make a new Case & File it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a claim
    function caseMakeOpen(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) public override returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address claimContract = caseMake(name_, uri_, rules, assignRoles, posts);
        //File Claim
        IClaim(claimContract).stageFile();
        //Return new Contract Address
        return claimContract;
    }

    /// Make a new Case, File it & Close it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a claim
    function caseMakeClosed(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts,
        string calldata decisionURI_
    ) public override returns (address) {
        //Validate Role
        require(gameRoles().roleHas(_msgSender(), "authority") , "ROLE:AUTHORITY_ONLY");
        //Generate A Decision -- Yes to All
        DataTypes.InputDecision[] memory verdict = new DataTypes.InputDecision[](rules.length);
        for (uint256 i = 0; i < rules.length; ++i) {
            verdict[i].ruleId = i+1;
            verdict[i].decision = true;
        }
        //Create new Claim
        // address claimContract = caseMake(name_, uri_, rules, assignRoles, posts);
        //Make Claim & Open
        // address claimContract = caseMakeOpen(name_, uri_, rules, assignRoles, posts);
        

        address claimContract =_caseMake(name_, uri_);
        _onCreation(claimContract, rules, assignRoles, posts);

        //File Claim
        IClaim(claimContract).stageFile();
        //Push Forward
        IClaim(claimContract).stageWaitForDecision();
        //Close Claim
        IClaim(claimContract).stageDecision(verdict, decisionURI_);
        //Return
        return claimContract;
    }

    /// Register New Claim Contract
    function _registerNewClaim(address claimContract) private {
        //Register Child Contract
        repo().addressAdd("claim", claimContract);
        //New Claim Created Event
        // emit ClaimCreated(claimId, claimContract);  //CANCELLED
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../libraries/DataTypes.sol";

interface ICourtExt {
    
    //--- Events

    //--- Functions
    
    /// Make a new Claim
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function caseMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) external returns (address);

    /// Make a new Claim & File it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a claim
    function caseMakeOpen(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) external returns (address);

    /// Make a new Claim, File it & Close it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing & closing a claim
    function caseMakeClosed(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts,
        string calldata decisionURI_
    ) external returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../public/interfaces/IOpenRepo.sol";
import "../interfaces/IERC1155RolesTracker.sol";
import "../interfaces/IProtocolEntity.sol";
import "../interfaces/IGameUp.sol";
import "../interfaces/IHub.sol";
import "../interfaces/ISoul.sol";

/**
 * @title GameExtension
 */
abstract contract GameExtension is Context {

    //--- Modifiers

    
    /// Permissions Modifier
    modifier AdminOnly() {
       //Validate Permissions
        require(gameRoles().roleHas(_msgSender(), "admin"), "ADMIN_ONLY");
        _;
    }
    
    //--- Functions 

    /// Use Self (Main Game)
    function game() internal view returns (IGame) {
        return IGame(address(this));
    }

    /// Use Game Role Interface on Self 
    function gameRoles() internal view returns (IERC1155RolesTracker) {
        return IERC1155RolesTracker(address(this));
    }

    /// Get Data Repo Address (From Hub)
    function getRepoAddr() public view returns (address) {
        return IProtocolEntity(address(this)).getRepoAddr();
    }

    /// Get Assoc Repo
    function repo() internal view returns (IOpenRepo) {
        return IOpenRepo(getRepoAddr());
    }

    /// Hub Address
    function getHubAddress() internal view returns (address) {
        return IProtocolEntity(address(this)).getHub();
    }
      
    /// Get Hub
    function hub() public view returns (IHub) {
        return IHub(getHubAddress());
    }  

    /// Get Soul Contract Address
    function getSoulAddr() internal view returns (address) {
        return repo().addressGetOf(getHubAddress(), "SBT");
    }

    /// Get Soul Contract
    function soul() internal view returns (ISoul) {
        return ISoul(getSoulAddr());
    }  
    
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @title DataTypes
 * @notice A standard library of generally used data types
 */
library DataTypes {

    //---

    /// NFT Identifiers
    struct Entity {
        address account;
        uint256 id;
        uint256 chain;
    }
    /// Rating Domains
    enum Domain {
        Environment,
        Personal,
        Community,
        Professional
    }

    //--- Claims

    //Claim Lifecycle
    enum ClaimStage {
        Draft,
        Open,           // Filed -- Confirmation/Discussion (Evidence, Witnesses, etc’)
        Decision,       // Awaiting Decision (Authority, Jury, vote, etc’)
        Action,         // Remedy - Reward / Punishment / Compensation
        Appeal,
        Execution,
        Closed,
        Cancelled       // Denied / Withdrawn
    }

    //--- Actions

    // Semantic Action Entity
    struct Action {
        string name;    // Title: "Breach of contract",  
        string text;    // text: "The founder of the project must comply with the terms of the contract with investors",  //Text Description
        string uri;     //Additional Info
        SVO entities;
        // Confirmation confirmation;          //REMOVED - Confirmations a part of the Rule, Not action
    }

    struct SVO {    //Action's Core (System Role Mapping) (Immutable)
        string subject;
        string verb;
        string object;
        string tool; //[TBD]
    }

    //--- Rules
    
    // Rule Object
    struct Rule {
        bytes32 about;      //About What (Action's GUID)      //TODO: Maybe Call This 'actionGUID'? 
        string affected;    //Affected Role. E.g. "investors"
        bool negation;      //0 - Commission  1 - Omission
        string uri;         //Test & Conditions
        bool disabled;      //1 - Rule Disabled
    }
    
    // Effect Structure (Reputation Changes)
    struct Effect {
        string name;
        uint8 value;    // value: 5
        bool direction; // Direction: -
        // bytes data;  //[TBD]
    }
    
    //Rule Confirmation Method
    struct Confirmation {
        string ruling;
        // ruling: "authority"|"jury"|"democracy",  //Decision Maker
        bool evidence;
        // evidence: true, //Require Evidence
        uint witness;
        // witness: 1,  //Minimal number of witnesses
    }

    //--- Claim Data

    //Rule Reference
    struct RuleRef {
        address game;
        uint256 ruleId;
    }
    
    //-- Function Inputs Structs

    //Role Input Struct
    struct InputRole {
        address account;
        string role;
    }

    //Role Input Struct (for Token)
    struct InputRoleToken {
        uint256 tokenId;
        string role;
    }

    //Decision Input
    struct InputDecision {
        uint256 ruleId;
        bool decision;
    }

    //Post Input Struct
    struct PostInput {
        uint256 tokenId;
        string entRole;
        string uri;
    }

    //Role Name Input Struct
    // struct InputRoleMapping {
    //     string role;
    //     string name;
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICTXEntityUpgradable {

    //--- Functions

    /// Request to Join
    function nominate(uint256 sbt, string memory uri_) external;

    /// Create a new Role
    function roleCreate(string calldata role) external;

    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 toToken, string memory role) external;

    /// Remove Someone Else from a Role
    function roleRemove(address account, string calldata role) external;

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 sbt, string memory role) external;

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external;

    /// Get Token URI by Token ID
    function uri(uint256 token_id) external returns (string memory);

    /// Set Metadata URI For Role
    function setRoleURI(string memory role, string memory _tokenURI) external;

    /// Set Contract URI
    function setContractURI(string calldata contract_uri) external;

    /// Generic Config Get Function
    function confGet(string memory key) external view returns (string memory);

    /// Generic Config Set Function
    function confSet(string memory key, string memory value) external;

    //--- Events

    /// Nominate
    event Nominate(address account, uint256 indexed id, string uri);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IClaim {
    
    //-- Functions

    /// File the Claim (Validate & Open Discussion)  --> Open
    function stageFile() external;

    /// Stage: Wait For Verdict  --> Pending
    function stageWaitForDecision() external;

    /// Stage: Place Verdict  --> Closed
    // function stageDecision(string calldata uri) external;
    function stageDecision(DataTypes.InputDecision[] calldata verdict, string calldata uri) external;

    /// Stage: Reject Claim --> Cancelled
    function stageCancel(string calldata uri) external;

    /// Request to Join
    // function nominate(uint256 soulToken, string memory uri) external;

    //Get Contract Association
    // function assocGet(string memory key) external view returns (address);

    //** Rules
    
    /// Add Rule Reference
    function ruleRefAdd(address game_, uint256 ruleId_) external;

    //--- Events

    /// Rule Reference Added
    event RuleAdded(address game, uint256 ruleId);

    //Rule Confirmed
    event RuleConfirmed(uint256 ruleId);

    //Rule Denied (Changed from Confirmed)
    // event RuleDenied(uint256 ruleId);
    
    /// Nominate
    // event Nominate(address account, uint256 indexed id, string uri);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IProcedure {

    //-- Functions

    /// Initialize
    function initialize(
        address container, 
        string calldata type_,
        string memory name_, 
        string calldata uri_
    ) external;

    /// Set Parent Container
    function setParentCTX(address container) external;

    /// Add Post 
    function post(string calldata entRole, uint256 tokenId, string calldata uri) external;

    //--- Events

    /// Claim Stage Change
    event Stage(DataTypes.ClaimStage stage);

    /// Post Verdict
    event Verdict(string uri, address account);

    /// Claim Cancelation Data
    event Executed(address account);

    /// Claim Cancelation Data
    event Cancelled(string uri, address account);

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
pragma solidity 0.8.4;

interface IOpenRepo {

    //--- Functions

    //-- Addresses  

    /// Get Association
    function addressGet(string memory key) external view returns (address);

    /// Get Contract Association
    function addressGetOf(address originContract, string memory key) external view returns (address);

    /// Check if address is Regitered
    function addressHasOf(address originContract, string memory key, address targetAddress) external view returns (bool);

    /// Check if address is Regitered to Slot
    function addressHas(string memory key, address targetAddress) external view returns (bool);

    /// Get First Address in Index
    function addressGetIndexOf(address originContract, string memory key, uint256 index) external view returns (address);

    /// Get First Address in Index
    function addressGetIndex(string memory key, uint256 index) external view returns (address);

    /// Get All Address in Slot
    function addressGetAllOf(address originContract, string memory key) external view returns (address[] memory);
    
    /// Get All Address in Slot
    function addressGetAll(string memory key) external view returns (address[] memory);

    /// Set  Association
    function addressSet(string memory key, address value) external;

    /// Add Address to Slot
    function addressAdd(string memory key, address value) external;

    /// Remove Address from Slot
    function addressRemove(string memory key, address value) external;

    //-- Booleans

    /// Get Association
    function boolGet(string memory key) external view returns (bool);

    /// Get Contract Association
    function boolGetOf(address originContract, string memory key) external view returns (bool);

    /// Get First Address in Index
    function boolGetIndexOf(address originContract, string memory key, uint256 index) external view returns (bool);

    /// Get First Address in Index
    function boolGetIndex(string memory key, uint256 index) external view returns (bool);

    /// Set  Association
    function boolSet(string memory key, bool value) external;

    /// Add Address to Slot
    function boolAdd(string memory key, bool value) external;

    /// Remove Address from Slot
    function boolRemove(string memory key, bool value) external;


    //-- Strings

    /// Get Association
    function stringGet(string memory key) external view returns (string memory);

    /// Get Contract Association
    function stringGetOf(address originAddress, string memory key) external view returns (string memory);

    /// Get First Address in Index
    function stringGetIndexOf(address originAddress, string memory key, uint256 index) external view returns (string memory);

    /// Get First Address in Index
    function stringGetIndex(string memory key, uint256 index) external view returns (string memory);

    /// Set  Association
    function stringSet(string memory key, string memory value) external;

    /// Add Address to Slot
    function stringAdd(string memory key, string memory value) external;

    /// Remove Address from Slot
    function stringRemove(string memory key, string memory value) external;


    //--- Events

    //-- Addresses

    /// Association Set
    event AddressSet(address originAddress, string key, address destinationAddress);

    /// Association Added
    event AddressAdd(address originAddress, string key, address destinationAddress);

    /// Association Added
    event AddressRemoved(address originAddress, string key, address destinationAddress);


    //-- Booleans

    /// Association Set
    event BoolSet(address originContract, string key, bool value);

    /// Association Added
    event BoolAdd(address originContract, string key, bool value);

    /// Association Added
    event BoolRemoved(address originContract, string key, bool value);


    //-- Strings

    /// Association Set
    event StringSet(address originAddress, string key, string value);

    /// Association Added
    event StringAdd(address originAddress, string key, string value);

    /// Association Added
    event StringRemoved(address originAddress, string key, string value);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.4;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IERC1155RolesTracker {

    //--- Functions

    /// Unique Members Addresses
    function uniqueRoleMembers(string memory role) external view returns (uint256[] memory);

    /// Unique Members Count (w/Token)
    function uniqueRoleMembersCount(string memory role) external view returns (uint256);    

    /// Check if Role Exists
    function roleExist(string memory role) external view returns (bool);

    /// Check if account is assigned to role
    function roleHas(address account, string calldata role) external view returns (bool);

    /// Check if Soul Token is assigned to role
    function roleHasByToken(uint256 soulToken, string memory role) external view returns (bool);

    /// Get Metadata URI by Role
    function roleURI(string calldata role) external view returns (string memory);

    //--- Events

    /// New Role Created
    event RoleCreated(uint256 indexed id, string role);

    /// URI Change Event
    event RoleURIChange(string value, string role);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Common Protocol Functions
 */
interface IProtocolEntity {
    
    /// Inherit owner from Protocol's config
    function owner() external view returns (address);
    
    // Change Hub (Move To a New Hub)
    function setHub(address hubAddr) external;

    /// Get Hub Contract
    function getHub() external view returns (address);
    
    //Repo Address
    function getRepoAddr() external view returns (address);

    /// Generic Config Get Function
    // function confGet(string memory key) external view returns (string memory);

    /// Generic Config Set Function
    // function confSet(string memory key, string memory value) external;

    //-- Events

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IGame {
    
    //--- Functions

    /// Initialize
    function initialize(string calldata type_, string calldata name_, string calldata uri_) external;

    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Add Post 
    function post(string calldata entRole, uint256 tokenId, string calldata uri) external;

    /// Disable Claim
    function claimDisable(address claimContract) external;

    /// Check if Claim is Owned by This Contract (& Active)
    function claimHas(address claimContract) external view returns (bool);

    /// Join game as member
    function join() external returns (uint256);

    /// Leave member role in current game
    function leave() external returns (uint256);

    /// Request to Join
    // function nominate(uint256 soulToken, string memory uri) external;

    /* MOVED UP
    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 toToken, string memory role) external;

    /// Remove Someone Else from a Role
    function roleRemove(address account, string calldata role) external;

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) external;

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external;

    /// Create a new Role
    // function roleCreate(address account, string calldata role) external;
    */
    
    /// Set Metadata URI For Role
    // function setRoleURI(string memory role, string memory _tokenURI) external;

    /// Add Reputation (Positive or Negative)
    // function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    /// Execute Rule's Effects (By Claim Contreact)
    function effectsExecute(uint256 ruleId, address targetContract, uint256 targetTokenId) external;

    /// Register an Incident (happening of a valued action)
    function reportEvent(uint256 ruleId, address account, string calldata detailsURI_) external;

    //--- Events

    /// Effect
    event EffectsExecuted(uint256 indexed targetTokenId, uint256 indexed ruleId, bytes data);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IHub {
    
    //--- Functions

    /// Arbitrary contract symbol
    function symbol() external view returns (string memory);
    
    /// Arbitrary contract designation signature
    function role() external view returns (string memory);
    
    /// Get Owner
    function owner() external view returns (address);

    //Repo Address
    function getRepoAddr() external view returns (address);

    /// Mint an SBT for another account
    function mintForAccount(address account, string memory tokenURI) external returns (uint256);

    /// Make a new Game
    function gameMake(
        string calldata type_,
        string calldata name_, 
        string calldata uri_
    ) external returns (address);

    /// Make a new Claim
    function claimMake(
        string calldata type_, 
        string calldata name_, 
        string calldata uri_
    ) external returns (address);

    /// Make a new Task
    function taskMake(
        string calldata type_, 
        string calldata name_, 
        string calldata uri_
    ) external returns (address);
    
    /// Update Hub
    function hubChange(address newHubAddr) external;

    /// Add Reputation (Positive or Negative)       /// Opinion Updated
    function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    //Get Contract Association
    function assocGet(string memory key) external view returns (address);
    
    //--- Events

    /// Beacon Contract Chnaged
    event UpdatedImplementation(string name, address implementation);

    /// New Contract Created
    event ContractCreated(string name, address indexed contractAddress);

    /// New Contract Created
    event HubChanged(address contractAddress);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title Soulbound Token Interface
 * @dev Additions to IERC721 
 */
interface ISoul {

    //--- Functions

    /// Get Token ID by Address
    function tokenByAddress(address owner) external view returns (uint256);

    /// Mint (Create New Avatar for oneself)
    function mint(string memory tokenURI) external returns (uint256);

    /// Mint (Create New Token for Someone Else)
    function mintFor(address to, string memory tokenURI) external returns (uint256);

    /// Add (Create New Avatar Without an Owner)
    // function add(string memory tokenURI) external returns (uint256);

    /// Update Token's Metadata
    function update(uint256 tokenId, string memory uri) external returns (uint256);

    /// Add Reputation (Positive or Negative)
    function repAdd(uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    /// Map Account to Existing Token
    function tokenOwnerAdd(address owner, uint256 tokenId) external;

    /// Remove Account from Existing Token
    function tokenOwnerRemove(address owner, uint256 tokenId) external;

    /// Check if the Current Account has Control over a Token
    function hasTokenControl(uint256 tokenId) external view returns (bool);
    
    /// Check if a Specific Account has control over a Token
    function hasTokenControlAccount(uint256 tokenId, address account) external view returns (bool);

    /// Post
    function post(uint256 tokenId, string calldata uri_) external;

    //--- Events
    
	/// URI Change Event
    event URI(string value, uint256 indexed id);    //Copied from ERC1155

    /// Reputation Changed
    event ReputationChange(uint256 indexed id, string domain, bool rating, uint256 score);

    /// General Post
    event Post(address indexed account, uint256 tokenId, string uri);

    /// Soul Type Change
    event SoulType(uint256 indexed tokenId, string soulType);

}