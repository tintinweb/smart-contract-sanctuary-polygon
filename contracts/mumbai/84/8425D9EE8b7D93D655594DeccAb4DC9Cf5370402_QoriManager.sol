pragma solidity >=0.4.21 <0.7.0;

import "./SafeMath.sol";
import "./Restricted.sol";

/**
 * @title Qori Manager - Main contract of the Qori Project
 * @author Qori - Magia Digital
 * @notice This contract has mainly an administrative usage, some basic user data edition is allowed
 * @dev Most requires should be revert
 * Due to initContract existing, maybe an onlyOnce and needBeginning modifiers are nedded
 */
contract QoriManager is RestrictedV2 {

    using SafeMath for uint256;

    /**    
     * @notice user-generated user-driven event
     */
    event Deposit(address indexed _user, uint _value, uint _blocknumber);

    /**    
     * @notice admin-generated user-driven events
     */
    event UserActivation(address indexed _user);
    event UserReactivation(address indexed _user);
    event UserDeactivation(address indexed _user);
    event UserToGuideUpgraded(address indexed _user);

    /**        
     * @notice admin-generated admin-driven events
     */
    event PercentagesChange(address _admin, uint _value, uint _index);
    event PercentagesCapChange(address _admin, uint _value);
    event FeeChange(address _admin, uint _value);
    event LimitChange(address _admin, uint _value);
    event FundsWithdrawal(address _admin, uint _value, address _receiver);
    
    /**
     * @notice Main structure for storing essential user data
     * @dev 
     * `status` uint8 legend:
     *       0 - non-existent
     *       1 - registered by guide but not active (deprecated, not used)
     *       2 - activated
     *       3 - inactive
     * `lastActivation` uint stores the block number where it was mined
     */
    struct Users {
        uint8 status;
        bool guide;
        address payable parent;
        uint lastActivation;
        uint currentBalance;
        string email;
        address[] children;

        /**
         * @notice DEVELOPMENT ONLY
         * @dev When deleting a user, it needs to be erased from 
         * its correspondent parent `children` array
         */
        uint indexParent;

        /**
         * @notice DEVELOPMENT ONLY
         * @dev Needed due to indexParent defaulting to 0
         */
        bool hasAParent;
    }

    /**
     * @notice initContrac() flag
     * @dev Due to the proxy storage initiating with default values
     * a special function that only can be call once is needed
     */
    bool public isInitiated = false;
    
    /**
     * @notice Main mapping for storing essential user data
     * @dev Public visibility allows for unautorized queries
     */
    mapping( address => Users) public users;

    /**
     * @notice List of all users with status 2 or greater 
     * @dev Although storage inefficient, this array is mandatory due to a requirement
     */
    address[] allUsers = [address(0)];

    /**
     * @notice List of the percentages distributed for the parents on the fee repartition (sharing) 
     *           Current percentages are:
     *           Level 1: 20%
     *           Level 2: 10%
     *           Level 3: 10%
     *           Level 4: 10%
     *           Level 5: 10%
     *           Level 6: 10%
     * @dev Max number of levels are six (6), but there is a posibility for it to vary
     */
    uint[6] PERCENTAGES = [ 20, 10, 10, 10, 10, 10 ];

    /**
     * @notice Maximum cap of percentages
     * @dev Current cap is dev decison, needs owner approval
     */
    uint public PERCENTAGES_CAP = 100;

    /**
     * @notice Fee to be part of the Qori network (currently 15 dollars)
     * @dev Fee is stored as a two decimal quantity * 100, i.e. 15 dollars = 1500
     */
    uint public FEE = 1500;

    /**
     * @notice Limit for lower bound due to high ether volatility
     * @notice This creates a 10% tolerance if for some reason market crashes (a bit) in between registration and activation
     * @dev Current limit is a dev decision, needs owner approval
     */
    uint public LIMIT = 90;

    /**
     * @notice Balance allowed for withdrawal
     * @dev Contract balance should only update on the following escenarios:
     *       - A user is activated (goes up)
     *       - A user is reactivated (goes up)
     *       - Funds are retrieved (goes down)
     */
    uint public CONTRACT_BALANCE = 0;

    /**
     * @notice DEVELOPMENT ONLY
     */
    mapping( address => uint) indexAllUsers;

    constructor() public{}
    
    function () external payable {
        require(users[msg.sender].status != 2, "User already active");

        users[msg.sender].currentBalance = users[msg.sender].currentBalance.add(msg.value);
        
        emit Deposit(msg.sender, msg.value, block.number);
    }

    /**
     * @notice External Functions
     * WARNING: This function should be called when the contract is first deployed (not updated, only deployed)
     * Change name to initialize for standar purposes
     */

    function initContract() external onlyOwner {
        require(isInitiated == false, "This function can only be called once");

        allUsers = [address(0)];
        PERCENTAGES = [ 20, 10, 10, 10, 10, 10 ];
        PERCENTAGES_CAP = 100;
        FEE = 1500;
        LIMIT = 90;
        CONTRACT_BALANCE = 0;

        isInitiated = true;
    }

    /// @notice Setters
    
    function changePercentages(uint _value, uint _index) external onlyOwner {
        require(_index < PERCENTAGES.length, "Index out of bounds");
        require(PERCENTAGES[_index] != _value, "Quantities must be different!");

        //uint sum = 0;

        //for (uint i = 0; i < PERCENTAGES.length; i++) {
        //    sum += PERCENTAGES[i];
        //}

        // Also PERCENTAGES_SUM_CAP can't be greater than 100%
        //require(sum < PERCENTAGES_CAP, "Sum of percentages can't be greater than cap");

        PERCENTAGES[_index] = _value;
        
        emit PercentagesChange(msg.sender, _value, _index);
    }

    function changePercentagesCap(uint _value) external onlyOwner {
        require(_value <= 100, "Cap can't be greater than 100");
        require(PERCENTAGES_CAP != _value, "Quantities must be different!");

        PERCENTAGES_CAP = _value;
        
        emit PercentagesCapChange(msg.sender, _value);
    }

    function changeFee(uint _newFee) external onlyOwner {
        require(_newFee != 0, "New fee can't be zero!");
        require(FEE != _newFee, "Quantities must be different!");

        FEE = _newFee;
        
        emit FeeChange(msg.sender, _newFee);
    }

    function changeLimit(uint _newLimit) external onlyOwner {
        require(_newLimit <= 100 && _newLimit > 0, "Limit can't be greater than 100 nor lesser than 0!");
        require(LIMIT != _newLimit, "Quantities must be different!");

        LIMIT = _newLimit;
        
        emit LimitChange(msg.sender, _newLimit);
    }

    function upgradeUserToGuide(address _user) external onlyOwner {
        users[_user].guide = true;
        
        emit UserToGuideUpgraded (_user);
    }

    /// @notice Logic

    function withdrawFunds(address payable _receiver) external onlyOwner {
        require(CONTRACT_BALANCE != 0, "Balance can't be zero");
        
        _receiver.transfer(CONTRACT_BALANCE);
        CONTRACT_BALANCE = 0;
        
        emit FundsWithdrawal(msg.sender, CONTRACT_BALANCE, _receiver);
    }

    function withdrawSomeFunds(address payable _receiver, uint _amount) external onlyOwner {
        require(_amount > 0, "Amount can't be zero");
        require(CONTRACT_BALANCE >= _amount, "Safe balance should be higher than the amount");
        
        _receiver.transfer(_amount);
        CONTRACT_BALANCE = CONTRACT_BALANCE.sub(_amount);
        
        emit FundsWithdrawal(msg.sender, _amount, _receiver);
    }

    /// @dev This function is used to return a possible excedent to the user
    function withdrawFundsToUser(address payable _receiver, uint _amount) external onlyOwner {
        require(_amount > 0, "Amount can't be zero");
        require(users[_receiver].currentBalance >= _amount, "Amount should be less than user current balance");
        
        users[_receiver].currentBalance = (users[_receiver].currentBalance).sub(_amount);

        _receiver.transfer(_amount);
        
        emit FundsWithdrawal(msg.sender, _amount, _receiver);
    }
    
    /// @dev ALERT This function can cause serious side effects
    function withdrawAllFunds(address payable _receiver) external onlyOwner {
        uint balance = address(this).balance;
        require(balance != 0, "Balance can't be zero");
        
        _receiver.transfer(balance);
        CONTRACT_BALANCE = 0;
        
        emit FundsWithdrawal(msg.sender, balance, _receiver);
    }

    /// @dev This function is only executed from the backend
    function activateUser(address _user, string calldata _email, address payable _parent, uint _balanceFromAdmin) external onlyOwner {
        require(
            _parent == address(0) || 
            (users[_parent].guide == true && users[_parent].status == 2), 
            "Parent should be a guide and be active!"
        );

        require(users[_user].status == 0, "User is already active or it is not its first payment!");

        users[_user].email = _email;
        users[_user].email = "";
        
        _setParent(_user, _parent);
        _shareUserFee(_user, _balanceFromAdmin);
        
        /// @notice DEVELOPMENT ONLY
        indexAllUsers[_user] = allUsers.length;

        allUsers.push(_user);             

        emit UserActivation(_user);
    }

    function deactivateUser(address _user) external onlyOwner {
        require(users[_user].status == 2, "User need to be active to inactivate!");

        users[_user].status = 3;             

        emit UserDeactivation(_user);
    }

    /// @dev This function is only executed from the backend
    /// @dev Inactive users doesn't change status automatically
    /// This problem is not trivial
    function reactivateUser(address _user, uint _balanceFromAdmin) external onlyOwner {
        require(users[_user].status == 3,  "User should be inactive!");

        _shareUserFee(_user, _balanceFromAdmin); 
        
        emit UserReactivation(_user);
    }

    /// @notice Getters

    function getChildren(address _parent) external view returns (address[] memory) {
        return users[_parent].children;
    }

    function getAllUsers() external view returns (address[] memory) {
        return allUsers;
    }

    function getPercentages() external view onlyOwner returns (uint[6] memory) {
        return PERCENTAGES;
    }

    /**
     * @notice Internal Functions
     */

    function _calculateLowerBound(uint _balanceFromAdmin, uint _currentBalance, uint _limit) internal pure returns (uint) {
        uint lowerBound = _balanceFromAdmin.mul(_limit).div(100);

        require(_currentBalance >= lowerBound, "User balance should be equal or greater than lower bound");

        if (_currentBalance >= _balanceFromAdmin)
          lowerBound = _balanceFromAdmin;

        if (_currentBalance > lowerBound && _currentBalance < _balanceFromAdmin)
          lowerBound = _currentBalance;

        return lowerBound;
    }

    /// @dev This function assumes the balance actually exists, but there can be collision if all ethers are retired
    function _shareUserFee(address _user, uint _balanceFromAdmin) internal {
        require(users[_user].currentBalance != 0, "User must have more than 0 ether deposited");
      
        uint slice;
        uint lowerBound = _calculateLowerBound(_balanceFromAdmin, users[_user].currentBalance, LIMIT);
        uint houseFee = lowerBound;
        address payable parent = users[_user].parent;

        for (uint i = 0; i < PERCENTAGES.length; ++i) {
            if(parent == address(0)) {
                break;
            }
            
            if (users[parent].guide == false || users[parent].status == 3) {
                parent = users[parent].parent;
                continue;
            }

            slice = (lowerBound).mul(PERCENTAGES[i]).div(100);
            parent.transfer(slice);
            parent = users[parent].parent;
            houseFee = houseFee.sub(slice);
        }

        users[_user].status = 2;
        users[_user].currentBalance = users[_user].currentBalance.sub(lowerBound);
        users[_user].lastActivation = block.number;

        CONTRACT_BALANCE = CONTRACT_BALANCE.add(houseFee);
    }

    function _setParent(address _user, address payable _parent) internal {
        if(_parent != address(0)) {
            users[_user].parent = _parent;
            
            /// @notice DEVELOPMENT ONLY
            users[_user].indexParent = users[_parent].children.length;

            users[_parent].children.push(_user);

            /// @notice DEVELOPMENT ONLY
            users[_user].hasAParent = true;
        }
    }
}