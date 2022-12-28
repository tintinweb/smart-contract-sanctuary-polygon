pragma solidity 0.7.6;
pragma abicoder v2;
import "datafeed.sol";

//SPDX-License-Identifier: MIT


interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface BridgeFallbackInterface {
	function bridgeFallBack(bytes32 _hash, bytes memory _data) external;
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Math {
	function sum(uint256[] memory numbers) internal pure returns (uint256 _sum) {
		uint256 i = 0;
		while (i < numbers.length) {
			_sum += numbers[i];
			i += 1;
		}
	}
	
	function min(uint256[] memory numbers) internal pure returns (uint256 _min) {
		uint256 i = 0;
		_min = numbers[0];
		while (i < numbers.length) {
			if (_min > numbers[i]) {
				_min = numbers[i];
			}
			i += 1;
		}
	}
	
	function max(uint256[] memory numbers) internal pure returns (uint256 _max) {
		uint256 i = 0;
		_max = numbers[0];
		while (i < numbers.length) {
			if (_max < numbers[i]) {
				_max = numbers[i];
			}
			i += 1;
		}
	}
}

contract RelayerSet {
	struct Relayer {
		address owner;
		address operator;
		bool active;
		uint256 collateral;
		uint256 depositBlock;
		bool exists;
	}
	
	address public owner;
	address public controlSigner; // veto right, no right to force push data
	bool public controlSignerReleased = false;
	ERC20Interface public stakingToken;
	uint256 public collateral;
	mapping (address => Relayer) public relayerInfo;
	address[] public relayersList;
	uint256 public activeRelayers;
	mapping (uint256 => mapping (bytes32 => mapping (address => bool))) signerCounted;
	uint256 public systemNonce;
	
	event ControlSignerReleased();
	
	
	modifier onlyRelayerOwner(address operator) {
		require(relayerInfo[operator].owner == msg.sender, "Only relayer owner can do that");
		_;
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
		require(sig.length == 65, "invalid signature length");

		assembly {
			// first 32 bytes, after the length prefix
			r := mload(add(sig, 32))
			// second 32 bytes
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes)
			v := byte(0, mload(add(sig, 96)))
		}

		// implicitly return (r, s, v)
	}

	function _addRelayer(address _owner, address operator, bool active, uint256 _collateral) private {
		require(!relayerInfo[operator].exists, "RELAYER_ALREADY_EXISTS");
		relayerInfo[operator] = Relayer({owner: _owner, operator: operator, active: active, collateral: _collateral, depositBlock: block.number, exists: true});
		relayersList.push(operator);
		activeRelayers += 1;
	}
	
	constructor(address _stakingToken, uint256 _collateral, address bootstrapRelayer) {
		owner = msg.sender;
		stakingToken = ERC20Interface(_stakingToken);
		collateral = _collateral;
		_addRelayer(address(0), bootstrapRelayer, true, 0);
		controlSigner = bootstrapRelayer;
	}
	
	function nakamotoCoefficient() public view returns (uint256) {
		return (activeRelayers/2)+1;
	}
	
	function createRelayer(address operator) public {
		require(stakingToken.transferFrom(msg.sender, address(this), collateral), "TRANSFER_FROM_FAILED");
		_addRelayer(msg.sender, operator, true, collateral);
	}
	
	function enableRelayer(address operator) public onlyRelayerOwner(operator) {
		Relayer storage relayer = relayerInfo[operator];
		require(!relayer.active, "ALREADY_ACTIVE");
		require(stakingToken.transferFrom(msg.sender, address(this), collateral), "TRANSFER_FROM_FAILED"); // assuming it's onlyRelayerOwner, then msg.sender == relayer.owner
		relayer.active = true;
		relayer.depositBlock = block.number;
		activeRelayers += 1;
	}
	
	function disableRelayer(address operator) public onlyRelayerOwner(operator) {
		Relayer storage relayer = relayerInfo[operator];
		require(relayer.active, "ALREADY_DISABLED");
		require(relayer.depositBlock < block.number, "UNMATCHED_COOLDOWN");
		relayer.active = false;
		stakingToken.transfer(relayer.owner, relayer.collateral);
		activeRelayers -= 1;
	}
	
	function getActiveness(address addr) public view returns (bool) {
		return relayerInfo[addr].active;
	}
	
	function recoverSig(bytes32 hash, bytes memory _sig) public pure returns (address signer) {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_sig);
		return ecrecover(hash, v, r, s);
	}
	
	function recoverRelayerSigs(bytes32 bkhash, bytes[] memory _sigs) public returns (uint256 validsigs, bool coeffmatched) {
		bool controlSigMatch;
		bool _controlReleased = controlSignerReleased;
		address _controlSigner = controlSigner;
		uint256 _systemNonce = systemNonce;
		uint256 naka = nakamotoCoefficient();
		for (uint256 n = 0; n<_sigs.length; n++) {
			address addr = recoverSig(bkhash, _sigs[n]);
			if ((!signerCounted[_systemNonce][bkhash][addr]) && relayerInfo[addr].active) {
				controlSigMatch = (controlSigMatch || _controlReleased || (_controlSigner == addr));
 				signerCounted[_systemNonce][bkhash][addr] = true;
				validsigs++;
			}
			coeffmatched = ((validsigs >= naka) && controlSigMatch);
			if (coeffmatched) { break; } // we don't need to keep checking once we're sure it works
		}
		systemNonce = _systemNonce+1; // using _systemNonce saves a gas-eating SLOAD
	}
	
	function renounceControlSigner() public {
		require(msg.sender == controlSigner, "UNMATCHED_CONTROL_SIGNER");
		require(!controlSignerReleased, "ALREADY_RELEASED");
		controlSignerReleased = true;
		emit ControlSignerReleased();
	}
}

contract BeaconChainHandler {
	struct Beacon {
		address miner;
		uint256 nonce;
		bytes[] messages;
		uint256 difficulty;
		bytes32 miningTarget;
		uint256 timestamp;
		bytes32 parent;
		bytes32 proof;
		uint256 height;
		bytes32 son;
		bytes32 parentTxRoot;
		uint8 v;
		bytes32 r;
		bytes32 s;
		bytes[] relayerSigs;
	}
	// StakeManager public stakingContract;
	Beacon[] public beacons;
	uint256 blockTime = 600;
	RelayerSet public relayerSet;
	
	event CallExecuted(address indexed to, bytes data, bool success);
	event CallDismissed(address indexed to, bytes data, string reason);

	function _chainId() internal pure returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}
	
	constructor(Beacon memory _genesisBeacon, address _stakingToken, uint256 mnCollateral) {
		beacons.push(_genesisBeacon);
		beacons[0].height = 0;
        address bootstrapRelayer = 0xE12Ca65C7A260bF91687A2e1763FA603eCCd812a;
		relayerSet = new RelayerSet(_stakingToken, mnCollateral, bootstrapRelayer);
	}
	
	function beaconHash(Beacon memory _beacon) public pure returns (bytes32 beaconRoot) {
		bytes32 messagesRoot = keccak256(abi.encode(_beacon.messages));
		bytes32 bRoot = keccak256(abi.encodePacked(_beacon.parent, _beacon.timestamp,  messagesRoot, _beacon.parentTxRoot, _beacon.miner));
		beaconRoot = keccak256(abi.encodePacked(bRoot, _beacon.nonce));
	}
	
	function isBeaconValid(Beacon memory _beacon) public view returns (bool valid, string memory reason) {
		bytes32 _hash = beaconHash(_beacon);
		if (_hash != _beacon.proof) {
			return (false, "UNMATCHED_HASH");
		}
		bytes32 lastBlockHash = beacons[beacons.length-1].proof;
		if (lastBlockHash != _beacon.parent) {
			return (false, "UNMATCHED_PARENT");
		}
		if (_beacon.height != beacons.length) {
			return (false, "UNMATCHED_HEIGHT");
		}
		if ((_beacon.timestamp > block.timestamp) || (_beacon.timestamp < (beacons[beacons.length-1].timestamp + blockTime))) {
			return (false, "UNMATCHED_TIMESTAMP");
		}
		if (ecrecover(_beacon.proof, _beacon.v, _beacon.r, _beacon.s) != _beacon.miner) {
			return (false, "INVALID_SIGNATURE");
		}
		return (true, "VALID_BEACON");
	}
	
	function extractBeaconMessages(Beacon memory _beacon) public pure returns (bytes[] memory messages, uint256 length) {
		return (_beacon.messages, _beacon.messages.length);
	}
	
	function executeCall(bytes memory message) private returns (bool success) {
		(address recipient, uint256 chainID, bytes memory data) = abi.decode(message, (address, uint256, bytes));
		if (_chainId() == chainID) {
			(success, ) = recipient.call(abi.encodeWithSelector(bytes4(keccak256("execBridgeCall(bytes)")), data));
			require(success, "MESSAGE_EXECUTION_FAILED");
			emit CallExecuted(recipient, data, success);
		}
		else {
			emit CallDismissed(recipient, data, "INVALID_CHAIN_ID");
		}
	}
	
	function executeMessages(Beacon memory _beacon) private {
		for (uint256 n = 0; n<_beacon.messages.length; n++) {
			executeCall(_beacon.messages[n]);
		}
	}
	
	function pushBeacon(Beacon memory _beacon) public {
		(bool _valid, string memory _reason) = isBeaconValid(_beacon);
		(, bool sigsMatched) = relayerSet.recoverRelayerSigs(_beacon.proof, _beacon.relayerSigs);
		require(_valid, _reason);
		require(sigsMatched, "UNMATCHED_RELAYER_SIGNATURES");
		beacons.push(_beacon);
		beacons[beacons.length-2].son = _beacon.proof;
		
		executeMessages(_beacon);
		// copyValidatorSet(beacons.length-1, beacons.length);
	}
	
	function chainLength() public view returns (uint256) {
		return beacons.length;
	}
	
	function beaconRelayerSigs(uint256 beaconHeight) public view returns (bytes[] memory) {
		return beacons[beaconHeight].relayerSigs;
	}
}


// contract ChainsImplementationHandler {
	// address[] public instances;
	// mapping (address => bool) public isInstance;
	// mapping (address => address[]) public instancesPerOwner;
	
	// BeaconChainHandler.Beacon public genesisBeacon;
	// ERC20Interface public stakingToken;
	// address owner;
	// address officialInstance;
	
	// event CallExecuted(address indexed to, bytes data, bool success);
	// event CallDismissed(address indexed to, bytes data, string reason);
	
	// modifier onlyOwner {
		// require(msg.sender == owner);
		// _;
	// }

	// constructor(BeaconChainHandler.Beacon memory _genesisBeacon, ERC20Interface _stakingToken) {
		// genesisBeacon = _genesisBeacon;
		// stakingToken = _stakingToken;
		// owner = tx.origin;
	// }

	// function _chainId() internal pure returns (uint256) {
		// uint256 id;
		// assembly {
			// id := chainid()
		// }
		// return id;
	// }
	
	// function transferOwnership(address _to) public onlyOwner {
		// owner = _to;
	// }
	
	// function setOfficialInstance(address _instance) public onlyOwner{
		// officialInstance = _instance;
	// }
	
	// function getAllInstances() public view returns (address[] memory) {
		// return instances;
	// }
	
	// function createInstance(address instanceOwner) public {
		// address newInstance = address(new BeaconChainHandler(genesisBeacon, instanceOwner));
		// instances.push(newInstance);
		// isInstance[newInstance] = true;
		// instancesPerOwner[instanceOwner].push(newInstance);
	// }
	
	// function routeCall(bytes memory call) public {
		// if (msg.sender != officialInstance) {
			// return;
		// }
		// (address recipient, uint256 chainID, bytes memory data) = abi.decode(call, (address, uint256, bytes));
		// if (_chainId() == chainID) {
			// (bool success, ) = recipient.call(abi.encodeWithSelector(bytes4(keccak256("execBridgeCall(bytes)")), data));
			// emit CallExecuted(recipient, data, success);
		// }
		// else {
			// emit CallDismissed(recipient, data, "INVALID_CHAIN_ID");
		// }
	// }
// }

contract MasterContract {
	// StakeManager public staking;
	BeaconChainHandler public beaconchain;
	DataFeed public datafeed;
    // ChainsImplementationHandler public chainInstances;
	
	// comment used as a reminder, DON'T REMOVE
	// struct Beacon {
		// address miner; // "0x0000000000000000000000000000000000000000"
		// uint256 nonce; // 0
		// bytes[] messages; // ["0x48657920677579732c206a75737420747279696e6720746f20696d706c656d656e742061206b696e64206f6620726170746f7220636861696e2c206665656c206672656520746f20686176652061206c6f6f6b"]
		// uint256 difficulty; // 1
		// bytes32 miningTarget; // bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
		// uint256 timestamp; // 1650271392
		// bytes32 parent; // bytes32(0x496e697469616c697a696e672074686520526170746f72436861696e2e2e2e20)
		// bytes32 proof; // bytes32(0x5115cbb8aab4470dcdb6950eb0e36d5ac7bb3ebb92988c21a5dc35547100a8ef)
		// uint256 height; // 0
		// bytes32 son; // "0x0000000000000000000000000000000000000000000000000000000000000000"
		// bytes32 parentTxRoot; // bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)
		// uint8 v; // 0
		// bytes32 r; // bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)
		// bytes32 s; // bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)
	// }
	
	// BeaconChainHandler.Beacon({miner: address(0), nonce: 0, messages: [bytes("0x48657920677579732c206a75737420747279696e6720746f20696d706c656d656e742061206b696e64206f6620726170746f7220636861696e2c206665656c206672656520746f20686176652061206c6f6f6b")], difficulty: 1, miningTarget: bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), timestamp: 1650271392, parent: bytes32(0x496e697469616c697a696e672074686520526170746f72436861696e2e2e2e20), proof: bytes32(0x5115cbb8aab4470dcdb6950eb0e36d5ac7bb3ebb92988c21a5dc35547100a8ef), height: 0, son: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), parentTxRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), v: 0, r: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), s: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000)})
	
	
	// calldata to use on deployment
	// GenesisBeacon calldata testnet : ["0x0000000000000000000000000000000000000000",0,["0x48657920677579732c206a75737420747279696e6720746f20696d706c656d656e742061206b696e64206f6620726170746f7220636861696e2c206665656c206672656520746f20686176652061206c6f6f6b"],1,"0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",1645457628,"0x496e697469616c697a696e672074686520526170746f72436861696e2e2e2e00","0x7d9e1f415e0084675c211687b1c8dfaee67e53128e325b5fdda9c98d7288aaeb",0,"0x0000000000000000000000000000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000000000000000000000000000",0,"0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000"]
	// GenesisBeacon calldata mainnet : ["0x0000000000000000000000000000000000000000", 0, ["0x48657920677579732c2049276d20776f726b696e67206f6e20526170746f72436861696e20616e6420657870656374696e6720697420746f20776f726b207665727920736f6f6e20212121202d2031302f30362f32303232"], 1, "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", 1658340032, "0x5361792068656c6c6f20746f20526170746f72436861696e204d61696e6e6574", "0xe1ffbed45ab5c4adbb363ea48519877f11988d56748bfa76b5845fac371bfc3c", 0, "0x0000000000000000000000000000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000000000000000000000000000", 0, "0x0000000000000000000000000000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000000000000000000000000000", []]
	
	constructor(BeaconChainHandler.Beacon memory _genesisBeacon, address stakingToken, uint256 mnCollateral) {
		// staking = new StakeManager(stakingToken);
        // chainInstances = new ChainsImplementationHandler(_genesisBeacon, stakingToken);
		beaconchain = new BeaconChainHandler(_genesisBeacon, stakingToken, mnCollateral);
		datafeed = new DataFeed(address(beaconchain));
		// staking.setBeaconHandler(beaconchain);
	}
	
}