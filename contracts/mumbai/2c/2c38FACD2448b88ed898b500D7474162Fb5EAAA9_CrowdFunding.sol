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

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
contract CrowdFunding{
    address payable public owner;
    using Counters for Counters.Counter;
    Counters.Counter public tokenID;
    constructor(){
        owner = payable(msg.sender);
    }
    struct Request_info{
        uint token;
        string name;
        string purpose;
        uint amount_needed;
        uint amount_raised;
        uint donors;
        uint deadline;
        address to;
        string tokenuri;
    }
    mapping(address => uint256) public addresstotoken;
    mapping(uint256 => string) public tokentouri;
    mapping(address => Request_info) public requesttoaddress;
    mapping(uint256 => Request_info) public tokentorequest;
    mapping(address => mapping(uint256 => uint256))public donation;

    function CreateRequest(string memory  name,string memory purpose,uint256 amount_needed,uint _days,string memory tokenuri,address _to) external returns(uint){
        require(addresstotoken[_to] == 0,"You can only create one request");
        tokenID.increment();
        uint newtokenid = tokenID.current();
        uint amount = amount_needed * (10**18);
        uint time = block.timestamp + (_days*86400);
       
        Request_info memory newreq = Request_info(
            newtokenid,
            name,
            purpose,
            amount,
            0,
            0,
            time,
            _to,
            tokenuri
        );
        requesttoaddress[_to] = newreq;
        addresstotoken[_to] = newtokenid;
        tokentorequest[newtokenid] = newreq;
        tokentouri[newtokenid] = tokenuri;
        
        return newtokenid;
    }
    function getmytoken(address to)public view returns(uint){
        return addresstotoken[to];
    }
    function donate(uint id) external  payable{
        require(msg.value > 0,"please enter a valid value");
        require(block.timestamp <= tokentorequest[id].deadline,"Time Expierd");
        require(msg.value + tokentorequest[id].amount_raised  <= tokentorequest[id].amount_needed ,"Amount raised thank you" );
        tokentorequest[id].amount_raised+=msg.value;
        address recvier_addr = tokentorequest[id].to;
        requesttoaddress[recvier_addr].amount_raised+=msg.value;
        if(donation[msg.sender][id] == 0){
             tokentorequest[id].donors +=1;
            requesttoaddress[recvier_addr].donors+=1;
        }
        donation[msg.sender][id] += msg.value;
    }
    function amountraisedtoken(uint tokenid) external view returns(uint){
        return tokentorequest[tokenid].amount_raised;
    }
    function amount_raisedaddress( address _addr) external view returns(uint){
        return requesttoaddress[_addr].amount_raised;
    }
    function getdeadline(uint tokenid) external view returns(uint){
        return tokentorequest[tokenid].deadline;
    }
    function getdeadlineaddress(address _addr) external view returns(uint){
        return requesttoaddress[_addr].deadline;
    }
    function getdonors(address _addr) external view returns(uint){
        return requesttoaddress[_addr].donors;
    }
    function getdonorstoken(uint id) external view returns(uint){
        return tokentorequest[id].donors;
    }
    function extractamount(uint id) external payable{
        require(msg.sender == tokentorequest[id].to,"You are not the requester");
        require(block.timestamp > tokentorequest[id].deadline,"You cant withdraw money righnow");
        addresstotoken[msg.sender] = 0;
        payable(tokentorequest[id].to).transfer(tokentorequest[id].amount_raised);
    }
    function geturi(uint tokenid) external view returns(string memory){
        return tokentouri[tokenid];
    }
    function destroy(uint tokenid) external{
        require(msg.sender == owner,"You are not the owner");
        tokentorequest[tokenid].name = "none";
        address crowdaddr =   tokentorequest[tokenid].to;
        requesttoaddress[crowdaddr].name = "none";
        tokentorequest[tokenid].to = address(0);
        requesttoaddress[crowdaddr].to = address(0);
    }
    function getallrequest() external view returns(Request_info[] memory){
        uint256 totalrequest = tokenID.current();
        uint currentindex = 0;
        Request_info[] memory req_info = new Request_info[](totalrequest);
        for(uint256 i = 0;i<totalrequest;i++){
            uint256 id = i+1;
            Request_info storage newreq = tokentorequest[id];
            req_info[currentindex] = newreq;
            currentindex+=1;
        }

        return req_info;
    }
    
}
//0x681583287a498f0836CAB7ECbC65706FeB0FD493