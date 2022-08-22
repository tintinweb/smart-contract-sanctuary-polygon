/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// File: utils/Imisc.sol

pragma solidity >=0.8.0 <0.9.0;

interface Imisc{
    function changeCapsuleContract(address addr) external;//ELFCore
    function changeSpawnContract(address addr) external;//ELFCore
    function changeCoinA(address addr) external;//SpawnContract
    function changeCoinB(address addr) external;//SpawnContract
    function setELFCore(address addr) external;//SpawnContract
    function changeCoinAddresses(uint256 coinType, address addr) external;//CoinMarket
    function setPermission(address addr,bool permitted) external;//decreaseAuction
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: security/Multisig.sol

pragma solidity >=0.8.0 <0.9.0;
//change 300


contract Multisig {

    string constant PROPOSED='proposed';
    string constant ALREADY_OWNER='already owner';
    string constant NOT_OWNER='not owner';
    string constant NO_PROPOSAL='proposal not found';
    string constant WRONG_THRESHOULD='number of owner<required';

    mapping (uint256 => mapping (address => bool)) confirmations;
    mapping (address => bool) isOwner;
    //1 addUser, 2 removeUser, 3 required, 4 changeAdmined, 
    //5 setSuperAdmin, 6 setAdmin, 7 withdrawBalance, 8 transfer
    //9 pause, 10 unpause
    mapping (uint256 => uint256) idToType;
    mapping (uint256 => address[]) idToVote;
    uint256 constant duration=300; 
    uint256 public required=2;
    uint256 public proposalCount;
    address admined;
    address[] owners=[0xf215893aeD38B7A307e84A9A2c1D775c9d5bA472,0x9bB69CcCD27d2625fdd5661Ea31629BF057CC215,0xd53b9aFf80819413EbF8316df64fca008911F8Ba];

    struct Proposal {
        uint256 id;
        uint256 endAt;
        uint256 num;
        address proposer;
        address addr;
        bool permit;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner],ALREADY_OWNER);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner],NOT_OWNER);
        _;
    }

    modifier notConfirmed(uint id, address owner) {
        require(!confirmations[id][owner],'tx confirmed');
        _;
    }

    modifier notNull(address _address) {
        require(_address!=address(0),'invalid address');
        _;
    }

    /// @dev Fallback function does not allows to deposit ether.
    fallback() external {}

    receive() external payable {}

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    constructor(){
        for (uint i=0; i<3; i++) {
            isOwner[owners[i]] = true;
        }
    }

    /// @dev Returns list of owners.
    function getOwners() external view ownerExists(msg.sender) returns (address[] memory){
        return owners;
    }

    /// @dev Returns voted owner of the given proposalId.
    function gainVotedOwner(uint256 proposalId) external view ownerExists(msg.sender) returns (address[] memory){
        require(proposalId<proposalCount,NO_PROPOSAL);
        return idToVote[proposalId];
    }

    function gainConfirmationCount(uint256 proposalId) public view returns(uint256 res){
        require(proposalId<proposalCount,NO_PROPOSAL);
        uint256 l=owners.length;
        for(uint256 i=0;i<l;i++){
            if(confirmations[proposalId][owners[i]]){
                res+=1;
            }
        }
    }

    Proposal[] addUserProposals;
    Proposal[] removeUserProposals;
    Proposal[] requiredProposals;
    Proposal[] adminedProposals;
    Proposal[] superAdminProposals;
    Proposal[] adminProposals;
    Proposal[] withdrawProposals;
    Proposal[] transferProposals;
    Proposal[] pauseProposals;
    Proposal[] unpauseProposals;

    /// @dev Allows an owner to submit and confirm an addUser Proposal.
    /// @param addr Add addr to owners.
    function submitAddUserProposal(address addr) external ownerExists(msg.sender) notNull(addr) ownerDoesNotExist(addr){
        removeExpiredProposal(addUserProposals);
        require(doublePropose(addUserProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=1;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        addUserProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in addUserProposals, and list of addr of proposals in addUserProposals
    function gainAddUserProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=addUserProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=addUserProposals[i].id;
            resAddr[i]=addUserProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a removeUser Proposal.
    /// @param addr Remove addr from owners.
    function submitRemoveUserProposal(address addr) external ownerExists(msg.sender) ownerExists(addr) {
        removeExpiredProposal(removeUserProposals);
        require(doublePropose(removeUserProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=2;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        removeUserProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in removeUserProposals, and list of addr of proposals in removeUserProposals
    function gainRemoveUserProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=removeUserProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=removeUserProposals[i].id;
            resAddr[i]=removeUserProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a set required Proposal.
    /// @param num Proposed required value.
    function submitRequiredProposal(uint256 num) external ownerExists(msg.sender){
        removeExpiredProposal(requiredProposals);
        require(doublePropose(requiredProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=3;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:num,
            proposer:msg.sender,
            addr:address(0),
            permit:false
        });
        proposalCount+=1;
        requiredProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in requiredProposals, and list of num of proposals in requiredProposals
    function gainRequiredProposals() external view returns(uint256[] memory,uint256[] memory){
        uint256 l=requiredProposals.length;
        uint256[] memory resId=new uint256[](l);
        uint256[] memory resNum=new uint256[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=requiredProposals[i].id;
            resNum[i]=requiredProposals[i].num;
        }
        return(resId,resNum);
    }

    /// @dev Allows an owner to submit and confirm a set admined Proposal.
    /// @param addr Proposed new admined address.
    function submitAdminedProposal(address addr) external ownerExists(msg.sender) notNull(addr){
        removeExpiredProposal(adminedProposals);
        require(doublePropose(adminedProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=4;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        adminedProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in adminedProposals, and list of addr of proposals in adminedProposals
    function gainAdminedProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=adminedProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=adminedProposals[i].id;
            resAddr[i]=adminedProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a superAdmin Proposal.
    /// @param addr Set addr as superAdmin of admined contract.
    function submitSuperAdminProposal(address addr) external ownerExists(msg.sender) notNull(addr) {
        removeExpiredProposal(superAdminProposals);
        require(doublePropose(superAdminProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=5;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        superAdminProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in superAdminProposals, and list of addr of proposals in superAdminProposals
    function gainSuperAdminProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=superAdminProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=superAdminProposals[i].id;
            resAddr[i]=superAdminProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a admin Proposal.
    /// @param addr Set addr as admin of admined contract.
    function submitAdminProposal(address addr) external ownerExists(msg.sender) notNull(addr) {
        removeExpiredProposal(adminProposals);
        require(doublePropose(adminProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=6;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        adminProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in adminProposals, and list of addr of proposals in adminProposals
    function gainAdminProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=adminProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=adminProposals[i].id;
            resAddr[i]=adminProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a withdrawBalance Proposal.
    /// @param amount Amount to withdraw from admined contract.
    function submitWithdrawProposal(uint256 amount) external ownerExists(msg.sender) {
        removeExpiredProposal(withdrawProposals);
        require(doublePropose(withdrawProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=7;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:amount,
            proposer:msg.sender,
            addr:address(0),
            permit:false
        });
        proposalCount+=1;
        withdrawProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in withdrawProposals, and list of num of proposals in adminProposals
    function gainWithdrawProposals() external view returns(uint256[] memory,uint256[] memory){
        uint256 l=withdrawProposals.length;
        uint256[] memory resId=new uint256[](l);
        uint256[] memory resNum=new uint256[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=withdrawProposals[i].id;
            resNum[i]=withdrawProposals[i].num;
        }
        return(resId,resNum);
    }

    /// @dev Allows an owner to submit and confirm a transfer Proposal.
    /// @param amount Amount of matic to transfer from this contract.
    /// @param addr Transfer matic to this address.
    function submitTransferProposal(uint256 amount, address addr) external ownerExists(msg.sender) {
        removeExpiredProposal(transferProposals);
        require(doublePropose(transferProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=8;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:amount,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        transferProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in withdrawProposals, and list of num of proposals in adminProposals
    function gainTransferProposals() external view returns(uint256[] memory,uint256[] memory,address[] memory){
        uint256 l=transferProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        uint256[] memory resNum=new uint256[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=transferProposals[i].id;
            resAddr[i]=transferProposals[i].addr;
            resNum[i]=transferProposals[i].num;
        }
        return(resId,resNum,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a pause Proposal.
    function submitPauseProposal() external ownerExists(msg.sender) {
        removeExpiredProposal(pauseProposals);
        require(doublePropose(pauseProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=9;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:address(0),
            permit:false
        });
        proposalCount+=1;
        pauseProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    function gainPauseProposals() external view returns(uint256[] memory){
        uint256 l=pauseProposals.length;
        uint256[] memory resId=new uint256[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=pauseProposals[i].id;
        }
        return(resId);
    }

    /// @dev Allows an owner to submit and confirm a unpause Proposal.
    function submitUnpauseProposal() external ownerExists(msg.sender) {
        removeExpiredProposal(unpauseProposals);
        require(doublePropose(unpauseProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=10;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:address(0),
            permit:false
        });
        proposalCount+=1;
        unpauseProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    /// @dev Return list of id of proposals in withdrawProposals, and list of num of proposals in adminProposals
    function gainUnpauseProposals() external view returns(uint256[] memory){
        uint256 l=unpauseProposals.length;
        uint256[] memory resId=new uint256[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=unpauseProposals[i].id;
        }
        return(resId);
    }

    /// @dev Allows an owner to confirm a proposal.
    function confirmProposal(uint proposalId) public ownerExists(msg.sender) notConfirmed(proposalId, msg.sender) {
        require(proposalId<proposalCount,NO_PROPOSAL);
        confirmations[proposalId][msg.sender] = true;
        idToVote[proposalId].push(msg.sender);
        if (gainConfirmationCount(proposalId)>=required){
            executeProposal(proposalId);
            delete idToVote[proposalId];
        }
    }

    function afterExe(uint256 i,uint256 l,Proposal[] storage proposals) internal {
        proposals[i]=proposals[l-1];
        proposals.pop();
    }
    
    /// @dev Execute a confirmed proposal.
    function executeProposal(uint256 proposalId) virtual internal{
        uint256 i;
        uint256 l;
        if (idToType[proposalId]==1){
            removeExpiredProposal(addUserProposals);
            (i,l)=findIndex(proposalId,addUserProposals);
            address addr=addUserProposals[i].addr;
            require(!isOwner[addr],ALREADY_OWNER);
            isOwner[addr]=true;
            owners.push(addr);
            afterExe(i,l,addUserProposals);
        }
        else if(idToType[proposalId]==2){
            removeExpiredProposal(removeUserProposals);
            (i,l)=findIndex(proposalId,removeUserProposals);
            address addr=removeUserProposals[i].addr;
            require(required<owners.length,WRONG_THRESHOULD);
            require(isOwner[addr],NOT_OWNER);
            afterExe(i,l,removeUserProposals);
            isOwner[addr]=false;
            l=owners.length;
            i=0;
            while(i<l){
                if (owners[i]==addr){
                    break;
                }
                i+=1;
            }
            owners[i]=owners[l-1];
            owners.pop();
        }
        else if(idToType[proposalId]==3){
            removeExpiredProposal(requiredProposals);
            (i,l)=findIndex(proposalId,requiredProposals);
            required=requiredProposals[i].num;
            require(required<=owners.length,WRONG_THRESHOULD);
            afterExe(i,l,requiredProposals);
        }
        else if(idToType[proposalId]==4){
            removeExpiredProposal(adminedProposals);
            (i,l)=findIndex(proposalId,adminedProposals);
            admined=adminedProposals[i].addr;
            afterExe(i,l,adminedProposals);
        }
        else if(idToType[proposalId]==5){
            removeExpiredProposal(superAdminProposals);
            (i,l)=findIndex(proposalId,superAdminProposals);
            AccessControl sc=AccessControl(admined);
            sc.changeSuperAdmin(payable(superAdminProposals[i].addr));
            afterExe(i,l,superAdminProposals);
        }
        else if(idToType[proposalId]==6){
            removeExpiredProposal(adminProposals);
            (i,l)=findIndex(proposalId,adminProposals);
            AccessControl sc=AccessControl(admined);
            sc.changeAdmin(payable(adminProposals[i].addr));
            afterExe(i,l,adminProposals);
        }
        else if(idToType[proposalId]==7){
            removeExpiredProposal(withdrawProposals);
            (i,l)=findIndex(proposalId,withdrawProposals);
            AccessControl sc=AccessControl(admined);
            sc.withdrawBalance(withdrawProposals[i].num);
            afterExe(i,l,withdrawProposals);
        }
        else if(idToType[proposalId]==8){
            removeExpiredProposal(transferProposals);
            (i,l)=findIndex(proposalId,transferProposals);
            payable(transferProposals[i].addr).transfer(transferProposals[i].num);
            afterExe(i,l,transferProposals);
        }
        else if(idToType[proposalId]==9){
            removeExpiredProposal(pauseProposals);
            (i,l)=findIndex(proposalId,pauseProposals);
            Pausable sc=Pausable(admined);
            sc.pause();
            afterExe(i,l,pauseProposals);
        }
        else if(idToType[proposalId]==10){
            removeExpiredProposal(unpauseProposals);
            (i,l)=findIndex(proposalId,unpauseProposals);
            Pausable sc=Pausable(admined);
            sc.unpause();
            afterExe(i,l,unpauseProposals);
        }
        else{
            require(false,'can not execute proposal');
        }
    }

    /// @dev Find index of proposalId in array.
    function findIndex(uint256 proposalId,Proposal[] memory array) internal pure returns(uint256 i,uint256 l){
        l=array.length;
        Proposal memory _Proposal;
        while(i<l){
            _Proposal=array[i];
            if(_Proposal.id==proposalId){
                break;
            }
            i++;
        }
        require(i<l,NO_PROPOSAL);
    }

    /// @dev Remove expired proposal in array.
    function removeExpiredProposal(Proposal[] storage array) internal {
        uint256 l=array.length;
        uint256 t=block.timestamp;
        for (uint256 i=0;i<l;){
            if (array[i].endAt<=t){
                array[i]=array[l-1];
                array.pop();
                l-=1;
            }
            else{
                i+=1;
            }
        }
    }

    /// @dev //Whether sender's previous proposal in array.
    function doublePropose(Proposal[] memory array,address sender) internal pure returns(bool) {
        uint256 l=array.length;
        for (uint256 i=0;i<l;i++){
            if (array[i].proposer==sender){
                return false;
            }
        }
        return true;
    }
}
// File: MultisigELFCore.sol

pragma solidity >=0.8.0 <0.9.0;



contract MultisigELFCore is Multisig{

    Proposal[] changeCapsuleProposals;
    Proposal[] changeSpawnProposals;

    /// @dev Allows an owner to submit and confirm a ChangeCapsule Proposal.
    /// @param addr Address of new capsule contract.
    function submitChangeCapsuleProposal(address addr) external ownerExists(msg.sender) {
        removeExpiredProposal(changeCapsuleProposals);
        require(doublePropose(changeCapsuleProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=11;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        changeCapsuleProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    function gainChangeCapsuleProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=changeCapsuleProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=changeCapsuleProposals[i].id;
            resAddr[i]=changeCapsuleProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Allows an owner to submit and confirm a ChangeSpawn Proposal.
    /// @param addr Address of new spawn contract.
    function submitChangeSpawnProposal(address addr) external ownerExists(msg.sender) {
        removeExpiredProposal(changeSpawnProposals);
        require(doublePropose(changeSpawnProposals,msg.sender),PROPOSED);
        uint256 proposalId=proposalCount;
        idToType[proposalId]=12;
        Proposal memory _Proposal=Proposal({
            id:proposalId,
            endAt:block.timestamp+duration,
            num:0,
            proposer:msg.sender,
            addr:addr,
            permit:false
        });
        proposalCount+=1;
        changeSpawnProposals.push(_Proposal);
        confirmProposal(proposalId);
    }

    function gainChangeSpawnProposals() external view returns(uint256[] memory,address[] memory){
        uint256 l=changeSpawnProposals.length;
        uint256[] memory resId=new uint256[](l);
        address[] memory resAddr=new address[](l);
        for (uint256 i=0;i<l;i++){
            resId[i]=changeSpawnProposals[i].id;
            resAddr[i]=changeSpawnProposals[i].addr;
        }
        return(resId,resAddr);
    }

    /// @dev Execute a confirmed proposal.
    function executeProposal(uint256 proposalId) override internal{
        uint256 i;
        uint256 l;
        if (idToType[proposalId]==1){
            removeExpiredProposal(addUserProposals);
            (i,l)=findIndex(proposalId,addUserProposals);
            address addr=addUserProposals[i].addr;
            require(!isOwner[addr],ALREADY_OWNER);
            isOwner[addr]=true;
            owners.push(addr);
            afterExe(i,l,addUserProposals);
        }
        else if(idToType[proposalId]==2){
            removeExpiredProposal(removeUserProposals);
            (i,l)=findIndex(proposalId,removeUserProposals);
            address addr=removeUserProposals[i].addr;
            require(required<owners.length,WRONG_THRESHOULD);
            require(isOwner[addr],NOT_OWNER);
            afterExe(i,l,removeUserProposals);
            isOwner[addr]=false;
            l=owners.length;
            i=0;
            while(i<l){
                if (owners[i]==addr){
                    break;
                }
                i+=1;
            }
            owners[i]=owners[l-1];
            owners.pop();
        }
        else if(idToType[proposalId]==3){
            removeExpiredProposal(requiredProposals);
            (i,l)=findIndex(proposalId,requiredProposals);
            required=requiredProposals[i].num;
            require(required<=owners.length,WRONG_THRESHOULD);
            afterExe(i,l,requiredProposals);
        }
        else if(idToType[proposalId]==4){
            removeExpiredProposal(adminedProposals);
            (i,l)=findIndex(proposalId,adminedProposals);
            admined=adminedProposals[i].addr;
            afterExe(i,l,adminedProposals);
        }
        else if(idToType[proposalId]==5){
            removeExpiredProposal(superAdminProposals);
            (i,l)=findIndex(proposalId,superAdminProposals);
            AccessControl sc=AccessControl(admined);
            sc.changeSuperAdmin(payable(superAdminProposals[i].addr));
            afterExe(i,l,superAdminProposals);
        }
        else if(idToType[proposalId]==6){
            removeExpiredProposal(adminProposals);
            (i,l)=findIndex(proposalId,adminProposals);
            AccessControl sc=AccessControl(admined);
            sc.changeAdmin(payable(adminProposals[i].addr));
            afterExe(i,l,adminProposals);
        }
        else if(idToType[proposalId]==7){
            removeExpiredProposal(withdrawProposals);
            (i,l)=findIndex(proposalId,withdrawProposals);
            AccessControl sc=AccessControl(admined);
            sc.withdrawBalance(withdrawProposals[i].num);
            afterExe(i,l,withdrawProposals);
        }
        else if(idToType[proposalId]==8){
            removeExpiredProposal(transferProposals);
            (i,l)=findIndex(proposalId,transferProposals);
            payable(transferProposals[i].addr).transfer(transferProposals[i].num);
            afterExe(i,l,transferProposals);
        }
        else if(idToType[proposalId]==9){
            removeExpiredProposal(pauseProposals);
            (i,l)=findIndex(proposalId,pauseProposals);
            Pausable sc=Pausable(admined);
            sc.pause();
            afterExe(i,l,pauseProposals);
        }
        else if(idToType[proposalId]==10){
            removeExpiredProposal(unpauseProposals);
            (i,l)=findIndex(proposalId,unpauseProposals);
            Pausable sc=Pausable(admined);
            sc.unpause();
            afterExe(i,l,unpauseProposals);
        }
        else if(idToType[proposalId]==11){
            removeExpiredProposal(changeCapsuleProposals);
            (i,l)=findIndex(proposalId,changeCapsuleProposals);
            Imisc sc=Imisc(admined);
            sc.changeCapsuleContract(changeCapsuleProposals[i].addr);
            afterExe(i,l,changeCapsuleProposals);
        }
        else if(idToType[proposalId]==12){
            removeExpiredProposal(changeSpawnProposals);
            (i,l)=findIndex(proposalId,changeSpawnProposals);
            Imisc sc=Imisc(admined);
            sc.changeSpawnContract(changeSpawnProposals[i].addr);
            afterExe(i,l,changeSpawnProposals);
        }
        else{
            require(false,'can not execute proposal');
        }
    }
}