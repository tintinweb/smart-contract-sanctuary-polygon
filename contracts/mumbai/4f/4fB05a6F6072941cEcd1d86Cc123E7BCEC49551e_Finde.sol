// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error AddressNotFound(address addr);

contract Finde {

    struct User{
        string displayName;
        string uri;
        Vote votes;
        address addr;
        uint lastVoteTime;
    }

    struct Vote{
        uint upVote;
        uint downVote;
    }
    
    using Counters for Counters.Counter;
    Counters.Counter private _uriIndexCounter ;

    IERC20 private _token;

    mapping(uint256 => User) public indexToUser;
    mapping(address => uint256) public addressToIndex;
    mapping(string => address[]) public countryToAddresses;
    mapping(string => mapping(address => uint256)) public countryToIndexOfAddress;

    modifier EligibleToVote{
        require(_token.balanceOf(msg.sender) > 100, "Insufficient tokens");
        _;
    }
    
    modifier VotingTimeOut(address _providerAddress){
        require(indexToUser[addressToIndex[_providerAddress]].lastVoteTime + 60 < block.timestamp);
        _;
    }

    modifier AddressFound(address _providerAddress ){
        if (addressToIndex[_providerAddress] == 0){
            revert AddressNotFound(_providerAddress);
        }
        _;
    }

    modifier ValidLimit(uint _from){
        require( (_from) < _uriIndexCounter.current() );
        _;
    }

    constructor (address _tokenAddress) {
        _token = IERC20(_tokenAddress);
        _uriIndexCounter.increment(); // start counter from 1;
    }

    function addURI(string memory _uri, string memory _country) public {

        if(addressToIndex[msg.sender] == 0){

            User memory usr = indexToUser[addressToIndex[msg.sender]];
            usr.addr = msg.sender;
            usr.uri = _uri;
            indexToUser[_uriIndexCounter.current()] = usr;

            addressToIndex[msg.sender] = _uriIndexCounter.current();
            _uriIndexCounter.increment();
        }
        
        if( countryToIndexOfAddress[_country][msg.sender] == 0){
            countryToAddresses[_country].push(msg.sender);
            countryToIndexOfAddress[_country][msg.sender] = countryToAddresses[_country].length;            
        }
    }

    function getPagenatedURIs(uint256 _from, uint256 _limit, uint rating) public view ValidLimit(_from) returns(User[] memory){
        require(_limit > 0 && _limit <= 10, "FINDE: Invalid Parameters" );
        
        User[] memory data = new User[](_limit);
        
        for(uint i=0; i< _limit; i++){
            if ((indexToUser[_from+i].votes.upVote - indexToUser[_from+i].votes.downVote) == rating){
                data[i] = indexToUser[_from+i];
            }
        }
        return data;
    }

    // function getPagenatedURIsByCountry(string memory _country, uint256 _from, uint256 _limit) public view returns(string[] memory){
    //     require(_limit > 0 && _limit <= 10, "FINDE: Invalid Parameters" );
        
    //     string[] memory data = new string[](_limit);
        
    //     // for(uint i=0; i< _limit; i++){
    //     //     data[i] = addressToURI[countryToAddresses[_country][_from+i]];
    //     // }
    //     return data;
    // }

    function upvoteProvider(address _providerAddress) public EligibleToVote AddressFound(_providerAddress) VotingTimeOut(_providerAddress){
        indexToUser[addressToIndex[_providerAddress]].votes.upVote += 1;
        indexToUser[addressToIndex[_providerAddress]].lastVoteTime = block.timestamp;
    }

    function downVoteProvider(address _providerAddress) public EligibleToVote AddressFound(_providerAddress) VotingTimeOut(_providerAddress){
        indexToUser[addressToIndex[_providerAddress]].votes.downVote += 1;
        indexToUser[addressToIndex[_providerAddress]].lastVoteTime = block.timestamp;
    }

    function getProviderVotes(address _providerAddress) public view returns(Vote memory){
        return indexToUser[addressToIndex[_providerAddress]].votes;
    }

    function readTokenBalance() public view returns (uint){
        return _token.balanceOf(msg.sender);
    }

    function getRemainingTimeForVote() public view returns (int){
        int timeLeft = int((indexToUser[addressToIndex[msg.sender]].lastVoteTime + 60) - block.timestamp);
        if (timeLeft >= 0){
            return timeLeft;
        }
        return 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}