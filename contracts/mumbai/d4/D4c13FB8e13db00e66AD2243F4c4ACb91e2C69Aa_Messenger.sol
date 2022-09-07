//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Wormhole/IWormhole.sol";
import "./XDappBook.sol";

contract Messenger is XDappBook {
    address constant private  WORMHOLE_BRIDGE = 0xC89Ce4735882C9F0f0FE26686c53074E09B0D550;
    IWormhole private bridge;
    uint32 private nonce = 0;
    address private owner;

    event Received (
        uint96  pair,
        address indexed sender,
        uint256 amount
    );

    constructor(address _bridge){
        owner = msg.sender;
        if(_bridge == address(0)){
            bridge = IWormhole(WORMHOLE_BRIDGE);
        }else{
            bridge = IWormhole(_bridge);
        }
    }
    
    function getNonce() internal override returns (uint32 _nonce){
        _nonce = nonce;
        unchecked {
            nonce += 1;
        }
    }

    function getWormhole() internal override view returns (IWormhole){
        return IWormhole(bridge);
    }

    function _requireOwner() internal view override {
        require(msg.sender == owner, "Only owner can register new chains!");
    }

    function raiseEvent(uint96 pair, uint256 amount) external returns (uint64 sequence) {
        uint32 _nonce = getNonce(); 
        bytes memory _msg = abi.encode(msg.sender, pair, amount);
        sequence = getWormhole().publishMessage(_nonce, _msg, 1);
    }

    function receiveEvent(bytes memory encodedMsg) external {  
        (IWormhole.VM memory vm, bool valid, string memory reason) = getWormhole().parseAndVerifyVM(encodedMsg);
        
        require(valid, reason);

        (address _sender, uint96 _pair, uint256 _amount) = abi.decode(vm.payload, (address, uint96, uint256));
        emit Received(_pair, _sender, _amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Wormhole/IWormhole.sol";

abstract contract XDappBook {
    string private currentMsg;
    mapping(uint16 => bytes32) internal _applicationContracts;
    mapping(bytes32 => bool) internal _completedMessages;

    function getNonce() internal virtual returns (uint32);
    function getWormhole() internal virtual view returns (IWormhole);

    function _requireOwner() internal view virtual;

    function sendMsg(bytes memory str) external returns (uint64 sequence) {
        uint32 _nonce = getNonce(); 
        sequence = getWormhole().publishMessage(_nonce, str, 1);
    }

    function decodeVM(bytes calldata encodedMsg) public view returns (uint16, bytes32) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = getWormhole().parseAndVerifyVM(encodedMsg);
        require(valid, reason);

        return (vm.emitterChainId, vm.hash);
    }

    function checkVM(IWormhole.VM memory vm) internal {
        //2. Check if the Emitter Chain contract is registered
        require(_applicationContracts[vm.emitterChainId] == vm.emitterAddress, "Invalid Emitter Address!");
    
        //3. Check that the message hasn't already been processed
        require(!_completedMessages[vm.hash], "Message already processed");
        _completedMessages[vm.hash] = true;
    }

    function receiveEncodedMsg(bytes memory encodedMsg) external {  
        (IWormhole.VM memory vm, bool valid, string memory reason) = getWormhole().parseAndVerifyVM(encodedMsg);
        
        //1. Check Wormhole Guardian Signatures
        //  If the VM is NOT valid, will return the reason it's not valid
        //  If the VM IS valid, reason will be blank
        require(valid, reason);

        checkVM(vm);

        currentMsg = string(vm.payload);    
    }

    /**
        Registers it's sibling applications on other chains as the only ones that can send this instance messages
     */
    function registerApplicationContracts(uint16 chainId, bytes32 applicationAddr) public {
        _requireOwner();
        _applicationContracts[chainId] = applicationAddr;
    }

    function getCurrentMsg() external view returns (string memory) {
        return currentMsg;
    }
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./Structs.sol";

interface IWormhole is Structs {
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;

    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;

    function getCurrentGuardianSetIndex() external view returns (uint32) ;

    function getGuardianSetExpiry() external view returns (uint32) ;

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;

    function isInitialized(address impl) external view returns (bool) ;

    function chainId() external view returns (uint16) ;

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256) ;
}

// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Structs {
	struct Provider {
		uint16 chainId;
		uint16 governanceChainId;
		bytes32 governanceContract;
	}

	struct GuardianSet {
		address[] keys;
		uint32 expirationTime;
	}

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
}