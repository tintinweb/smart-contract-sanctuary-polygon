// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ESovStructs.sol";
import "./AgentManagement.sol";
// import "hardhat/console.sol";
/**
 *@author metadev3 team
 *@title Contract for Agent.
 */
contract Agent is ESovStructs {
    // AgentData
    UserESovWallet public userESovWallet;
    UserRole public role;
    string public keyPII;           // crypted
    string public challenges;       // crypted
    bool public hasPurchased;
    bool public challengesPassed;   // the user succeeded to answer to challenges
    uint256 nbRecoveriesDone;   // total number of recoveries done by the agent
    address agentManagement;

    modifier onlyAgentManagement {
        require(msg.sender == agentManagement, "ESov Agent: Only AgentManagement can do this action");
        _;
    }
    modifier challengesArePassed {
        require(challengesPassed, "ESov Agent: You need to pass the challenges");
        _;
    }
    
    constructor(UserESovWallet memory _userESovWallet, string memory _keyPII, string memory _challenges, address _agentManagementContractAddress){
        userESovWallet = _userESovWallet;
        keyPII = _keyPII;
        challenges = _challenges;
        agentManagement = _agentManagementContractAddress;
    }
    
    function setUserESovWallet(string calldata _password, address _publicAddress) public challengesArePassed {
        // userESovWallet
        UserESovWallet memory _userESovWallet = UserESovWallet(_password, _publicAddress);
        userESovWallet = _userESovWallet;
    }
    // condition to confirm
    function setRole(UserRole _newRole) public onlyAgentManagement {
        role = _newRole;
    }

    function setKeyPII(string memory _keyPII) public challengesArePassed {
        require(!AgentManagement(agentManagement).checkKeyPII(_keyPII), "ESov Agent: Key PII already used");
        keyPII = _keyPII;
    }

    function setChallenges(string memory _challenges) public challengesArePassed {
        challenges = _challenges;
    }

    // conditions to do
    function setHasPurchased(bool _hasPurchased) public {
        // require(false, "ESov Agent: "); 
        hasPurchased = _hasPurchased;
    }

    // conditions to do
    function setChallengesPassed(bool _challengesPassed) public {
        // require(false, "ESov Agent: ");
        challengesPassed = _challengesPassed;
    }

    function getUserWalletPublicAddress() public view returns(address) {
        return userESovWallet.walletPublicAddress;
    }

    function getUserWalletPassword() public onlyAgentManagement view returns(string memory) {
        return userESovWallet.walletPassword;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "hardhat/console.sol";
import "./Agent.sol";
import "./interfaces/ESovStructs.sol";
/**
 *@author metadev3 team
 *@title Contract to manage Agents.
 */
contract AgentManagement is ESovStructs {

    Agent[] public agentContractList;
    RoleCounter public roleCounter;

    event NewAgentContract(address);

    constructor(){
        //test //////////
        // agents.push(AgentData(address(1), UserRole.OPTIN,"cryptedKeyPIItest0", "cryptedEmail0"));
        // agents.push(AgentData(address(msg.sender), UserRole.OPTIN,"cryptedKeyPIItest1", "cryptedEmail1"));
        // agents.push(AgentData(address(2), UserRole.OPTIN,"cryptedKeyPIItest2", "cryptedEmail2"));
        // increaseOptInCounter();
        // increaseOptInCounter();
        // increaseOptInCounter();
        // agents.push(AgentData(address(111), UserRole.OPTOUT));
        // agents.push(AgentData(address(222), UserRole.DISQUALIFIED));
        // agents.push(AgentData(address(223), UserRole.DISQUALIFIED));
        // increaseOptInCounter();
        // increaseOptInCounter();
        // increaseOptInCounter();
        // manageRoleCounter(UserRole.OPTIN, UserRole.OPTOUT);
        // manageRoleCounter(UserRole.OPTIN, UserRole.DISQUALIFIED);
        // manageRoleCounter(UserRole.OPTIN, UserRole.DISQUALIFIED);
        /////////////////
        // UserESovWallet memory _userESovWallet = UserESovWallet("123456", address(2));
        // Agent newAgent = new Agent(_userESovWallet, "keyPII", "_challenges", address(this));
        // agentContractList.push(newAgent);
        // console.log("icii0", address(newAgent));
    }

    function createAgent(string calldata _password, address _publicAddress, string calldata _keyPII, string memory _challenges) public 
    {
        require(!checkKeyPII(_keyPII), "ESov AgentManagement: Key PII already used !");

        // userESovWallet
        UserESovWallet memory _userESovWallet = UserESovWallet(_password, _publicAddress);
        // create new contract Agent
        Agent newAgent = new Agent(_userESovWallet, _keyPII, _challenges, address(this));
        agentContractList.push(newAgent);
        emit NewAgentContract(address(newAgent));
    }
    
    function checkKeyPII(string memory _keyPII) public view returns (bool) {
        for(uint256 i = 0;i < agentContractList.length; ++i) {
            if(keccak256(abi.encodePacked(agentContractList[i].keyPII())) == keccak256(abi.encodePacked(_keyPII))) {
                return true;
            }
        }
        return false;
    }
    // try to optimize by getting the index from checkKeyPII ?
    function connection(string calldata _keyPII, string calldata _password) public view returns (address) {
        for(uint256 i = 0;i < agentContractList.length; ++i) {
            if(keccak256(abi.encodePacked(agentContractList[i].keyPII())) == keccak256(abi.encodePacked(_keyPII))) {
                if(keccak256(abi.encodePacked(agentContractList[i].getUserWalletPassword())) == keccak256(abi.encodePacked(_password))) {
                    return address(agentContractList[i].getUserWalletPublicAddress());
                }
            }
        }
        return address(0);
    }

    // get the addresses of optInAgents
    function getOptInAgents() public view returns(address[] memory){
        require(roleCounter.optOut > 0, "ESov Agent: Opted in agents is null");
        address[] memory optInAgents = new address[](roleCounter.optIn);
        uint256 indexOptInAgent;
        uint256 i;  // all agents index
        do {
            if (agentContractList[i].role() == UserRole.OPTIN) {
                optInAgents[indexOptInAgent] = agentContractList[i].getUserWalletPublicAddress();
                ++indexOptInAgent;
            }
            ++i;
        } while(optInAgents[roleCounter.optIn-1] == address(0) && i < agentContractList.length);
        //remove && i < agents.length ??  to save gas fee ?
        return optInAgents;
    }

    // get the addresses of optOutAgents
    function getOptOutAgents() public view returns(address[] memory){
        require(roleCounter.optOut > 0, "ESov Agent: Opted out agents is null");
        address[] memory optOutAgents = new address[](roleCounter.optOut);
        uint256 indexOptOutAgent;
        uint256 i;  // all agents index
        do {
            if (agentContractList[i].role() == UserRole.OPTOUT) {
                optOutAgents[indexOptOutAgent] = agentContractList[i].getUserWalletPublicAddress();
                ++indexOptOutAgent;
            }
            ++i;
        } while(optOutAgents[roleCounter.optOut-1] == address(0) && i < agentContractList.length);
        //remove && i < agents.length ??  to save gas fee ?
        return optOutAgents;
    }

    // get the addresses of disqualifiedAgents
    function getDisqualifiedAgents() public view returns(address[] memory){
        require(roleCounter.disqualified > 0, "ESov Agent: Disqualified agents is null");
        address[] memory disqualifiedAgents = new address[](roleCounter.disqualified);
        uint256 indexDisqualifiedAgent;
        uint256 i;  // all agents index
        do {
            if (agentContractList[i].role() == UserRole.DISQUALIFIED) {
                disqualifiedAgents[indexDisqualifiedAgent] = agentContractList[i].getUserWalletPublicAddress();
                ++indexDisqualifiedAgent;
            }
            ++i;
        } while(disqualifiedAgents[roleCounter.disqualified-1] == address(0) && i < agentContractList.length);
        //remove && i < agents.length ??  to save gas fee ?
        return disqualifiedAgents;
    }

    // getQualifiedAgent to do in Scoreboard contract ?

    function increaseOptInCounter() private {
        ++roleCounter.optIn;
    }
    function increaseOptOutCounter() private {
        ++roleCounter.optOut;
    }

    function manageRoleCounter(UserRole previousRole, UserRole newRole) private {
        // previousRole
        if(previousRole == UserRole.OPTIN) {--roleCounter.optIn;}
        else if (previousRole == UserRole.OPTOUT) {--roleCounter.optOut;}
        else if (previousRole == UserRole.DISQUALIFIED) {--roleCounter.disqualified;}
        //to remove ? not used in this function ?
        else if (previousRole == UserRole.QUALIFIED) {--roleCounter.qualified;}
        
        // newRole
        if(newRole == UserRole.OPTIN) {++roleCounter.optIn;}
        else if (newRole == UserRole.OPTOUT) {++roleCounter.optOut;}
        else if (newRole == UserRole.DISQUALIFIED) {++roleCounter.disqualified;}
        //to remove ? not used in this function ?
        else if (newRole == UserRole.QUALIFIED) {++roleCounter.qualified;}
    }

    function getUserFromAddress(address _userAddress) public view returns (Agent) {
        for (uint256 i = 0; i < agentContractList.length; ++i) {
            if (agentContractList[i].getUserWalletPublicAddress() == _userAddress) {
                return agentContractList[i];
            }
        }
        revert("ESov Agent: Address searched not found");
    }

    // opt out the user that call this function
    function optOut() public {
        // this require to confirm
        require(roleCounter.optIn > 10000, "ESov Agent: You cannot opt out when the opted in agents are not more numerous than 10 000");
        // uint256 index = indexOfUserContract(msg.sender);
        Agent user = getUserFromAddress(msg.sender);
        require(user.role() != UserRole.OPTOUT, "ESov Agent: You are already opted out");
        manageRoleCounter(user.role(), UserRole.OPTOUT);
        user.setRole(UserRole.OPTOUT);
    }

    // opt in the user that call this function
    function optIn() public {
        Agent user = getUserFromAddress(msg.sender);
        require(user.role() != UserRole.OPTIN, "ESov Agent: You are already opted in");
        manageRoleCounter(user.role(), UserRole.OPTIN);
        user.setRole(UserRole.OPTIN);
    }

    // function indexOfUserContract(address _userAddress) private view returns (uint256) {
    //     for (uint256 i = 0; i < agentContractList.length; ++i) {
    //         if (agentContractList[i].getUserWalletPublicAddress() == _userAddress) {
    //             return i;
    //         }
    //     }
    //     revert("ESov Agent: Address searched not found");
    // }

    // function isOptInAgent(address _address) public view returns(bool) {
    //     uint256 index = indexOfUserContract(_address);
    //     return user.role() == UserRole.OPTIN;
    // }

    // function isOptOutUser(address _address) public view returns(bool) {
    //     uint256 index = indexOfUserContract(_address);
    //     return user.role() == UserRole.OPTOUT;
    // }

    // function isDisqualifiedAgent(address _address) public view returns(bool) {
    //     uint256 index = indexOfUserContract(_address);
    //     return user.role() == UserRole.DISQUALIFIED;
    // }

    // //remove this function ?
    // function isQualifiedAgent(address _address) public view returns(bool) {
    //     uint256 index = indexOfUserContract(_address);
    //     return user.role() == UserRole.QUALIFIED;
    // }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17 ;
interface ESovStructs {
    
    enum UserRole {QUALIFIED, OPTOUT, OPTIN, DISQUALIFIED}   //remove QUALIFIED ?
    
    struct UserESovWallet {
        string walletPassword;      //crypted
        address walletPublicAddress;
    }

    struct RoleCounter {            // count the number of users in each role
        uint256 qualified;
        uint256 optIn;
        uint256 optOut;
        uint256 disqualified;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";
import "./Agent.sol";
import "./AgentManagement.sol";

/**
 *@author metadev3 team
 *@title Contract for Vault.
 */
contract Vault is ESovStructs {

    mapping(address => string) public secrets;   // Agent contract address of user => secret
    AgentManagement agentManagement;

    constructor(address _agentManagement){
        agentManagement = AgentManagement(_agentManagement);
    }

    function addInitialSecret(string calldata _secret) public {  // add initial secret   (should add a require to check if msg.sender is a agent/user ?)  //if the user setSecret with empty string, he will be able to use this function again => prevent emptyString in setSecret ??
        Agent user = agentManagement.getUserFromAddress(msg.sender); // get user from agentManagement
        require(keccak256(abi.encodePacked(secrets[address(user)])) == keccak256(abi.encodePacked("")), "ESov Vault: You can't add initial secret when it has already been added");
        secrets[address(user)] = _secret;
    }

    function setSecret(string calldata _secret) public {  
        Agent user = agentManagement.getUserFromAddress(msg.sender); // get user from agentManagement
        require(user.challengesPassed(), "ESov Vault: You need to pass the challenges");
        require(keccak256(abi.encodePacked(_secret)) != keccak256(abi.encodePacked("")), "ESov Vault: You can't add empty secret"); //prevent to add empty string, to keep/remove ?
        secrets[address(user)] = _secret;
    }

    function setUserESovWallet(string calldata _password, address _publicAddress) public {  
        Agent user = agentManagement.getUserFromAddress(msg.sender);
        user.setUserESovWallet(_password, _publicAddress);
    }

    function setChallenges(string calldata _challenges) public {
        Agent user = agentManagement.getUserFromAddress(msg.sender); // get user from agentManagement
        user.setChallenges(_challenges);    // need to have passed the challenges to do this
    }    

}