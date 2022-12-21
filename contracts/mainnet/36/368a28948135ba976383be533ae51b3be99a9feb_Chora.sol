//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./IERC20.sol";

contract Chora {

    // MUST stay the first declared field here (for the ChoraProxy)
    address internal masterContract;

    uint16 public constant VERSION = 300; // 200 = v0.2, 1000 = v1, etc

    // Chain id (ethereum = 1, polygon = 137, etc)
    uint64 private _chainId;

    // Owner wallet address
    address private _owner;

    // Co-signing key
    address private _online;

    uint64 private _nonce;

    // Delay for critical actions that were signed with both keys
    uint64 private _signedCriticalActionsActivationPeriod;
    uint64 private _recoveryPeriodSec;

    uint16 public constant RECOVERY_MODE_NONE = 0;
    uint16 public constant RECOVERY_MODE_RECOVER_OWNER = 1;
    uint16 public constant RECOVERY_MODE_DECOUPLE = 2;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    uint16 private _recoveryMode = RECOVERY_MODE_NONE;

    address private _requestedNewOwner;
    uint256 private _recoveryRedeemableAtEpochSec;

    constructor (address owner, address online, uint64 chainId, uint64 recoveryPeriodSec)
    {
        _owner = owner;
        _online = online;
        _chainId = chainId;
        _recoveryPeriodSec = recoveryPeriodSec;
    }

    struct Info {

        uint16 version;
        address owner;
        address onlineKey;
        address pendingNewOwner;
        uint16 recoveryMode;
        uint64 recoveryPeriodSec;
        uint256 recoveryRedeemableAtEpochSec;
        uint64 chainId;
    }

    function getInfo() public view returns (Info memory) {
        Info memory info;

        info.version = VERSION;
        info.owner = _owner;
        info.onlineKey = _online;
        info.recoveryMode = _recoveryMode;
        info.recoveryRedeemableAtEpochSec = _recoveryRedeemableAtEpochSec;
        info.pendingNewOwner = _requestedNewOwner;
        info.recoveryPeriodSec = _recoveryPeriodSec;
        info.chainId = _chainId;

        return info;
    }


    // onlyOwner modifier that validates only
    // if caller of function is contract owner,
    // otherwise not
    modifier onlyOwner()
    {
        require(isOwner(),
            "Access denied");
        _;
    }



    // For initialization with a proxy
    function init(address owner, address online, uint64 chainId) external {
        require(_owner == address(0), "Init can only be called when no owner wallet is assigned");
        require(_online == address(0), "Init can only be called when no online wallet is assigned");

        require(owner != address(0), "Invalid owner wallet address");

        _owner = owner;
        _online = online;
        _chainId = chainId;
        _recoveryPeriodSec = 30 days;

    }

    function isOwner() public view returns (bool)
    {
        return msg.sender == _owner;
    }

    function getNonce() public view returns (uint64)
    {
        return _nonce;
    }

    function calcHash(string memory operation, address argument) private view returns (bytes32 ) {
        bytes32 hash = keccak256(abi.encodePacked(
                abi.encodePacked(address(this)),
                _nonce,
                _chainId,
                operation,
                abi.encodePacked(argument)
            ));

        return hash;
    }


    function sendERC20(address tokenAddr, uint256 amount, address toAddress, uint8 v, bytes32 r, bytes32 s) onlyOwner public returns (bool) {

        bytes32 hash = keccak256(abi.encodePacked(
                abi.encodePacked(address(this)),
                _nonce,
                _chainId,
                abi.encodePacked(tokenAddr),
                amount,
                abi.encodePacked(toAddress)
            ));


        checkHashAndBumpNonce(hash, v, r, s);

        IERC20 tokenContract = IERC20(tokenAddr);
        tokenContract.transfer(toAddress, amount);
        return true;

    }


    function execute(Transaction[] calldata transactions, uint8 v, bytes32 r, bytes32 s) onlyOwner external {
        require(transactions.length > 0, 'No transactions provided');

        // validate signature
        bytes32 hash = keccak256(abi.encode(address(this), _nonce, _chainId, transactions));

        checkHashAndBumpNonce(hash, v, r, s);

        uint len = transactions.length;
        for (uint i = 0; i < len; i++) {
            Transaction memory t = transactions[i];
            execute(t.to, t.value, t.data);
        }
    }

    // execute generic operation on a smart contract
    function execute(address to, uint256 value, bytes memory data) internal returns (bool success) {

        uint256 gasToForward = gasleft();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(gasToForward, to, value, add(data, 0x20), mload(data), 0, 0)

            switch success case 0 {
                let size := returndatasize()
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
            default {}
        }
    }

    function reconfigureRecoveryPeriod(uint64 newRecoveryPeriod, uint8 v, bytes32 r, bytes32 s) onlyOwner public returns (bool) {

        bytes32 hash = keccak256(
            abi.encodePacked(
                abi.encodePacked(address(this)),
                _nonce,
                _chainId,
                "reconfigure",
                uint64(0), // backward compatibility
                newRecoveryPeriod
            )
        );

        checkHashAndBumpNonce(hash, v, r, s);
        _recoveryPeriodSec = newRecoveryPeriod;

        return true;
    }

    function changeOwner(address newOwnerAddress, uint8 v, bytes32 r, bytes32 s) onlyOwner public returns (bool) {

        bytes32 hash = calcHash("changeOwner", newOwnerAddress);
        checkHashAndBumpNonce(hash, v, r, s);

        _owner = newOwnerAddress;

        return true;
    }

    // No owner signature required
    function launchOwnerRecovery(address newOwnerAddress, uint8 v, bytes32 r, bytes32 s) public returns (bool) {

        require(_online != address(0), "Owner recovery is not available for a decoupled wallet");

        bytes32 hash = calcHash("recoverOwner", newOwnerAddress);
        checkHashAndBumpNonce(hash, v, r, s);

        activateRecovery(RECOVERY_MODE_RECOVER_OWNER);
        _requestedNewOwner = newOwnerAddress;

        return true;
    }

    // Can only be called by the owner, no online signature required
    function launchDecoupleRecovery() onlyOwner public returns (bool) {

        activateRecovery(RECOVERY_MODE_DECOUPLE);
        return true;
    }


    /**
    * Changes the online key.
    * - Verifies signature if the current online key is not 0x000..000
    * - newOnline may be 0x0, which means it's a decoupling operation
    * - Either way, only the owner may do this
    */
    function changeOnlineKey(address newOnline, uint8 v, bytes32 r, bytes32 s) onlyOwner public returns (bool) {

        bytes32 hash = calcHash("changeOnlineKey", newOnline);
        checkHashAndBumpNonce(hash, v, r, s);

        _online = newOnline;
        _recoveryMode = RECOVERY_MODE_NONE; // cancel any pending recovery

        return true;
    }

    // can be called by anyone, triggers the final recovery action if the grace period is over
    function redeemRecovery() public returns (bool) {

        require(_recoveryMode > RECOVERY_MODE_NONE, "No recovery pending");
        require(block.timestamp > _recoveryRedeemableAtEpochSec, "Wallet is still time-locked");

        if (_recoveryMode == RECOVERY_MODE_RECOVER_OWNER) {

            // change owner to the new address
            _owner = _requestedNewOwner;
            _requestedNewOwner = address(0);

        } else if (_recoveryMode == RECOVERY_MODE_DECOUPLE) {

            // nullify online public key
            _online = address(0);
        } else {
            return false;
        }

        _recoveryMode = RECOVERY_MODE_NONE;
        return true;

    }

    function cancelRecovery(uint8 v, bytes32 r, bytes32 s) public returns (bool)  {

        require(_recoveryMode > RECOVERY_MODE_NONE, "No recovery pending");

        bytes32 hash = keccak256(
            abi.encodePacked(
                abi.encodePacked(address(this)),
                _nonce,
                _chainId,
                "cancelRecovery"
            )
        );

        if (_recoveryMode == RECOVERY_MODE_RECOVER_OWNER) {
            assert(_online != address(0)); // this would be an unexpected state... we're in owner recovery but online address is 0x0

            checkHashAndBumpNonce(hash, v, r, s);
            _recoveryMode = RECOVERY_MODE_NONE;
            return true;

        } else if (_recoveryMode == RECOVERY_MODE_DECOUPLE) {
            require(isOwner(), "Access denied");
            _recoveryMode = RECOVERY_MODE_NONE;
            return true;
        }

        return false;
    }


    function checkHashAndBumpNonce(bytes32 hash, uint8 v, bytes32 r, bytes32 s) private returns (bool)  {

        _nonce = _nonce + 1;

        // if the wallet is decoupled, hash verification is disabled
        if (_online == address(0)) {
            return true;
        }

        address signer = ecrecover(hash, v, r, s);

        require(signer == _online, "Invalid signature");
        require(signer != address(0), "Invalid signature");

        return true;
    }

    function activateRecovery(uint16 requestedRecovery) private returns (bool){

        require(requestedRecovery > 0, "No recovery pending");
        require(requestedRecovery < 3, "Invalid recovery request");
        require(requestedRecovery > _recoveryMode, "Recovery request rejected - a higher priority recovery is active");

        _recoveryMode = requestedRecovery;
        _recoveryRedeemableAtEpochSec = block.timestamp + _recoveryPeriodSec;

        return true;
    }


    // accept ETH without calldata
    receive() external payable {}


    /**
 * @dev Reads a bytes32 value from a position in a byte array.
       * @param b Byte array containing a bytes32 value.
       * @param index Index in byte array of bytes32 value.
       * @return result bytes32 value from byte array.
       */
    function readBytes32(
        bytes memory b,
        uint256 index
    )
    internal
    pure
    returns (bytes32 result)
    {
        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        require(b.length >= index, "BytesLib: length");

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    // EIP 1271
    // https://eips.ethereum.org/EIPS/eip-1271
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {

        // signature structure:
        // bytes 0-64 : owner signature - 32 bytes for r, 32 bytes for s, and 1 byte v
        // byte 65 : signature type - 0: personal_sign, 1: EIP712
        // if not decoupled, bytes 66-130 : online signature - 32 bytes for r, 32 bytes for s, and 1 byte v

        if (_online == address(0)) {
            require(signature.length == 66, "Signature length invalid");
        } else {
            require(signature.length == 131, "Signature length invalid");
        }

        uint8 mode = uint8(signature[65]);
        if (mode == 0) hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        uint8 v_owner = uint8(signature[64]);
        bytes32 r_owner = readBytes32(signature, 0);
        bytes32 s_owner = readBytes32(signature, 32);

        address signer1 = ecrecover(hash, v_owner, r_owner, s_owner);

        if (signer1 != _owner) {
            return 0xffffffff;
        }

        if (_online != address(0)) {
            uint8 v_online = uint8(signature[130]);
            bytes32 r_online = readBytes32(signature, 66);
            bytes32 s_online = readBytes32(signature, 98);

            address signer2 = ecrecover(hash, v_online, r_online, s_online);

            if (signer2 != _online) {
                return 0xffffffff;
            }
        }

        return 0x1626ba7e;
    }

}