// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMortgageControl.sol";
import "./IVaultLenders.sol";
import "../Marketplace/IVaultRewards.sol";

contract Payments is ReentrancyGuard, AccessControl, IMortgageInterest {
    //Binance relayer 0x59C1E897f0A87a05B2B6f960dE5090485f86dd3D;
   address private relayAddress = 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23;
    // Contratos de los tokens Busd y Usdc en BSC Mainnet
    IERC20 private Busd; // Mainet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    IERC20 private Usdc;

    // address de prueba como la wallet de panoram para el envio de los intereses.
    address walletPanoram; //wallet 0x75831a177faeb135e0f78F16f2a701e26339f05

    IVaultLenders private vaultLenders;
    IVaultRewards private PoolRewardsLenders;

    IMortgageControl private mortgageControl;

    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    uint16 private percentagePanoram = 1000;
    uint16 private percentagePool = 9000;
    uint16 private percentagePanoramDelayedPay = 7000;
    uint16 private percentagePoolDelayedPay = 3000;
    uint8 private penalization = 3; // Penalizacion mensual por pago moratorio: 1 = normal; 2 = al doble (200%) ; Default => 3 = al triple (300%)
    bool private paused = false;

    event successfullPayment(
        address indexed client,
        uint256 _IdMortgage,
        uint256 _amount
    );

    constructor(address _Mortgagecontrol, address _Busd, address _Usdc, address _walletPanoram,
        address _vaultLenders, address _PoolRewardsLenders) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEV_ROLE, relayAddress);
        mortgageControl = IMortgageControl(_Mortgagecontrol);
        Busd = IERC20(_Busd); 
        Usdc = IERC20(_Usdc);
        walletPanoram = _walletPanoram; 
        vaultLenders = IVaultLenders(_vaultLenders);
        PoolRewardsLenders = IVaultRewards(_PoolRewardsLenders);
        // approve para realizar las transferencias de los tokens Busd y usdc
        Busd.approve(address(vaultLenders), 2**255);
        Usdc.approve(address(vaultLenders), 2**255);
        Busd.approve(address(PoolRewardsLenders), 2**255);
        Usdc.approve(address(PoolRewardsLenders), 2**255);
        // el approve para que el usuario nos mande fondos al contrato lo hace francisco y asi porder usar el transferFrom
    }

    modifier onlyDev() {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("Not enough Permissions");
        }
        _;
    }

    modifier isPaused(){
        if(paused){
            revert("contract paused");
        }
        _;
    }

    function getDebt(uint256 _IdMortgage, address _walletUser) public onlyDev returns(uint256) {
        uint256 totalMortgages = mortgageControl.getTotalMortgages();
        if(_IdMortgage == 0 || _IdMortgage > totalMortgages){
            revert("Invalid Mortgage");
        }
        CalcDailyInterest(_IdMortgage);
        MortgageInterest memory mortgage = mortgageControl.getuserToMortgageInterest(_walletUser, _IdMortgage);

        uint256 deudaFinal = mortgage.totalDebt - mortgage.amountToVault;
        if(mortgage.isMonthlyPaymentDelayed){
            deudaFinal += mortgage.totalToPayOnLiquidation;
        }else{
            deudaFinal += mortgage.totalMonthlyPay;
        }
        return(deudaFinal);
    }

        ///@dev Funcion para realizar pagos adelantados
    function advancePayment(address _token,uint256 _IdMortgage,uint256 _amountToPay) public nonReentrant isPaused {
        if (_token != address(Busd) && _token != address(Usdc)) {
            revert("Token Invalid");
        }
        MortgageInterest memory mortgage = mortgageControl.getuserToMortgageInterest(msg.sender, _IdMortgage);
        uint256 startDate = mortgageControl.getStartDate(msg.sender, _IdMortgage);
        if((mortgage.lastTimePayment - startDate) < 30 days){ 
            revert("You Must Waite at Least a Month to Do Advance Payments");
        }
        if (mortgage.totalDebt == 0) {
            revert("Mortgage is Paid");
        }
        if (mortgage.liquidate) {
            revert("Liquidated Mortgage");
        }
        if (mortgage.isMonthlyPaymentDelayed) {
            revert("You Must pay the accumulated debt first");
        }
        if (!mortgage.isMonthlyPaymentPayed) {
            revert("You must be up to date on your payments first");
        }
            if (_token == address(Busd)) {
                bool success = Busd.transferFrom(msg.sender,address(this),_amountToPay);
                if (success) {
                    vaultLenders.deposit(_amountToPay, _token);

                    if (_amountToPay >= mortgage.totalDebt) {
                        mortgage.totalDebt = 0;
                        mortgageControl.updateMortgageState(_IdMortgage,msg.sender,true);
                    } else {
                        mortgage.totalDebt -= _amountToPay;
                    }

                    mortgageControl.updateTotalDebtOnAdvancePayment(msg.sender, _IdMortgage,mortgage.totalDebt);
                    mortgageControl.updateMortgagePayment(_IdMortgage,msg.sender);
                }
            } else if (_token == address(Usdc)) {
                bool success = Usdc.transferFrom(msg.sender,address(this),_amountToPay);
                if (success) {
                    vaultLenders.deposit(_amountToPay, _token);

                    if (_amountToPay >= mortgage.totalDebt) {
                        mortgage.totalDebt = 0;
                        mortgageControl.updateMortgageState(_IdMortgage,msg.sender,true);
                    } else {
                        mortgage.totalDebt -= _amountToPay;
                    }

                    mortgageControl.updateTotalDebtOnAdvancePayment(msg.sender, _IdMortgage, mortgage.totalDebt);
                    mortgageControl.updateMortgagePayment(_IdMortgage, msg.sender);
                }
            }
        
    }

   ///@dev function to pay and Calc interes when the users decide to pay.
    function dailyInterestPayment(uint256 _IdMortgage,uint256 _amountToPay,address _token) public nonReentrant isPaused {
        if (_token != address(Busd) && _token != address(Usdc)) {
            revert("Token Invalid");
        }
        MortgageInterest memory mortgage = mortgageControl.getuserToMortgageInterest(msg.sender, _IdMortgage);
        
        if (mortgage.liquidate) {
            revert("Liquidated Mortgage");
        }
        CalcDailyInterest(_IdMortgage);
        if (mortgage.isMonthlyPaymentDelayed) {
            if (_amountToPay != mortgage.totalToPayOnLiquidation) {
                revert("Amount sent is different from the total accumulated debt");
            }
            handlePayment(_token, _amountToPay, mortgage, _IdMortgage, true);
        } else {
            if (_amountToPay != mortgage.totalMonthlyPay) {
                revert("Amount sent is different from the require total monthly payment");
            }
            handlePayment(_token, _amountToPay, mortgage, _IdMortgage, false);
        }
    }

    ///@dev Function to calc the Daily Interest
    function CalcDailyInterest(uint256 _IdMortgage) private isPaused {
        if (mortgageControl.getIdInfo(_IdMortgage) != msg.sender) {
            revert("Wrong Mortgage ID");
        }
        MortgageInterest memory mortgage = mortgageControl.getuserToMortgageInterest(msg.sender, _IdMortgage);
        if(mortgage.totalDebt == 0){
                revert("Mortgage is Paid");
        }
        if (!mortgage.liquidate) {
            if ((block.timestamp - mortgage.lastTimePayment) < 1 days) {
                revert("You already pay this Day");
            }
            if(mortgageControl.getMortgageStatus(msg.sender, _IdMortgage)){
                revert("Mortgage is Paid");
            }

            if ((block.timestamp - mortgage.lastTimeCalc) > 1 days) {
                (uint256 loan,uint256 period,uint64 interestrate,uint256 payCounter) = mortgageControl.getDebtInfo(msg.sender, _IdMortgage);
                if (payCounter == 0) {
                    mortgage.totalDebt = loan;
                }
                uint256 daysLastCalc = (block.timestamp - mortgage.lastTimeCalc) / 86400;

                if (!mortgage.isMonthlyPaymentDelayed) {
                    uint256 dailyInterestToPay = ((mortgage.totalDebt * interestrate) / 100000);
                    uint256 newAmountVault = loan / (period * 30);
                    mortgage.amountToVault += newAmountVault;
                    mortgage.totalMonthlyPay += (dailyInterestToPay + newAmountVault) * daysLastCalc;
                    mortgage.amountToPanoram += ((dailyInterestToPay * percentagePanoram) / 10000) * daysLastCalc;
                    mortgage.amountToPool += ((dailyInterestToPay * percentagePool) / 10000) * daysLastCalc;
                    mortgage.isMonthlyPaymentPayed = false;
                    mortgage.lastTimeCalc = block.timestamp;
                    mortgageControl.addNormalMorgateInterestData(msg.sender,_IdMortgage,mortgage);
                } else {
                    uint256 dailyDelayedInterestToPay = ((mortgage.totalDebt * interestrate) / 100000) * penalization;
                    uint256 newAmountVault = loan / (period * 30);
                    mortgage.amountToVault += newAmountVault;
                    mortgage.totalDelayedMonthlyPay = (dailyDelayedInterestToPay + newAmountVault) * daysLastCalc;
                    mortgage.amountToPanoramDelayed = ((dailyDelayedInterestToPay * percentagePanoramDelayedPay) / 10000) * daysLastCalc;
                    mortgage.amountToPoolDelayed = ((dailyDelayedInterestToPay * percentagePoolDelayedPay) / 10000) * daysLastCalc;
                    if (mortgage.strikes == 2) {
                        mortgage.totalToPayOnLiquidation += mortgage.totalDelayedMonthlyPay;
                        mortgage.totalPoolLiquidation += mortgage.amountToPoolDelayed;
                        mortgage.totalPanoramLiquidation += mortgage.amountToPanoramDelayed;
                    }
                    // mortgage.isMonthlyPaymentDelayed = true;
                    mortgage.lastTimeCalc = block.timestamp;
                    mortgageControl.addDelayedMorgateInterestData(msg.sender,_IdMortgage,mortgage);
                }
            }
        }
    }

    ///@dev Function to calculate the mortgage interest payment for the user.
    ///@dev cuando el array de wallets sea muy grande hay que llamar a la funcion por lotes de wallets para evitar que consuma todo el gas durante su ejecucion.
    function CalcMortgageInterestPayment(address[] calldata _userWallet,uint256[] calldata _idMortgage) public onlyDev isPaused {
        if (_userWallet.length != _idMortgage.length) {
            revert("Array Mismatch");
        }

        for (uint16 i = 0; i < _userWallet.length; i++) {
            MortgageInterest memory mortgage = mortgageControl.getuserToMortgageInterest(_userWallet[i], _idMortgage[i]);
            if (!mortgage.liquidate) {
                (uint256 loan,uint256 period,uint64 interestrate,uint256 payCounter) = mortgageControl.getDebtInfo(_userWallet[i], _idMortgage[i]);
                if(!mortgageControl.getMortgageStatus(_userWallet[i], _idMortgage[i])){
                    if (payCounter == 0) {
                        mortgage.totalDebt = loan;
                    }
                    if (mortgage.strikes > 0) {
                        if (!mortgage.isMonthlyPaymentPayed) {
                            mortgage.isMonthlyPaymentDelayed = true;
                        }
                    }
                    if ((block.timestamp - mortgage.lastTimeCalc) > 1 days) {
                        uint256 daysLastCalc = (block.timestamp - mortgage.lastTimeCalc) / 86400;

                        if (!mortgage.isMonthlyPaymentDelayed) {
                            uint256 dayInterestToPay = (mortgage.totalDebt * interestrate) / 100000;
                            uint256 newAmountVault = loan / (period * 30);
                            mortgage.amountToVault += newAmountVault;
                            mortgage.totalMonthlyPay += (dayInterestToPay + newAmountVault) * daysLastCalc;
                            mortgage.amountToPanoram = ((dayInterestToPay * percentagePanoram) / 10000) * daysLastCalc;
                            mortgage.amountToPool = ((dayInterestToPay * percentagePool) / 10000) * daysLastCalc;

                            mortgage.isMonthlyPaymentPayed = false;
                            mortgage.strikes += 1;
                            mortgage.lastTimeCalc = block.timestamp;

                            mortgageControl.addNormalMorgateInterestData(_userWallet[i],_idMortgage[i],mortgage);
                            
                        } else {
                            uint256 dayDelayedInterestToPay = ((mortgage.totalDebt * interestrate) / 100000) * penalization;

                            uint256 newAmountVault = loan / (period * 30);
                            mortgage.amountToVault += newAmountVault;

                            mortgage.totalDelayedMonthlyPay = (dayDelayedInterestToPay + newAmountVault) * daysLastCalc;
                            mortgage.amountToPanoramDelayed = ((dayDelayedInterestToPay * percentagePanoramDelayedPay) / 10000) * daysLastCalc;
                            mortgage.amountToPoolDelayed = ((dayDelayedInterestToPay * percentagePoolDelayedPay) / 10000) * daysLastCalc;
                            mortgage.strikes += 1;
                            if (mortgage.strikes == 2) {
                                mortgage.totalToPayOnLiquidation = mortgage.totalMonthlyPay + mortgage.totalDelayedMonthlyPay;
                                mortgage.totalPoolLiquidation = mortgage.amountToPool + mortgage.amountToPoolDelayed;
                                mortgage.totalPanoramLiquidation = mortgage.amountToPanoram + mortgage.amountToPanoramDelayed;
                            } else if (mortgage.strikes >= 3) {
                                mortgage.totalToPayOnLiquidation += mortgage.totalDelayedMonthlyPay;
                                mortgage.totalPoolLiquidation += mortgage.amountToPoolDelayed;
                                mortgage.totalPanoramLiquidation += mortgage.amountToPanoramDelayed;
                                mortgage.liquidate = true;
                            }
                            mortgage.isMonthlyPaymentDelayed = true;
                            mortgage.lastTimeCalc = block.timestamp;

                            mortgageControl.addDelayedMorgateInterestData(_userWallet[i], _idMortgage[i], mortgage);
                            
                        }
                    }
                }
            }
        } // for
    }

    function handlePayment(address _token,uint256 _amount,MortgageInterest memory mortgageInt, uint256 _IdMortgage,bool delayedPayment) private nonReentrant {
        if (_token == address(Busd)) {
            bool success = Busd.transferFrom(msg.sender,address(this), _amount);
            if (success) {
                if (delayedPayment) {
                    vaultLenders.deposit(mortgageInt.amountToVault, _token);
                    PoolRewardsLenders.deposit(mortgageInt.totalPoolLiquidation, _token);
                    Busd.transfer(walletPanoram, mortgageInt.totalPanoramLiquidation);
                } else {
                    vaultLenders.deposit(mortgageInt.amountToVault, _token);
                    PoolRewardsLenders.deposit(mortgageInt.amountToPool, _token);
                    Busd.transfer(walletPanoram, mortgageInt.amountToPanoram);
                }
                setLocalMortgageData(mortgageInt, _IdMortgage);
            }
        } else if (_token == address(Usdc)) {
            bool success = Usdc.transferFrom(msg.sender, address(this), _amount);
            if (success) {
                if (delayedPayment) {
                    vaultLenders.deposit(mortgageInt.amountToVault, _token);
                    PoolRewardsLenders.deposit(mortgageInt.totalPoolLiquidation,_token);
                    Usdc.transfer(walletPanoram, mortgageInt.totalPanoramLiquidation);
                } else {
                    vaultLenders.deposit(mortgageInt.amountToVault, _token);
                    PoolRewardsLenders.deposit(mortgageInt.amountToPool, _token);
                    Usdc.transfer(walletPanoram, mortgageInt.amountToPanoram);
                }
                setLocalMortgageData(mortgageInt, _IdMortgage);
            }
        }
        emit successfullPayment(msg.sender, _IdMortgage, _amount);
    }

    function setLocalMortgageData(MortgageInterest memory mortgageInt, uint256 _IdMortgage) private {
        if (mortgageInt.amountToVault >= mortgageInt.totalDebt) {
                    mortgageInt.totalDebt = 0;
                    mortgageControl.updateMortgageState(_IdMortgage, msg.sender, true);
                } else {
                    mortgageInt.totalDebt -= mortgageInt.amountToVault;
                }
                mortgageInt.totalMonthlyPay = 0;
                mortgageInt.amountToPanoram = 0;
                mortgageInt.amountToPool = 0;
                mortgageInt.amountToVault = 0;
                mortgageInt.totalDelayedMonthlyPay = 0;
                mortgageInt.amountToPanoramDelayed = 0;
                mortgageInt.amountToPoolDelayed = 0;
                mortgageInt.totalToPayOnLiquidation = 0;
                mortgageInt.totalPoolLiquidation = 0;
                mortgageInt.totalPanoramLiquidation = 0;
                mortgageInt.strikes = 0;
                mortgageInt.isMonthlyPaymentPayed = true;
                mortgageInt.isMonthlyPaymentDelayed = false;
                mortgageInt.lastTimePayment = block.timestamp;

                mortgageControl.updateOnPayMortgageInterest(msg.sender, _IdMortgage, mortgageInt);
                mortgageControl.updateMortgagePayment(_IdMortgage, msg.sender);
    }

    function updatePaused(bool _status) public {
        if (!hasRole(DEV_ROLE, msg.sender)) {
             revert("have no dev role");
        }
        paused = _status;
    }

    ///@dev Funcion para actualizar los porcentajes a pagar a Panoram y al Pool en pago puntual
    function updateNormalPercentages(uint16 _panoram, uint16 _pool) public onlyDev isPaused{
        percentagePanoram = _panoram;
        percentagePool = _pool;
    }

  ///@dev Funcion para actualizar los porcentajes a pagar a Panoram y al Pool en pago moratorio
    function updateDelayedPercentages(uint16 _panoram, uint16 _pool) public onlyDev isPaused{
        percentagePanoramDelayedPay = _panoram;
        percentagePoolDelayedPay = _pool;
    }

    ///@dev Funcion para actualizar el porcentaje de penalizacion mensual por pago moratorio
    function updatePenalization(uint8 _penalization) public onlyDev isPaused{
        penalization = _penalization;
    }

    function updateVaultLenders(address _newVaultLenders) public onlyDev isPaused {
        vaultLenders = IVaultLenders(_newVaultLenders);
        Busd.approve(address(vaultLenders), 2**255);
        Usdc.approve(address(vaultLenders), 2**255);
    }

    function updatePoolRewardsLenders(address _PoolRewardsLenders) public onlyDev isPaused {
        PoolRewardsLenders = IVaultRewards(_PoolRewardsLenders);
        Busd.approve(address(PoolRewardsLenders), 2**255);
        Usdc.approve(address(PoolRewardsLenders), 2**255);
    }

    function updateMortgageControl(address _newMortgageControl) public onlyDev isPaused {
        mortgageControl = IMortgageControl(_newMortgageControl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultLenders {
    function deposit(uint256,address) external;

    function withdraw(uint256,address) external;

    function withdrawAll() external;

    function totalSupplyBUSD() external view returns (uint256);

    function totalSupplyUSDC() external view returns (uint256);

    function getBusdBorrows() external view returns(uint256 borrows);

    function getUsdcBorrows() external view returns(uint256 borrows);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultRewards {
    function deposit(uint256 _amount,  address _token) external;

    function withdraw(uint256 amount, address _token) external;

    function withdrawAll() external;

    function seeDaily() external view returns (uint256 tempRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

import "./IMortgageInterest.sol";

interface IMortgageControl is IMortgageInterest {

    function addIdInfo(uint256 id, address wallet) external;

    function getTotalMortgages() external view returns (uint256);

    function getDebtInfo(address _user, uint256 _mortgageId) external view returns(uint256,uint256,uint64,uint256);

    function mortgageStatuts(address _user, uint256 _mortgageId) external view returns (bool _isPay);

    function mortgageLink(address _user, uint256 _mortgageId) external view returns (bool _mortgageAgain, uint256 _linkId);

    function getMortgagesForWallet(address _wallet, address _collection)
        external
        view
        returns (uint256[] memory _idMortgagesForCollection);

    function getuserToMortgageInterest(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (MortgageInterest memory);

    // Get FrontEnd Data
    function getFrontMortgageData(address _wallet, uint256 _IdMortage)
        external
        view
        returns (
            uint256 totalDebt,
            uint256 totalMonthlyPay,
            uint256 totalDelayedMonthlyPay,
            uint256 totalToPayOnLiquidation,
            uint256 lastTimePayment,
            bool isMonthlyPaymentPayed,
            bool isMonthlyPaymentDelayed,
            bool liquidate
        );

    function getIdInfo(uint256 id) external view returns (address _user);

    function getStartDate(address _wallet, uint256 _mortgageID) external view returns(uint256);

    function getMortgageId(address _collection, uint256 _nftId) external view returns(uint256 _mortgageId);

    function getUserInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256, 
            uint64,
            uint256,
            bool,
            bool,
            uint256
        );

    function getMortgageStatus(address _user, uint256 _mortgageId) external view returns(bool _status);

    function addMortgageId(address _collection, uint256 _nftId, uint256 _loanId) external;

    function eraseMortgageId(address _collection, uint256 _nftId) external;

    function addRegistry(uint256 id, address wallet, address _collection, address _wrapContract,uint256 _nftId, uint256 _loan,uint256 _downPay,
    uint256 _price,uint256 _startDate,uint256 _period, uint64 _interestrate) external; 

    function updateMortgageLink(
        uint256 oldId,
        uint256 newId,
        address wallet,
        uint256 _loan,
        uint256 _downPay,
        uint256 _startDate,
        uint256 _period,
        bool _mortageState
    ) external;

    function updateMortgageState(
        uint256 id,
        address wallet,
        bool _state
    ) external;

    function updateMortgagePayment(uint256 id, address wallet) external;

    function addNormalMorgateInterestData(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory _mortgage
    ) external;

    function resetMortgageInterest(address _wallet, uint256 _idMortgage) external;
    
    function resetDebt(address _wallet, uint256 _idMortgage) external;
    
    function updateLastTimeCalc(address _wallet, uint256 _idMortgage,uint256 _lastTimeCalc) external;
    
    function addDelayedMorgateInterestData(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory _mortgage
    ) external;

    function updateOnPayMortgageInterest(
        address _wallet,
        uint256 _idMortgage,
        MortgageInterest memory mort
    ) external;

    function updateTotalDebtOnAdvancePayment(
        address _wallet,
        uint256 _idMortgage,
        uint256 _totalDebt
    ) external;

    ///@dev only for test erase in production
    function getTestInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256);
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
pragma solidity ^0.8.9;

interface IMortgageInterest {
    struct MortgageInterest {
        uint256 totalDebt; // para guardar lo que adeuda el cliente despues de cada pago
        uint256 totalMonthlyPay; // total a pagar en pago puntual 100
        uint256 amountToPanoram; // cantidad que se ira a la wallet de Panoram
        uint256 amountToPool; // cantidad que se ira al Pool de rewards
        uint256 amountToVault; // cantidad que se regresa al vault de lenders
        uint256 totalDelayedMonthlyPay; // total a pagar en caso de ser pago moratorio, incluye pagar las cuotas atrasadas
        uint256 amountToPanoramDelayed; // cantidad que se ira a la wallet de Panoram
        uint256 amountToPoolDelayed; // cantidad que se ira al Pool de rewards
        uint256 totalToPayOnLiquidation; // sumar los 3 meses con los interes
        uint256 totalPoolLiquidation; // intereses al pool en liquidation
        uint256 totalPanoramLiquidation; // total a pagar de intereses a panoram en los 3 meses que no pago.
        uint256 lastTimePayment; // guardamos la fecha de su ultimo pago
        uint256 lastTimeCalc; // la ultima vez que se calculo sus interes: para evitar calcularle 2 veces el mismo dia
        uint8 strikes; // cuando sean 2 se pasa a liquidacion. Resetear estas variables cuando se haga el pago
        bool isMonthlyPaymentPayed; // validar si ya hizo el pago mensual
        bool isMonthlyPaymentDelayed; // validar si el pago es moratorio
        bool liquidate; // true si el credito se liquido, se liquida cuando el user tiene 3 meses sin pagar
    }

    ///@notice structure and mapping that keeps track of mortgage
    struct Information {
        address collection;
        uint256 nftId;
        address wrapContract;
        uint256 loan; // total prestado
        uint256 downPay;
        uint256 price;
        uint256 startDate;
        uint256 period; //months
        uint64 interestrate; //interest percentage diario
        uint256 payCounter; //Start in zero
        bool isPay; //default is false
        bool mortgageAgain; //default is false
        uint256 linkId; //link to the new mortgage
    }
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