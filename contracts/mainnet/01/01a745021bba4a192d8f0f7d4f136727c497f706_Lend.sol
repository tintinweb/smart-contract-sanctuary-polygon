/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

pragma solidity =0.8.6;

// SPDX-License-Identifier: SimPL-2.0

interface IERC897 {
    function proxyType() external view returns(uint256);
    
    function implementation() external view returns(address);
}

abstract contract ContractOwner {
    event OwnerChanged(address indexed from, address indexed to);

    address private contractOwner = msg.sender;
    
    modifier onlyContractOwner {
        require(msg.sender == contractOwner, "only contract owner");
        _;
    }
    
    function getContractOwner() public view returns(address) {
        return contractOwner;
    }
    
    function changeContractOwner(address to) external onlyContractOwner {
        address from = contractOwner;
        contractOwner = to;
        emit OwnerChanged(from, to);
    }
}

contract ERC897 is ContractOwner, IERC897 {
    address public override implementation;
    uint256 public override proxyType = 2; 
    
    receive() external payable {
    }
    
    fallback(bytes calldata input) external payable returns(bytes memory) {
        (bool success, bytes memory output) = implementation.delegatecall(input);
        
        require(success, string(output));
        
        return output;
    }
    
    function setCodeAddress(address codeAddress) external onlyContractOwner {
        implementation = codeAddress;
    }
    
	/*
    function callContract(address contractAddress, bytes calldata input)
        external payable onlyContractOwner {
        
        (bool success, bytes memory output) = contractAddress.call(input);
        
    	require(success, string(output));
    }
    
    function callContract(address contractAddress, bytes calldata input, uint256 value)
        external payable onlyContractOwner {
        
        (bool success, bytes memory output) = contractAddress.call
            {value: value} (input);
        
        require(success, string(output));
    }
	*/
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns(uint256);
    
    function ownerOf(uint256 _tokenId) external view returns(address);
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    
    function approve(address _approved, uint256 _tokenId) external payable;
    
    function setApprovalForAll(address _operator, bool _approved) external;
    
    function getApproved(uint256 _tokenId) external view returns(address); 
    
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);
}

library UInteger {
    function toString(uint256 a, uint256 radix)
        internal pure returns(string memory) {
        
        if (a == 0) {
            return "0";
        }
        
        uint256 length = 0;
        for (uint256 n = a; n != 0; n /= radix) {
            ++length;
        }
        
        bytes memory bs = new bytes(length);
        
        while (a != 0) {
            uint256 b = a % radix;
            a /= radix;
            
            if (b < 10) {
                bs[--length] = bytes1(uint8(b + 48));
            } else {
                bs[--length] = bytes1(uint8(b + 87));
            }
        }
        
        return string(bs);
    }
    
    function toString(uint256 a) internal pure returns(string memory) {
        return UInteger.toString(a, 10);
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }
    
    function toDecBytes(uint256 n) internal pure returns(bytes memory) {
        if (n == 0) {
            return bytes("0");
        }
        
        uint256 length = 0;
        for (uint256 m = n; m > 0; m /= 10) {
            ++length;
        }
        
        bytes memory bs = new bytes(length);
        
        while (n > 0) {
            uint256 m = n % 10;
            n /= 10;
            
            bs[--length] = bytes1(uint8(m + 48));
        }
        
        return bs;
    }
}

library Util {
    uint256 internal constant DENO = 1e18;
}

abstract contract Member is ContractOwner {
    modifier onlyPermit(string memory permit) {
        require(manager.containsPermit(permit, msg.sender),
            "no permit");
        _;
    }
    
    Manager internal manager;
    
    function setManager(address addr) external onlyContractOwner {
        manager = Manager(addr);
    }
}

library AddressSet {
    struct Set {
        mapping(address => uint256) indexes;
        address[] addresses;
    }
    
    function add(Set storage set, address addr) internal returns(bool) {
        if (contains(set, addr)) {
            return false;
        }
        
        set.indexes[addr] = set.addresses.length;
        set.addresses.push(addr);
        
        return true;
    }
    
    function remove(Set storage set, address addr) internal returns(bool) {
        if (!contains(set, addr)) {
            return false;
        }
        
        uint256 index = set.indexes[addr];
        address tail = set.addresses[set.addresses.length - 1];
        
        set.indexes[tail] = index;
        set.indexes[addr] = 0;
        
        set.addresses[index] = tail;
        set.addresses.pop();
        
        return true;
    }
    
    function contains(Set storage set, address addr) internal view returns(bool) {
        uint256 index = set.indexes[addr];
        return index < set.addresses.length && set.addresses[index] == addr;
    }
    
    function indexOf(Set storage set, address addr) internal view returns(uint256) {
        if (contains(set, addr)) {
            return set.indexes[addr];
        } else {
            return ~uint256(0);
        }
    }
    
    function length(Set storage set) internal view returns(uint256) {
        return set.addresses.length;
    }
    
    function get(Set storage set) internal view returns(address[] memory) {
        return set.addresses;
    }
    
    function get(Set storage set, uint256 index)
        internal view returns(address) {
        
        require(index < set.addresses.length, "invalid index");
        
        return set.addresses[index];
    }
    
    // [startIndex, endIndex)
    function get(Set storage set, uint256 startIndex, uint256 endIndex)
        internal view returns(address[] memory) {
        
        if (endIndex == 0) {
            endIndex = set.addresses.length;
        }
        
        require(startIndex <= endIndex && endIndex <= set.addresses.length,
            "invalid index");
        
        address[] memory result = new address[](endIndex - startIndex);
        
        for (uint256 i = startIndex; i < endIndex; ++i) {
            result[i - startIndex] = set.addresses[i];
        }
        
        return result;
    }
}

contract Manager is ContractOwner {
    using AddressSet for AddressSet.Set;
    
    mapping(string => address) public members;
    
    mapping(string => AddressSet.Set) internal permits;
    
    modifier onlyPermit(string memory permit) {
        require(permits[permit].contains(msg.sender), "no permit");
        _;
    }
    
    function setMember(string memory name, address member)
        external onlyContractOwner {
        
        members[name] = member;
    } 
    
    function addPermit(string memory permit, address account)
        external onlyContractOwner {
        
        require(permits[permit].add(account), "account existed");
    }
    
    function removePermit(string memory permit, address account)
        external onlyContractOwner {
        
        require(permits[permit].remove(account), "account not existed");
    }
    
    function removePermitAll(string memory permit)
        external onlyContractOwner {
        
        delete permits[permit];
    }
    
    function getPermitLength(string memory permit) external view returns(uint256) {
        return permits[permit].length();
    }
    
    // [startIndex, endIndex)
    function getPermitMaps(string memory permit, uint256 startIndex, uint256 endIndex)
        external view returns(address[] memory) {
        
        return permits[permit].get(startIndex, endIndex);
    }
    
    function containsPermit(string memory permit, address account)
        public view returns(bool) {
        
        return permits[permit].contains(account);
    }
    
    function requirePermit(string memory permit, address account) public view {
        require(containsPermit(permit, account), "not permit");
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

contract Lend is ERC897, Member, ReentrancyGuard {
    enum PoolStatus {
        Open,
        Closed,
        Cleared
    }
    
    struct Pool {
        PoolStatus status;
        address owner;
        
        address nftAddr;
        uint256 nftId;
        
        uint256 earnestMin;
        uint256 interest;
        
        uint256 durationMin;
        uint256 durationMax;
        
        bool isPriceClear;
        uint256 backCount;
        
        uint256 balance;
        uint256 settledDuration;
        
        address lender;
        uint256 earnest;
        uint256 startTime;
    }
    
    enum RecordType {
        Deposit,
        Close,
        Lend,
        Back,
        PriceClear,
        TimeClear,
        ClaimBalance
    }
    
    struct Record {
        RecordType rt;
        uint256 id;
        uint256 timestamp;
        address sender;
        bytes data;
    }
    
    mapping(uint256 => Pool) internal idPools;
    uint256 internal poolCount;
    
    Record[] internal records;
    
    uint256 public platformInterestRatio;
    uint256 public platformPriceClearRatio;
    uint256 public platformBalance;
    
    function setPlatformInterestRatio(uint256 ratio) external onlyPermit("Admin") {
        platformInterestRatio = ratio;
    }
    
    function setPlatformPriceClearRatio(uint256 ratio) external onlyPermit("Admin") {
        platformPriceClearRatio = ratio;
    }
    
    function getPools(uint256[] memory ids)
        external view returns(Pool[] memory) {
        
        uint256 length = ids.length;
        Pool[] memory pools = new Pool[](length);
        
        for (uint256 i = 0; i < length; ++i) {
            pools[i] = idPools[ids[i]];
        }
        
        return pools;
    }
    
    function deposit(address nftAddr, uint256[] memory nftIds,
        uint256 earnestMin, uint256 interest,
        uint256 durationMin, uint256 durationMax,
        bool isPriceClear)
        external nonReentrant {
        
        IERC721 nft = IERC721(nftAddr);
        
        for (uint256 i = 0; i < nftIds.length; ++i) {
            uint256 id = ++poolCount;
            Pool storage pool = idPools[id];
            
            pool.owner = msg.sender;
            
            pool.nftAddr = nftAddr;
            pool.nftId = nftIds[i];
            nft.transferFrom(msg.sender, address(this), pool.nftId);
            
            pool.earnestMin = earnestMin;
            pool.interest = interest;
            
            pool.durationMin = durationMin;
            pool.durationMax = durationMax;
            
            pool.isPriceClear = isPriceClear;
            
            records.push(Record({
                rt: RecordType.Deposit,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: abi.encodePacked(nftAddr, nftIds[i],
                    earnestMin, interest, durationMin, durationMax, isPriceClear)
            }));
        }
    }
    
    function close(uint256[] memory ids) external nonReentrant {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            Pool storage pool = idPools[id];
            require(pool.owner == msg.sender, "pool is not yours");
            
            require(pool.status == PoolStatus.Open, "pool is not open");
            pool.status = PoolStatus.Closed;
            
            if (pool.lender == address(0)) {
                IERC721(pool.nftAddr).transferFrom(address(this), msg.sender, pool.nftId);
            }
            
            records.push(Record({
                rt: RecordType.Close,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: bytes("")
            }));
        }
    }
    
    function lend(uint256[] memory ids, uint256[] memory earnests)
        external payable nonReentrant {
        
        uint256 value = 0;
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            Pool storage pool = idPools[id];
            
            require(pool.status == PoolStatus.Open, "pool is not open");
            require(pool.lender == address(0), "pool is lended");
            
            uint256 earnest = earnests[i];
            require(earnest >= pool.earnestMin, "earnest too little");
            value += earnest;
            
            pool.lender = msg.sender;
            pool.earnest = earnest;
            pool.startTime = block.timestamp - 1;
            
            IERC721(pool.nftAddr).transferFrom(address(this), msg.sender, pool.nftId);
            
            records.push(Record({
                rt: RecordType.Lend,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: abi.encodePacked(earnest)
            }));
        }
        
        if (msg.value < value) {
            revert("msg.value too little");
        } else if (msg.value > value) {
            payable(msg.sender).transfer(msg.value - value);
        }
    }
    
    function back(uint256[] memory ids, uint256[] memory nftIds)
        external nonReentrant {
        
        uint256 value = 0;
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            Pool storage pool = idPools[id];
            
            require(pool.lender == msg.sender, "you are not lender");
            require(pool.status != PoolStatus.Cleared, "pool is cleared");
            
            _settleInterest(pool);
            
            require(pool.settledDuration >= pool.durationMin
                && pool.settledDuration <= pool.durationMax,
                "duration invalid");
            
            value += pool.earnest - pool.interest * pool.settledDuration;
            
            uint256 nftId = nftIds[i];
            IERC721(pool.nftAddr).transferFrom(msg.sender, address(this), nftId);
            pool.nftId = nftId;
            
            pool.backCount++;
            
            records.push(Record({
                rt: RecordType.Back,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: abi.encodePacked(nftId)
            }));
        }
        
        payable(msg.sender).transfer(value);
    }
    
    function priceClear(uint256[] memory ids, uint256 deadline, uint256 backCount)
        external onlyPermit("Admin") nonReentrant {
        
        require(block.timestamp <= deadline, "timeout");
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            Pool storage pool = idPools[id];
            
            require(pool.status != PoolStatus.Cleared, "pool is cleared");
            
            require(pool.lender != address(0), "nft not lend");
            
            require(pool.isPriceClear, "isPriceClear is false");
            
            require(pool.backCount == backCount, "backCount not match");
            
            pool.status = PoolStatus.Cleared;
            
            _settleInterest(pool);
            
            uint256 value = pool.earnest - pool.interest * pool.settledDuration;
            uint256 platform = value * platformPriceClearRatio / Util.DENO;
            platformBalance += platform;
            pool.balance += value - platform;
            
            records.push(Record({
                rt: RecordType.PriceClear,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: bytes("")
            }));
        }
    }
    
    function timeClear(uint256[] memory ids) external nonReentrant {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            Pool storage pool = idPools[id];
            
            require(pool.status != PoolStatus.Cleared,
                "pool is cleared");
            
            require(pool.lender != address(0), "nft not lend");
            
            uint256 duration = _calcDuration(pool);
            require(duration > pool.durationMax, "lend not timeout");
            
            pool.status = PoolStatus.Cleared;
            
            _settleInterest(pool);
            
            pool.balance += pool.earnest - pool.interest * pool.settledDuration;
            
            records.push(Record({
                rt: RecordType.TimeClear,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: bytes("")
            }));
        }
    }
    
    function claimBalance(uint256[] memory ids) external nonReentrant {
        uint256 value = 0;
        
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            Pool storage pool = idPools[id];
            
            if (pool.lender != address(0)) {
                _settleInterest(pool);
            }
            
            value += pool.balance;
            pool.balance = 0;
            
            records.push(Record({
                rt: RecordType.ClaimBalance,
                id: id,
                timestamp: block.timestamp,
                sender: msg.sender,
                data: bytes("")
            }));
        }
    } 
    
    function _calcDuration(Pool storage pool)
        internal view returns(uint256) {
        
        uint256 unit = 1 days;
        return (block.timestamp - pool.startTime + unit - 1) / unit;
    }
    
    function _settleInterest(Pool storage pool) internal {
        uint256 duration = _calcDuration(pool);
        if (duration == pool.settledDuration) {
            return;
        }
        
        uint256 interest = pool.interest * (duration - pool.settledDuration);
        uint256 platform = interest * platformInterestRatio / Util.DENO;
        platformBalance += platform;
        pool.balance += interest - platform;
        
        pool.settledDuration = duration;
    }
    
    function queryRecords(uint256 startIndex, uint256 maxLength)
        external view returns(uint256, Record[] memory) {
        
        uint256 length = UInteger.min(records.length, maxLength);
        Record[] memory result = new Record[](length);
        
        for (uint256 i = 0; i < length; ++i) {
            result[i] = records[startIndex + i];
        }
        
        return (records.length, result);
    }
}