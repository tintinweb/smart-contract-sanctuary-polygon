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

struct UserInvitationInfo {
    address user;
    string code;
    bool used;
}

contract SelfkeyInviteCodeRegistry is SafeOwn {

    event SignerChanged(address indexed _address);
    event InvitationCodeAdded(address indexed _address, string _code);
    event InvitationCodeUsed(address indexed _address, address indexed _inviter, string _code);

    address public authorizedSigner;
    mapping(address => UserInvitationInfo) private _userInvitationInfo;
    mapping(string => address) private _userInvitationCode;

    constructor(address _signer) SafeOwn(14400) {
        require(_signer != address(0), "Invalid authorized signer");
        authorizedSigner = _signer;
    }

    function changeSignerAddress(address _signer) public onlyOwner {
        require(_signer != address(0), "Invalid authorized signer");
        authorizedSigner = _signer;
        emit SignerChanged(_signer);
    }

    function getInviteCode(address _address) public virtual view returns (string memory) {
        string memory _code = string(_userInvitationInfo[_address].code);
        return _code;
    }

    function getInviteCodeOwner(string memory _code) public virtual view returns (address) {
        return _userInvitationCode[_code];
    }

    function registerInviteCode(address _address, string memory _code) external {
        require(msg.sender == authorizedSigner, "Invalid signer");
        require(_userInvitationInfo[_address].user == address(0), "Already registered");

        UserInvitationInfo memory _invitationInfo = UserInvitationInfo({
            user: _address,
            code: _code,
            used: false
        });

        _userInvitationInfo[_address] = _invitationInfo;
        _userInvitationCode[_code] = _address;

        emit InvitationCodeAdded(_address, _code);
    }

    function registerInviteCodeUsed(address _address, string memory _code) external {
        require(msg.sender == authorizedSigner, "Invalid signer");

        UserInvitationInfo memory existingOwner = _userInvitationInfo[_address];
        require(existingOwner.used == false, "Already redeemed invite code");
        require(existingOwner.user != address(0), "Address not found");
        address _inviter = _userInvitationCode[_code];
        require(_inviter != address(0), "Invalid code");

        _userInvitationInfo[_address].used = true;

        emit InvitationCodeUsed(_address, _inviter, _code);
    }

    function isInviteUsed(address _address) public virtual view returns (bool) {
        UserInvitationInfo memory _userInfo = _userInvitationInfo[_address];
        return _userInfo.used;
    }

    function isInviteCodeValid(string memory _inviteCode) public virtual view returns (bool) {
        address _inviterAddress = _userInvitationCode[_inviteCode];
        return _inviterAddress != address(0);
    }

}