/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface DAIGON {
	function users(address) external view returns (address, uint32, uint32, uint128, uint96, uint32, uint96, uint32, uint96, uint32, uint96);
}

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract CrowdMargin {
    token public DAI = token(0x25Ca4E40c20c6e5a2e5eF7E8b207F94C4DfF1981);
    DAIGON public daigon = DAIGON(0xa4f3209ef68493e089c9105dC1841Da4dF2de643);
    address public scatterContract = 0x4aC894a1f6a58574Be11aA63a6EF97138e6894A8;

    address public owner;
    address public a1;
    address public a2;
    address public a3;
    address public stakingFunder;

    PoolInfo[] public poolInfos;
    mapping(uint32 => Blob[]) public poolBlobs;
    mapping(uint32 => mapping(uint32 => bool)) public isPoolBlobClaimed;

    mapping(uint32 => uint32[]) public vacantBlobs;
    mapping(uint32 => uint32) public vacantBlobIndex;
    mapping(address => mapping(uint32 => bool)) public userForcedAutoFill;
    mapping(address => bool) public userEnabled;

    mapping(address => uint32[]) public userData;
    mapping(address => uint32) public lastDownlineCount;

    mapping(address => uint128) public totalIncome;

    uint32 public minimumDownline = 2;
    uint32 public repeatMinimum = 0;
    uint96 public joinFee = 0;
    bool public membersOnly = true;

    struct Blob {
    	address owner;
    	uint32 up;
    	uint32 left;
    	uint32 right;
    }

    struct PoolInfo {
    	uint128 amount;
    	uint32 nextPool;
    	uint96 penaltyAmount;
    }

    constructor(address _stakingFunder, address _a1, address _a2, address _a3) {
    	stakingFunder = _stakingFunder;
    	a1 = _a1;
    	a2 = _a2;
    	a3 = _a3;
    	owner = msg.sender;

    	createPool(100 ether, 1, 0);
    	createPool(200 ether, 2, 0);
    	createPool(400 ether, 3, 0);
    	createPool(800 ether, 0, 1000 ether);
    }

    function claimBlobAuto(uint32 poolNumber, uint32 blobNumber) internal {
    	PoolInfo memory poolInfo = poolInfos[poolNumber];
    	Blob memory blob = poolBlobs[poolNumber][blobNumber];

		PoolInfo memory nextPool = poolInfos[poolInfo.nextPool];

		DAI.transfer(stakingFunder, poolInfo.amount);
		uint256 transferAmount = poolInfo.amount * 3;
		transferAmount -= nextPool.amount;

		if(blob.owner == address(this)) {
			DAI.transfer(a1, transferAmount / 3);
			DAI.transfer(a2, transferAmount / 3);
			DAI.transfer(a3, transferAmount / 3);
		}
		else {
			if(poolInfo.penaltyAmount > 0) {
	        	(,,,,,uint32 downlines_0,,,,,) = daigon.users(blob.owner);
	        	uint32 newDownlines = downlines_0 - lastDownlineCount[blob.owner];
	        	if(downlines_0 < minimumDownline || newDownlines < repeatMinimum) {
	        		uint256 penaltyBlobsCount = poolInfo.penaltyAmount / nextPool.amount;
	        		for(uint256 i = 0; i < penaltyBlobsCount; ++i) {
	        			transferAmount -= nextPool.amount;
						addToPool(address(this), poolInfo.nextPool, 0);
	        		}
	        	}
	        	lastDownlineCount[blob.owner] = downlines_0;
			}
			DAI.transfer(blob.owner, transferAmount);
		}
		emit Claimed(blob.owner, transferAmount);

		totalIncome[blob.owner] += uint128(transferAmount);

		userForcedAutoFill[blob.owner][poolNumber] = true;
		isPoolBlobClaimed[poolNumber][blobNumber] = true;

		if(poolInfo.nextPool != 0) {
			addToPool(blob.owner, poolInfo.nextPool, 0);
		}
		else {
			addToPool(address(this), poolInfo.nextPool, 0);
		}
    }

    function findUnfilledBlob(uint32 poolNumber, uint32 blobNumber, uint32 priorityBlob) internal view returns (uint32) {
    	Blob memory currentBlob = poolBlobs[poolNumber][blobNumber];
    	if(currentBlob.right == 0) return blobNumber;

    	uint32 first;
    	uint32 second;

    	if(priorityBlob == currentBlob.right) {
    		first = priorityBlob;
    		second = currentBlob.left;
    	}
    	else {
    		first = currentBlob.left;
    		second = currentBlob.right;
    	}

    	Blob memory wingBlob = poolBlobs[poolNumber][first];
    	if(wingBlob.right == 0) return first;

    	wingBlob = poolBlobs[poolNumber][second];
    	if(wingBlob.right == 0) return second;

    	revert("Group fully filled");
    }

    function findGroupToFill(uint32 poolNumber, uint32 blobNumber) public view returns (uint32) {
		Blob memory currentBlob = poolBlobs[poolNumber][blobNumber];
		require(currentBlob.owner != address(0), "Invalid Group Number");

		if(currentBlob.up != 0 && !isPoolBlobClaimed[poolNumber][currentBlob.up]) {
			Blob memory upperBlob = poolBlobs[poolNumber][currentBlob.up];
			if(upperBlob.up != 0 && !isPoolBlobClaimed[poolNumber][upperBlob.up]) {
				return findUnfilledBlob(poolNumber, upperBlob.up, currentBlob.up);
			}
			return findUnfilledBlob(poolNumber, currentBlob.up, blobNumber);
		}
		return findUnfilledBlob(poolNumber, blobNumber, blobNumber);
    }

    function addToPool(address addr, uint32 poolNumber, uint32 origBlobNumber) internal returns (uint32 blobId) {

		uint32 blobNumber = origBlobNumber;

		bool forced = userForcedAutoFill[addr][poolNumber];

		if(origBlobNumber != 0 && !forced) {

			blobNumber = findGroupToFill(poolNumber, blobNumber);

		}
		else if(vacantBlobs[poolNumber].length > 0) {
			uint32 vacantIndex = vacantBlobIndex[poolNumber];
			uint256 length = vacantBlobs[poolNumber].length;
			Blob memory currentBlob;
			for(uint256 i = vacantIndex; i < length; ++i) {
				blobNumber = vacantBlobs[poolNumber][i];
				currentBlob = poolBlobs[poolNumber][blobNumber];
				if(currentBlob.right == 0) {
					if(i != vacantIndex) vacantBlobIndex[poolNumber] = uint32(i);
					break;
				}
			}

			if(forced) userForcedAutoFill[addr][poolNumber] = false;
		}

		poolBlobs[poolNumber].push(Blob(addr, blobNumber, 0, 0));
        blobId = uint32(poolBlobs[poolNumber].length) - 1;
		vacantBlobs[poolNumber].push(blobId);

		userData[addr].push(poolNumber);
		userData[addr].push(blobId);

		if(blobNumber != 0) {
			Blob storage upBlob = poolBlobs[poolNumber][blobNumber];

			uint32 upupIndex = upBlob.up;
			Blob memory upupBlob = poolBlobs[poolNumber][upupIndex];

			if(upBlob.left == 0) {
				upBlob.left = blobId;
			}
			else if(upBlob.right == 0) {
				upBlob.right = blobId;

				if(upupIndex != 0) {

					Blob memory otherBlob;
					if(blobNumber == upupBlob.left) {
						otherBlob = poolBlobs[poolNumber][upupBlob.right];
					}
					else {
						otherBlob = poolBlobs[poolNumber][upupBlob.left];
					}

					if(otherBlob.right != 0) {
						claimBlobAuto(poolNumber, upupIndex);
					}
				}
			}
		}
    }

    function joinPool(uint32 poolNumber, uint32 origBlobNumber) public {
    	if(poolNumber != 0) {
    		require(userEnabled[msg.sender], "You need to invest on 100 dai first.");
    	}
    	else if(!userEnabled[msg.sender]) {
    		userEnabled[msg.sender] = true;
    	}

    	PoolInfo memory poolInfo = poolInfos[poolNumber];
    	require(poolInfo.amount > 0, "Invalid Pool.");

    	if(membersOnly) {
	    	(address referrer,,,,,,,,,,) = daigon.users(msg.sender);
	    	require(referrer != address(0), "You need to stake atleast once to join");
    	}

		DAI.transferFrom(msg.sender, address(this), poolInfo.amount + (poolInfo.amount * joinFee / 100));

		if(joinFee > 0) DAI.transfer(scatterContract, poolInfo.amount * joinFee / 100);

		uint32 blobId = addToPool(msg.sender, poolNumber, origBlobNumber);

		emit BlobInserted(msg.sender, blobId);
    }

    function getUserInfo(address addr) external view returns (uint128, uint32, uint32, uint32, uint96, bool) {
    	return (totalIncome[addr], lastDownlineCount[addr], minimumDownline, repeatMinimum, joinFee, userEnabled[addr]);
    }

    function getUserData(address addr) external view returns (uint32[] memory, uint32[] memory, bool[] memory) {
		uint256 length = userData[addr].length;
		uint32[] memory poolNumber = new uint32[](length / 2);
		uint32[] memory blobNumber = new uint32[](length / 2);
		bool[] memory isClaimed = new bool[](length / 2);

		for(uint256 i = 0; i < length; i+=2) {
			poolNumber[i / 2] = userData[addr][i];
			blobNumber[i / 2] = userData[addr][i + 1];
			isClaimed[i / 2] = isPoolBlobClaimed[poolNumber[i / 2]][blobNumber[i / 2]];
		}

		return (poolNumber, blobNumber, isClaimed);
    }

    function getPoolInfos() external view returns(uint128[] memory, uint96[] memory) {
		uint256 length = poolInfos.length;
		uint128[] memory amount = new uint128[](length);
		uint96[] memory penaltyAmount = new uint96[](length);

		for(uint256 i = 0; i < length; ++i) {
			amount[i] = poolInfos[i].amount;
			penaltyAmount[i] = poolInfos[i].penaltyAmount;
		}
		return (amount, penaltyAmount);
    }

    function createPool(uint128 amount, uint32 nextPool, uint96 penaltyAmount) public onlyOwner {
    	poolInfos.push(PoolInfo(amount, nextPool, penaltyAmount));
    	uint32 poolNumber = uint32(poolInfos.length) - 1;
    	poolBlobs[poolNumber].push(Blob(address(0), 0, 0, 0));

    	addToPool(address(this), poolNumber, 0);
    	addToPool(address(this), poolNumber, 0);
    	addToPool(address(this), poolNumber, 0);
    }

    function editPool(uint32 poolNumber, uint128 amount, uint32 nextPool, uint96 penaltyAmount) external onlyOwner {
    	poolInfos[poolNumber].amount = amount;
    	poolInfos[poolNumber].nextPool = nextPool;
    	poolInfos[poolNumber].penaltyAmount = penaltyAmount;
    }

	function changeAddress(uint256 n, address addr) external onlyOwner {
		if(n == 1) {
			a1 = addr;
		}
		else if(n == 2) {
			a2 = addr;
		}
		else if(n == 3) {
			a3 = addr;
		}
		else if(n == 4) {
			stakingFunder = addr;
		}
		else if(n == 5) {
			owner = addr;
		}
		else if(n == 6) {
			scatterContract = addr;
		}
	}

	function changeValue(uint256 n, uint96 value) external onlyOwner {
		if(n == 1) {
			minimumDownline = uint32(value);
		}
		else if(n == 2) {
			repeatMinimum = uint32(value);
		}
		else if(n == 3) {
			joinFee = value;
		}
		else if(n == 4) {
			membersOnly = value == 1;
		}
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	event Claimed(address indexed user, uint256 amount);
	event BlobInserted(address indexed user, uint32 indexed number);
}