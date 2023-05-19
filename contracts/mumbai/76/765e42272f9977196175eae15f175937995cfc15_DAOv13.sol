/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: DAOv13.sol




/*

██████╗░░█████╗░░█████╗░  ██╗░░░██╗░░███╗░░██████╗░
██╔══██╗██╔══██╗██╔══██╗  ██║░░░██║░████║░░╚════██╗
██║░░██║███████║██║░░██║  ╚██╗░██╔╝██╔██║░░░█████╔╝
██║░░██║██╔══██║██║░░██║  ░╚████╔╝░╚═╝██║░░░╚═══██╗
██████╔╝██║░░██║╚█████╔╝  ░░╚██╔╝░░███████╗██████╔╝
╚═════╝░╚═╝░░╚═╝░╚════╝░  ░░░╚═╝░░░╚══════╝╚═════╝░

*/

// Author: KIRA  0x9769Dd9831a96E49B2c73C3C8431ff349AebD328

pragma solidity 0.8.19;



interface Authf {
   function balanceOf(address owner) external view returns (uint256 balance);
}

contract DAOv13 is Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private posid;
  Counters.Counter private proid;

   constructor()  {
       posid.increment();
       proid.increment();
   }

    address public nftAddress = 0xb152A8318E63560E87C35220FB45DC87d8E7bb5C ;

    modifier auth() {
    
        uint bal = Authf(nftAddress).balanceOf(msg.sender);

        require(bal>0,"Unauthorized Access !");

     _;
    }

    struct post {
        uint postid;
        address postOwner;
        int40 uvotes;
        int40 dvotes;
        string category;
        uint ctime;
        uint etime;
        string topic;
    }

    mapping (uint => post) public postRegistry;
    mapping (address => mapping (uint => bool)) voteRegistry;


    function createPost(string memory _category, uint duration, string memory _topic) external auth() {

        require(duration >  43200, "Minimum Duration (12 Hours) for Voting not Allocated");

        address _owner = msg.sender;
        uint _postId = posid.current();
        postRegistry[_postId].postid = _postId;
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].category = _category;
        postRegistry[_postId].ctime = block.timestamp;
        postRegistry[_postId].etime = postRegistry[_postId].ctime + duration ;
        postRegistry[_postId].topic = _topic;

        posid.increment();
    }

    function voteUp(uint _postId) external auth() {
        address _voter = msg.sender;
        require (block.timestamp<=postRegistry[_postId].etime , "Voting Time Elapsed");
        require (postRegistry[_postId].postOwner != _voter, "You cannot vote on your own Posts");
        require (voteRegistry[_voter][_postId] == false, "Your Vote had already been registered");
        postRegistry[_postId].uvotes += 1;
        voteRegistry[_voter][_postId] = true;
    }

    function voteDown(uint _postId) external auth() {
        address _voter = msg.sender;
        require (block.timestamp<=postRegistry[_postId].etime , "Voting Time Elapsed");
        require (postRegistry[_postId].postOwner != _voter, "You cannot vote on your own Posts");        
        require (voteRegistry[_voter][_postId] == false, "Your Vote had already been registered");
        postRegistry[_postId].dvotes += 1;
        voteRegistry[_voter][_postId] = true;
    }

    function totalposts() public view  returns(uint)  {   
       return posid.current()-1;
    }

    function postsOfOwner(address _owner) public view returns (uint256[] memory) {

            uint256[] memory postIds = new uint256[](posid.current());

            uint256 _index = 0;

            uint256 _pindex = 0;

          while (_index <= posid.current()) {

            if (postRegistry[_index].postOwner == _owner) {

                postIds[_pindex] = _index;

                _pindex++;

            }

            _index++;

        }

            return postIds;

    }





    struct proposal {
        uint proid;
        address proOwner;
        int40 uvotes;
        int40 dvotes;
        string category;
        uint ctime;
        uint etime;
        string topic;
        string uri;
        uint pamt;
        bool claim_status ;
    }



    mapping (uint => proposal) public proposalRegistry;
    mapping (address => mapping (uint => bool)) voteRegistry2;

    function createPro(string memory _category, uint duration, string memory _topic, string memory _uri, uint _pamt) external auth() {

        require(duration >  86400, "Minimum Duration (24 Hours) for Voting not Allocated"); 

        address _owner = msg.sender;
        uint _proId = proid.current();
        proposalRegistry[_proId].proid = _proId;
        proposalRegistry[_proId].proOwner = _owner;
        proposalRegistry[_proId].category = _category;
        proposalRegistry[_proId].ctime = block.timestamp;
        proposalRegistry[_proId].etime = proposalRegistry[_proId].ctime + duration ;
        proposalRegistry[_proId].topic = _topic;
        proposalRegistry[_proId].uri = _uri;
        proposalRegistry[_proId].claim_status = false;
        proposalRegistry[_proId].pamt = _pamt;

        proid.increment();
    }

    function pvoteUp(uint _proId) external auth() {
        address _voter = msg.sender;
        require (block.timestamp<=proposalRegistry[_proId].etime , "Voting Time Elapsed");
        require (proposalRegistry[_proId].proOwner != _voter, "You cannot vote on your own Proposals");
        require (voteRegistry2[_voter][_proId] == false, "Your Vote had already been registered");
        proposalRegistry[_proId].uvotes += 1;
        voteRegistry2[_voter][_proId] = true;
    }

    function pvoteDown(uint _proId) external auth() {
        address _voter = msg.sender;
        require (block.timestamp<=proposalRegistry[_proId].etime , "Voting Time Elapsed");
        require (proposalRegistry[_proId].proOwner != _voter, "You cannot vote on your own Proposals");        
        require (voteRegistry2[_voter][_proId] == false, "Your Vote had already been registered");
        proposalRegistry[_proId].dvotes += 1;
        voteRegistry2[_voter][_proId] = true;
    }

    function totalproposals() public view returns(uint) {   
       return proid.current()-1;
    }

    function prosOfOwner(address _owner) public view returns (uint256[] memory) {

            uint256[] memory proIds = new uint256[](proid.current());

            uint256 _index = 0;

            uint256 _pindex = 0;

          while (_index <= proid.current()) {

            if (proposalRegistry[_index].proOwner == _owner) {

                proIds[_pindex] = _index;

                _pindex++;

            }

            _index++;

        }

            return proIds;

    }


    
    function claim(uint _proid) payable external auth() {

      
      require(proposalRegistry[_proid].proOwner == msg.sender, "You do not owner of this proposal");
      require(proposalRegistry[_proid].claim_status != true, "Already Claimed");
      uint bal = address(this).balance;
      require(proposalRegistry[_proid].pamt < bal, "Contract Balance Defecit");
      require(block.timestamp > proposalRegistry[_proid].etime , "Voting has not ended");
      require(proposalRegistry[_proid].uvotes !=0, "Propsal Failed due to no positive reaction");   
      require(proposalRegistry[_proid].uvotes > proposalRegistry[_proid].dvotes, "Propsal Rejected");

      payable(msg.sender).transfer(proposalRegistry[_proid].pamt);

      proposalRegistry[_proid].claim_status = true;

    }


    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }



}