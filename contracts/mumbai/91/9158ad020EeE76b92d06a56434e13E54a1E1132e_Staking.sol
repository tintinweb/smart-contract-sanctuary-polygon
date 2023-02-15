// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";

contract Staking {
    // Enum representing shipping status
    enum Status {
        Empty,
        Stake,
        Unstake,
        Suspend,
        Ban,
        Pause
    }

    struct AddressStakeInfo {
        address addr;
        uint256 amount;
        Status state;
        uint256 timeLock;
    }

    using Address for address;

    // Parameters
    uint128 public constant VALIDATOR_THRESHOLD = 0.0001 ether;
    uint128 public constant DELEGATION_THRESHOLD = 0.00001 ether;
    uint128 public constant PERCENTAGE_TOKEN_SLASHING = 25; // 25%
    uint128 public constant SUSPEND_DURATION = 10800; // 3 hours = 3 * 60 * 60 = 10800 (s)
    uint128 public constant BAN_DURATION = 2592000; // 30 days = 30 * 24 * 60 * 60 = 2592000 (s)
    uint128 public constant SUSPEND_THRESHOLD = 3;

    // Properties
    address[] public _validators;

    mapping(address => bool) public _addressToIsValidator;
    mapping(address => uint256) public _addressToStakedAmount;
    mapping(address => uint256) public _addressToValidatorIndex;
    uint256 public _stakedAmount;
    uint256 public _minimumNumValidators;
    uint256 public _maximumNumValidators;

    mapping(address => bytes) public _addressToBLSPublicKey;
    mapping(address => AddressStakeInfo) public _validatorsState;
    mapping(address => uint256) public suspendCounter;

    // withdrawal address (This can only be changed once after becoming validator)
    mapping(address => address) public _addressToWithdrawalAddress;
    mapping(address => bool) public _didChangeWithdrawalAddress;

    // proposer delegation
    struct DelegatorInfo {
        mapping(address => uint256) validatorToStakedAmount;
        mapping(address => uint256) delegatorIndex;
        mapping(address => bool) isSupportingValidator;
        Status state;
        uint256 timeLock;
    }

    struct DelegatorUnstakeInfo {
        address signer;
        address validator;
    }

    uint256 public _minimumNumDelegators = 0;
    uint256 public _maximumNumDelegators = 100;
    DelegatorUnstakeInfo[] private _addressToDelegatorUnstake;
    mapping(address => DelegatorInfo) private _addressToDelegatorInfo;
    mapping(address => address[]) public _addressToDelegators;

    // Events
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event Suspended(address indexed account, uint256 blockNumber, uint256 timeLock, uint256 numberOfSuspend);

    event Ban(address indexed account, uint256 blockNumber, uint256 timeLock, uint256 tokenSlashing);

    event BLSPublicKeyRegistered(address indexed accout, bytes key);

    event DelegatorStaked(address indexed account, address indexed validator, uint256 amount);

    event DelegatorUnstaked(address indexed account, uint256 amount);

    // Modifiers
    modifier onlyEOA() {
        require(!msg.sender.isContract(), "Only EOA can call function");
        _;
    }

    modifier onlyStaker() {
        require(
            _addressToStakedAmount[msg.sender] > 0,
            "Only staker can call function"
        );
        _;
    }

    modifier onlyBlockCreator() {
        require(msg.sender == block.coinbase, "Only block proposer can call function");
        _;
    }

    constructor(uint256 minNumValidators, uint256 maxNumValidators) {
        require(
            minNumValidators <= maxNumValidators,
            "Min validators num can not be greater than max num of validators"
        );
        _minimumNumValidators = minNumValidators;
        _maximumNumValidators = maxNumValidators;
    }

    // View functions
    function stakedAmount() public view returns (uint256) {
        return _stakedAmount;
    }

    function validators() public view returns (address[] memory) {
        uint256 counterValidatorsActive = 0;
        uint256 index = 0;

        for (uint256 i = 0; i < _validators.length; i++) {
            Status state = _validatorsState[_validators[i]].state;
            //if present state : empty or stake
            if (state == Status.Empty|| state == Status.Stake) {
                counterValidatorsActive ++;
            }
        }

        address[] memory _vlds = new address[](counterValidatorsActive);
        for (uint256 i = 0; i < _validators.length; i++) {
            Status state = _validatorsState[_validators[i]].state;
            //if present state : empty or stake
            if (state == Status.Empty || state == Status.Stake) {
                _vlds[index] = _validators[i];
                index ++;
            }
        }
        return _vlds;
    }

    function validatorBLSPublicKeys() public view returns (bytes[] memory) {
        bytes[] memory keys = new bytes[](_validators.length);

        for (uint256 i = 0; i < _validators.length; i++) {
            keys[i] = _addressToBLSPublicKey[_validators[i]];
        }

        return keys;
    }

    function isValidator(address addr) public view returns (bool) {
        return _addressToIsValidator[addr];
    }

    function accountStake(address addr) public view returns (uint256) {
        return _addressToStakedAmount[addr];
    }

    function minimumNumValidators() public view returns (uint256) {
        return _minimumNumValidators;
    }

    function maximumNumValidators() public view returns (uint256) {
        return _maximumNumValidators;
    }

    // Public functions
    receive() external payable onlyEOA {
        _stake();
    }

    function stake() public payable onlyEOA {
        uint256 timeLock = _validatorsState[msg.sender].timeLock;
        uint256 timeNow = block.timestamp;
        require (timeLock < timeNow, "staker is banned or suspended");
        _stake();
        // update state == "stake"
        _validatorsState[msg.sender].state = Status.Stake;
    }

    function unstake() public onlyEOA onlyStaker {
        uint256 timeLock = _validatorsState[msg.sender].timeLock;
        uint256 timeNow = block.timestamp;
        require (timeLock < timeNow, "staker is banned or suspended");
        // update state == "unstake"
        _validatorsState[msg.sender].state = Status.Unstake;
    }

    function suspend(address badValidator) public onlyBlockCreator  {
        // update state == "suspend"
        _validatorsState[badValidator].state = Status.Suspend;
        //set the time start to suspend validators
        _validatorsState[badValidator].timeLock = block.timestamp + SUSPEND_DURATION;
        // count the number of suspends
        suspendCounter[badValidator] ++;
        emit Suspended(badValidator, block.number, _validatorsState[badValidator].timeLock, suspendCounter[badValidator]);

    }

    function ban(address badValidator) public onlyBlockCreator  {
        _ban(badValidator);
        _validatorsState[badValidator].state = Status.Ban;
        //set the time start to suspend validators
        _validatorsState[badValidator].timeLock = block.timestamp + BAN_DURATION;
    }

    function registerBLSPublicKey(bytes memory blsPubKey) public {
        _addressToBLSPublicKey[msg.sender] = blsPubKey;

        emit BLSPublicKeyRegistered(msg.sender, blsPubKey);
    }

    // function to check state of every validator in validatorsList.This function runs every epoch
    function checkStateValidators() public onlyBlockCreator {
        uint256 timeNow = block.timestamp;

        for (uint256 i = 0; i < _validators.length; i++) {
            uint256 timeLock = _validatorsState[_validators[i]].timeLock;
            Status state = _validatorsState[_validators[i]].state;
            //check if state == "suspend" or "ban"
            if (state == Status.Suspend || state == Status.Ban) {
                
                if (timeNow >= timeLock) {
                    //reset timeLock
                    _validatorsState[_validators[i]].timeLock = 0;
                    // update state == "pause"
                    _validatorsState[_validators[i]].state = Status.Pause;          
                }
                
                // exceed the allowed number of suspends
                if (suspendCounter[_validators[i]] == SUSPEND_THRESHOLD) {
                    _deleteFromValidators(_validators[i]);
                    // reset counter
                    suspendCounter[_validators[i]] = 0; 

                }
            } 
            // check if state == "unstake"
            if (state == Status.Unstake) {
                // withdraw token
                _withdraw(_validators[i]);
            }
        }
    }

    // Get staked amount with all validators' address
    function getValidatorsStakeInfo() public view returns (AddressStakeInfo[] memory) {
        AddressStakeInfo[] memory rs = new AddressStakeInfo[](_validators.length);
        for (uint256 i = 0; i < _validators.length; i++) {
            Status state = _validatorsState[_validators[i]].state;
            uint256 timeLock = _validatorsState[_validators[i]].timeLock;
            uint256 amount =  _addressToStakedAmount[_validators[i]];
            AddressStakeInfo memory addressStakeInfo = AddressStakeInfo(_validators[i], amount, state, timeLock);
            rs[i] = addressStakeInfo;
        }
        return rs;
    }


    // Private functions
    function _stake() private {
        _stakedAmount += msg.value;
        _addressToStakedAmount[msg.sender] += msg.value;

        if (_canBecomeValidator(msg.sender)) {
            _appendToValidatorSet(msg.sender);
        }
        
        emit Staked(msg.sender, msg.value);
    }

    function _ban(address badValidator) private {
        uint256 amount = _addressToStakedAmount[badValidator];
        //slashing a part of token
        uint256 amountTokenSlashing = (amount * PERCENTAGE_TOKEN_SLASHING) / 100;
        _addressToStakedAmount[badValidator] = amount - amountTokenSlashing;
        _stakedAmount -= amountTokenSlashing;

        emit Ban(badValidator, block.number, _validatorsState[badValidator].timeLock, amountTokenSlashing);
    }

    function _withdraw(address validator) private {
        uint256 amount = _addressToStakedAmount[validator];
        bool hasWithdrawalAddress = _didChangeWithdrawalAddress[validator];

        _addressToStakedAmount[validator] = 0 ;
        _stakedAmount -= amount;
        
        if (_isValidator(validator)) {
            _deleteFromValidators(validator);

            // reset changing withdrawal flag
            _didChangeWithdrawalAddress[validator] = false;
        }
        if (hasWithdrawalAddress) {
            payable(_addressToWithdrawalAddress[validator]).transfer(amount);
        } else {
            payable(validator).transfer(amount);
        }

        emit Unstaked(validator, amount);
        
    }

    function _deleteFromValidators(address staker) private {
        require(
            _validators.length > _minimumNumValidators,
            "Validators can't be less than the minimum required validator num"
        );

        require(
            _addressToValidatorIndex[staker] < _validators.length,
            "index out of range"
        );

        // index of removed address
        uint256 index = _addressToValidatorIndex[staker];
        uint256 lastIndex = _validators.length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _validators[lastIndex];
            _validators[index] = lastAddr;
            _addressToValidatorIndex[lastAddr] = index;
        }

        _addressToIsValidator[staker] = false;
        _addressToValidatorIndex[staker] = 0;
        _validators.pop();
    }

    function _appendToValidatorSet(address newValidator) private {
        require(
            _validators.length < _maximumNumValidators,
            "Validator set has reached full capacity"
        );

        _addressToIsValidator[newValidator] = true;
        _addressToValidatorIndex[newValidator] = _validators.length;
        _validators.push(newValidator);
    }

    function _isValidator(address account) private view returns (bool) {
        return _addressToIsValidator[account];
    }

    function _canBecomeValidator(address account) private view returns (bool) {
        return
        !_isValidator(account) &&
        _addressToStakedAmount[account] >= VALIDATOR_THRESHOLD;
    }


    // ================================================================================================
    // withdrawal part
    function setWithdrawalAddress(address withdrawal) public onlyEOA {
        require(_isValidator(msg.sender), "only validator account can call this function");
        require(!_didChangeWithdrawalAddress[msg.sender], "account has already changed withdrawal address before");

        _didChangeWithdrawalAddress[msg.sender] = true;
        _addressToWithdrawalAddress[msg.sender] = withdrawal;
    }


    // ================================================================================================
    // proposer delegation parts
    function delegateTokens(address validatorAccount) public payable onlyEOA {
        _delegateTo(validatorAccount);
    }

    function delegatorUnstake(address validatorAccount) public onlyEOA {
        _delegatorUnstake(validatorAccount);
    }

    function getDelegatedAmountFrom(address account, address validatorAccount) public view returns (uint256) {
        return _addressToDelegatorInfo[account].validatorToStakedAmount[validatorAccount];
    }

    // function to check state of every delegator.This function runs every epoch
    function checkStateDelegators() public onlyBlockCreator {
        uint256 timeNow = block.timestamp;

        for (uint256 i = 0; i < _addressToDelegatorUnstake.length; i++) {
            address validatorAccount = _addressToDelegatorUnstake[i].validator;

            //check state validator account
            Status vldState = _validatorsState[validatorAccount].state;

            //update state delegator account
            address signer = _addressToDelegatorUnstake[i].signer;
            _addressToDelegatorInfo[signer].state = vldState;
            Status state = _addressToDelegatorInfo[signer].state;

            uint256 timeLock = _addressToDelegatorInfo[signer].timeLock;
            //check if state == "suspend" or "ban"
            if (state == Status.Suspend || state == Status.Ban) {
                if (timeNow >= timeLock) {
                    //reset timeLock
                    _addressToDelegatorInfo[signer].timeLock = 0;
                    //update state == "pause"
                    _addressToDelegatorInfo[signer].state = Status.Pause;
                }
            }
            // check if state == "unstake"
            if (state == Status.Unstake) {
                // withdraw token
                _delegatorWithdraw(signer, validatorAccount);
            }
        }
    }

    function getDelegatorsInfoOfValidator(address validatorAccount) public view returns (AddressStakeInfo[] memory) {
        uint256 _size = _addressToDelegators[validatorAccount].length;
        AddressStakeInfo[] memory rs = new AddressStakeInfo[](_size);
        for (uint256 i = 0; i < _size; i++) {
            address delegatorAccount = _addressToDelegators[validatorAccount][i];
            uint256 delegatedAmount = _addressToDelegatorInfo[delegatorAccount].validatorToStakedAmount[validatorAccount];
            Status state = _addressToDelegatorInfo[delegatorAccount].state;
            uint256 timeLock = _addressToDelegatorInfo[delegatorAccount].timeLock;
            AddressStakeInfo memory valInfo = AddressStakeInfo(delegatorAccount, delegatedAmount, state, timeLock);
            rs[i] = valInfo;
        }
        return rs;
    }

    // private functions

    function _delegateTo(address validatorAccount) private {
        require(_isValidator(validatorAccount), "cannot delegate tokens to someone who is not validator");
        uint256 timeLock = _validatorsState[validatorAccount].timeLock;
        uint256 timeNow = block.timestamp;
        require (timeLock < timeNow, "validator is banned or suspended");

        _addressToDelegatorInfo[msg.sender].state = _validatorsState[validatorAccount].state;
        _addressToDelegatorInfo[msg.sender].timeLock = timeLock;
        _stakedAmount += msg.value;

        _addressToDelegatorInfo[msg.sender].validatorToStakedAmount[validatorAccount] += msg.value;

        if (_canBecomeDelegator(msg.sender, validatorAccount)) {
            _appendToDelegatorSet(msg.sender, validatorAccount);
        }

        emit DelegatorStaked(msg.sender, validatorAccount, msg.value);
    }

    function _delegatorUnstake(address validatorAccount) private {
        require(
            _addressToDelegatorInfo[msg.sender].validatorToStakedAmount[validatorAccount] > 0,
            "only who staked can call function"
        );

        _addressToDelegatorInfo[msg.sender].state = Status.Unstake;
        _addressToDelegatorUnstake.push(DelegatorUnstakeInfo(msg.sender, validatorAccount));
    }

    function _delegatorWithdraw(address signer, address validatorAccount) private {
        uint256 amount = _addressToDelegatorInfo[signer].validatorToStakedAmount[validatorAccount];

        _addressToDelegatorInfo[signer].validatorToStakedAmount[validatorAccount] = 0;
        _stakedAmount -= amount;

        if (_isDelegator(signer, validatorAccount)) {
            _deleteFromDelegatorsOfValidator(signer, validatorAccount);
        }

        payable(signer).transfer(amount);
        
        emit DelegatorUnstaked(signer, amount);
    }

    function _deleteFromDelegatorsOfValidator(address account, address validatorAccount) private {
        require(
            _addressToDelegators[validatorAccount].length >= _minimumNumDelegators,
            "delegators can't be less than the minimum required"
        );

        require(
            _addressToDelegatorInfo[account].delegatorIndex[validatorAccount] < _addressToDelegators[validatorAccount].length,
            "index out of range in the delegators list of validator"
        );

        // index of removed address
        uint256 index = _addressToDelegatorInfo[account].delegatorIndex[validatorAccount];
        uint256 lastIndex = _addressToDelegators[validatorAccount].length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _addressToDelegators[validatorAccount][lastIndex];
            _addressToDelegators[validatorAccount][index] = lastAddr;
            _addressToDelegatorInfo[account].delegatorIndex[lastAddr] = index;
        }

        _addressToDelegatorInfo[account].isSupportingValidator[validatorAccount] = false;
        _addressToDelegatorInfo[account].delegatorIndex[validatorAccount] = 0;
        _addressToDelegators[validatorAccount].pop();
    }

    function _appendToDelegatorSet(address newDelegator, address validatorAccount) private {
        require(
            _addressToDelegators[validatorAccount].length < _maximumNumDelegators,
            "delegator set has reached full capacity"
        );

        _addressToDelegatorInfo[newDelegator].isSupportingValidator[validatorAccount] = true;
        _addressToDelegatorInfo[newDelegator].delegatorIndex[validatorAccount] = _addressToDelegators[validatorAccount].length;
        _addressToDelegators[validatorAccount].push(newDelegator);
    }

    function _isDelegator(address account, address validatorAccount) private view returns (bool) {
        return _addressToDelegatorInfo[account].isSupportingValidator[validatorAccount];
    }

    function _canBecomeDelegator(address account, address validatorAccount) private view returns (bool) {
        return !_addressToDelegatorInfo[account].isSupportingValidator[validatorAccount]
        && _addressToDelegatorInfo[account].validatorToStakedAmount[validatorAccount] >= DELEGATION_THRESHOLD;
    }
}