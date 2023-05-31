//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InterfaceM {
    function balanceOf(address account) external view returns(uint);
    function transfer(address to, uint value) external;
}

contract BullZWallet is Ownable {
    
    address[] public teamWallets;
    mapping (address => bool) public isTeam;
    
    uint public voteNum;
    uint public required = 4;

    struct info {
        address sender;
        address token;
        string text;
        uint requested;
        uint remaining;
        bool[] votes;
        bool done;       
    }

    mapping (uint => mapping (address => bool)) public addressVoted;
    mapping (uint => info) public voteInfo;

    constructor() {
        
    }

    function addTeamMembers(address[] calldata members) public onlyOwner{
        uint num = members.length;
        uint i = 0;
        for (i; i< num; i++){
            teamWallets.push(members[i]);
            isTeam[members[i]] = true;
        }
    }

    function makeRequest(string memory reason, address token, uint amount) public {
        require (isTeam[msg.sender] == true, "You're not on the team...");

        info memory temp;
        voteNum += 1;
        temp.sender = msg.sender;
        temp.token = token;
        temp.text = reason;
        temp.remaining = teamWallets.length;
        temp.requested = amount;
        addressVoted[voteNum][msg.sender] = true;
        voteInfo[voteNum] = temp;
        voteInfo[voteNum].votes.push(true);
    }

    function submitVote(uint voteID, bool myVote) public {
        require (isTeam[msg.sender] == true, "You're not on the team...");

        //make sure they haven't voted on this topic
        bool hasVoted = addressVoted[voteID][msg.sender];
        require(hasVoted == false, "You've already voted on this.");

        //check how many votes are remaining on that topic
        uint _rem = voteInfo[voteID].remaining;

        //subtract 1 for vote being cast
        _rem -= 1;
        voteInfo[voteID].remaining = _rem;

        //update tally
        voteInfo[voteID].votes.push(myVote);

        //user has now voted on this topic
        addressVoted[voteID][msg.sender] = true;
    }

    function withdraw(uint voteID) public {
        InterfaceM _token = InterfaceM(voteInfo[voteID].token);

        require (isTeam[msg.sender] == true, "You're not on the team...");
        
        uint _balance = _token.balanceOf(address(this));
        uint reqAmt = voteInfo[voteID].requested;
        address recipient = voteInfo[voteID].sender;
        uint count = 0;
        for(uint i = 0; i < voteInfo[voteID].votes.length; i++){
            if (voteInfo[voteID].votes[i] == true){
                count += 1;
            }
        }
        

        require (count >= required, "Not enough votes for this request.");
        require (_balance >= reqAmt, "Not enough ERC20 in contract!");

        voteInfo[voteID].done = true;

        _token.transfer(recipient,reqAmt);

    }


    //  //
    
    fallback() external payable {}

    receive() external payable {
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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