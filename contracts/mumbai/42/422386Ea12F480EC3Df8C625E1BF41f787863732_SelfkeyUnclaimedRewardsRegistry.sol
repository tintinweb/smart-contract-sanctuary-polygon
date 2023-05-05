// SPDX-License-Identifier: proprietary
pragma solidity >=0.8.0;

interface ISelfkeyUnclaimedRewardsRegistry {
    event SignerChanged(address indexed _address);
    event RewardRegistered(address indexed _account, uint _amount, string _scope, address _relying_party);
    event ClaimRegistered(address indexed _account, uint _amount, string _scope, address _relying_party);

    function setSignerAddress(address _signer) external;
    function registerReward(address _account, uint256 _amount, string memory _scope, address _relying_party, address _signer) external;
    function registerClaim(address _account, uint256 _amount, string memory _scope, address _relying_party) external;

    function earned(address _account) external view returns(uint);
    function claimed(address _account) external view returns(uint);
    function balanceOf(address _account) external view returns(uint);

    function earnedByScope(address _account, string memory _scope, address _relying_party) external view returns(uint);
    function claimedByScope(address _account, string memory _scope, address _relying_party) external view returns(uint);
    function balanceOfByScope(address _account, string memory _scope, address _relying_party) external view returns(uint);
}

// SPDX-License-Identifier: MIT
// @author Razzor https://twitter.com/razzor_tweet
pragma solidity 0.8.19;
     /**
     * @dev Contract defines a 2-step Access Control for the owner of the contract in order
     * to avoid risks. Such as accidentally transferring control to an undesired address or renouncing ownership.
     * The contracts mitigates these risks by using a 2-step process for ownership transfers and a time margin
     * to renounce ownership. The owner can propose the ownership to the new owner, and the pending owner can accept
     * the ownership in order to become the new owner. If an undesired address has been passed accidentally, Owner
     * can propose the ownership again to the new desired address, thus mitigating the risk of losing control immediately.
     * Also, an owner can choose to retain ownership if renounced accidentally prior to future renounce time.
     * The Owner can choose not to have this feature of time margin while renouncing ownership, by initialising _renounceInterval as 0.
     */
abstract contract SafeOwn{
    bool private isRenounced;
    address private _Owner;
    address private _pendingOwner;
    uint256 private _renounceTime;
    uint256 private _renounceInterval;

     /**
     * @dev Emitted when the Ownership is transferred or renounced. AtTime may hold
     * a future time value, if there exists a _renounceInterval > 0 for renounceOwnership transaction.
     */
    event ownershipTransferred(address indexed currentOwner, address indexed newOwner, uint256 indexed AtTime);
     /**
     * @dev Emitted when the Ownership is retained by the current Owner.
     */
    event ownershipRetained(address indexed currentOwner, uint256 indexed At);

     /**
     * @notice Initializes the Deployer as the Owner of the contract.
     * @param renounceInterval time in seconds after which the Owner will be removed.
     */

    constructor(uint256 renounceInterval){
        _Owner = msg.sender;
        _renounceInterval = renounceInterval;
        emit ownershipTransferred(address(0), _Owner, block.timestamp);
    }
     /**
     * @notice Throws if the caller is not the Owner.
     */

    modifier onlyOwner(){
        require(Owner() == msg.sender, "SafeOwn: Caller is the not the Owner");
        _;
    }

     /**
     * @notice Throws if the caller is not the Pending Owner.
     */

    modifier onlyPendingOwner(){
        require(_pendingOwner == msg.sender, "SafeOwn: Caller is the not the Pending Owner");
        _;
    }

     /**
     * @notice Returns the current Owner.
     * @dev returns zero address after renounce time, if the Ownership is renounced.
     */

    function Owner() public view virtual returns(address){
        if(block.timestamp >= _renounceTime && isRenounced){
            return address(0);
        }
        else{
            return _Owner;
        }
    }
     /**
     * @notice Returns the Pending Owner.
     */

    function pendingOwner() public view virtual returns(address){
        return _pendingOwner;
    }

     /**
     * @notice Returns the renounce parameters.
     * @return bool value determining whether Owner has called renounceOwnership or not.
     * @return Renounce Interval in seconds after which the Ownership will be renounced.
     * @return Renounce Time at which the Ownership was/will be renounced. 0 if Ownership retains.
     */
    function renounceParams() public view virtual returns(bool, uint256, uint256){
        return (isRenounced, _renounceInterval, _renounceTime);
    }
     /**
     * @notice Owner can propose ownership to a new Owner(newOwner).
     * @dev Owner can not propose ownership, if it has called renounceOwnership and
     * not retained the ownership yet.
     * @param newOwner address of the new owner to propose ownership to.
     */
    function proposeOwnership(address newOwner) public virtual onlyOwner{
        require(!isRenounced, "SafeOwn: Ownership has been Renounced");
        require(newOwner != address(0), "SafeOwn: New Owner can not be a Zero Address");
        _pendingOwner = newOwner;
    }

     /**
     * @notice Pending Owner can accept the ownership proposal and become the new Owner.
     */
    function acceptOwnership() public virtual onlyPendingOwner{
        address currentOwner = _Owner;
        address newOwner = _pendingOwner;
        _Owner = _pendingOwner;
        _pendingOwner = address(0);
        emit ownershipTransferred(currentOwner, newOwner, block.timestamp);
    }

     /**
     * @notice Owner can renounce ownership. Owner will be removed from the
     * contract after _renounceTime.
     * @dev Owner will be immediately removed if the _renounceInterval is 0.
     * @dev Pending Owner will be immediately removed.
     */
    function renounceOwnership() public virtual onlyOwner{
        require(!isRenounced, "SafeOwn: Already Renounced");
        if(_pendingOwner != address(0)){
             _pendingOwner = address(0);
        }
        _renounceTime = block.timestamp + _renounceInterval;
        isRenounced = true;
        emit ownershipTransferred(_Owner, address(0), _renounceTime);
    }

     /**
     * @notice Owner can retain its ownership and cancel the renouncing(if initiated
     * by Owner).
     */

    function retainOwnership() public virtual onlyOwner{
        require(isRenounced, "SafeOwn: Already Retained");
        _renounceTime = 0;
        isRenounced = false;
        emit ownershipRetained(_Owner, block.timestamp);
    }

}

// SPDX-License-Identifier: proprietary
pragma solidity 0.8.19;

import "./SafeOwn.sol";
import "./ISelfkeyUnclaimedRewardsRegistry.sol";

struct RewardEntry {
    uint256 timestamp;
    uint amount;
    string scope;
    address relying_party;
    address signer;
}

struct ClaimedEntry {
    uint256 timestamp;
    uint amount;
    string scope;
    address relying_party;
}

contract SelfkeyUnclaimedRewardsRegistry is SafeOwn, ISelfkeyUnclaimedRewardsRegistry {

    address public authorizedSigner;
    mapping(address => RewardEntry[]) private _rewardEntries;
    mapping(address => ClaimedEntry[]) private _claimedEntries;

    constructor(address _signer) SafeOwn(14400) {
        require(_signer != address(0), "Invalid authorized signer");
        authorizedSigner = _signer;
    }

    function setSignerAddress(address _signer) public onlyOwner {
        require(_signer != address(0), "Invalid authorized signer");
        authorizedSigner = _signer;
        emit SignerChanged(_signer);
    }

    function registerReward(address _account, uint256 _amount, string memory _scope, address _relying_party, address _signer) external {
        require(authorizedSigner == msg.sender, "Not authorized to register");
        _rewardEntries[_account].push(RewardEntry(block.timestamp, _amount, _scope, _relying_party, _signer));
        emit RewardRegistered(_account, _amount, _scope, _relying_party);
    }

    function registerClaim(address _account, uint256 _amount, string memory _scope, address _relying_party) external {
        require(authorizedSigner == msg.sender, "Not authorized to register");
        require(balanceOf(_account) >= _amount, "Not enough balance");
        _claimedEntries[_account].push(ClaimedEntry(block.timestamp, _amount, _scope, _relying_party));
        emit ClaimRegistered(_account, _amount, _scope, _relying_party);
    }

    function earned(address _account) public view returns(uint) {
        uint _balance = 0;
        RewardEntry[] memory _accountRecords = _rewardEntries[_account];
        for(uint i=0; i<_accountRecords.length; i++) {
            RewardEntry memory _record = _accountRecords[i];
            if (_record.timestamp <= block.timestamp) {
                _balance = _balance + _record.amount;
            }
        }
        return _balance;
    }

    function claimed(address _account) public view returns(uint) {
        uint _balance = 0;
        ClaimedEntry[] memory _accountRecords = _claimedEntries[_account];
        for(uint i=0; i<_accountRecords.length; i++) {
            ClaimedEntry memory _record = _accountRecords[i];
            if (_record.timestamp <= block.timestamp) {
                _balance = _balance + _record.amount;
            }
        }
        return _balance;
    }

    function balanceOf(address _account) public view returns(uint) {
        return earned(_account) - claimed(_account);
    }

    function earnedByScope(address _account, string memory _scope, address _relying_party) public view returns(uint) {
        uint _balance = 0;
        RewardEntry[] memory _accountRecords = _rewardEntries[_account];
        for(uint i=0; i<_accountRecords.length; i++) {
            RewardEntry memory _record = _accountRecords[i];
            if (_record.timestamp <= block.timestamp) {
                if (keccak256(abi.encodePacked(_scope)) == keccak256(abi.encodePacked(_record.scope)) && _relying_party == _record.relying_party) {
                    _balance = _balance + _record.amount;
                }
            }
        }
        return _balance;
    }

    function claimedByScope(address _account, string memory _scope, address _relying_party) public view returns(uint) {
        uint _balance = 0;
        ClaimedEntry[] memory _accountRecords = _claimedEntries[_account];
        for(uint i=0; i<_accountRecords.length; i++) {
            ClaimedEntry memory _record = _accountRecords[i];
            if (_record.timestamp <= block.timestamp) {
                if (keccak256(abi.encodePacked(_scope)) == keccak256(abi.encodePacked(_record.scope)) && _relying_party == _record.relying_party) {
                    _balance = _balance + _record.amount;
                }
            }
        }
        return _balance;
    }

    function balanceOfByScope(address _account, string memory _scope, address _relying_party) public view returns(uint) {
        return earnedByScope(_account, _scope, _relying_party) - claimedByScope(_account, _scope, _relying_party);
    }
}