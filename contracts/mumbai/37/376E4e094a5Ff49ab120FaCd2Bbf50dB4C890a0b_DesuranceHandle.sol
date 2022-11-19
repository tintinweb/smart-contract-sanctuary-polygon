// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

error WithdrawFailed();

contract Desurance is Ownable {
    struct MemberRequest {
        address memberAddress;
        string requestUri;
        uint256 accepted;
    }

    struct InsuranceClaimRequest {
        address memberAddress;
        string requestUri;
        uint256 amount;
        uint256 accepted;
    }

    // struct Acceptance {
    //     address memberAddress; // member address who will accept joining requests or judge address who will accept claims
    //     uint256 id;
    // }

    struct Judgement {
        bool accepted;
        string reasonUri;
    }

    struct ClaimAccepted {
        uint256 claimId;
        uint256 amount;
    }

    struct JudgementJobFullfilled {
        uint256 judgeId;
        uint256 amount; // amount judge will get
    }

    string private s_baseUri;
    uint256 private immutable i_minMembers;
    uint256 private immutable i_requestBefore;
    uint256 private immutable i_validity;
    uint256 private immutable i_judgingStartTime;
    uint256 private immutable i_judgingEndTime;
    uint256 private immutable i_judgesLength;
    uint256 private immutable i_amount;
    uint256 private immutable i_percentageDividedIntoJudges;
    string private s_groupId;
    bool private s_isMinMembersReachedCalculated; // also isJudges selected
    bool private s_isMinMembersReached;
    uint256 private s_totalClaimAmountRequested;
    uint256 private s_totalClaimAmountAccepted;
    bool private s_isFinalJudgementCalculated;
    // bool private s_isAnyClaimAccepted = s_claimAccepted.length > 0;
    // bool private s_isAnyJudgementFullfilledJob == s_judgesFullfilledJobs.length > 0;
    uint256 private s_memberNumber = 1; // total members exists + 1
    mapping(uint256 => address) private s_idToMemberAddress; // memberNumber (id) => s_memberAddresses
    mapping(address => uint256) private s_addressToMemberId; // memberAddress => memberNumber (id)
    uint256 private s_requestNumber = 1; // total requests exists + 1
    mapping(address => uint256) private s_addressToRequestId; // memberAddress => requestNumber (id)
    mapping(uint256 => MemberRequest) private s_idToMemberRequest; // request id number => request
    mapping(bytes => bool) private s_memberRequestAcceptances; // abi.encode(Acceptance) => member request accepted or not
    uint256 private s_claimNumber = 1; // total claims exists + 1
    mapping(address => uint256) s_addressToClaimId; // memberAddress => Insurance claimId
    mapping(uint256 => InsuranceClaimRequest) s_idToClaimRequest; // Insurance claimId => request
    mapping(address => uint256) s_addressToJudgeId; // memberAddress => Insurance claimId (even judge id starts from 1)
    mapping(uint256 => address) s_idToJudgeAddress; // Insurance claimId => memberAddress (even judge id starts from 1)
    mapping(bytes => Judgement) private s_judgements; // abi.encode(Acceptance) => accepted or not + reason
    mapping(address => uint256) private s_judged; // judge address => number of judgement

    JudgementJobFullfilled[] private s_judgesFullfilledJobs; // judges who fullfilled their job that is judged everyone && obviously index starts from 0
    ClaimAccepted[] private s_claimAccepted; // claims which are accepted that more than half of judges has accepted && obviously index starts from 0

    mapping(address => uint256) private s_balance; // member address => balance (after claim accepted)

    constructor(
        string memory baseUri,
        uint256 minMembers,
        uint256 requestTime, // (in seconds) time before one can make a request
        uint256 validity, // (in seconds) insurance valid after requestTime seconds and user can claim insurance after validity
        uint256 claimTime, // (in seconds) time before use can make a insurance claim request, after this time judging will start.
        uint256 judgingTime, // (in seconds) time before judges should judge insurance claim requests.
        uint256 judgesLength, // number of judges
        uint256 amount, // amount everyone should put in the pool
        uint256 percentDivideIntoJudges, // percent of total pool amount that should be divided into judges (total pool amount = amount * members.length where members.length == s_memberNumber - 1) (only valid for judges who had judged every claim request)
        string memory groupId
    ) {
        require(minMembers > 0, "BurfyInsurance: minMembers should be greater than 0");
        require(requestTime > 0, "BurfyInsurance: requestTime should be greater than 0");
        require(validity > 0, "BurfyInsurance: validity should be greater than 0");
        require(claimTime > 0, "BurfyInsurance: judgingStartTime should be greater than 0");
        require(judgingTime > 0, "BurfyInsurance: judgingTime should be greater than 0");
        require(judgesLength > 0, "BurfyInsurance: judgesLength should be greater than 0");
        require(
            judgesLength <= minMembers,
            "BurfyInsurance: judgesLength should be less than or equal to minMembers"
        );
        require(amount > 0, "BurfyInsurance: amount should be greater than 0");
        require(
            percentDivideIntoJudges > 0,
            "BurfyInsurance: percentDivideIntoJudges should be greater than 0"
        );
        require(
            percentDivideIntoJudges <= 100,
            "BurfyInsurance: percentDivideIntoJudges should be less than or equal to 100"
        );

        s_baseUri = baseUri;
        i_minMembers = minMembers;
        i_requestBefore = block.timestamp + requestTime;
        i_validity = i_requestBefore + validity;
        i_judgingStartTime = i_validity + claimTime;
        i_judgingEndTime = i_judgingStartTime + judgingTime;
        i_judgesLength = judgesLength;
        i_amount = amount;
        i_percentageDividedIntoJudges = percentDivideIntoJudges;
        s_groupId = groupId;
    }

    // function getBaseUri() public view returns (string memory) {
    //     return s_baseUri;
    // }

    // function getMemberNumber(address memberAddress) public view returns (uint256) {
    //     return s_addressToMemberId[memberAddress];
    // }

    // function getMemberAddress(uint256 memberNumber) public view returns (address) {
    //     return s_idToMemberAddress[memberNumber];
    // }

    // function getMemberCount() public view returns (uint256) {
    //     return s_memberNumber - 1;
    // }

    // function getRequestNumber() public view returns (uint256) {
    //     return s_requestNumber - 1;
    // }

    // function getRequest(uint256 requestId) public view returns (MemberRequest memory) {
    //     return s_idToRequest[requestId];
    // }

    // function getAcceptance(uint256 requestId, address memberAddress) public view returns (bool) {
    //     return s_acceptances[Acceptance(memberAddress, requestId)];
    // }

    // function getClaimNumber() public view returns (uint256) {
    //     return s_claimNumber - 1;
    // }

    function addAsMember() public {
        require(block.timestamp < i_requestBefore, "Adding member is not valid anymore");
        require(s_addressToMemberId[msg.sender] == 0, "Already a member");
        require(
            s_idToMemberRequest[s_addressToRequestId[msg.sender]].accepted == s_memberNumber - 1,
            "Not all members accepted the request"
        );
        uint256 id = s_addressToRequestId[msg.sender];
        s_idToMemberRequest[id] = MemberRequest(address(0), "", 0);
        s_addressToRequestId[msg.sender] = 0;

        s_idToMemberAddress[s_memberNumber] = msg.sender;
        s_addressToMemberId[msg.sender] = s_memberNumber;
        s_memberNumber++;
    }

    // function addRequest(string memory requestUri) public {
    //     s_requests[s_requestNumber] = MemberRequest(msg.sender, requestUri, new uint256[](0));
    //     s_requestNumber++;
    // }

    function acceptJoiningRequest(uint256 requestId) public {
        require(s_addressToMemberId[msg.sender] != 0, "Not a member");
        require(
            s_idToMemberRequest[requestId].memberAddress != address(0),
            "Request does not exist"
        );
        require(
            s_memberRequestAcceptances[abi.encode(msg.sender, requestId)] == false,
            "Already accepted"
        );
        s_memberRequestAcceptances[abi.encode(msg.sender, requestId)] = true;
        s_idToMemberRequest[requestId].accepted += 1;
    }

    function makeJoiningRequest(string memory uri) public payable {
        require(msg.value == i_amount, "Amount sent isn't correct");
        require(block.timestamp < i_requestBefore, "Adding member is not valid anymore");
        require(s_addressToMemberId[msg.sender] == 0, "Member already exists");
        require(s_addressToRequestId[msg.sender] == 0, "Request already exists");
        s_idToMemberRequest[s_requestNumber] = MemberRequest(msg.sender, uri, 0);
        s_addressToRequestId[msg.sender] = s_requestNumber;
        s_requestNumber++;
    }

    function requestForInsurance(string memory baseUri, uint256 amount) public {
        require(block.timestamp > i_validity, "Contract is not valid anymore");
        require(block.timestamp < i_judgingStartTime, "Judging already started");
        require(s_addressToMemberId[msg.sender] != 0, "Not a member");
        require(s_addressToClaimId[msg.sender] == 0, "Insurance already exists");
        s_addressToClaimId[msg.sender] = s_claimNumber;
        s_idToClaimRequest[s_claimNumber] = InsuranceClaimRequest(msg.sender, baseUri, amount, 0);
        s_totalClaimAmountRequested += amount;
        s_claimNumber++;
    }

    // judges will judge insurance claim requests
    function updateInsurance(
        uint256 claimId,
        bool accepted,
        string memory reasonUri
    ) public {
        require(block.timestamp > i_judgingStartTime, "Judging not started yet");
        require(block.timestamp < i_judgingEndTime, "Judging already ended");
        require(s_addressToJudgeId[msg.sender] != 0, "Not a judge");
        require(
            s_idToClaimRequest[claimId].memberAddress != address(0),
            "Insurance does not exist"
        );
        if (
            (s_judgements[abi.encode(msg.sender, claimId)].accepted == false &&
                bytes(reasonUri).length != 0) ||
            (s_judgements[abi.encode(msg.sender, claimId)].accepted == true)
        ) {
            revert("Already updated");
        }
        if (!accepted) {
            require(bytes(reasonUri).length != 0, "Reason uri is empty");
        }
        s_judgements[abi.encode(msg.sender, claimId)] = Judgement(accepted, reasonUri);
        if (accepted) {
            s_idToClaimRequest[claimId].accepted += 1;
        }
        s_judged[msg.sender] += 1;
    }

    function selectJudges(uint256 randomNumber) public onlyOwner {
        require(block.timestamp > i_judgingStartTime, "Judging not started yet");
        require(block.timestamp < i_judgingEndTime, "Judging already ended");
        require(s_isMinMembersReachedCalculated == false, "Judges already selected");
        if (!s_isMinMembersReachedCalculated && s_memberNumber - 1 < i_minMembers) {
            s_isMinMembersReachedCalculated = true;
            s_isMinMembersReached = false;
            for (uint256 i = 1; i < s_memberNumber; i++) {
                s_balance[s_idToMemberAddress[i]] += i_amount;
            }
            return;
        }
        s_isMinMembersReachedCalculated = true;
        s_isMinMembersReached = true;
        uint256 index = randomNumber % (s_memberNumber - 1);
        for (uint256 i = 1; i <= i_judgesLength; i++) {
            address judgeAddress = s_idToMemberAddress[index + i]; // as index for member starts from 1
            if (s_addressToJudgeId[judgeAddress] != 0) {
                i--;
                index = (index + index + i + 1) % (s_memberNumber - 1); // 2 * index + 1
                continue;
            }
            index = (index + index + i) % (s_memberNumber - 1); // 2 * index + 1
            s_addressToJudgeId[judgeAddress] = i;
            s_idToJudgeAddress[i] = judgeAddress;
        }
    }

    function fullfillRequests() public {
        require(block.timestamp > i_judgingEndTime, "Judging not ended yet");
        require(s_isFinalJudgementCalculated == false, "Already fullfilled");
        if (s_isMinMembersReachedCalculated && !s_isMinMembersReached) {
            s_isFinalJudgementCalculated = true;
            return;
        }
        // if no judges were selected, then pay all members
        if (!s_isMinMembersReachedCalculated) {
            s_isMinMembersReachedCalculated = true;
            s_isMinMembersReached = false;
            for (uint256 i = 1; i < s_memberNumber; i++) {
                s_balance[s_idToMemberAddress[i]] += i_amount;
            }
            return;
        }
        s_isFinalJudgementCalculated = true;

        // check whether there's atleast one judge who fullfilled his job that is accepted everyone's request
        for (uint256 i = 1; i <= i_judgesLength; i++) {
            if (s_judged[s_idToJudgeAddress[i]] == s_claimNumber - 1) {
                s_judgesFullfilledJobs.push(JudgementJobFullfilled(i, 0));
            }
        }

        // pay everyone except the judges as no one fullfilled their job
        if (s_judgesFullfilledJobs.length == 0) {
            uint256 amountForEachMember = (i_amount + i_judgesLength) / (s_memberNumber - 1);
            for (uint256 i = 1; i < s_memberNumber; i++) {
                if (s_addressToJudgeId[s_idToMemberAddress[i]] == 0) {
                    s_balance[s_idToMemberAddress[i]] += amountForEachMember; // no judge will get their money back
                }
            }
            return;
        }

        // pay all the judges who fullfilled their job
        uint256 amountForEachJudge = ((i_percentageDividedIntoJudges *
            (s_memberNumber - 1) *
            i_amount) / (100 * s_judgesFullfilledJobs.length));
        uint256 amountLeftForMembers = ((i_amount * (s_memberNumber - 1)) -
            (amountForEachJudge * s_judgesFullfilledJobs.length));
        for (uint256 i = 0; i < s_judgesFullfilledJobs.length; i++) {
            s_judgesFullfilledJobs[i].amount = amountForEachJudge;
            s_balance[s_idToJudgeAddress[s_judgesFullfilledJobs[i].judgeId]] += amountForEachJudge;
        }

        // check whether atleast one claim is accepted by majority of judges && calculate amount to be paid to insuranceClaimers who are accepted
        for (uint256 i = 1; i < s_claimNumber; i++) {
            if (s_idToClaimRequest[i].accepted > (i_judgesLength / 2)) {
                s_totalClaimAmountAccepted += s_idToClaimRequest[i].amount;
                s_claimAccepted.push(ClaimAccepted(i, 0));
            }
        }

        // pay everyone except the judges as no one fullfilled their job
        if (s_claimAccepted.length == 0) {
            uint256 amountForEachMember = amountLeftForMembers / (s_memberNumber - 1);

            // pay all the judges who fullfilled their job as amountForEachMember
            for (uint256 i = 0; i < s_judgesFullfilledJobs.length; i++) {
                s_balance[
                    s_idToJudgeAddress[s_judgesFullfilledJobs[i].judgeId]
                ] += amountForEachMember;
            }
            // pay everyone except the judges as amountForEachMember as either no one fullfilled their job or who fullfilled their job already got their money
            for (uint256 i = 1; i < s_memberNumber; i++) {
                if (s_addressToJudgeId[s_idToMemberAddress[i]] == 0) {
                    s_balance[s_idToMemberAddress[i]] += amountForEachMember;
                }
            }
            return;
        }
        uint256 extraAmount = 0;
        // calculate extra amount to be paid to insuranceClaimers who are accepted
        if (s_totalClaimAmountAccepted >= amountLeftForMembers) {
            extraAmount = s_totalClaimAmountAccepted - amountLeftForMembers;
            amountLeftForMembers = 0;
        } else {
            amountLeftForMembers -= s_totalClaimAmountAccepted;
        }

        // pay insuranceClaimers who are accepted
        for (uint256 i = 0; i < s_claimAccepted.length; i++) {
            uint256 amountRequested = s_idToClaimRequest[s_claimAccepted[i].claimId].amount;
            uint256 amountToPay = amountRequested -
                ((amountRequested * extraAmount) / s_totalClaimAmountAccepted);
            s_claimAccepted[i].amount = amountToPay;
            s_balance[s_idToClaimRequest[s_claimAccepted[i].claimId].memberAddress] += amountToPay;
        }
        // if there's any amount left, pay it to everyone
        if (amountLeftForMembers > 0) {
            uint256 amountForEachMember = amountLeftForMembers / (s_memberNumber - 1);
            // pay all the judges who fullfilled their job as amountForEachMember
            for (uint256 i = 0; i < s_judgesFullfilledJobs.length; i++) {
                s_balance[
                    s_idToJudgeAddress[s_judgesFullfilledJobs[i].judgeId]
                ] += amountForEachMember;
            }
            // pay everyone except the judges as amountForEachMember as either no one fullfilled their job or who fullfilled their job already got their money
            for (uint256 i = 1; i < s_memberNumber; i++) {
                if (s_addressToJudgeId[s_idToMemberAddress[i]] == 0) {
                    s_balance[s_idToMemberAddress[i]] += amountForEachMember;
                }
            }
        }
    }

    function withdraw() public {
        require(s_balance[msg.sender] > 0, "No balance");
        uint256 amount = s_balance[msg.sender];
        s_balance[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function withdrawMemberRequest() public {
        require(s_addressToRequestId[msg.sender] != 0, "No request");
        require(block.timestamp > i_requestBefore, "Time is still left");
        uint256 amount = i_amount;
        uint256 id = s_addressToRequestId[msg.sender];
        s_idToMemberRequest[id] = MemberRequest(address(0), "", 0);
        s_addressToRequestId[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function getBaseUri() public view returns (string memory) {
        return s_baseUri;
    }

    function getMinMembers() public view returns (uint256) {
        return i_minMembers;
    }

    function getRequestBefore() public view returns (uint256) {
        return i_requestBefore;
    }

    function getValidity() public view returns (uint256) {
        return i_validity;
    }

    function getJudgingStartTime() public view returns (uint256) {
        return i_judgingStartTime;
    }

    function getJudgingEndTime() public view returns (uint256) {
        return i_judgingEndTime;
    }

    function getJudgesLength() public view returns (uint256) {
        return i_judgesLength;
    }

    function getAmount() public view returns (uint256) {
        return i_amount;
    }

    function getTotalMembers() public view returns (uint256) {
        return s_memberNumber - 1;
    }

    function getDeadlineMet() public view returns (bool) {
        return getTotalMembers() >= i_minMembers;
    }

    function getMemberById(uint256 id) public view returns (address) {
        return s_idToMemberAddress[id];
    }

    function getMemberIdByAddress(address memberAddress) public view returns (uint256) {
        return s_addressToMemberId[memberAddress];
    }

    function getTotalRequests() public view returns (uint256) {
        return s_requestNumber - 1;
    }

    function getRequestById(uint256 id) public view returns (MemberRequest memory) {
        return s_idToMemberRequest[id];
    }

    function getRequestIdByAddress(address memberAddress) public view returns (uint256) {
        return s_addressToRequestId[memberAddress];
    }

    function getMemberRequestAcceptance(uint256 memberId, uint256 requestId)
        public
        view
        returns (bool)
    {
        return s_memberRequestAcceptances[abi.encode(s_idToMemberAddress[memberId], requestId)];
    }

    function getTotalClaims() public view returns (uint256) {
        return s_claimNumber - 1;
    }

    function getClaimById(uint256 id) public view returns (InsuranceClaimRequest memory) {
        return s_idToClaimRequest[id];
    }

    function getClaimIdByAddress(address memberAddress) public view returns (uint256) {
        return s_addressToClaimId[memberAddress];
    }

    function getJudgeById(uint256 id) public view returns (address) {
        return s_idToJudgeAddress[id];
    }

    function getJudgeIdByAddress(address memberAddress) public view returns (uint256) {
        return s_addressToJudgeId[memberAddress];
    }

    function getJudgement(uint256 judgeId, uint256 claimId) public view returns (Judgement memory) {
        return s_judgements[abi.encode(s_idToJudgeAddress[judgeId], claimId)];
    }

    function getJudged(address judgeAddress) public view returns (uint256) {
        return s_judged[judgeAddress];
    }

    function getJudgesFullFilledJobs() public view returns (JudgementJobFullfilled[] memory) {
        return s_judgesFullfilledJobs;
    }

    function getTotalJudgesFullFilledJobs() public view returns (uint256) {
        return s_judgesFullfilledJobs.length;
    }

    function getClaimAcceptedLength() public view returns (uint256) {
        return s_claimAccepted.length;
    }

    function getClaimsAccepted() public view returns (ClaimAccepted[] memory) {
        return s_claimAccepted;
    }

    function getTotalClaimAmountRequested() public view returns (uint256) {
        return s_totalClaimAmountRequested;
    }

    function getTotalClaimAmountAccepted() public view returns (uint256) {
        return s_totalClaimAmountAccepted;
    }

    function getIsClaimFullfilled() public view returns (bool) {
        return s_isFinalJudgementCalculated;
    }

    function getPercentageDividedIntoJudges() public view returns (uint256) {
        return i_percentageDividedIntoJudges;
    }

    function getBalance(address memberAddress) public view returns (uint256) {
        return s_balance[memberAddress];
    }

    function getIsMinimumMembersReachedCalculated() public view returns (bool) {
        return s_isMinMembersReachedCalculated;
    }

    function getIsJudgeSelected() public view returns (bool) {
        return s_isMinMembersReachedCalculated; // both are calculated at the same time
    }

    function getIsMinimumMembersReached() public view returns (bool) {
        return s_isMinMembersReached;
    }

    function getGroupId() public view returns (string memory) {
        return s_groupId;
    }

    // function getIsAnyClaimAccepted() public view returns (bool) {
    //     return s_claimAccepted.length > 0;
    // }

    // function getIsAnyJudgeFullfilledTheirJob() public view returns (bool) {
    //     return s_judgesFullfilledJobs.length > 0;
    // }
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
pragma solidity ^0.8.12;

import "./Desurance.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// import "@tableland/evm/contracts/ITablelandTables.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@tableland/evm/contracts/utils/TablelandDeployments.sol";

contract DesuranceHandle is AutomationCompatibleInterface, VRFConsumerBaseV2 {
    struct ContractInfo {
        address contractAddress;
        uint256 judgingStartTime;
        uint256 judgingEndTime;
    }

    // ITablelandTables private _tableland;
    // uint256 private _tableId;
    // string private _tableName;
    // string private _prefix = "desurance";

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    mapping(uint256 => address) private s_requestIdToContractAddress;

    // address[] private s_insuranceContracts;
    ContractInfo[] private s_contractInfos;

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyH
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        // _tableland = TablelandDeployments.get();
        // _tableId = _tableland.createTable(
        //     address(this),
        //     /*
        //      *  CREATE TABLE {prefix}_{chainId} (
        //      *    id integer primary key,
        //      *    message text
        //      *  );
        //      */
        //     string.concat(
        //         "CREATE TABLE ",
        //         _prefix,
        //         "_",
        //         Strings.toString(block.chainid),
        //         " (id integer primary key, insuranceAddress text NOT NULL, baseUri text NOT NULL, minMembers integer NOT NULL, requestTime integer NOT NULL, validity integer NOT NULL, claimTime integer NOT NULL, judgingTime integer NOT NULL, judgesLength integer NOT NULL, amount integer NOT NULL, percentDivideIntoJudges integer NOT NULL);"
        //     )
        // );

        // _tableName = string.concat(
        //     _prefix,
        //     "_",
        //     Strings.toString(block.chainid),
        //     "_",
        //     Strings.toString(_tableId)
        // );
    }

    function createInsurance(
        string memory baseUri,
        uint256 minMembers,
        uint256 requestTime, // (in seconds) time before one can make a request
        uint256 validity, // (in seconds) insurance valid after startBefore seconds and user can claim insurance after validity
        uint256 claimTime, // (in seconds) time before use can make a insurance claim request, after this time judging will start.
        uint256 judgingTime, // (in seconds) time before judges should judge insurance claim requests.
        uint256 judgesLength, // number of judges
        uint256 amount, // amount everyone should put in the pool
        uint256 percentDivideIntoJudges, // percent of total pool amount that should be divided into judges (total pool amount = amount * members.length where members.length == s_memberNumber - 1) (only valid for judges who had judged every claim request)
        string memory groupId
    ) public payable returns (address) {
        Desurance newInsurance = new Desurance(
            baseUri,
            minMembers,
            requestTime,
            validity,
            claimTime,
            judgingTime,
            judgesLength,
            amount,
            percentDivideIntoJudges,
            groupId
        );

        uint256 judgingStartTime = block.timestamp + requestTime + validity + claimTime;

        // s_insuranceContracts.push(address(newInsurance));
        uint256 judgingEndTime = judgingStartTime + judgingTime;

        s_contractInfos.push(ContractInfo(address(newInsurance), judgingStartTime, judgingEndTime));

        // _tableland.runSQL(
        //     address(this),
        //     _tableId,
        //     string.concat(
        //         "INSERT INTO ",
        //         _tableName,
        //         " (insuranceAddress, baseUri, minMembers, requestTime, validity, claimTime, judgingTime, judgesLength, amount, percentDivideIntoJudges) VALUES (",
        //         "'",
        //         _addressToString(address(newInsurance)),
        //         "','",
        //         baseUri,
        //         "','",
        //         Strings.toString(minMembers),
        //         "','",
        //         Strings.toString(requestTime),
        //         "','",
        //         Strings.toString(validity),
        //         "','",
        //         Strings.toString(claimTime),
        //         "','",
        //         Strings.toString(judgingTime),
        //         "','",
        //         Strings.toString(judgesLength),
        //         "','",
        //         Strings.toString(amount),
        //         "','",
        //         Strings.toString(percentDivideIntoJudges),
        //         "');"
        //     )
        // );

        return address(newInsurance);
    }

    // Assumes the subscription is funded sufficiently.
    function getRandomNumbers(address contractAddress) public payable returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToContractAddress[requestId] = contractAddress;
    }

    function performUpkeep(bytes calldata performData) external override {
        (uint256 index, uint256 which) = abi.decode(performData, (uint256, uint256));
        address contractAddress = s_contractInfos[index].contractAddress;
        if (which == 0) {
            s_contractInfos[index].judgingStartTime = 0;
            getRandomNumbers(contractAddress);
            return;
        }
        s_contractInfos[index].judgingEndTime = 0;
        Desurance(contractAddress).fullfillRequests();
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls.
     */
    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        Desurance burfyInsurance = Desurance(s_requestIdToContractAddress[requestId]);
        burfyInsurance.selectJudges(randomWords[0]);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        for (uint256 i = 0; i < s_contractInfos.length; i++) {
            if (
                s_contractInfos[i].judgingStartTime != 0 &&
                s_contractInfos[i].judgingStartTime < block.timestamp &&
                s_contractInfos[i].judgingEndTime > block.timestamp
            ) {
                upkeepNeeded = true;
                performData = abi.encode(i, 0); // index, which (0 = getRandomNumbers for selecting judges, 1 = fullfillRequests for fullfilling insurance claim requests)
                break;
            }
            if (
                s_contractInfos[i].judgingEndTime != 0 &&
                s_contractInfos[i].judgingEndTime < block.timestamp
            ) {
                upkeepNeeded = true;
                performData = abi.encode(i, 1);
                break;
            }
        }
    }

    function _addressToString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string.concat("0x", string(s));
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function getContracts() public view returns (ContractInfo[] memory) {
        return s_contractInfos;
    }

    function getContract(uint256 index) public view returns (ContractInfo memory) {
        return s_contractInfos[index];
    }

    function getContractsLength() public view returns (uint256) {
        return s_contractInfos.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}