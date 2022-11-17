pragma solidity ^0.8.6;
import "./Enums.sol";

contract Workflow {
    
    address _owner;
    address _externalSystemAddress;

    mapping(uint8 => mapping(string => SignableEntity)) _signableEntities;
    mapping(uint16 => bool) _validEventCode;
    mapping(uint16 => string) _errorCodes;
    mapping(uint16 => string) _eventsName;
    mapping(uint16 => string) _statusCodes;
    bool _allowMigration;
    mapping(address => mapping(uint8 => mapping(string => uint256)))
        public _nonce; //Key identity -> (Key EntityType -> (Key: RootObjectId - Value: uint))

    //Rules Sequence EvenCode
    mapping(string => uint16[]) _eventCodesByRootObjectId; //Key: rootObjectId  - Value: array of eventCodes
    mapping(uint16 => bool) _mayBeFirst; //key: eventCode
    mapping(uint16 => uint16[]) _rulesSequence; //key: eventCode

    //#region Eventos
    event ProcessEventCode( string );
    //#region Eventos

    struct SignableEntity {
        bytes id;
        bool isCreated;
        bytes rootHash;
    }

    constructor(address externalSystemAddress)
    {
        _owner = msg.sender;
        _externalSystemAddress = externalSystemAddress;
        _allowMigration = false;
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidSender)]
        );
        _;
    }

    modifier onlyExternalSystem() {
        require(
            _externalSystemAddress == msg.sender,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidSender)]
        );
        _;
    }

    modifier onlyValidEventCode(uint16 eventCode) {
        require(
            _validEventCode[eventCode],
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidEventCode)]
        );
        _;
    }

    modifier onlyValidEventCodeSequence(string memory rootObjectId, uint16 eventCode) {
        bool validSequenceEventCode;
        // Si no tiene secuencia y puede ser el primero -> es valido
        // Si no tiene secuencia y no puede ser el primero -> es invalido
        // Si tiene secuencia, no tiene reglas de secuencia -> es valido
        // Si tiene secuencia, tiene reglas de secuencia y el ultimo eventCode esta dentro de la reglas es valido, sino es invalido

        //_mayBeFirst; //key: eventCode
        //_rulesSequence; //key: eventCode
        if( _eventCodesByRootObjectId[rootObjectId].length == 0)
        {
            if (_mayBeFirst[eventCode])
            {
                validSequenceEventCode = true;
            }
            else
            {
                validSequenceEventCode = false;
            }
        }
        else
        {
            uint16 lastEventCode = _eventCodesByRootObjectId[rootObjectId][_eventCodesByRootObjectId[rootObjectId].length-1];
            validSequenceEventCode = (_rulesSequence[eventCode].length > 0) ? false : true;
            uint index = 0;
            while (!validSequenceEventCode && index < _rulesSequence[eventCode].length)
            {
                if(_rulesSequence[eventCode][index] == lastEventCode)
                {
                    validSequenceEventCode = true;
                }
                index++;
            }
        }

        require(
            validSequenceEventCode,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidSequenceEventCode)]
        );
        _;
    }

    function initCodes() private {
        _errorCodes[
            uint16(Enums.ErrorCode.CommonInvalidRootObjectId)
        ] = "CommonInvalidRootObjectId";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonValidateError)
        ] = "CommonValidateError";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonRootHashError)
        ] = "CommonRootHashError";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonInvalidSignature)
        ] = "CommonInvalidSignature";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonInvalidSender)
        ] = "CommonInvalidSender";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonInvalidEventCode)
        ] = "CommonInvalidEventCode";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonFailDelegateCall)
        ] = "CommonFailDelegateCall";
        _errorCodes[
            uint16(Enums.ErrorCode.CommonInvalidSequenceEventCode)
        ] = "CommonInvalidSequenceEventCode";

        _statusCodes[uint16(Enums.EventStatus.Started)] = "Started";
        _statusCodes[uint16(Enums.EventStatus.Finished)] = "Finished";
    }

    function init() public onlyOwner {
        initCodes();
    }

    function processEventContent(
        address from,
        uint16 entityType,
        string memory rootObjectId,
        uint16 eventCode,
        string memory hashData,
        string memory signatureId,
        string memory roothash,
        bytes memory friendlyHash,
        bytes memory sig
    ) public onlyOwner {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                this,
                _nonce[from][uint8(entityType)][rootObjectId],
                from,
                "processEventContent",
                entityType,
                rootObjectId,
                eventCode,
                hashData,
                signatureId,
                friendlyHash
            )
        );
        checkSignature(
            from,
            sig,
            hash,
            entityType,
            rootObjectId
        );
        _processEvent(entityType, rootObjectId, eventCode, signatureId, roothash);
    }

    function processEvent(
        uint16 entityType,
        string memory rootObjectId,
        uint16 eventCode,
        string memory hashData,
        string memory signatureId,
        string memory roothash
    ) public onlyExternalSystem {
        _processEvent(
            entityType,
            rootObjectId,
            eventCode,
            signatureId,
            roothash
        );
    }

    function _processEvent(
        uint16 entityType,
        string memory rootObjectId,
        uint16 eventCode,
        string memory signatureId,
        string memory roothash
    )
        internal
        onlyValidEventCode(eventCode)
        onlyValidEventCodeSequence(rootObjectId, eventCode)
    {
        _signableEntities[uint8(entityType)][rootObjectId].isCreated = true;
        _signableEntities[uint8(entityType)][rootObjectId].rootHash = bytes(roothash);
        _eventCodesByRootObjectId[rootObjectId].push(eventCode);
        emit ProcessEventCode(signatureId);
    }

    function setEventName(uint16 eventCode, string memory value)
        private
        onlyOwner
        onlyValidEventCode(eventCode)
    {
        _eventsName[eventCode] = value;
    }

    function ecrecovery(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }

    function checkSignature(
        address identity,
        bytes memory sig,
        bytes32 hash,
        uint16 entityType,
        string memory rootObjectId
    ) internal  {
        address signer = ecrecovery(hash, sig);
        require(signer == identity, "signer <> identity");
        _nonce[signer][uint8(entityType)][rootObjectId]++;
    }
    
    function setRules(uint16 eventCode, bool mayBeFirst, uint16[] memory rulesSequence)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        _mayBeFirst[eventCode] = mayBeFirst;
        _rulesSequence[eventCode] = rulesSequence;
    }

    function configureEventCode(
        uint16 eventCode,
        string memory eventName,
        bool mayBeFirst,
        uint16[] memory rulesSequence
    ) public onlyOwner {
        _validEventCode[eventCode] = true;
        setEventName(eventCode, eventName);
        setRules(eventCode, mayBeFirst, rulesSequence);
    }

    function verifyData(
        uint16 entityType,
        string memory rootObjectId,
        string memory roothash
    ) public view returns (bool) {
        require(
            _signableEntities[uint8(entityType)][rootObjectId].isCreated,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidRootObjectId)]
        );
        return
            keccak256(
                _signableEntities[uint8(entityType)][rootObjectId].rootHash
            ) == keccak256(bytes(roothash));
    }

    function openMigration() public onlyOwner {
        _allowMigration = true;
    }

    function migrate(
        uint16 entityType,
        string memory rootObjectId,
        string memory roothash
    ) public onlyOwner {
        require(
            _allowMigration,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidMigrate)]
        );
        _signableEntities[uint8(entityType)][rootObjectId].isCreated = true;
        _signableEntities[uint8(entityType)][rootObjectId].rootHash = bytes(
            roothash
        );
    }

    function finishMigration() public onlyOwner {
        _allowMigration = false;
    }
}