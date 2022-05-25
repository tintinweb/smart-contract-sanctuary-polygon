/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract EcoPotVoting {
    uint public constant MAX_VOTING_POT_COUNT = 10;

    mapping(uint => address) public ecoPotList;
    mapping(address => bool) public ecoPotExist;

    mapping(address => mapping(uint => address)) public userVotingPotAddress;
    mapping(address => mapping(uint => uint)) public userVotingPotAmount;
    mapping(address => uint) public userVotingPotCount;
    mapping(address => uint) public potTotalVotedAmount;

    uint public ecoPotCount;

    address public governance;
    address payable public implementation;
    address payable public ecoPotImplementation;

    address public owner;
    address public nextOwner;

    bool public entered = false;
    address public policyAdmin;

    mapping(address => address) operatorToEcoPot; 

    constructor(address _owner, address payable _implementation, address payable _ecoPotImpl, address _governance) public {
        owner = _owner;
        implementation = _implementation;
        ecoPotImplementation = _ecoPotImpl;
        governance = _governance;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == owner);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setEcoPotImplementation(address payable _newEcoPotImpl) public {
        require(msg.sender == owner);
        require(ecoPotImplementation != _newEcoPotImpl);
        
        ecoPotImplementation = _newEcoPotImpl;
    }

    function getEcoPotImplementation() public view returns (address) {
        return ecoPotImplementation;
    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

interface ImplGetter {
    function getEcoPotImplementation() external view returns (address);
}

contract EcoPot {
    
    address payable public ecoPotVoting;
    address public operator;
    address public token;

    uint public decimal;
    uint public totalAmount;
    uint public amountPerBlock;
    uint public distributableBlock;
    uint public distributedAmount;

    uint public lastDistributed;
    uint public distributionIndex;      

    mapping(address => uint) public userIndex;
    mapping(address => uint) public userRewardSum;

    bool public entered = false;
    bool public isInitialized = false;
    bool public isAvailable = false;

    string public name;

    constructor(address _operator, address _token, string memory _name) public {
        ecoPotVoting = msg.sender;
        operator = _operator;
        token = _token;
        name = _name;
    }

    function () payable external {
        address impl = ImplGetter(ecoPotVoting).getEcoPotImplementation();
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IGovernance {
    function votingMESH() external view returns (address);
}

interface IEcoPot {
    function token() external view returns (address);
    function isInitialized() external view returns (bool);
    function isAvailable() external view returns (bool);
    function init(address _token, uint _amountPerBlock, uint _startBlock) external; 
    function remove() external;
    function depositETH() external payable;
    function depositToken(uint amount) external;
    function giveReward(address user, uint voted) external;
    function estimateEndBlock() external view returns (uint);
    function changeAvailable(bool b) external;
    function updateDistributionIndex() external;
}

interface IEcoPotOperator {
    function setEcoPot(address _ecoPot) external;
    function token() external view returns (address);
    function name() external view returns (string memory);
}

contract EcoPotVotingImpl is EcoPotVoting {   

    using SafeMath for uint256;

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);

    event AddVoting(address user, address exchange, uint amount);
    event RemoveVoting(address user, address exchange, uint amount);
    
    event ChangeEcoPotAvailable(address ecoPot, bool b);
    event CreateEcoPot(address operator, address ecoPot, address token, string name);
    event RemoveEcoPot(address ecoPot);

    constructor() public EcoPotVoting(address(0), address(0), address(0), address(0)){}

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyPolicyAdmin {
        require(msg.sender == owner || msg.sender == policyAdmin);
        _;
    }

    function version() public pure returns (string memory) {
        return "EcoPotVotingImpl20220322";
    }

    function changeNextOwner(address _nextOwner) public onlyOwner {
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);

        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function setPolicyAdmin(address _policyAdmin) public onlyOwner {
        policyAdmin = _policyAdmin;
    }

    function createEcoPot(address operator) public onlyPolicyAdmin {
        require(operator != address(0));
        require(operatorToEcoPot[operator] == address(0));
        address token = IEcoPotOperator(operator).token();
        string memory name = IEcoPotOperator(operator).name();

        address ecoPot = address(new EcoPot(operator, token, name));

        ecoPotExist[ecoPot] = true;
        ecoPotList[ecoPotCount] = ecoPot;
        operatorToEcoPot[operator] = ecoPot;
        ecoPotCount = ecoPotCount.add(1);

        IEcoPotOperator(operator).setEcoPot(ecoPot);

        emit CreateEcoPot(operator, ecoPot, token, name);
    }

    function removeEcoPot(address ecoPot) public onlyOwner {
        uint index;
        bool isExist;

        for (uint i = 0; i < ecoPotCount; i++) {
            if (ecoPotList[i] == ecoPot) {
                index = i;
                isExist = true;
            }
        }
        require(isExist);
            
        IEcoPot(ecoPot).remove();

        ecoPotExist[ecoPot] = false;
        ecoPotList[index] = ecoPotList[ecoPotCount - 1];
        ecoPotList[ecoPotCount - 1] = address(0);
        ecoPotCount = ecoPotCount.sub(1);

        emit RemoveEcoPot(ecoPot);
    }    

    function changeEcoPotAvailable(address ecoPot, bool b) public onlyPolicyAdmin {
        require(ecoPotExist[ecoPot]);
        IEcoPot(ecoPot).changeAvailable(b);

        emit ChangeEcoPotAvailable(ecoPot, b);
    }
    
    function addVoting(address ecoPot, uint amount) public nonReentrant {
        require(ecoPotExist[ecoPot]);
        require(amount != 0);
        require(IEcoPot(ecoPot).isInitialized());
        require(IEcoPot(ecoPot).isAvailable());

        IEcoPot(ecoPot).updateDistributionIndex();
        _giveReward(msg.sender, ecoPot);

        amount = amount.mul(10 ** 18);

        uint ecoPotIndex;
        bool isVotedPot = false;
        uint votedAmount = 0;

        for (uint i = 0; i < userVotingPotCount[msg.sender]; i++){
            if (userVotingPotAddress[msg.sender][i] == ecoPot){
                isVotedPot = true;
                ecoPotIndex = i;
            }
            votedAmount = votedAmount.add(userVotingPotAmount[msg.sender][i]);
        }
        require(IERC20(IGovernance(governance).votingMESH()).balanceOf(msg.sender) >= votedAmount.add(amount));

        if (isVotedPot) {
            userVotingPotAmount[msg.sender][ecoPotIndex] = userVotingPotAmount[msg.sender][ecoPotIndex].add(amount);
        } else {
            require(userVotingPotCount[msg.sender] < MAX_VOTING_POT_COUNT);
            ecoPotIndex = userVotingPotCount[msg.sender];
            userVotingPotAddress[msg.sender][ecoPotIndex] = ecoPot;
            userVotingPotAmount[msg.sender][ecoPotIndex] = amount;
            userVotingPotCount[msg.sender] = ecoPotIndex.add(1);
        }

        potTotalVotedAmount[ecoPot] = potTotalVotedAmount[ecoPot].add(amount);

        emit AddVoting(msg.sender, ecoPot, amount);
    }

    function removeVoting(address ecoPot, uint amount) public nonReentrant {
        require(amount != 0);

        IEcoPot(ecoPot).updateDistributionIndex();
        _giveReward(msg.sender, ecoPot);

        amount = amount.mul(10 ** 18);

        bool isVotedPot = false;
        uint ecoPotIndex;

        for (uint i = 0; i < userVotingPotCount[msg.sender]; i++){
            if (userVotingPotAddress[msg.sender][i] == ecoPot){
                isVotedPot = true;
                ecoPotIndex = i;
            }
        }
        require(isVotedPot);

        if (amount >= userVotingPotAmount[msg.sender][ecoPotIndex])
            amount = userVotingPotAmount[msg.sender][ecoPotIndex];

        userVotingPotAmount[msg.sender][ecoPotIndex] = userVotingPotAmount[msg.sender][ecoPotIndex].sub(amount);

        if (userVotingPotAmount[msg.sender][ecoPotIndex] == 0) {
            uint lastIndex = userVotingPotCount[msg.sender].sub(1);
            userVotingPotAddress[msg.sender][ecoPotIndex] = userVotingPotAddress[msg.sender][lastIndex];
            userVotingPotAddress[msg.sender][lastIndex] = address(0);

            userVotingPotAmount[msg.sender][ecoPotIndex] = userVotingPotAmount[msg.sender][lastIndex];
            userVotingPotAmount[msg.sender][lastIndex] = 0;

            userVotingPotCount[msg.sender] = lastIndex;
        }

        potTotalVotedAmount[ecoPot] = potTotalVotedAmount[ecoPot].sub(amount);

        emit RemoveVoting(msg.sender, ecoPot, amount);
    }

    function removeAllVoting() public nonReentrant {
        _removeAllVoting(msg.sender);
    }

    function removeAllVoting(address user) public nonReentrant {
        require(msg.sender == IGovernance(governance).votingMESH());
        require(user != address(0));

        _removeAllVoting(user);
    }

    function _removeAllVoting(address user) internal {
        
        for(uint i = 0; i < userVotingPotCount[user]; i++) {
            address ecoPot = userVotingPotAddress[user][i];
            
            IEcoPot(ecoPot).updateDistributionIndex();
            _giveReward(user, ecoPot);

            uint amount = userVotingPotAmount[user][i];

            userVotingPotAddress[user][i] = address(0);
            userVotingPotAmount[user][i] = 0;

            potTotalVotedAmount[ecoPot] = potTotalVotedAmount[ecoPot].sub(amount);

            emit RemoveVoting(user, ecoPot, amount);
        }

        userVotingPotCount[user] = 0;
    }


    function claimReward(address ecoPot) public nonReentrant {
        _giveReward(msg.sender, ecoPot);
    }

    function claimRewardAll() public nonReentrant {
        _giveRewardAll(msg.sender);
    }

    function _giveReward(address user, address ecoPot) internal {
        bool isExist;
        uint potIndex;

        for (uint i = 0; i < userVotingPotCount[user]; i++){
            if (userVotingPotAddress[user][i] == ecoPot){
                isExist = true;
                potIndex = i;
                break;
            }
        }

        IEcoPot(ecoPot).giveReward(user, (isExist) ? userVotingPotAmount[user][potIndex] : 0);
        
    }

    function _giveRewardAll(address user) internal {
        for (uint i = 0; i < userVotingPotCount[user]; i++){
            IEcoPot(userVotingPotAddress[user][i]).giveReward(user, userVotingPotAmount[user][i]);
        }
    }

    function () payable external {
        revert();
    }
}