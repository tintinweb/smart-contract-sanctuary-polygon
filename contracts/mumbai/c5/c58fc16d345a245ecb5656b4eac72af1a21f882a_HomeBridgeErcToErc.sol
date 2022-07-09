/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

pragma solidity 0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface IBridgeValidators {
    function isValidator(address _validator) external view returns(bool);
    function requiredSignatures() external view returns(uint256);
    function owner() external view returns(address);
    function validatorsList() external view returns(address[]);
}


library Message {

    function addressArrayContains(address[] array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function parseMessage(bytes message)
        internal
        pure
        returns(address recipient, uint256 amount, bytes32 txHash, address contractAddress)
    {
        require(isMessageValid(message));
        assembly {
            recipient := and(mload(add(message, 20)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amount := mload(add(message, 52))
            txHash := mload(add(message, 84))
            contractAddress := mload(add(message, 104))
        }
    }

    function isMessageValid(bytes _msg) internal pure returns(bool) {
        return _msg.length == requiredMessageLength();
    }

    function requiredMessageLength() internal pure returns(uint256) {
        return 104;
    }

    function recoverAddressFromSignedMessage(bytes signature, bytes message) internal pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        return ecrecover(hashMessage(message), uint8(v), r, s);
    }

    function hashMessage(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        string memory msgLength = "104";
        return keccak256(abi.encodePacked(prefix, msgLength, message));
    }

    function hasEnoughValidSignatures(
        bytes _message,
        uint8[] _vs,
        bytes32[] _rs,
        bytes32[] _ss,
        IBridgeValidators _validatorContract) internal view {
        require(isMessageValid(_message));
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        require(_vs.length >= requiredSignatures);
        bytes32 hash = hashMessage(_message);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            address recoveredAddress = ecrecover(hash, _vs[i], _rs[i], _ss[i]);
            require(_validatorContract.isValidator(recoveredAddress));
            if (addressArrayContains(encounteredAddresses, recoveredAddress)) {
                revert();
            }
            encounteredAddresses[i] = recoveredAddress;
        }
    }
}


interface IOwnedUpgradeabilityProxy {
    function proxyOwner() external view returns (address);
}


contract OwnedUpgradeability {

    function upgradeabilityAdmin() public view returns (address) {
        return IOwnedUpgradeabilityProxy(this).proxyOwner();
    }

    modifier onlyIfOwnerOfProxy() {
        require(msg.sender == upgradeabilityAdmin());
        _;
    }
}


contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}


contract Validatable is EternalStorage {

    function validatorContract() public view returns(IBridgeValidators) {
        return IBridgeValidators(addressStorage[keccak256(abi.encodePacked("validatorContract"))]);
    }

    modifier onlyValidator() {
        require(validatorContract().isValidator(msg.sender));
        _;
    }

    function requiredSignatures() public view returns(uint256) {
        return validatorContract().requiredSignatures();
    }

}


contract Ownable is EternalStorage {
  
    event OwnershipTransferred(address previousOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    function owner() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("owner"))];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256(abi.encodePacked("owner"))] = newOwner;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicBridge is EternalStorage, Validatable, Ownable, OwnedUpgradeability {
    using SafeMath for uint256;

    event GasPriceChanged(uint256 gasPrice);
    event RequiredBlockConfirmationChanged(uint256 requiredBlockConfirmations);
    event DailyLimitChanged(uint256 newLimit);
    event ExecutionDailyLimitChanged(uint256 newLimit);

    function getBridgeInterfacesVersion() public pure returns(uint64 major, uint64 minor, uint64 patch) {
        return (2, 2, 0);
    }

    function setGasPrice(uint256 _gasPrice) public onlyOwner {
        require(_gasPrice > 0);
        uintStorage[keccak256(abi.encodePacked("gasPrice"))] = _gasPrice;
        emit GasPriceChanged(_gasPrice);
    }

    function gasPrice() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("gasPrice"))];
    }

    function setRequiredBlockConfirmations(uint256 _blockConfirmations) public onlyOwner {
        require(_blockConfirmations > 0);
        uintStorage[keccak256(abi.encodePacked("requiredBlockConfirmations"))] = _blockConfirmations;
        emit RequiredBlockConfirmationChanged(_blockConfirmations);
    }

    function requiredBlockConfirmations() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("requiredBlockConfirmations"))];
    }

    function deployedAtBlock() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("deployedAtBlock"))];
    }

    function setTotalSpentPerDay(uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _day))] = _value;
    }

    function totalSpentPerDay(uint256 _day) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _day))];
    }

    function setTotalExecutedPerDay(uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _day))] = _value;
    }

    function totalExecutedPerDay(uint256 _day) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _day))];
    }

    function minPerTx() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("minPerTx"))];
    }

    function maxPerTx() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("maxPerTx"))];
    }

    function executionMaxPerTx() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionMaxPerTx"))];
    }

    function setInitialize(bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("isInitialized"))] = _status;
    }

    function isInitialized() public view returns(bool) {
        return boolStorage[keccak256(abi.encodePacked("isInitialized"))];
    }

    function getCurrentDay() public view returns(uint256) {
        return now / 1 days;
    }

    function setDailyLimit(uint256 _dailyLimit) public onlyOwner {
        uintStorage[keccak256(abi.encodePacked("dailyLimit"))] = _dailyLimit;
        emit DailyLimitChanged(_dailyLimit);
    }

    function dailyLimit() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("dailyLimit"))];
    }

    function setExecutionDailyLimit(uint256 _dailyLimit) public onlyOwner {
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit"))] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_dailyLimit);
    }

    function executionDailyLimit() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionDailyLimit"))];
    }

    function setExecutionMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx < executionDailyLimit());
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx"))] = _maxPerTx;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx < dailyLimit());
        uintStorage[keccak256(abi.encodePacked("maxPerTx"))] = _maxPerTx;
    }

    function setMinPerTx(uint256 _minPerTx) external onlyOwner {
        require(_minPerTx < dailyLimit() && _minPerTx < maxPerTx());
        uintStorage[keccak256(abi.encodePacked("minPerTx"))] = _minPerTx;
    }

    function withinLimit(uint256 _amount) public view returns(bool) {
        uint256 nextLimit = totalSpentPerDay(getCurrentDay()).add(_amount);
        return dailyLimit() >= nextLimit && _amount <= maxPerTx() && _amount >= minPerTx();
    }

    function withinExecutionLimit(uint256 _amount) public view returns(bool) {
        uint256 nextLimit = totalExecutedPerDay(getCurrentDay()).add(_amount);
        return executionDailyLimit() >= nextLimit && _amount <= executionMaxPerTx();
    }

    function claimTokens(address _token, address _to) public  {
        require(_to != address(0));
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        require(token.transfer(_to, balance));
    }


    function isContract(address _addr) internal view returns (bool)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}


contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract ERC677 is ERC20 {
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    function transferAndCall(address, uint, bytes) external returns (bool);

}

contract IBurnableMintableERC677Token is ERC677 {
    function mint(address, uint256) public returns (bool);
    function burn(uint256 _value) public;
    function claimTokens(address _token, address _to) public;
}


contract ERC677Receiver {
  function onTokenTransfer(address _from, uint _value, bytes _data) external returns(bool);
}



contract BasicHomeBridge is EternalStorage, Validatable {
    using SafeMath for uint256;

    event UserRequestForSignature(address recipient, uint256 value);
    event AffirmationCompleted (address recipient, uint256 value, bytes32 transactionHash);
    event SignedForUserRequest(address indexed signer, bytes32 messageHash);
    event SignedForAffirmation(address indexed signer, bytes32 transactionHash);
    event CollectedSignatures(address authorityResponsibleForRelay, bytes32 messageHash, uint256 NumberOfCollectedSignatures);

    function executeAffirmation(address recipient, uint256 value, bytes32 transactionHash) external  {
        if (affirmationWithinLimits(value)) {
            bytes32 hashMsg = keccak256(abi.encodePacked(recipient, value, transactionHash));
            bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));
            require(!affirmationsSigned(hashSender));
            setAffirmationsSigned(hashSender, true);

            uint256 signed = numAffirmationsSigned(hashMsg);
            require(!isAlreadyProcessed(signed));
            signed = signed + 1;

            setNumAffirmationsSigned(hashMsg, signed);

            emit SignedForAffirmation(msg.sender, transactionHash);

            if (signed >= requiredSignatures()) {
                setNumAffirmationsSigned(hashMsg, markAsProcessed(signed));
                require(onExecuteAffirmation(recipient, value));
                emit AffirmationCompleted(recipient, value, transactionHash);
            }
        } else {
            onFailedAffirmation(recipient, value, transactionHash);
        }
    }

    function submitSignature(bytes signature, bytes message) external  {
        require(Message.isMessageValid(message));
        require(msg.sender == Message.recoverAddressFromSignedMessage(signature, message));
        bytes32 hashMsg = keccak256(abi.encodePacked(message));
        bytes32 hashSender = keccak256(abi.encodePacked(msg.sender, hashMsg));

        uint256 signed = numMessagesSigned(hashMsg);
        require(!isAlreadyProcessed(signed));
        signed = signed + 1;
        if (signed > 1) {
            require(!messagesSigned(hashSender));
        } else {
            setMessages(hashMsg, message);
        }
        setMessagesSigned(hashSender, true);

        bytes32 signIdx = keccak256(abi.encodePacked(hashMsg, (signed-1)));
        setSignatures(signIdx, signature);

        setNumMessagesSigned(hashMsg, signed);

        emit SignedForUserRequest(msg.sender, hashMsg);

        uint256 reqSigs = requiredSignatures();
        if (signed >= reqSigs) {
            setNumMessagesSigned(hashMsg, markAsProcessed(signed));
            emit CollectedSignatures(msg.sender, hashMsg, reqSigs);
        }
    }

    function setMessagesSigned(bytes32 _hash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("messagesSigned", _hash))] = _status;
    }

    function onExecuteAffirmation(address, uint256) internal  returns(bool) {
    }

    function numAffirmationsSigned(bytes32 _withdrawal) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("numAffirmationsSigned", _withdrawal))];
    }

    function setAffirmationsSigned(bytes32 _withdrawal, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("affirmationsSigned", _withdrawal))] = _status;
    }

    function setNumAffirmationsSigned(bytes32 _withdrawal, uint256 _number) internal {
        uintStorage[keccak256(abi.encodePacked("numAffirmationsSigned", _withdrawal))] = _number;
    }

    function affirmationsSigned(bytes32 _withdrawal) public view returns(bool) {
        return boolStorage[keccak256(abi.encodePacked("affirmationsSigned", _withdrawal))];
    }

    function signature(bytes32 _hash, uint256 _index) public view returns (bytes) {
        bytes32 signIdx = keccak256(abi.encodePacked(_hash, _index));
        return signatures(signIdx);
    }

    function messagesSigned(bytes32 _message) public view returns(bool) {
        return boolStorage[keccak256(abi.encodePacked("messagesSigned", _message))];
    }

    function messages(bytes32 _hash) internal view returns(bytes) {
        return bytesStorage[keccak256(abi.encodePacked("messages", _hash))];
    }

    function signatures(bytes32 _hash) internal view returns(bytes) {
        return bytesStorage[keccak256(abi.encodePacked("signatures", _hash))];
    }

    function setSignatures(bytes32 _hash, bytes _signature) internal {
        bytesStorage[keccak256(abi.encodePacked("signatures", _hash))] = _signature;
    }

    function setMessages(bytes32 _hash, bytes _message) internal {
        bytesStorage[keccak256(abi.encodePacked("messages", _hash))] = _message;
    }

    function message(bytes32 _hash) public view returns (bytes) {
        return messages(_hash);
    }

    function setNumMessagesSigned(bytes32 _message, uint256 _number) internal {
        uintStorage[keccak256(abi.encodePacked("numMessagesSigned", _message))] = _number;
    }

    function markAsProcessed(uint256 _v) internal pure returns(uint256) {
        return _v | 2 ** 255;
    }

    function isAlreadyProcessed(uint256 _number) public pure returns(bool) {
        return _number & 2**255 == 2**255;
    }

    function numMessagesSigned(bytes32 _message) public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("numMessagesSigned", _message))];
    }

    function requiredMessageLength() public pure returns(uint256) {
        return Message.requiredMessageLength();
    }

    function affirmationWithinLimits(uint256) internal view returns(bool) {
        return true;
    }

    function onFailedAffirmation(address, uint256, bytes32) internal {
    }
}

contract ERC677Bridge is BasicBridge {
    function erc677token() public view returns(IBurnableMintableERC677Token) {
        return IBurnableMintableERC677Token(addressStorage[keccak256(abi.encodePacked("erc677token"))]);
    }

    function setErc677token(address _token) internal {
        require(_token != address(0) && isContract(_token));
        addressStorage[keccak256(abi.encodePacked("erc677token"))] = _token;
    }

    function onTokenTransfer(address _from, uint256 _value, bytes /*_data*/) external returns(bool) {
        require(msg.sender == address(erc677token()));
        require(withinLimit(_value));
        setTotalSpentPerDay(getCurrentDay(), totalSpentPerDay(getCurrentDay()).add(_value));
        erc677token().burn(_value);
        fireEventOnTokenTransfer(_from, _value);
        return true;
    }

    function fireEventOnTokenTransfer(address /*_from */, uint256 /* _value */) internal {
        // has to be defined
    }

}



contract OverdrawManagement is EternalStorage, OwnedUpgradeability {
    using SafeMath for uint256;

    event UserRequestForSignature(address recipient, uint256 value);

    function fixAssetsAboveLimits(bytes32 txHash, bool unlockOnForeign) external onlyIfOwnerOfProxy {
        require(!fixedAssets(txHash));
        address recipient;
        uint256 value;
        (recipient, value) = txAboveLimits(txHash);
        require(recipient != address(0) && value > 0);
        setOutOfLimitAmount(outOfLimitAmount().sub(value));
        if (unlockOnForeign) {
            emit UserRequestForSignature(recipient, value);
        }
        setFixedAssets(txHash, true);
    }

    function outOfLimitAmount() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("outOfLimitAmount"))];
    }

    function fixedAssets(bytes32 _txHash) public view returns(bool) {
        return boolStorage[keccak256(abi.encodePacked("fixedAssets", _txHash))];
    }

    function setOutOfLimitAmount(uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("outOfLimitAmount"))] = _value;
    }

    function txAboveLimits(bytes32 _txHash) internal view returns(address recipient, uint256 value) {
        recipient = addressStorage[keccak256(abi.encodePacked("txOutOfLimitRecipient", _txHash))];
        value = uintStorage[keccak256(abi.encodePacked("txOutOfLimitValue", _txHash))];
    }

    function setTxAboveLimits(address _recipient, uint256 _value, bytes32 _txHash) internal {
        addressStorage[keccak256(abi.encodePacked("txOutOfLimitRecipient", _txHash))] = _recipient;
        uintStorage[keccak256(abi.encodePacked("txOutOfLimitValue", _txHash))] = _value;
    }

    function setFixedAssets(bytes32 _txHash, bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("fixedAssets", _txHash))] = _status;
    }
}



contract FeeManager is EternalStorage, Ownable {
    using SafeMath for uint256;

    event FeePercentChanged(uint newFeePercent);

    function setFeePercent(uint256 _feePercent) public onlyOwner {
        require(_feePercent < 10000, "Invalid fee percent");
        uintStorage[keccak256(abi.encodePacked("feePercent"))] = _feePercent;
        emit FeePercentChanged(_feePercent);
    }

    function feePercent() public view returns(uint256) {
        return uintStorage[keccak256(abi.encodePacked("feePercent"))];
    }

    function subtractFee(uint _value) public view returns(uint256) {
        uint256 fullPercent = 10000;
        return _value.sub(_value.mul(feePercent()).div(fullPercent));
    }
}


contract HomeBridgeErcToErc is ERC677Receiver, EternalStorage, BasicBridge, BasicHomeBridge, ERC677Bridge, OverdrawManagement, FeeManager {

    event AmountLimitExceeded(address recipient, uint256 value, bytes32 transactionHash);

    function initialize (
        address _validatorContract,
        uint256 _dailyLimit,
        uint256 _maxPerTx,
        uint256 _minPerTx,
        uint256 _homeGasPrice,
        uint256 _requiredBlockConfirmations,
        address _erc677token,
        uint256 _foreignDailyLimit,
        uint256 _foreignMaxPerTx,
        address _owner,
        uint256 _feePercent
    ) public
      returns(bool)
    {
        require(!isInitialized());

        require(_feePercent < 10000, "Invalid fee percent");
        addressStorage[keccak256(abi.encodePacked("validatorContract"))] = _validatorContract;
        uintStorage[keccak256(abi.encodePacked("deployedAtBlock"))] = block.number;
        uintStorage[keccak256(abi.encodePacked("dailyLimit"))] = _dailyLimit;
        uintStorage[keccak256(abi.encodePacked("maxPerTx"))] = _maxPerTx;
        uintStorage[keccak256(abi.encodePacked("minPerTx"))] = _minPerTx;
        uintStorage[keccak256(abi.encodePacked("gasPrice"))] = _homeGasPrice;
        uintStorage[keccak256(abi.encodePacked("requiredBlockConfirmations"))] = _requiredBlockConfirmations;
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit"))] = _foreignDailyLimit;
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx"))] = _foreignMaxPerTx;
        uintStorage[keccak256(abi.encodePacked("feePercent"))] = _feePercent;
        setOwner(_owner);
        setInitialize(true);
        setErc677token(_erc677token);

        return isInitialized();
    }

    function getBridgeMode() public pure returns(bytes4 _data) {
        return bytes4(keccak256(abi.encodePacked("erc-to-erc-core")));
    }

    function () payable public {
        revert();
    }

    function onExecuteAffirmation(address _recipient, uint256 _value) internal  returns(bool) {
        setTotalExecutedPerDay(getCurrentDay(), totalExecutedPerDay(getCurrentDay()).add(_value));
        if (feePercent() == 0) {
            return erc677token().mint(_recipient, _value);
        } else {
            uint256 userValue = subtractFee(_value);
            address[] memory validators = validatorContract().validatorsList();
            uint256 entireValidatorValue = _value.sub(userValue);
            uint256 particularValidatorValue = entireValidatorValue.div(validators.length);
            for(uint256 i = 0; i < validators.length - 1; i++) {
                erc677token().mint(validators[i], particularValidatorValue);
            }
            uint256 lastValidatorValue = entireValidatorValue.sub(
                particularValidatorValue.mul(validators.length.sub(1))
            );
            erc677token().mint(validators[validators.length - 1], lastValidatorValue);
            return erc677token().mint(_recipient, userValue);
        }

    }

    function fireEventOnTokenTransfer(address _from, uint256 _value) internal {
        emit UserRequestForSignature(_from, _value);
    }

    function affirmationWithinLimits(uint256 _amount) internal view returns(bool) {
        return withinExecutionLimit(_amount);
    }

    function onFailedAffirmation(address _recipient, uint256 _value, bytes32 _txHash) internal {
        address recipient;
        uint256 value;
        (recipient, value) = txAboveLimits(_txHash);
        require(recipient == address(0) && value == 0);
        setOutOfLimitAmount(outOfLimitAmount().add(_value));
        setTxAboveLimits(_recipient, _value, _txHash);
        emit AmountLimitExceeded(_recipient, _value, _txHash);
    }
}