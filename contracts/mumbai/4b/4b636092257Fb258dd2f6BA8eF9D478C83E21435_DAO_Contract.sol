//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Interfaces.sol"; 
import "./Ownable.sol";


contract DAO_Contract is Ownable{

    ERC721 public token;
    Ownable ownable;

    bool public approvalNeeded;
    uint public minCriteriaForApproval;


    address custodialWallet; 
    address public deployer; 
    // address contractAddress = address(this);
   
    string callerNotOwner = "Caller is not the Owner";
    string invalidProposalID = "Invalid proposal ID";
    string invalidMinimumNFTs = "invalid Minimum NFTs";
    string proposalCriteriaMismatched = "proposalCriteriaType mismatched with the given arguments.";

    struct DAO{
        address creator;
        uint proposalType;
        uint totalVotesForProposal;
        uint voteQuorem;
        uint timePeriodInHours;
        uint proposalCriteriaType;
        uint approvalNeeded;
        uint minCriteriaForApproval;
        uint totalVotesForApproval;     //for proposal approval
        uint weightage;                 // 0 for false, 1 for true
        uint minimumNFTsToVote;
        uint[] options;
        DAOStatus proposalStatus;
    }   

    mapping(uint => DAO) public proposalData;
    mapping(uint => mapping(address => bool)) addressVoted;         //Returns true if the address has already voted for the particular proposalID or vice versa.
    // mapping(uint => mapping(address => uint)) weightageVoting;      //
    mapping(uint => mapping(address => uint)) nonWeightageVotingCount;   //for non-weightage voting
    mapping(uint => mapping(address => bool)) private isVotedForProposalApproval;
    // mapping(uint => mapping(address => uint))

    //proposalID => option => votes
    mapping(uint => mapping(uint => uint)) proposalVotes;     
    mapping(uint => mapping(uint => uint)) proposalResults;

    enum DAOStatus {NotInitialized, Running, Completed}
    event proposalCreated(uint proposalID, uint proposalType, uint proposalCriteriaType, uint approvalNeeded);
    event resultAnnounced(uint proposalID, uint proposalType, uint proposalCrioteriaType, uint result);

    modifier onlyTokenHolders{
        require(token.balanceOf(msg.sender) > 0, 
        "Insufficient Token balance.");
        _;
    }

    modifier onlyOwner() override {
        if(address(ownable) != address(0)){
        require(
        ownable.verifyOwner(msg.sender) == true ||
        verifyOwner(msg.sender) == true,
        callerNotOwner
        );
        } 
        else{
        require(
        verifyOwner(msg.sender) == true,
        callerNotOwner );
        }
        _;
    }


    modifier onlyCustodialWallet() {
        require(msg.sender == token.getCustodialWallet()
        , "call from unknown address");
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, 
            "Caller in not deployer"
        );
        _;
    } 

    constructor(address tokenAddress, bool approval, uint minCriteria){

        token = ERC721(tokenAddress);

        if(approval == true){
            require(minCriteria > 0 && minCriteria < token.totalSupply(),
            invalidMinimumNFTs);
        } else if(approval == false){
            require(minCriteria == 0,
            invalidMinimumNFTs);
        }

        approvalNeeded = approval;
        minCriteriaForApproval = minCriteria;

        custodialWallet = token.getCustodialWallet();
        deployer = msg.sender;
    }
    
    //PROPOSAL TYPE
    //mutuallyExclusive {Yes / No}                           1
    //multipleChoiceWithSingleAnswer                         2
    //MultipleChoiceWithMultipleAnswers                      3
    //Likert Scale                                           4

    //PROPOSAL CRITERIA TYPE
    //VoteQuorem(Threshold)                                  1
    //Time Limit                                             2
    //VoteQuorem and TimeLimit                               3

    function createProposal( 
        uint proposalID,
        uint proposalType,
        uint voteQuorem,
        uint timePeriodInHours,
        uint proposalCriteriaType,
        uint weightage,
        uint minimumNFTsToVote, 
        bytes memory optionsInBytes
        ) public onlyTokenHolders{ 

            require(weightage <= 1, "Invalid weightage.");

            require(proposalData[proposalID].proposalStatus == DAOStatus.NotInitialized, 
                "Proposal ID already initialized."
            );

            require(proposalData[proposalID].proposalStatus != DAOStatus.Completed, 
                "Proposal ID status is completed."
            );

            require(proposalType > 0 && proposalType <= 4,
                "Invalid proposal type."
            );

            require(proposalCriteriaType > 0 && proposalCriteriaType <= 3,
                "Invalid proposal criteria type."
            );

            if(voteQuorem > 0 && timePeriodInHours == 0){
                require(proposalCriteriaType == 1,
                proposalCriteriaMismatched);
            }

            if(timePeriodInHours > 0 && voteQuorem == 0){
                require(proposalCriteriaType == 2, proposalCriteriaMismatched);
            }

            if(timePeriodInHours > 0 && voteQuorem > 0){
                require(proposalCriteriaType == 3,
                proposalCriteriaMismatched);
            }

            if(weightage == 0){
                require(minimumNFTsToVote > 0, "Zero min NFTs for weightage.");
            }

            else if(weightage == 1){
                require(minimumNFTsToVote == 0, "invalid min NFTs.");
            }

            uint approval;

            if(approvalNeeded == true){
                approval = 1;
            }else if(approvalNeeded == false){
                approval = 0;
            }

            uint[] memory options = returnOptions(optionsInBytes);

            if(proposalType == 1){
                require(options.length == 2,
                "options length invalid");
            }
            else{
                require(options.length > 1,
                "length invalid");
            }
    
            proposalData[proposalID] = DAO(
                msg.sender,
                proposalType,
                0,
                voteQuorem,
                block.timestamp + (timePeriodInHours * 1 hours),
                proposalCriteriaType,
                approval,
                minCriteriaForApproval,
                0,
                weightage,
                minimumNFTsToVote,
                options,
                DAOStatus.Running
            );

            if(approvalNeeded == true){
                emit proposalCreated( proposalID, proposalType, proposalCriteriaType, getProposalData(proposalID).approvalNeeded);
            }
    }

    function voteToApproveProposal(uint proposalID) public onlyTokenHolders{
        
        require(getProposalData(proposalID).approvalNeeded == 1,
        "This proposal doesn't require approval");


        address msgSender = msg.sender;
      
        require(getVotedProposalApprovalStatus(proposalID, msgSender) != true,
            "This user has already voted for the given proposal ID");    

        // require(proposalData[proposalID].totalVotesForApproval < proposalData[proposalID].minCriteriaForApproval, "Votes reached till the approval");

        require(checkApprovalForProposal(proposalID) == true,
        "Maximum Vote limit reached.");

        proposalData[proposalID].totalVotesForApproval +=1;
        isVotedForProposalApproval[proposalID][msgSender] = true;

        if(getProposalData(proposalID).approvalNeeded == 1){
            emit proposalCreated( proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), getProposalData(proposalID).approvalNeeded);
        }
    } 

    function calculateWeightage(uint proposalID, address addr) internal view returns (uint){
        require(getProposalData(proposalID).weightage == 1, invalidProposalID);
        uint balance = token.balanceOf(addr);

        return balance;
    }

    function voteForProposal (uint proposalID, bytes memory voteArray) public onlyTokenHolders{
        address msgSender = msg.sender;
        uint[] memory votes = returnOptions(voteArray);

        require(getProposalStatus(proposalID) == DAOStatus.Running, 
        "This proposal is not initialized or is already completed.");

        if(getProposalType(proposalID) == 4){
            uint optionsQty = getOptions(proposalID).length;
            require(votes.length >= 1 && votes.length <= optionsQty, 
            "Invalid Votes length for the proposal");
        } else {
            votes.length == 1;
        }

        // if(getProposalType(proposalID) == 1){
        //     require(votes.length == 1,
        //     "Invalid Votes length.");
        // }

        if(getProposalCriteriaType(proposalID) == 1){
            require(proposalData[proposalID].totalVotesForProposal <  proposalData[proposalID].voteQuorem,
                "This proposal has already completed its vote Quorem"
            );
        }

        else if(getProposalCriteriaType(proposalID) == 2){
            require(getTimeLimit(proposalID) >= block.timestamp, 
                "This proposal time limit has been completed."
            );
        } 
        else if(getProposalCriteriaType(proposalID) == 3){
            require(proposalData[proposalID].totalVotesForProposal <  proposalData[proposalID].voteQuorem ||
                getTimeLimit(proposalID) >= block.timestamp, "This proposal already have completed its vote Quorem"
            );
        }

        if(getProposalData(proposalID).approvalNeeded == 1){
            require(getProposalData(proposalID).minCriteriaForApproval == getProposalData(proposalID).totalVotesForApproval,
            "This proposal has not been approved yet.");
        }
        
        bool isWeightage;
        uint weightage;
        
        if(getProposalData(proposalID).weightage == 0){
            bool votesAllowed = calculateNonWeightageVote(proposalID, msgSender);

            if(votesAllowed == true){
                nonWeightageVotingCount[proposalID][msgSender] += 1;
                
                isWeightage = false;
                proposalData[proposalID].totalVotesForProposal += 1;
            } else{
                revert ("No votes left");
            }
            
        } else if(getProposalData(proposalID).weightage == 1){

            require(getWeightageVoteStatus(proposalID, msgSender) == false,
                "This user has already voted for the given proposal ID");   

            weightage = calculateWeightage(proposalID, msgSender);
            
            isWeightage = true;
            proposalData[proposalID].totalVotesForProposal += 1;
            addressVoted[proposalID][msgSender] = isWeightage;
        }

        for(uint i = 0; i < votes.length; i++){

            require(isOptionAvailable(proposalID, votes[i]), "invalid vote");
            if(isWeightage == true){
                proposalVotes[proposalID][votes[i]] += weightage;
            } 
            else {         
                proposalVotes[proposalID][votes[i]] += 1;
            }
        }


        if(
            getProposalCriteriaType(proposalID) == 1 && 
            getProposalData(proposalID).totalVotesForProposal == getProposalData(proposalID).voteQuorem
        ){
            announceResult(proposalID);
        }else if( 
            getProposalCriteriaType(proposalID) == 3 && block.timestamp < getTimeLimit(proposalID)
            )
            {
                if( getProposalData(proposalID).totalVotesForProposal == getProposalData(proposalID).voteQuorem){
                    announceResult(proposalID);
                }
            }
    }
    
    function setOwnable(address ownableAddr) external onlyDeployer {
        require(ownableAddr != address(0) && ownableAddr != address(this), "Invalid ownable address.");
        ownable = Ownable(ownableAddr);
    }

    function checkApprovalForProposal(uint proposalID) internal view returns (bool){

        if(getProposalData(proposalID).totalVotesForApproval < getProposalData(proposalID).minCriteriaForApproval){
            return true;
        } else {
            return false;
        }
    }   

    function getProposalTotalVotes(uint proposalID) public view returns(uint){
        return proposalData[proposalID].totalVotesForProposal;
    }

    // function _announceProposalResult(uint proposalID) internal  {
    //     console.log("In announce proposal result function");

    //     require(getProposalStatus(proposalID) == DAOStatus.Running,
    //         "Proposal is not initialized or is already completed.");

    //     if(getProposalCriteriaType(proposalID) == 2){
    //         require(block.timestamp >= getTimeLimit(proposalID),
    //         "This proposal has not completed its time period yet."
    //         );

    //         announceResult(proposalID);
    //     }

    //     else if(getProposalCriteriaType(proposalID) == 3){
            
    //         require(
    //         block.timestamp >= getTimeLimit(proposalID),
    //         "This proposal has not completed it's time period or vote quorem yet.");

    //         announceResult(proposalID);
    //     }
           
    // }


    function announceProposalResult(bytes memory _proposalIDs) external onlyCustodialWallet{

        uint[] memory proposalIDs = getFilteredProposalIDs(_proposalIDs);
        
        for(uint i = 0; i < proposalIDs.length; i++){
            if(proposalIDs[i] != 0){
                announceResult(proposalIDs[i]);
            }
        }

    }


    function getFilteredProposalIDs(bytes memory _proposalIDs) public view returns(uint[] memory){
        uint[] memory proposalIDs = abi.decode(_proposalIDs, (uint[]));
        uint[] memory filteredProposalIDs  = new uint[](proposalIDs.length);
        uint count = 0;

        for(uint i = 0; i < proposalIDs.length; i++){
            
            bool allowed = false;

            if(getProposalStatus(proposalIDs[i]) == DAOStatus.Running){
                allowed = true;
            }

            if(getProposalCriteriaType(proposalIDs[i]) == 2){
                if(block.timestamp < getTimeLimit(proposalIDs[i])){
                    allowed = false;
                }
            }

            if(getProposalCriteriaType(proposalIDs[i]) == 3){
                if(block.timestamp < getTimeLimit(proposalIDs[i])){
                    allowed = false;
                }
            }

            if(allowed == true){
                filteredProposalIDs[count] = proposalIDs[i];
                count += 1;
            }
        }

        return filteredProposalIDs;
    }

    function calculateNonWeightageVote(uint proposalID, address addr) internal view returns(bool){
        uint balance = token.balanceOf(addr);
        uint minimumVotes = getProposalData(proposalID).minimumNFTsToVote;
        uint votesAllowed = balance / minimumVotes;

        if(nonWeightageVotingCount[proposalID][addr] < votesAllowed){
            return true;
        } else {
            return false;
        }
    }



    //SC single choice
    //MC Multiple choice
    //Likert Scale
    function announceResult(uint proposalID) internal onlyTokenHolders{

        if(getProposalTotalVotes(proposalID) == 0){
            emit resultAnnounced(proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), 0);
        }
        else{

            uint leadingOption = getLeadingOption(proposalID); 

            proposalResults[proposalID][getProposalType(proposalID)] = leadingOption;
            emit resultAnnounced(proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), leadingOption);
        }
            proposalData[proposalID].proposalStatus = DAOStatus.Completed;
    }

    function getLeadingOption(uint proposalID) public view returns (uint){
        uint[] memory options = getOptions(proposalID);
        uint leadingIndex;

  
        for(uint i = 0; i < (options.length - 1); i++){
    
            if(proposalVotes[proposalID][options[leadingIndex]] < proposalVotes[proposalID][options[i+1]]){
                leadingIndex = i+1;
            } else{
                leadingIndex = i;
            }
        }

        return options[leadingIndex];
    }   

    function deleteProposal(uint proposalID) public {
        require(msg.sender == getProposalData(proposalID).creator,
        "You don't own this proposal");

        delete proposalData[proposalID];
    }

    function getProposalCriteriaType(uint proposalID) public view returns(uint){
        return proposalData[proposalID].proposalCriteriaType;
    }

    function getProposalData(uint proposalID) public view returns(DAO memory){
        return proposalData[proposalID];
    }

    function getProposalType(uint proposalID) public view returns (uint){
        return proposalData[proposalID].proposalType;
    }

    function getResults(uint proposalID) public view returns (uint){
        return proposalResults[proposalID][getProposalType(proposalID)];
    }

    function getTimeLimit(uint proposalID) public view returns (uint){
        return getProposalData(proposalID).timePeriodInHours;
    }

    function getWeightageVoteStatus(uint proposalID, address addr) internal view returns (bool){
        return addressVoted[proposalID][addr];
    }

    function getNonWeightageVoteStatus(uint proposalID, address addr) internal view returns (bool){
        bool status = calculateNonWeightageVote(proposalID, addr);
        if(status)
            return false;
        else
            return true;
    }

    function getAddressVotedStatus(uint proposalID, address addr) public view returns(bool){
        if(getProposalData(proposalID).weightage == 1)
            return getWeightageVoteStatus(proposalID, addr);
        else
            return getNonWeightageVoteStatus(proposalID, addr);
    }

    function getVotedProposalApprovalStatus(uint proposalID, address addr) public view returns(bool){
        return isVotedForProposalApproval[proposalID][addr];
    }

    function setApprovalNeeded(bool approval, uint minCriteria) external onlyOwner{

        if(approval == true){
            require(minCriteria > 0 && minCriteria < token.totalSupply(),
            invalidMinimumNFTs);
            
        } else if(approval == false){
            require(minCriteria == 0,
            invalidMinimumNFTs);
        }

        approvalNeeded  = approval;
        minCriteriaForApproval = minCriteria;
    }
    
    function returnOptions(bytes memory optionsInBytes) public pure returns(uint[] memory){
        uint[] memory options = abi.decode(optionsInBytes, (uint[])); 
        for(uint i = 0; i < options.length; i++){
            require(options[i] != 0, "Value 0 passed as options.");
            for(uint j = 0; j < options.length; j++){
            
            if( i != j){
                require(options[i] != options[j], "Value doubled up");
            }
              
            }
        }

        return options;
    }

    function getProposalApprovalStatus(uint proposalID) public view returns(bool){
        if(proposalData[proposalID].totalVotesForApproval >= proposalData[proposalID].minCriteriaForApproval){
            return true;
        } 
        else {
            return false;
        }
    }

    function getProposalVotes(uint proposalID, uint optionNo) public view returns(uint){
        require(isOptionAvailable(proposalID, optionNo), "Option not available.");
        return proposalVotes[proposalID][optionNo];
    }

    function getOptions(uint proposalID) public view returns (uint[] memory){
        return proposalData[proposalID].options;
    }

    function isOptionAvailable(uint proposalID, uint option ) public view returns(bool){
        
        uint[] memory options = getOptions(proposalID);
        bool found;

        for(uint i = 0; i < options.length; i++){
            if(option == options[i]){
                found = true;
                break;
            }
        }
        return found;
    }

   
    function getProposalStatus(uint proposalID) public view returns(DAOStatus ){
        return proposalData[proposalID].proposalStatus;   
    }

    // function getTimeLimitBool(uint proposalID) public view returns(bool){
    //     return (block.timestamp >= getTimeLimit(proposalID));
    // }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
// import "./Ownable.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * - `target` must be a contract.78
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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

interface IERC721 is IERC165 {

    // address custodial;
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getNFTsOfTheAddress(address _address) external view returns(uint256[] memory);
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
}



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

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    address private custodialWallet;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    uint public totalSupply = 0; 

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    mapping(address => uint256[]) private NFTsOfTheOwner;
 
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

    function setTotalSupply(uint256 _supply) internal {
        totalSupply = _supply;
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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

    function _setCustodialWallet(address _custodialWallet) internal {
        custodialWallet = _custodialWallet;
    }
    
    function getCustodialWallet() public view returns(address){
        return custodialWallet;
    }

    function getNFTsOfTheAddress(address _address) external override view returns(uint256[] memory){
        return NFTsOfTheOwner[_address];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        NFTsOfTheOwner[to].push(tokenId);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


contract ERC721Holder is IERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  )
    public
    override
    virtual
    returns(bytes4)
  {
    return this.onERC721Received.selector;
  }
}


library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /*
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

interface IGenerateRandom{
      function fullfillRandomWords(uint256) external view returns(uint256);
      function fullfillRandomWords(uint256, uint256) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// abstract contract Context {
   
// }

contract Ownable  {
    address private _owner;
    uint256 public totalOwners;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address[] private ownersArray;
    mapping(address => bool) private owners;

    constructor() {
        _transferOwnership(_msgSender());
        owners[_msgSender()] = true;
        totalOwners++;
    }

     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // It will return the address who deploy the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySuperOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    modifier onlyOwner() virtual {
        require(owners[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

  
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        owners[newOwner] = true;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(owners[newOwner] == false, "This address have already owner rights.");
        owners[newOwner] = true;
        totalOwners++;
        ownersArray.push(newOwner);
    }

    function findOwnerAddress(address _ownerAddr) internal view returns(uint256 index){
        for(uint i = 0; i < ownersArray.length; i++){
            if(ownersArray[i] == _ownerAddr){
                index = i;
            }
        }
    }

    function removeOwner(address _Owner) public onlyOwner {
        require(owners[_Owner] == true, "This address have not any owner rights.");
        owners[_Owner] = false;
        totalOwners--;
        uint256 index = findOwnerAddress(_Owner);
        require(index >= 0, "Invalid index!");
        for (uint i = index; i<ownersArray.length-1; i++){
            ownersArray[i] = ownersArray[i+1];
        }
        ownersArray.pop();
    }

    function verifyOwner(address _ownerAddress) public view returns(bool){
        return owners[_ownerAddress];
    }

    function getAllOwners() public view returns (address[] memory){
        return ownersArray;
    }
}