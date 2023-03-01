// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ILending.sol";
import "./ICals.sol";

/// @title Contract to works as a DataBase in lending/Earn section.
/// @author Panoram Finance.
/// @notice This contract is use to save all the information related to Lending/Earn Section.
contract LendingControl is AccessControl, ReentrancyGuard, ILending {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    uint16 public interesLenders = 1000; // interest to pay in lending 10% en base 10 mil 
    uint32 private daysBeforePenalization = 30 days;
    uint32 private extendPenalization = 20 days;
    uint256 public requestId = 0;

    ICals private calc;

    /// @dev number of deposits in lending.
    uint256 private numberDeposits = 0; 
    /// @dev wallets that have deposited in lending. ID lending => user wallet.
    mapping(uint256 => address) private walletsRegister; 

    /// @dev Lending Struct.
     struct Data {
        uint256 amount; // amount deposited
        uint256 pendRewards; // pending Rewards for withdrawals.
        uint256 claimed; //Amount of rewards already redeemed
        uint256 payPerSecond; // how much the user earn per second.
        uint96 depositTime;
        uint96 lastCalcTime; // calculate the interest based on the date, starting from the date when it was last calculated.
        uint96 withdrawTime; 
        uint96 claimTime; // last time the user claim the rewards
        uint96 lastSetClaimRewards; // the date when the user set a claim.
        uint32 daysLeft; // days left to avoid penalization.
        address token;
    }

    /// @dev User address => Lending ID => Struct
    mapping(address => mapping(uint256 => Data)) public lenders;

    /// @dev Struct for withdrawal data.
    struct withdrawRequest{
        uint256 _amount; // amount to withdraw from lending
        uint256 _rewards; // interest amount to withdraw
        uint96 _date; // time of withdrawal request creation
        uint96 lastCalcTime; //in case of user cancellation, Data's lastCalcTime is returned to this date.
        Status _status;
    }

    /// @dev user address => Request ID => Struct
    mapping(address => mapping(uint256 => withdrawRequest)) private request;

    /// @dev wallet => ID Lenders - register of wallets in lending.
    mapping(address => uint256) private idInfo;
    /// @dev Mapping for permissions.
    mapping(address => bool) public lend;

    /// @dev Contract Constructor.
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);   
    }

    /// @dev Modifier to allow or deny access to contract functions, only contracts allowed can use these functions.
    modifier onlyLending() {
        if (!lend[msg.sender]) {
            revert("you can not modify");
        }
        _;
    }

    /// @dev Modifier to allow or deny access to admin functions.
    modifier onlyDev(){
        if(!hasRole(DEV_ROLE, msg.sender)){
            revert("Not enough Permissions");
        }
        _;
    }

    /// @dev Function to get specific information from a lender necessary in other contracts.
    /// @param wallet - the user's wallet address.
    /// @param id - the user's Lending ID.
    /// @return _amount - the amount the user deposited in lending.
    /// @return _deposit - the deposit date.
    /// @return _token - the deposit token.
    /// @return _lastCalcTime - the date of the last time the interest was calculated.
    /// @return _payPerSecond - the amount to pay per second to this lender.
    /// @return _withdraw - the last time the user withdraw money/earnings from lending.
    function getLenderInfo(address wallet, uint256 id) public view returns (uint256 _amount, uint256 _deposit, address _token, uint96 _lastCalcTime, uint256 _payPerSecond, uint96 _withdraw){
        return (lenders[wallet][id].amount,
        lenders[wallet][id].depositTime,
        lenders[wallet][id].token,
        lenders[wallet][id].lastCalcTime,
        lenders[wallet][id].payPerSecond,
        lenders[wallet][id].withdrawTime);
    }

    /// @dev Function to get information related to the interests earned by the user.
    /// @param wallet - the user's wallet address.
    /// @param id - the user's Lending ID.
    /// @return rewards - the interests that the user has claimed.
    /// @return claimTime - the date when the user claimed the rewards/interests.
    /// @return lastTimeClaim - the date of the last time the interest was calculated.
    function getRewardsClaimed(address wallet, uint256 id) public view returns (uint256 rewards, uint96 claimTime, uint96 lastTimeClaim){
        rewards = lenders[wallet][id].claimed;
        claimTime = lenders[wallet][id].claimTime;
        lastTimeClaim = lenders[wallet][id].lastCalcTime;
    }

    /// @dev Function to get the pending interests/rewards to be paid to the user.
    /// @param _wallet - the user's wallet address.
    /// @param _idLending - the user's Lending ID.
    /// @return pendRewards - the pending interests/rewards.
    function getPendingRewards(address _wallet, uint256 _idLending) public view returns(uint256){
        return lenders[_wallet][_idLending].pendRewards;
    }

    /// @dev Function to get the last time the user set a claim for interests.
    /// @param _wallet - the user's wallet address.
    /// @param _idLending - the user's Lending ID.
    /// @return lastSetClaimRewards - the date the user set a interests/rewards claim.
    function getLastSetClaimRewards(address _wallet,uint256 _idLending) public view returns(uint96 lastSetClaimRewards){
        lastSetClaimRewards = lenders[_wallet][_idLending].lastSetClaimRewards;
    }

    /// @dev Function to get the days left to avoid penalization for withdrawals.
    /// @param _wallet - the user's wallet address.
    /// @param _idLending - the user's Lending ID.
    /// @return daysLeft - the days left to avoid penalization.
    function getDaysLeft(address _wallet,uint256 _idLending) public view returns(uint32 daysLeft){
        daysLeft = lenders[_wallet][_idLending].daysLeft;
    }

    /// @dev Function to update the days left to avoid penalization for withdrawals.
    /// @param _wallet - the user's wallet address.
    /// @param _idLending - the user's Lending ID.
    /// @param _daysLeft - the new days left value.
    function updateDaysLeft(address _wallet, uint256 _idLending, uint32 _daysLeft) public onlyLending {
        lenders[_wallet][_idLending].daysLeft = _daysLeft;
    }

    /// @dev Function to register a new lender in lending struct.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - the amount deposited by the user.
    /// @param _token - the token address that the user deposited.
    /// @param _payPerSecond - The payment per second that corresponds to this user.
    function addRegistry(uint256 id, address wallet, uint256 _amount,address _token, uint256 _payPerSecond) public onlyLending nonReentrant {
        uint96 time = safeCastToUint96(block.timestamp);
        lenders[wallet][id].amount = _amount;
        lenders[wallet][id].depositTime = time;
        lenders[wallet][id].token = _token;
        lenders[wallet][id].lastCalcTime = time;
        lenders[wallet][id].claimTime = time;
        lenders[wallet][id].lastSetClaimRewards = time;
        lenders[wallet][id].payPerSecond = _payPerSecond;
        lenders[wallet][id].daysLeft = daysBeforePenalization;
        numberDeposits++;
        walletsRegister[numberDeposits] = wallet;
    }

    /// @dev Function to update a user deposit in Lending/Earn.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - the amount deposited by the user.
    /// @param _payPerSecond - The payment per second that corresponds to this user.
    function updateRegistry(uint256 id, address wallet, uint256 _amount, uint256 _payPerSecond) public onlyLending nonReentrant {
        lenders[wallet][id].amount += _amount;
        lenders[wallet][id].depositTime = safeCastToUint96(block.timestamp);
        lenders[wallet][id].payPerSecond = _payPerSecond;
    }

    /// @dev Function to update the days Left to avoid penalizations for lending withdrawals.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    function updatePenalization(uint256 id, address wallet) public onlyLending nonReentrant {
        lenders[wallet][id].daysLeft = extendPenalization;
    }

    /// @dev Function to update the last time the interest to be paid to the user was calculated.
    /// @param wallet - the user's wallet address.
    /// @param idLending - the Lending ID created for the user.
    /// @param _timeClaim - The date of the last time the user's interest payment was calculated.
    function updateLastTimeClaim(address wallet, uint256 idLending, uint256 _timeClaim) public onlyLending nonReentrant {
        lenders[wallet][idLending].lastCalcTime = safeCastToUint96(_timeClaim);
    }

    /// @dev Function to clear the pending rewards after the user set a claim for that rewards/interests.
    /// @param wallet - the user's wallet address.
    /// @param idLending - the Lending ID created for the user.
    /// @param _timeClaim - The date of the last time the user's interest payment was calculated.
    function updatePendingRewards(address wallet, uint256 idLending, uint256 _timeClaim) public onlyLending nonReentrant {
        lenders[wallet][idLending].pendRewards = 0;
        lenders[wallet][idLending].lastSetClaimRewards = safeCastToUint96(_timeClaim);
    }

    /// @dev Function to update the interest claimed and the last time the user claims it.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _rewards - the amount claimed.
    /// @param _claimTime - The date when the user claimed their interests/rewards.
    function updateClaimed(uint256 id, address wallet, uint256 _rewards, uint256 _claimTime) public onlyLending nonReentrant {
        lenders[wallet][id].claimed += _rewards;
        lenders[wallet][id].claimTime = safeCastToUint96(_claimTime);
        //lenders[wallet][id].pendRewards = 0; 
    }

    /// @dev Function to rest the amount to withdrawn from the deposit amount register for the user after He set a withdrawal request.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - the amount the user wants to withdraw.
    function claimMoney(uint256 id, address wallet, uint256 _amount) public onlyLending nonReentrant{
        if(lenders[wallet][id].amount == _amount){
            lenders[wallet][id].amount = 0;
        }else{
        lenders[wallet][id].amount -= _amount;
        }
    }

    /// @dev Function to add the amount to the amount registered for the user if He cancels the withdrawal.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - The amount that the user had requested to withdraw.
    function updateMoney(uint256 id, address wallet, uint256 _amount) public onlyLending nonReentrant{
        lenders[wallet][id].amount += _amount;
    }

    /// @dev Function to update the amount to pay per second to a lender.
    /// @param _wallet - the user's wallet address.
    /// @param _idLending - the Lending ID created for the user.
    /// @param _newPayPerSecond - The new payment per second that corresponds to this user.
    function updatePayPerSecond(address _wallet, uint256 _idLending ,uint256 _newPayPerSecond) public onlyLending {
        lenders[_wallet][_idLending].payPerSecond = _newPayPerSecond;
    }

    /// @dev Function to update key information in the 'Data' struct after the user reinvests the interest they have earned.
    /// @param _wallet - the user's wallet address.
    /// @param _idLending - the Lending ID created for the user.
    /// @param _amount - the amount to reinvest.
    /// @param _claimed - the amount claimed, equal to the _amount parameter.
    /// @param _lastCalcTime - the last time interest was calculated.
    function updateOnReinvestmentRewards(address _wallet, uint256 _idLending, uint256 _amount, uint256 _claimed, uint256 _lastCalcTime) public onlyLending{
        lenders[_wallet][_idLending].amount += _amount;
        lenders[_wallet][_idLending].claimed += _claimed;
        lenders[_wallet][_idLending].lastCalcTime = safeCastToUint96(_lastCalcTime);
        lenders[_wallet][_idLending].pendRewards = 0; 
    }

    /// @dev Function to create a request to withdraw your investment in Lending or your interest earned.
    /// @param _wallet - the user's wallet address.
    /// @param _amount - The amount to withdraw when the user wants to withdraw from the money they deposited in lending.
    /// @param _rewards - The interest/rewards earned by the user in lending.
    /// @param _flag - a flag (1,2) to know if the user's request is to withdraw the earned interests or what the user deposited in lending.
    /// @return _id - The Request ID created.
    function createRequest(address _wallet, uint256 _amount, uint256 _rewards, uint8 _flag) public onlyLending returns(uint256){
        uint256 _id = ++requestId;
        request[_wallet][_id]._amount = _amount;
        request[_wallet][_id]._rewards = _rewards ;
        if(_flag == 1){
            request[_wallet][_id]._status = Status.pending;
        } else if(_flag == 2){
            request[_wallet][_id]._status = Status.pendrewards;
        }
        request[_wallet][_id]._date = safeCastToUint96(block.timestamp);
        request[_wallet][_id].lastCalcTime = lenders[_wallet][_id].lastCalcTime;

        return _id;
    }

    /// @dev Function to close a withdrawal request.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Request ID created for the withdrawal.
    /// @param _state - the state from the Status enum that you want to set in the request.
    /// @param _idLending - The user's Lending ID.
    function closeRequest(address _wallet, uint256 _id, Status _state, uint256 _idLending) public onlyLending {
        lenders[_wallet][_idLending].withdrawTime = safeCastToUint96(block.timestamp);
        request[_wallet][_id]._status = _state;
    }

    /// @dev Function to get the information registered in a withdrawal request.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Request ID created for the withdrawal.
    /// @return _amount - The amount to withdraw in case the user wants to withdraw from the money they deposited in lending.
    /// @return _rewards - The amount of interests to claim if they want to withdraw the interests they have earned.
    /// @return _state - The current status of this request.
    /// @return _date - The date this request was created.
    function getRequest(address _wallet, uint256 _id) public view returns(uint256 _amount,uint256 _rewards, Status _state, uint96 _date) {
        return(request[_wallet][_id]._amount,
         request[_wallet][_id]._rewards,
         request[_wallet][_id]._status,
         request[_wallet][_id]._date);
    }

    /// @dev Function to associate and address to a Lending ID.
    /// @param id - the Lending ID created for the user.
    /// @param wallet - the user's wallet address.
    function addInfo(uint256 id, address wallet) public onlyLending nonReentrant {
        idInfo[wallet]= id;
    }

    /// @dev Function to delete the register of an address => Lending ID.
    /// @param wallet - the user's wallet address to delete.
    function deleteInfo(address wallet) public onlyLending nonReentrant {
        idInfo[wallet]= 0;
    }

    /// @dev Function to get the Lending ID of an Address.
    /// @param wallet - the user's wallet address to query.
    /// @return _id - the lending ID.
    function getIdInfo(address wallet) public view returns(uint256 _id){
        return  idInfo[wallet];
    }

    /// @dev Function to check if a Lending ID is associated with an address wallet.
    /// @param wallet - the user's wallet address to check.
    /// @param _id - the Lending ID created for the user to check.
    /// @return _valid - "true" if the wallet is associated with the Lending ID or "false" otherwise.
    function validateId(address wallet, uint256 _id) public view returns (bool _valid){
        uint256 cons = getIdInfo(wallet);
        if(cons == _id){
            return true;
        }else{
            return false;
        }
    }

    /// @dev Function to get the variable "daysBeforePenalization" from LendingControl, 
    /// @dev that saves the days that a user must wait before making a withdrawal to avoid being penalized.
    /// @return _days - a uint32 that represents the value of daysBeforePenalization variable.
    function getDaysBeforePenalization() public view onlyLending returns(uint32 _days) {
        return daysBeforePenalization;
    }

    /// @dev Function to set the contracts that can use the functions of this contract.
    /// @param _lend - The contract address to allow or deny.
    /// @param _state - True to allow or false to remove the permission.
    function setLendContract(address _lend, bool _state) public onlyDev {
        lend[_lend] = _state;
    }

    /// @dev Function to update the pending interest to pay for an user.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Lending ID created for the user.
    function UpdateInteresAccumulated(address _wallet, uint _id) public onlyLending nonReentrant{
        uint256 interesToPay;
        uint256 timeOfCalc;
            (interesToPay, timeOfCalc) = calc.calcInterestAccumulated(_wallet, _id);
            lenders[_wallet][_id].pendRewards += interesToPay;
            lenders[_wallet][_id].lastCalcTime = safeCastToUint96(timeOfCalc);
    }

    ///@dev Function that saves the earned interests for when the interest rate is changed."
    function SaveInteresAccumulated() private {
        uint256 interesToPay;
        uint256 timeOfCalc;

        for(uint256 i = 1; i<=numberDeposits; ){
            (interesToPay, timeOfCalc) = calc.calcInterestAccumulated(walletsRegister[i], i);
            lenders[walletsRegister[i]][i].pendRewards = interesToPay;
            lenders[walletsRegister[i]][i].lastCalcTime = safeCastToUint96(timeOfCalc);
            lenders[walletsRegister[i]][i].payPerSecond = calc.calcInterestForSecond(lenders[walletsRegister[i]][i].amount, interesLenders);
            interesToPay = 0; // validar si esto es necesario o las variables se sobre escriben en cada llamada a calcInterestAccumulated.
            timeOfCalc = 0; 
            unchecked {
                ++i;
            }
        }  
    }

    /// @dev function to avoid silently overflow bug.
    /// @param value - the value to cast.
    /// @return result - the value casted
    function safeCastToUint96(uint256 value) private pure returns(uint96){
        require(value <= type(uint96).max, "SafeCast: Value doesn't fit in 96 bits");
        return uint96(value);
    }
    
    // habra que ponerle una buena cantidad de gas cuando haya muchas wallets en lending por la llamada a SaveInteresAccumulated()
    /// @dev Function to change the annual interest to pay to lenders.
    /// @param _newInteres - the new interest to pay.
    function setInteresLenders(uint16 _newInteres)public onlyDev {
        interesLenders = _newInteres;
        SaveInteresAccumulated();
    }

    /// @dev Function to update the variable daysBeforePenalization.
    /// @param _newDaysLeft - the value for the variable.
    function updateDaysBeforePenalization(uint32 _newDaysLeft) public onlyDev{
        daysBeforePenalization = _newDaysLeft;
    }

    /// @dev Function to update the variable daysBeforePenalization.
    /// @param _newExtend - the value for the variable.
    function updateExtendPenalization(uint32 _newExtend) public onlyDev{
        extendPenalization = _newExtend;
    }

    // Llamar a esta funcion en cuanto se tenga desplegado el contrato de calcs
    /// @dev Function to set the Calcs contract address.
    /// @param _calcs - the calcs contract address.
    function updateCalcs(address _calcs) public onlyDev{
        if(_calcs == address(0)){
            revert("Address 0 not allowed");
        }
        calc = ICals(_calcs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

/// @title Lending Interface.
/// @author Panoram Finance.
/// @notice You can import this interface to access the statuses of a lending withdraw.
interface ILending {

    /// @dev Enum to declare the Status of a lending / interest withdrawal
    enum Status{
        complete, //0
        pending, //1
        pendrewards,
        cancelled //2
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title Calcs Interface.
/// @author Panoram Finance.
/// @notice You can use this interface in other contracts to connect to the Calcs Contract.
interface ICals {

    /// @dev Function to calculate the user's interest accumulated in Lending.  
    function calcInterestAccumulated(address _wallet,uint256 _idLending) external view returns(uint256 interesToPay, uint256 timeOfCalc);

    /// @dev Function to calculate the interest paid to the user every second.
    function calcInterestForSecond(uint256 _amountDeposit, uint16 _interes) external pure returns(uint256 payPerSecond);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}