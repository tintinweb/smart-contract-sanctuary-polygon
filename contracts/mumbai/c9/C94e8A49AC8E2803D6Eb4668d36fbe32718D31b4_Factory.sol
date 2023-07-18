// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Investment.sol";

/// @title SLFactory
/// @author Something Legendary
/// @notice This contract is responsible for deploying new Investment contracts and managing them.
/// @dev This contract uses an external contract for access control (SLPERMISSIONS_ADDRESS) and requires a valid SLCore address to initialize Investment contracts.
contract Factory {
    ///
    //-----STATE VARIABLES------
    ///
    /// @notice A mapping that stores deployed Investment contracts by their level.
    /// @dev The key is the level of the Investment contract and the value is an array of Investment contracts at that level.
    mapping(uint256 => Investment[]) public deployedContracts;
    /// @notice Stores SLCore address
    /// @dev Used to initialize Investment contracts
    address public slCoreAddress;
    /// @notice Stores SLPermissions address
    /// @dev Used to Control Access to certain functions
    address public immutable SLPERMISSIONS_ADDRESS;

    ///
    //-----EVENTS------
    ///
    /// @notice An event that is emitted when a new Investment contract is deployed.
    /// @param ContractID The ID of the new contract in its level.
    /// @param conAddress The address of the new contract.
    /// @param conLevel The level of the new contract.
    event ContractCreated(
        uint256 indexed ContractID,
        address indexed conAddress,
        uint256 indexed conLevel
    );

    ///
    //-----ERRORS------
    ///
    /// @notice Reverts if a certain address == address(0)
    /// @param reason which address is missing
    error InvalidAddress(string reason);

    /// @notice Reverts if input is not in level range
    /// @param input level inputed
    /// @param min minimum level value
    /// @param max maximum level value
    error InvalidLevel(uint256 input, uint256 min, uint256 max);

    /// @notice Reverts if platform is paused
    error PlatformPaused();

    ///Function caller is not CEO level
    error NotCEO();

    ///
    //-----CONSTRUCTOR------
    ///
    /// @notice Initializes the contract with the address of the SLPermissions contract.
    /// @param _slPermissionsAddress The address of the SLPermissions contract.
    constructor(address _slPermissionsAddress) {
        SLPERMISSIONS_ADDRESS = _slPermissionsAddress;
    }

    ///
    //-----MAIN FUNCTIONS------
    ///
    /// @notice Deploys a new Investment contract with the specified parameters.
    /// @dev The function requires the caller to be a CEO and the platform to be active. It also checks if the slCoreAddress and _paymentTokenAddress are not zero addresses and if the _level is within the range 1-3.
    /// @param  _totalInvestment The total amount of tokens needed to fulfill the investment.
    /// @param  _paymentTokenAddress The address of the token management contract.
    /// @param _level The level of the new Investment contract.
    /// @return The address of the newly deployed Investment contract.
    /// @custom:requires  1 <= level <= 3 and CEO access Level
    function deployNew(
        uint256 _totalInvestment,
        address _paymentTokenAddress,
        uint256 _level
    ) external isCEO isNotGloballyStoped returns (address) {
        if (slCoreAddress == address(0)) {
            revert InvalidAddress("SLCore");
        }
        if (_paymentTokenAddress == address(0)) {
            revert InvalidAddress("PaymentToken");
        }
        if (_level == 0) {
            revert InvalidLevel(_level, 1, 3);
        }
        if (_level > 3) {
            revert InvalidLevel(_level, 1, 3);
        }

        //Generate new Investment contract
        Investment inv = new Investment(
            _totalInvestment,
            SLPERMISSIONS_ADDRESS,
            slCoreAddress,
            _paymentTokenAddress,
            _level
        );
        //Store the generated contract
        deployedContracts[_level].push(inv);
        //emit contract generation event
        emit ContractCreated(
            deployedContracts[_level].length,
            address(inv),
            _level
        );
        //return address
        return address(inv);
    }

    /// @notice Updates the SLCore address.
    /// @dev The function requires the caller to be a CEO and the platform to be active. It also checks if the _slCoreAddress is not a zero address.
    /// @param  _slCoreAddress The new SLCore address.
    /// @custom:requires  CEO access Level
    /// @custom:intent If SLCore gets compromised, there's a way to fix the factory withouth the need of redeploying
    function setSLCoreAddress(
        address _slCoreAddress
    ) external isCEO isNotGloballyStoped {
        if (_slCoreAddress == address(0)) {
            revert InvalidAddress("SLCore");
        }
        slCoreAddress = _slCoreAddress;
    }

    /// @notice Returns the total amount invested by the user across all levels.
    /// @dev The function iterates over all deployed contracts and sums up the balance of the user in each contract.
    /// @param _user The address of the user.
    /// @return userTotal The total amount invested by the user.
    function getAddressTotal(
        address _user
    ) external view returns (uint256 userTotal) {
        //Cicle through every level
        for (uint256 i = 1; i <= 3; ++i) {
            //Cicle through every investment in every level
            uint256 numberOfContracts = deployedContracts[i].length;
            for (uint256 j; j < numberOfContracts; j++) {
                //sum value to user total
                userTotal += ERC20(deployedContracts[i][j]).balanceOf(_user);
            }
        }
    }

    /// @notice Returns the total amount invested by the user at a specific level.
    /// @dev The function iterates over all deployed contracts at the specified level and sums up the balance of the user in each contract.
    /// @param _user The address of the user.
    /// @param _level The level of the Investment contracts.
    /// @return userTotal The total amount invested by the user at the specified level.
    function getAddressTotalInLevel(
        address _user,
        uint256 _level
    ) external view returns (uint256 userTotal) {
        //Cicle through every investment in given level
        uint256 numberOfContracts = deployedContracts[_level].length;
        for (uint256 i; i < numberOfContracts; ++i) {
            //sum value to user total
            userTotal += ERC20(deployedContracts[_level][i]).balanceOf(_user);
        }
    }

    /// @notice Returns the total amount invested by the caller in a specific contract.
    /// @dev The function gets the balance of the caller in the specified contract.
    /// @param _contractAddress The address of the Investment contract.
    /// @return userTotal The total amount invested by the caller in the specified contract.
    function getAddressOnContract(
        address _contractAddress
    ) external view returns (uint256 userTotal) {
        userTotal = ERC20(_contractAddress).balanceOf(msg.sender);
    }

    /// @notice Returns the address of the last deployed Investment contract at a specific level.
    /// @dev The function returns a zero address if there are no deployed contracts at the specified level.
    /// @param  _level The level of the Investment contracts.
    /// @return contractAddress The address of the last deployed Investment contract at the specified level.
    function getLastDeployedContract(
        uint256 _level
    ) external view returns (address contractAddress) {
        if (deployedContracts[_level].length != 0) {
            contractAddress = address(
                deployedContracts[_level][deployedContracts[_level].length - 1]
            );
        } else {
            contractAddress = address(0);
        }
    }

    ///
    //---- MODIFIERS------
    ///
    /// @notice Verifies if platform is paused.
    /// @dev If platform is paused, the whole contract is stopped
    modifier isNotGloballyStoped() {
        if (ISLPermissions(SLPERMISSIONS_ADDRESS).isPlatformPaused()) {
            revert PlatformPaused();
        }
        _;
    }
    /// @notice Verifies if user is CEO.
    /// @dev CEO has the right to interact with: deployNew() and setSLCoreAddress()
    modifier isCEO() {
        if (!ISLPermissions(SLPERMISSIONS_ADDRESS).isCEO(msg.sender)) {
            revert NotCEO();
        }
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ISLPermissions.sol";

interface ISLCore {
    function whichLevelUserHas(address user) external view returns (uint256);
}

interface IToken is IERC20 {}

/// @title Investment Contract
/// @author Something Legendary
/// @notice This contract is used for managing an investment.
/// @dev The contract includes functions for investing, withdrawing, processing, and refilling.
contract Investment is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Enum for the status of the contract.
    /// @dev The status can be Pause, Progress, Process, Withdraw, or Refunding.
    enum Status {
        Pause,
        Progress,
        Process,
        Withdraw,
        Refunding
    }

    ///
    //-----STATE VARIABLES------
    ///
    /// @notice The status of the contract.
    /// @dev The status is public and can be changed through the changeStatus function.
    Status public status;
    /// @notice The total investment in the contract.
    /// @dev This value is immutable and set at the time of contract deployment.
    uint256 public immutable TOTAL_INVESTMENT;
    /// @notice The return profit.
    /// @dev This value is set as 0 until contract is refilled.
    uint256 public returnProfit;
    /// @notice The address of the payment token.
    /// @dev This value is set at the time of contract deployment.
    address public paymentTokenAddress;
    /// @notice The address of SLCore contract.
    /// @dev This value is set at the time of contract deployment.
    address public immutable SLCORE_ADDRESS;
    /// @notice The address of the Access Control contract.
    /// @dev This value is set at the time of contract deployment.
    address public immutable SLPERMISSIONS_ADDRESS;
    /// @notice Minimum investment amount
    /// @dev This value is set at the time of contract deployment.
    uint256 public constant MINIMUM_INVESTMENT = 100;
    /// @notice The Level of the contract.
    /// @dev This value is set at the time of contract deployment.
    uint256 public immutable CONTRACT_LEVEL;
    /// @notice Stores if user has withdrawn.
    /// @dev Keeps user from withdrawing twice.
    mapping(address => uint256) public userWithdrew;

    ///
    //-----EVENTS------
    ///
    /// @notice An event that is emitted when a user invests.
    /// @param user The address of the user who invested.
    /// @param amount The amount invested.
    /// @param time The timestamp where action was perfomed.
    event UserInvest(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed time
    );

    /// @notice An event that is emitted when a user withdraws.
    /// @param user The address of said user.
    /// @param amount The amount withdrawn.
    /// @param time The timestamp where action was perfomed.
    event Withdraw(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed time
    );

    /// @notice An event that is emitted when Something Legendary wtihdraws tokens for processing.
    /// @param amount The amount withdrawn.
    /// @param time The timestamp where action was perfomed.
    event SLWithdraw(uint256 indexed amount, uint256 indexed time);

    /// @notice An event that is emitted when Something Legendary refill contract with tokens.
    /// @param amount The amount refilled.
    /// @param profit The profit rate.
    /// @param time The timestamp where action was perfomed.
    event ContractRefilled(
        uint256 indexed amount,
        uint256 indexed profit,
        uint256 indexed time
    );

    /// @notice An event that is emitted when contract is filled by an investment.
    /// @param time The timestamp where action was perfomed.
    event ContractFilled(uint256 indexed time);

    ///
    //-----ERRORS------
    ///
    /// @notice Reverts if a certain address == address(0)
    /// @param reason which address is missing
    error InvalidAddress(string reason);

    /// @notice Reverts if input is not in level range
    /// @param input level inputed
    /// @param min minimum level value
    /// @param max maximum level value
    error InvalidLevel(uint256 input, uint256 min, uint256 max);

    /// Investing amount exceeded the maximum allowed
    /// @param amount the amount user is trying to invest
    /// @param minAllowed minimum amount allowed to invest
    /// @param maxAllowed maximum amount allowed to invest
    error WrongfulInvestmentAmount(
        uint256 amount,
        uint256 minAllowed,
        uint256 maxAllowed
    );

    /// @notice Reverts if input is not in level range
    /// @param currentStatus current contract status
    /// @param expectedStatus expected status for function to run
    error InvalidContractStatus(Status currentStatus, Status expectedStatus);

    /// @notice Reverts if user is not at least at contract level
    /// @param expectedLevel expected user minimum level
    /// @param userLevel user level
    error IncorrectUserLevel(uint256 expectedLevel, uint256 userLevel);

    /// @notice reverts if refill value is incorrect
    /// @param expected expected refill amount
    /// @param input input amount
    error IncorrectRefillValue(uint256 expected, uint256 input);

    /// @notice reverts if paltofrm hasn´t enough investment for starting process
    /// @param expected expected investment total
    /// @param actual actual investment total
    error NotEnoughForProcess(uint256 expected, uint256 actual);

    /// @notice reverts if user tries a second withdraw
    error CannotWithdrawTwice();

    /// @notice Reverts if platform is paused
    error PlatformPaused();

    ///Function caller is not CEO level
    error NotCEO();

    ///Function caller is not CEO level
    error NotCFO();

    ///
    //-----CONSTRUCTOR------
    ///
    /// @notice Initializes contract with given parameters.
    /// @dev Requires a valid SLCore address and payment token address.
    /// @param _totalInvestment The total value of the investment.
    /// @param _slPermissionsAddress The address of the Access Control contract.
    /// @param _slCoreAddress The SLCore address.
    /// @param  _paymentTokenAddress The address of the token management contract.
    /// @param _contractLevel The level of this contract.
    constructor(
        uint256 _totalInvestment,
        address _slPermissionsAddress,
        address _slCoreAddress,
        address _paymentTokenAddress,
        uint256 _contractLevel
    ) ERC20("InvestmentCurrency", "IC") {
        if (_slCoreAddress == address(0)) {
            revert InvalidAddress("SLCore");
        }
        if (_paymentTokenAddress == address(0)) {
            revert InvalidAddress("PaymentToken");
        }
        TOTAL_INVESTMENT = _totalInvestment * 10 ** decimals();
        SLPERMISSIONS_ADDRESS = _slPermissionsAddress;
        SLCORE_ADDRESS = _slCoreAddress;
        paymentTokenAddress = _paymentTokenAddress;
        _changeStatus(Status.Progress);
        CONTRACT_LEVEL = _contractLevel;
    }

    ///
    //-----MAIN FUNCTIONS------
    ///
    /// @notice Allows a user to invest a certain amount.
    /// @dev The function requires the contract to be in Progress status and the platform to be active.
    /// @param _amount The amount to be invested.
    function invest(
        uint256 _amount
    ) public nonReentrant isAllowed isProgress isNotGloballyStoped {
        //Get amount already invested by user
        uint256 userInvested = _amount *
            10 ** decimals() +
            balanceOf(msg.sender);
        //Get max to invest
        uint256 maxToInvest = getMaxToInvest();
        //Check if amount invested is at least the minimum amount invested
        if (_amount < MINIMUM_INVESTMENT) {
            revert WrongfulInvestmentAmount(
                userInvested,
                MINIMUM_INVESTMENT,
                maxToInvest
            );
        }
        //If user has invested more than the max to invest, he's not allowed to invest
        if (userInvested > maxToInvest) {
            revert WrongfulInvestmentAmount(
                userInvested,
                MINIMUM_INVESTMENT,
                maxToInvest
            );
        }
        //If the amount invested by the user fills the contract, the status is automaticaly changed
        if (totalSupply() + _amount * 10 ** 6 == TOTAL_INVESTMENT) {
            _changeStatus(Status.Process);
            emit ContractFilled(block.timestamp);
        }
        //Mint the equivilent amount of investment token to user
        _mint(msg.sender, _amount * 10 ** decimals());

        //ask for user payment
        IERC20(paymentTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount * 10 ** decimals()
        );

        emit UserInvest(msg.sender, _amount, block.timestamp);
    }

    /// @notice Allows a user to withdraw their investment.
    /// @dev The function requires the contract to be in Withdraw or Refunding status and the platform to be active.
    /// @custom:logic If contract is in Refunding status, profit will be 0 and users will withdraw exactly the same amount invested
    function withdraw()
        external
        nonReentrant
        isAllowed
        isWithdrawOrRefunding
        isNotGloballyStoped
    {
        //Check if user has withdrawed already
        if (userWithdrew[msg.sender] == 1) {
            revert CannotWithdrawTwice();
        }
        //Set user as withdrawed
        userWithdrew[msg.sender] = 1;
        //Calculate final amount
        uint256 finalAmount = calculateFinalAmount(balanceOf(msg.sender));
        //Transfer final amount
        IERC20(paymentTokenAddress).safeTransfer(msg.sender, finalAmount);
        emit Withdraw(msg.sender, finalAmount, block.timestamp);
    }

    // @notice Allows the CFO to withdraw funds for processing.
    /// @dev The function requires the contract to be in Process status and the platform to be active.
    function withdrawSL() external isProcess isNotGloballyStoped isCFO {
        //get total invested by users
        uint256 totalBalance = totalContractBalanceStable();
        //check if total invested is at least 80% of totalInvestment
        if (totalBalance < (TOTAL_INVESTMENT * 80) / 100) {
            revert NotEnoughForProcess(
                (TOTAL_INVESTMENT * 80) / 100,
                totalBalance
            );
        }

        emit SLWithdraw(totalBalance, block.timestamp);
        //Transfer tokens to caller
        IERC20(paymentTokenAddress).safeTransfer(msg.sender, totalBalance);
    }

    /// @notice Allows the CFO to refill the contract.
    /// @dev The function requires the contract to be in Process status and the platform to be active.
    /// @param _amount The amount to be refilled.
    /// @param _profitRate The profit rate for the refill.
    function refill(
        uint256 _amount,
        uint256 _profitRate
    ) public nonReentrant isNotGloballyStoped isProcess isCFO {
        //Verify if _amount is the total needed to fulfill users withdraw
        if (
            TOTAL_INVESTMENT + ((TOTAL_INVESTMENT * _profitRate) / 100) !=
            _amount * 10 ** decimals()
        ) {
            //calculates the amount expected without the decimals
            revert IncorrectRefillValue(
                TOTAL_INVESTMENT +
                    ((TOTAL_INVESTMENT * _profitRate) / 100) /
                    10 ** decimals(),
                _amount
            );
        }
        //globally sets profit rate amount
        returnProfit = _profitRate;
        // Change status to withdraw
        _changeStatus(Status.Withdraw);
        //ask for caller tokens
        IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount * 10 ** decimals()
        );
        emit ContractRefilled(_amount, _profitRate, block.timestamp);
    }

    ///
    //-----GETTERS------
    ///
    /// @notice returns the total invested by users
    /// @return totalBalance the total amount invested
    function totalContractBalanceStable()
        public
        view
        returns (uint256 totalBalance)
    {
        totalBalance = totalSupply();
    }

    /// @notice Calculates the possible amount to invest
    /// @dev Checks if contract is more than 90% full and returns the remaining to fill, if not, returns 10% of total investment
    /// @return maxToInvest max allowed to invest at any time (by a user that didn't invest yet)
    function getMaxToInvest() public view returns (uint256 maxToInvest) {
        maxToInvest = TOTAL_INVESTMENT - totalContractBalanceStable();
        if (maxToInvest > TOTAL_INVESTMENT / 10) {
            maxToInvest = TOTAL_INVESTMENT / 10;
        }
    }

    /// @notice calculates the amount that the user has for withdrawal
    /// @dev if profit rate = 0 the amount returned will be as same as the amount invested
    /// @param _amount amount invested by the user
    /// @return totalAmount amount that the user has the right to withdraw
    /// @custom:obs minimum amount returned: [{_amount}]
    function calculateFinalAmount(
        uint256 _amount
    ) internal view returns (uint256 totalAmount) {
        totalAmount = (_amount + ((_amount * returnProfit) / 100));
    }

    ///
    //---- MODIFIERS------
    ///
    /// @notice Verifies if platform is paused.
    /// @dev If platform is paused, the whole contract is stopped
    modifier isNotGloballyStoped() {
        if (ISLPermissions(SLPERMISSIONS_ADDRESS).isPlatformPaused()) {
            revert PlatformPaused();
        }
        _;
    }
    /// @notice Verifies if contract is in progress status.
    /// @dev If contract is in progress, the only available functions are invest(), changeStatus()
    modifier isProgress() {
        if (status != Status.Progress) {
            revert InvalidContractStatus(status, Status.Progress);
        }
        _;
    }
    /// @notice Verifies if contract is in process status.
    /// @dev If contract is in process, the only available functions are withdrawSL(), changeStatus() and refill()
    modifier isProcess() {
        if (status != Status.Process) {
            revert InvalidContractStatus(status, Status.Process);
        }
        _;
    }
    /// @notice Verifies if contract is in withdraw or refunding status.
    /// @dev If contract is in progress, the only available functions are withdraw(), changeStatus()
    modifier isWithdrawOrRefunding() {
        if (status != Status.Withdraw && status != Status.Refunding) {
            revert InvalidContractStatus(status, Status.Withdraw);
        }
        _;
    }
    /// @notice Verifies if user has the necessary NFT to interact with the contract.
    /// @dev User should be at least the same level as the contract
    modifier isAllowed() {
        uint256 userLevel = ISLCore(SLCORE_ADDRESS).whichLevelUserHas(
            msg.sender
        );
        if (userLevel < CONTRACT_LEVEL) {
            revert IncorrectUserLevel(CONTRACT_LEVEL, userLevel);
        }
        _;
    }
    /// @notice Verifies if user is CEO.
    /// @dev CEO has the right to interact with: changeStatus()
    modifier isCEO() {
        if (!ISLPermissions(SLPERMISSIONS_ADDRESS).isCEO(msg.sender)) {
            revert NotCEO();
        }
        _;
    }
    /// @notice Verifies if user is CFO.
    /// @dev CEO has the right to interact with: withdrawSL() and refill()
    modifier isCFO() {
        if (!ISLPermissions(SLPERMISSIONS_ADDRESS).isCFO(msg.sender)) {
            revert NotCFO();
        }
        _;
    }

    ///
    //----STATUS FUNCTIONS------
    ///
    /// @notice Changes the status of the contract.
    /// @dev The function requires the caller to be a CEO.
    /// @param _newStatus The new status for the contract.
    function changeStatus(Status _newStatus) public isCEO nonReentrant {
        _changeStatus(_newStatus);
    }

    function _changeStatus(Status _newStatus) private {
        status = _newStatus;
    }

    ///
    //----OVERRIDES------
    ///
    /// @notice Returns the number of decimals for investment token. Is the same number of decimals as the payment token!
    /// @dev This function is overridden from the ERC20 standard.
    function decimals() public view override returns (uint8) {
        //ERC20 _token = ERC20(paymentTokenAddress);
        return 6;
    }

    /// @notice Disallows investment token transfers from one address to another.
    /// @dev This function is overridden from the ERC20 standard and always returns false.
    /// @param from The address to NOT transfer from.
    /// @param to The address to NOT transfer to.
    /// @param amount The amount to NOT be transferred.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        return false;
    }

    /// @notice Disallows investment token transfers to another wallet.
    /// @dev This function is overridden from the ERC20 standard and always returns false.
    /// @param to The address to NOT transfer to.
    /// @param amount The amount to NOT be transferred.
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISLPermissions {
    function isCEO(address _address) external view returns (bool);

    function isCFO(address _address) external view returns (bool);

    function isCLevel(address _address) external view returns (bool);

    function isAllowedContract(address _address) external view returns (bool);

    function isPlatformPaused() external view returns (bool);

    function isInvestmentsPaused() external view returns (bool);

    function isClaimPaused() external view returns (bool);

    function isEntryMintPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}