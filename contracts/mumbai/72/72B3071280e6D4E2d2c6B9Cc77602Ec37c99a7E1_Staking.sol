// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

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

    struct AccountStakingInfo {
        address addr;
        uint256 amount;
        Status state;
        uint256 timeLock;
    }

    using Address for address;

    // Parameters
    uint128 public constant VALIDATOR_THRESHOLD = 10000000000000000000; // 10 ether
    uint128 public constant PERCENTAGE_TOKEN_SLASHING = 25; // 25%
    uint128 public constant SUSPEND_DURATION = 7200; // 7200 blocks = 12 hours 
    uint128 public constant BAN_DURATION = 433200; // 433200 blocks = 30 days
    uint8 public constant COUNTER_SUSPEND = 3;
    uint64 public constant MAXIMUM_VALIDATORSUBSET_SIZE = 27;
    uint64 public constant MINIMUM_VALIDATORSUBSET_SIZE = 4;
    uint64 public constant EPOCH_SIZE = 15;

    // Properties
    address[] public _validators;

    mapping(address => bool) public _addressToIsValidator;
    mapping(address => uint256) public _addressToStakedAmount;
    mapping(address => uint256) public _addressToValidatorIndex;
   
    uint256 public _stakedAmount;
    uint256 public _minimumNumValidators;
    uint256 public _maximumNumValidators;
    
    mapping(address => bytes) public _addressToBLSPublicKey;
    mapping(address => AccountStakingInfo) public _validatorsState;
    uint8[MAXIMUM_VALIDATORSUBSET_SIZE] public _validatorSubsetCounter;
    

    // withdrawal address part
    mapping(address => address) public _addressToSignerAddress; // from staker -> signer/validator
    mapping(address => address) public _addressToStakerAddress; // from signer/validator -> staker
    mapping(address => bool) public _addressToIsStaker; // is staker address
    mapping(address => bool) public _addressToIsSigner; // is signer address

    // proposer delegation
    uint128 public constant DELEGATION_THRESHOLD = 100000000000000000; // 0.1 ether
    struct DelegatorInfo {
        mapping(address => uint256) validatorToStakedAmount;
        mapping(address => uint256) delegatorIndex;
        mapping(address => bool) isDelegatorOfValidator;
    }
    uint256 public _minimumNumDelegators = 0;
    uint256 public _maximumNumDelegators = 100;
    mapping(address => DelegatorInfo) private _addressToDelegatorInfo;
    mapping(address => address[]) public _addressToDelegators;

    // Events
    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event BLSPublicKeyRegistered(address indexed accout, bytes key);

    event Ban(address indexed account, uint256 blockNumber, uint256 timeLock, uint256 tokenSlashing);

    event Suspended(address indexed account, uint256 blockNumber, uint256 timeLock, uint64 suspendCounter);

    event Warning(address indexed account, uint256 blockNumber, string message);

    event DelegatorStaked(address indexed account, address indexed validator, uint256 amount);

    event DelegatorUnstaked(address indexed account, uint256 amount);

    // Modifiers
    modifier onlyEOA() {
        require(!msg.sender.isContract(), "Only EOA can call function");
        _;
    }

    modifier onlyStaker() {
        require(
            _isStaker(msg.sender) ||
            _addressToStakedAmount[msg.sender] > 0,
            "Only staker can call function"
        );
        _;
    }

    modifier onlyBlockProposer() {
        require(msg.sender == block.coinbase, "Only block proposer can call function");
        _;
    }

    modifier onlyDelegator(address signer) {
        require(
            _addressToDelegatorInfo[msg.sender].validatorToStakedAmount[signer] > 0,
            "only delegator can call function"
        );
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
        return _validators;
    }

    function validatorBLSPublicKeys() public view returns (bytes[] memory) {
        bytes[] memory keys = new bytes[](_validators.length);

        for (uint64 i = 0; i < _validators.length; i++) {
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

    // Get staked amount with all validators' address
    function getValidatorsStakeInfo() public view returns (AccountStakingInfo[] memory) {
        AccountStakingInfo[] memory rs = new AccountStakingInfo[](_validators.length);
        for (uint64 i = 0; i < _validators.length; i++) {
            uint256 timeLock = _validatorsState[_validators[i]].timeLock;
            Status state = _validatorsState[_validators[i]].state;
            AccountStakingInfo memory valInfo = AccountStakingInfo(_validators[i], _addressToStakedAmount[_validators[i]], state, timeLock);
            rs[i] = valInfo;
        }
        return rs;
    }

    function getValidatorsSubsetTimeout() public view returns (uint8[] memory) {
        uint64 length = MAXIMUM_VALIDATORSUBSET_SIZE;
        uint8[] memory rs = new uint8[](length);
        for (uint64 i = 0; i < length; i ++) {
            rs[i] = _validatorSubsetCounter[i];
        }
        return rs;
    }

    function resetValidatorsSubsetTimeout() public onlyBlockProposer {
        for (uint64 i = 0; i < MAXIMUM_VALIDATORSUBSET_SIZE; i ++) {
            _validatorSubsetCounter[i] = 0;
        }
    }


    // Public functions
    receive() external payable onlyEOA {
        _stake();
    }

    function stake() public payable onlyEOA {
        _stake();
    }

    function unstake() public onlyEOA onlyStaker {
        _unstake();
    }

    function ban(address badValidator, uint64 lengthValidatorSubset) public onlyBlockProposer  {
        _ban(badValidator, lengthValidatorSubset);
    }

    function suspend(uint256 indexValidator, address badValidator, uint8 count) public onlyBlockProposer {
        _validatorSubsetCounter[indexValidator] = count;
        if (_validatorSubsetCounter[indexValidator] >= COUNTER_SUSPEND) {
            _suspend(badValidator);
        }
        emit Suspended(badValidator, block.number, _validatorsState[badValidator].timeLock, _validatorSubsetCounter[indexValidator]);
    }

    function warning(address badValidator) public onlyBlockProposer {
        emit Warning(badValidator, block.number, "timeout");
    }

    function registerBLSPublicKey(bytes memory blsPubKey) public {
        _addressToBLSPublicKey[msg.sender] = blsPubKey;

        emit BLSPublicKeyRegistered(msg.sender, blsPubKey);
    }

    // function to check state of every validator in validatorsList.This function runs every epoch
    function checkStateValidators() public {
        uint256 blockPresent = block.number;

        for (uint64 i = 0; i < _validators.length; i++) {
            uint256 timeLock = _validatorsState[_validators[i]].timeLock;
            Status state = _validatorsState[_validators[i]].state;
            //check if state == "suspend"
            if (state == Status.Suspend || state == Status.Ban) {
                if (blockPresent >= timeLock) {
                    //reset timeLock
                    _validatorsState[_validators[i]].timeLock = 0;
                    // update state == "pause"
                    _validatorsState[_validators[i]].state = Status.Pause;                         
                }
            }
            //check if state == "unstake"
            if (state == Status.Unstake) {
                // withdraw token
                _withdraw(_validators[i]);
            }
        }
    }

    // Private functions
    function _stake() private {
        (, address signer) = _getStakerAndSigner();
        uint256 timeLock = _validatorsState[signer].timeLock;
        uint256 blockPresent = block.number;
        require (timeLock < blockPresent, "staker is banned or suspended");

        _stakedAmount += msg.value;
        _addressToStakedAmount[signer] += msg.value;

        if (_canBecomeValidator(signer)) {
            _appendToValidatorSet(signer);
        }

        emit Staked(signer, msg.value);
    }

    function _unstake() private {
        (address staker, address signer) = _getStakerAndSigner();

        uint256 timeLock = _validatorsState[signer].timeLock;
        uint256 blockPresent = block.number;
        require (timeLock < blockPresent, "staker is banned or suspended");

        _addressToIsStaker[staker] = false;
        _addressToIsSigner[signer] = false;
        _addressToSignerAddress[staker] = address(0);
        _addressToStakerAddress[signer] = address(0);
        //state = unstake
        _validatorsState[signer].state = Status.Unstake;
    }

    function _ban(address badValidator, uint64 lengthValidatorSubset) private {
        // add co check max validator subset size
        if (lengthValidatorSubset > MINIMUM_VALIDATORSUBSET_SIZE && lengthValidatorSubset <= MAXIMUM_VALIDATORSUBSET_SIZE) {
            //set state == "ban"
            _validatorsState[badValidator].state = Status.Ban;
            //set the time start to suspend validators
            _validatorsState[badValidator].timeLock = block.number + BAN_DURATION;
        }

        //slashing token of validator
        uint256 amount= _addressToStakedAmount[badValidator];
        uint256 amountTokenSlashing = (amount * PERCENTAGE_TOKEN_SLASHING) / 100;
        _addressToStakedAmount[badValidator] = amount - amountTokenSlashing;
        _stakedAmount -= amountTokenSlashing;

        address[] memory delegatorInfo = _addressToDelegators[badValidator];
        if (_addressToDelegators[badValidator].length > 0) {
            //slashing token of delegator
            for (uint64 i = 0; i < _addressToDelegators[badValidator].length; i++) {
                uint256 amountDelegator = _addressToDelegatorInfo[delegatorInfo[i]].validatorToStakedAmount[badValidator];
                uint256 amountDelegatorSlashing = (amountDelegator * PERCENTAGE_TOKEN_SLASHING) / 100;
                _addressToDelegatorInfo[delegatorInfo[i]].validatorToStakedAmount[badValidator] = amountDelegator - amountDelegatorSlashing;
                _stakedAmount -= amountDelegatorSlashing;
            }
        }

        emit Ban(badValidator, block.number, _validatorsState[badValidator].timeLock, amountTokenSlashing);
    }

    function _suspend(address badValidator) private {
        //set state == "suspend"
        _validatorsState[badValidator].state = Status.Suspend;
        //update timeLock
        _validatorsState[badValidator].timeLock = block.number + SUSPEND_DURATION;
    }

    function _withdraw(address validator) private {
        uint256 amount = _addressToStakedAmount[validator];
        _addressToStakedAmount[validator] = 0 ;
        _stakedAmount -= amount;
        
        if (_isValidator(validator)) {
            _deleteFromValidators(validator);
        }
        payable(validator).transfer(amount);

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
        _validatorsState[newValidator].state = Status.Stake;
        _validatorsState[newValidator].timeLock = 0;
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

    function stake(address signer) public payable onlyEOA {
        _stake(signer);
    }

    // Signer and Staker addresses must not already be used by any other stake as either Signer or Staker roles
    function _stake(address signer) private {
        uint256 timeLock = _validatorsState[signer].timeLock;
        uint256 blockPresent = block.timestamp;
        require (timeLock < blockPresent, "staker is banned or suspended");

        // if both signer and staker are valid
        if (_isStaker(msg.sender) && _isSigner(signer)) {
            require(
                _addressToSignerAddress[msg.sender] == signer &&
                _addressToStakerAddress[signer] == msg.sender,
                "the sender is not a valid staker of this signer"
            );
        } else {
            require(
                !_isStaker(msg.sender) && !_isStaker(signer) &&
                !_isSigner(signer) && !_isSigner(msg.sender) &&
                _addressToStakedAmount[msg.sender] == 0 &&
                _addressToStakedAmount[signer] == 0,
                "both addresses are not valid to call function. If you still want to call. Just calling unstake for both accounts manually"
            );
        }

        _addressToIsStaker[msg.sender] = true;
        _addressToIsSigner[signer] = true;
        _addressToSignerAddress[msg.sender] = signer;
        _addressToStakerAddress[signer] = msg.sender;

        _stakedAmount += msg.value;
        _addressToStakedAmount[signer] += msg.value;

        if (_canBecomeValidator(signer)) {
            _appendToValidatorSet(signer);
        }

        emit Staked(msg.sender, msg.value);
    }

    function _isStaker(address account) private view returns (bool) {
        return _addressToIsStaker[account];
    }

    function _isSigner(address account) private view returns (bool) {
        return _addressToIsSigner[account];
    }

    function _getStakerAndSigner() private view returns (address, address) {
        address staker = msg.sender;
        address signer = msg.sender;
        // if address is either signer or staker called this function
        // signer and staker were determined if the address had called stake(signer)
        // otherwise both staker and signer are the same account
        if (_isStaker(msg.sender)) {
            signer = _addressToSignerAddress[msg.sender];
        } else if (_isSigner(msg.sender)) {
            staker = _addressToStakerAddress[msg.sender];
        }
        return (staker, signer);
    }

    // ================================================================================================
    // proposer delegation parts
    function delegate(address signer) public payable onlyEOA {
        _delegate(signer);
    }

    function delegatorUnstake(address signer) public onlyEOA onlyDelegator(signer) {
        _delegatorUnstake(msg.sender, signer);
    }

    function getDelegatedAmount(address account, address signer) public view returns (uint256) {
        return _addressToDelegatorInfo[account].validatorToStakedAmount[signer];
    }

    function getTotalDelegatorOfValidator(address account) public view returns (uint256) {
        return _addressToDelegators[account].length;
    }

    function getDelegatorsInfoOfValidator(address signer) public view returns (AccountStakingInfo[] memory) {
        uint256 _size = _addressToDelegators[signer].length;
        AccountStakingInfo[] memory rs = new AccountStakingInfo[](_size);
        for (uint64 i = 0; i < _size; i++) {
            address delegatorAccount = _addressToDelegators[signer][i];
            uint256 delegatedAmount = _addressToDelegatorInfo[delegatorAccount].validatorToStakedAmount[signer];
            // Note: need to add variables state & timeLock
            Status state = _validatorsState[signer].state;
            uint256 timeLock = _validatorsState[signer].timeLock;
            AccountStakingInfo memory valInfo = AccountStakingInfo(delegatorAccount, delegatedAmount, state, timeLock);
            rs[i] = valInfo;
        }
        return rs;
    }

    // private functions

    function _delegate(address signer) private {
        require(_isValidator(signer), "cannot delegate tokens to someone who is not validator");

        _stakedAmount += msg.value;
        _addressToDelegatorInfo[msg.sender].validatorToStakedAmount[signer] += msg.value;

        if (_canBecomeDelegator(msg.sender, signer)) {
            _appendToDelegatorSet(msg.sender, signer);
        }

        emit DelegatorStaked(msg.sender, signer, msg.value);
    }

    function _delegatorUnstake(address account, address signer) private {
        uint256 amount = _addressToDelegatorInfo[account].validatorToStakedAmount[signer];

        _addressToDelegatorInfo[account].validatorToStakedAmount[signer] = 0;
        _stakedAmount -= amount;

        if (_isDelegator(account, signer)) {
            _deleteFromDelegatorsOfValidator(account, signer);
        }

        payable(account).transfer(amount);
        emit DelegatorUnstaked(account, amount);
    }

    function _deleteFromDelegatorsOfValidator(address account, address signer) private {
        require(
            _addressToDelegators[signer].length > _minimumNumDelegators,
            "delegators size can't be less than the minimum requirement"
        );

        require(
            _addressToDelegatorInfo[account].delegatorIndex[signer] < _addressToDelegators[signer].length,
            "index out of range in the delegators list of validator"
        );

        // index of removed address
        uint256 index = _addressToDelegatorInfo[account].delegatorIndex[signer];
        uint256 lastIndex = _addressToDelegators[signer].length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = _addressToDelegators[signer][lastIndex];
            _addressToDelegators[signer][index] = lastAddr;
            _addressToDelegatorInfo[lastAddr].delegatorIndex[signer] = index;
        }

        _addressToDelegatorInfo[account].isDelegatorOfValidator[signer] = false;
        _addressToDelegatorInfo[account].delegatorIndex[signer] = 0;
        _addressToDelegators[signer].pop();
    }

    function _appendToDelegatorSet(address account, address signer) private {
        require(
            _addressToDelegators[signer].length < _maximumNumDelegators,
            "delegator set has reached its full capacity"
        );

        _addressToDelegatorInfo[account].isDelegatorOfValidator[signer] = true;
        _addressToDelegatorInfo[account].delegatorIndex[signer] = _addressToDelegators[signer].length;
        _addressToDelegators[signer].push(account);
    }

    function _isDelegator(address account, address signer) private view returns (bool) {
        return _addressToDelegatorInfo[account].isDelegatorOfValidator[signer];
    }

    function _canBecomeDelegator(address account, address signer) private view returns (bool) {
        return
        !_isDelegator(account, signer) &&
        _addressToDelegatorInfo[account].validatorToStakedAmount[signer] >= DELEGATION_THRESHOLD;
    }

    function _unstakeAllDelegators(address signer) private {
        uint256 _size = _addressToDelegators[signer].length;
        for (uint64 i = 0; i < _size;) {
            _delegatorUnstake(_addressToDelegators[signer][i], signer);
            _size--;
            if (_size == 0) {
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}