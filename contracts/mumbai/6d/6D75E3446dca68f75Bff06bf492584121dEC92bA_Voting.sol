/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/[email protected]/utils/Context.sol



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

// File: @openzeppelin/[email protected]/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: voting.sol


pragma solidity ^0.8.9;


contract Voting is Ownable{

   // Proposalの構造
   struct Proposal {
       uint id;
       string title;
       address[] voters;
   }

   // アクセスコードの管理
   string private accessCode;
   // ProposalのIDの管理
   uint private currentProposalId = 1;
   // IDからProposalを取得するmapping
   mapping(uint => Proposal) public proposals;
   // 投票済みのWalletAddressを管理
   mapping(address => uint) public voteCount;
   // 投票可能総数/wallet
   uint constant public MAXIMUM_VOTES_PER_WALLET = 3;
   // 無効なことを表す値
   uint constant INVALID_VALUE = type(uint).max;
   // 特権投票者を定義する
   mapping(address => uint) public voteWeightsOfPrivilegedVoters;
   // 特権投票者の数
   uint private numberOfPrivilegedVoter = 0;
   // Boolean variable to track the voting status
   bool public votingStarted;

    // voting中だけ起動できることを保証する
    modifier onlyDuringVoting() {
        require(votingStarted, "Voting is not currently active");
        _;
    }

    // votingを開始する
    function startVoting() public onlyOwner {
        require(!votingStarted, "Voting has already started");
        votingStarted = true;
    }

    // votingを終了する
    function stopVoting() public onlyOwner {
        require(votingStarted, "Voting has not started yet");
        votingStarted = false;
    }

    // アクセスコードをセットする。
    function setAccessCode(string memory code) public onlyOwner {
       accessCode = code;
    }

   // Proposalの追加
   function createProposal(string memory _title) public onlyOwner {
       address[] memory emptyVotersArray;
       proposals[currentProposalId] = Proposal(currentProposalId, _title, emptyVotersArray);
       currentProposalId++;
   }

   // Proposalの削除
   function removeLastProposal() public onlyOwner {
       require(proposals[currentProposalId-1].id != 0, "No proposal remains");
       delete proposals[currentProposalId-1];
       // currentProposalId=1の時はもう空なので、値をマイナスしない。
       if (currentProposalId > 1) {
           currentProposalId--;
       }
   }

   // Proposalのタイトルをupdateする
   function updateProposal(string memory _title, uint _proposalId) public onlyOwner {
       // Proposalが存在しているか確認
       require(proposals[_proposalId].id != 0, "Proposal not found");
       proposals[_proposalId].title = _title;
   }

   // Voteする
   function vote(uint _proposalId, string memory providedCode) public onlyDuringVoting {
       // アクセスコードの確認
       require(keccak256(bytes(providedCode)) == keccak256(bytes(accessCode)), "Invalid access code");

       // WalletAddresにつき MAXIMUM_VOTES_PER_WALLET 票まで
       require(voteCount[msg.sender] < MAXIMUM_VOTES_PER_WALLET, string(abi.encodePacked("Already reached the maximum voting limit (", MAXIMUM_VOTES_PER_WALLET, ")")));
      
       // Proposalが存在しているか確認
       require(proposals[_proposalId].id != 0, "Proposal not found");

       // チェック済みアドレスの重複を防ぐ
       for (uint i = 0; i < proposals[_proposalId].voters.length; i++) {
           require(proposals[_proposalId].voters[i] != msg.sender, "Already voted for this proposal");
       }

       // ProposalにVoteする
       proposals[_proposalId].voters.push(msg.sender);
       voteCount[msg.sender]++;
   }

   // Voteをcancelする
   function cancelVote(uint _proposalId) public onlyDuringVoting {
        require(proposals[_proposalId].id != 0, "Proposal not found");

        uint voterIndex = findVoterIndex(_proposalId, msg.sender);
        require(voterIndex != INVALID_VALUE, "No vote found for this proposal");

        // msg.senderのvoteを取り消す。
        removeVoter(_proposalId, voterIndex);

        voteCount[msg.sender]--;
    }

    // 投票者のindexを探す。
    function findVoterIndex(uint _proposalId, address _voter) internal view returns (uint) {
        address[] storage voters = proposals[_proposalId].voters;
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i] == _voter) {
                return i;
            }
        }
        return INVALID_VALUE; // Voter not found
    }

    // 投票者を削除する
    function removeVoter(uint _proposalId, uint _voterIndex) internal {
        address[] storage voters = proposals[_proposalId].voters;

        // 最後の要素を移す
        voters[_voterIndex] = voters[voters.length - 1];

        // 最後の要素を削除する
        voters.pop();
    }

   // ProposalIDのProposalを取得
   function getProposal(uint _proposalId) public view returns (Proposal memory) {
       require(proposals[_proposalId].id != 0, "Proposal not found");
       return proposals[_proposalId];
   }

   // ProposalIDの投票者一覧の取得
   function getVotersForProposal(uint _proposalId) public view returns (address[] memory) {
       require(proposals[_proposalId].id != 0, "Proposal not found");
       return proposals[_proposalId].voters;
   }

   // Proposalの一覧を取得
   function getAllProposals() public view returns (Proposal[] memory) {
       Proposal[] memory allProposals = new Proposal[](currentProposalId - 1);
       for (uint i = 1; i < currentProposalId; i++){
           allProposals[i - 1] = proposals[i];
       }
       return allProposals;
   }

    // 与えられたaddressのProposalの一覧を返す。
    function getProposalsForVoter(address _voter) public view returns (uint[] memory) {
        uint[] memory proposalIds = new uint[](MAXIMUM_VOTES_PER_WALLET);
        uint count = 0;

        for (uint i = 1; i < currentProposalId; i++) {
            for (uint j = 0; j < proposals[i].voters.length; j++) {
                if (proposals[i].voters[j] == _voter) {
                    proposalIds[count] = proposals[i].id;
                    count++;
                    if (count >= MAXIMUM_VOTES_PER_WALLET) {
                        // Maximum number of votes reached, exit the loop
                        i = currentProposalId;
                        break;
                    }
                }
            }
        }

        // Resize the proposalIds array to remove empty elements
        assembly {
            mstore(proposalIds, count)
        }

        return proposalIds;
    }



   // 一番投票者が多いProposalを取得
   function getMostVotedProposal() public view returns (Proposal memory) {
       return getNthBiggestProposal(1);
   }


   // 投票の降順に並べ替えられたvotesの一覧を返す。
   function getSortedProposals() public view returns (Proposal[] memory) {
        Proposal[] memory sortedProposals = new Proposal[](currentProposalId-1);

        for (uint i = 1; i < currentProposalId; i++) {
            sortedProposals[i-1] = proposals[i];
        }

        sortProposalsDescending(sortedProposals);

        return sortedProposals;
    }

    // proposalを並べ替える。
    function sortProposalsDescending(Proposal[] memory proposalArray) internal view {
        for (uint i = 0; i < proposalArray.length - 1; i++) {
            for (uint j = i + 1; j < proposalArray.length; j++) {
                if (getVoteCount(proposalArray[j]) > getVoteCount(proposalArray[i])) {
                    (proposalArray[i], proposalArray[j]) = (proposalArray[j], proposalArray[i]);
                }
            }
        }
    }

    function getVoteCount(Proposal memory _proposal) private view returns (uint) {
        uint totalVotes = 0;

        for (uint i = 0; i < _proposal.voters.length; i++) {
            address voter = _proposal.voters[i];
            totalVotes += getWeight(voter);
        }

        return totalVotes;
    }

    // 与えられたアドレスが特権アドレスかどうか確認する。
    function isPrivilegedVoter(address _voter) public view returns (bool) {
        return voteWeightsOfPrivilegedVoters[_voter]!=0;
    }

    function getWeight(address _voter) internal view returns (uint) {
        if (isPrivilegedVoter(_voter)) {
            return voteWeightsOfPrivilegedVoters[_voter];
        } 
        return 1;
    }

    // N番目に投票数の多いProposalを返す
    function getNthBiggestProposal(uint n) public view returns (Proposal memory) {
        require(n > 0 && n <= currentProposalId, "Invalid proposal index");

        Proposal[] memory sortedProposals = getSortedProposals();

        return sortedProposals[n - 1];
    }

    // 特権voterの追加
   function addPrivilegedVoter(address _address, uint _weight) public onlyOwner {
       voteWeightsOfPrivilegedVoters[_address] = _weight;
       numberOfPrivilegedVoter++;
   }

   // Proposalの削除
   function removePrivilegedVoter(address _address) public onlyOwner {
       require(voteWeightsOfPrivilegedVoters[_address] != 0, "Not Privileged Voter");
       delete voteWeightsOfPrivilegedVoters[_address];
       numberOfPrivilegedVoter--;
   }

   // 特権投票者の一覧
   struct PrivilegedVoter {
        address voterAddress;
        uint voteWeight;
    }

    // 特権投票者の一覧をgetする
    function getPrivilegedVoters() public view returns (address[] memory) {
        address[] memory uniqueVoters = new address[](numberOfPrivilegedVoter);
        uint count = 0;

        for (uint i = 1; i < currentProposalId; i++) {
            address[] memory voters = proposals[i].voters;
            for (uint j = 0; j < voters.length; j++) {
                if (voteWeightsOfPrivilegedVoters[voters[j]] > 0 && !isAddressInArray(voters[j], uniqueVoters)) {
                    uniqueVoters[count] = voters[j];
                    count++;
                }
            }
        }

        address[] memory result = new address[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = uniqueVoters[i];
        }

        return result;
    }

    function isAddressInArray(address addr, address[] memory arr) private pure returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == addr) {
                return true;
            }
        }
        return false;
    }

}