/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/YugAccessControl.sol


pragma solidity ^0.8.7;

// import "hardhat/console.sol";


interface IYugIDManager {
    function hasValidID(address addr, uint64 kind) external view returns (bool);
}

interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

interface IYugFees {
    function findFee(uint64 kind) external view returns (address, uint256, uint256);
}

contract YugAccessControl {

    address _admin;
    address _yugFee;
    address _yugIDManager;

    mapping(uint256 => AccessRequest) _access_request_registry;
    mapping(uint256 => uint256) _access_request_to_granted;
    mapping(address => mapping(address => mapping(uint64 => uint256))) _viewOf_to_viewBy_to_kind_to_id_mapping;

    using Counters for Counters.Counter;
    Counters.Counter private _accessRequestIDs;

    struct AccessRequest {
        uint256 id;
        address view_of;
        address view_by;
        //0: requested
        //1: accepted
        //2: rejected 
        uint8 status;
        uint256 at;
        uint256 expiry;
        uint64 kind;
        string url;
    }

    event AccessEvent(uint256 indexed id,  address view_of, address view_by, uint8 status, uint256 at, uint256 expiry, uint64 kind);

    constructor() {
    }

    function initialize(address yugIDManager, address admin, address yugFee) public {
        require(_admin != address(0) && IAdmin(_admin).isValidAdmin(msg.sender) || _yugIDManager == address(0), "Unauthorized");
        _yugIDManager = yugIDManager;
        _admin = admin;
        _yugFee = yugFee;
    }


    function reject(uint256 id) public {
        require(_access_request_registry[id].view_of == msg.sender, "Unauthorized");
        _access_request_registry[id].status = 2;
        _access_request_registry[id].url = "";
    }

    function request(address view_of, uint64 kind) public payable{
        require(IYugIDManager(_yugIDManager).hasValidID(msg.sender, 1), "Requestor KYC not done");

        if(_viewOf_to_viewBy_to_kind_to_id_mapping[view_of][msg.sender][kind] > 0) {
            require(_access_request_registry[_viewOf_to_viewBy_to_kind_to_id_mapping[view_of][msg.sender][kind]].expiry < block.timestamp, "Request already rejected");
        }

        (address treasury,uint256 fee_for_requesting,) = IYugFees(_yugFee).findFee(kind);
        if(fee_for_requesting > 0){
            require(msg.value >= fee_for_requesting, "Fees not provided.");
            payable(treasury).transfer(fee_for_requesting);
        }

        _accessRequestIDs.increment();
        AccessRequest memory accessRequest = AccessRequest(_accessRequestIDs.current(), view_of, msg.sender, 0, block.timestamp, block.timestamp + (90 * 86400), kind, "");
        _access_request_registry[_accessRequestIDs.current()] = accessRequest;

        _viewOf_to_viewBy_to_kind_to_id_mapping[view_of][msg.sender][kind] = _accessRequestIDs.current();
        emit AccessEvent(_accessRequestIDs.current(), view_of, msg.sender, 0, block.timestamp, block.timestamp + (90 * 86400), kind);
    }


    function share(address view_by, string memory url, uint64 expiry, uint64 kind) public payable {
        (address treasury,,uint256 fee_for_sharing) = IYugFees(_yugFee).findFee(kind);
        if(fee_for_sharing > 0){
            require(msg.value >= fee_for_sharing, "Fees not provided.");
            payable(treasury).transfer(fee_for_sharing);
        }
        accept(0, view_by, url, expiry, kind);
    }


    function accept(uint256 id, address view_by, string memory url, uint64 expiry, uint64 kind) public {
        require(expiry > block.timestamp, "Incorrect expiry");
        require(IYugIDManager(_yugIDManager).hasValidID(msg.sender, kind), "Sender KYC not done");

        if(id == 0) {
            _accessRequestIDs.increment();
            AccessRequest memory accessRequest = AccessRequest(_accessRequestIDs.current(), msg.sender, view_by, 1, block.timestamp, expiry, kind, url);
            _access_request_registry[_accessRequestIDs.current()] = accessRequest;
            _viewOf_to_viewBy_to_kind_to_id_mapping[msg.sender][view_by][kind] = _accessRequestIDs.current();
        } else {
            require(_access_request_registry[id].view_of == msg.sender, "Unauthorized");
            _access_request_registry[id].url = url;
            _access_request_registry[id].expiry = expiry;
            _access_request_registry[id].status = 1;
        }
    
        emit AccessEvent(id == 0 ? _accessRequestIDs.current() : id, msg.sender, view_by, 1, block.timestamp, expiry, kind);
    }

    function getAccessInfo(uint256 id) public view returns(string memory) {
        require(_access_request_registry[id].view_by == msg.sender 
        && _access_request_registry[id].status == 1 
        && _access_request_registry[id].expiry > block.timestamp, "Unauthorized");
        return (_access_request_registry[id].url);
    }

    function getAccessRequestInfo(uint256 id) public view returns(uint256, address, address, uint8, uint64, uint256, uint256) {
        return (id, 
        _access_request_registry[id].view_by, 
        _access_request_registry[id].view_of, 
        _access_request_registry[id].status, 
        _access_request_registry[id].kind, 
        _access_request_registry[id].at,
        _access_request_registry[id].expiry);
    }
}