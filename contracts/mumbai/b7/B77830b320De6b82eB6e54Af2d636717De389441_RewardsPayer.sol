// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Marketplace/PRBMathUD60x18Typed.sol";

import "../Marketplace/IControl.sol";
import "./IVaultRewards.sol";
import "../Marketplace/ILazymint.sol";
import "../Marketplace/IVaultRent.sol";
import "../Lending/IVaultLenders.sol";
import "../Mortgage/IMortgageInterest.sol";
import "../Mortgage/IMortgageControl.sol";
import "./IUserRewards.sol";

import "./HelperRewardsContract.sol";
import "../Mortgage/TokenInfo.sol";
import "./IRewardsControl.sol";

/// @title A contract that Calculate and Pay the Rewards per User.
/// @author Panoram.
/// @notice You can use this contract to calculate and pay the user rewards for Minters(Builders), Holders and Rents.
contract RewardsPayer is AccessControl, HelperRewardsContract, IMortgageInterest, IUserRewards {
    using PRBMathUD60x18Typed for PRBMath.UD60x18;

    uint256 private constant MAX_UINT = 2 ** 255;
    /**
     * @dev Amount predefine to pay per NFT, when payRent = 0  -> the CalcRentRewardsForCollection Function will calculate the Rent pay per NFT based on
     *  the amount returned from the Rent Vault.
     */
    uint256 public payRent = 166666;

    IControl private controlContract;
    IMortgageControl private mortgageControl;
    TokenInfo private tokenInfo;
    IRewardsControl private RControl;

    /// @dev Constructor to set the permissions and access roles
    /// @param _tokenInfo - the address of the Token Info Contract.
    /// @param _Mortgagecontrol - the address of the Mortgage Control Contract.
    /// @param _controlContract - the address of the Control Contract.
    /// @param _token - the address of the Token allowed.
    /// @param vaultLenders - the address of the Vault Lenders Contract.
    /// @param VaultRewardsContract - the address of the Vault Rewards B & H Contract.
    /// @param PoolRewardsLenders - the address of the Vault Lenders Rewards Contract.
    /// @param _rewardsControl - the address of the Rewards Contrl Contract.
    constructor(
        address _tokenInfo,
        address _Mortgagecontrol,
        address _controlContract,
        address _token,
        address vaultLenders,
        address VaultRewardsContract,
        address PoolRewardsLenders,
        address _rewardsControl
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEV_ROLE, relayAddress); // defender relayer
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); //cambiar por el multisign
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); //cambiar por el multisign

        mortgageControl = IMortgageControl(_Mortgagecontrol);
        controlContract = IControl(_controlContract);
        tokenInfo = TokenInfo(_tokenInfo);
        RControl = IRewardsControl(_rewardsControl);

        permissions(_token, vaultLenders, VaultRewardsContract, PoolRewardsLenders);
    }

    ///@dev Modifier to check if the token address sent is allowed.
    modifier validToken(address _token) {
        if (!tokenInfo.getToken(_token)) {
            revert("Token not support");
        }
        _;
    }

    ///@dev Modifier to only allow the Relayer to use the Calc Functions.
    modifier onlyRelayer() {
        if (msg.sender != relayAddress) {
            revert("You're not Allowed");
        }
        _;
    }

    /// @dev CUANDO EL NUMERO DE WALLETS PARA LAS QUE SE CALCULARA EL REWARD SEA MUY ALTO, EL AUTOTASK DEBE MANDAR A LLAMAR,
    /// @dev ESTAS FUNCIONES POR LOTES PARA REDUCIR EL RIESGO DE QUE LA FUNCION SE ACABE EL GAS DURANTE LA EJECUCION DE LA FUNCION.

    /// @dev Function to calculate the user Rewards per being a Builder for all the collections.
    /// @param _walletsUsers - Array of user wallets for which we must do the calculation. The relayer must filter the wallets to avoid duplicates.
    /// @param _numNFTsMinted - Array with the number of NFTs that every wallet in _walletsUsers minted, the relayer must sort the array in the same order as the wallets array.
    /// @param _token - The token address to get the vault associated with it.
    function CalcBuilderRewardsDaily(
        address[] calldata _walletsUsers,
        uint256[] calldata _numNFTsMinted,
        address _token
    ) external onlyRelayer validToken(_token) isPaused {
        if (_walletsUsers.length != _numNFTsMinted.length) {
            revert("Arrays Mismatch");
        }
        (,, address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        uint256 ingresoTemporalDiario = IVaultRewards(VaultRewardsContract).seeDaily();
        if (ingresoTemporalDiario == 0) {
            revert("No Rewards yet");
        }

        uint256 payPerNFT = PRBMathForBH(ingresoTemporalDiario, true);

        UserRewardsBuilder memory rewards;
        for (uint24 i = 0; i < _walletsUsers.length;) {
            if (_numNFTsMinted[i] != 0) {
                rewards.rewardPerBuilder = _numNFTsMinted[i] * payPerNFT;
                rewards.rewardPerBuilderNFT = payPerNFT;
                rewards.lastTimeCalcBuilder = block.timestamp;
                RControl.setBuilderRewards(rewards, _walletsUsers[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to calculate the user Rewards per being a Holder for all the collections.
    /// @param _walletsUsers - Array of user wallets for which we must do the calculation. The relayer must filter the wallets to avoid duplicates.
    /// @param _numNFTsHolder - Array with the number of NFTs owned by each wallet in "_walletsUsers", the relayer must sort the array in the same order as the wallets array.
    /// @param _token - The token address to get the vault associated with it.
    function CalcHolderRewardsDaily(address[] calldata _walletsUsers, uint256[] calldata _numNFTsHolder, address _token)
        external
        onlyRelayer
        validToken(_token)
        isPaused
    {
        if (_walletsUsers.length != _numNFTsHolder.length) {
            revert("Array Mismatch");
        }
        (,, address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        uint256 ingresoTemporalDiario = IVaultRewards(VaultRewardsContract).seeDaily();
        if (ingresoTemporalDiario == 0) {
            revert("No Rewards yet");
        }

        uint256 payPerNFT = PRBMathForBH(ingresoTemporalDiario, false);

        UserRewardsHolder memory rewards;
        for (uint24 i = 0; i < _walletsUsers.length;) {
            if (_numNFTsHolder[i] != 0) {
                rewards.rewardPerHolder = _numNFTsHolder[i] * payPerNFT;
                rewards.rewardPerHolderNFT = payPerNFT;
                rewards.lastTimeCalcHolder = block.timestamp;
                RControl.setHolderRewards(rewards, _walletsUsers[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to calculate the B&H rewards amount to pay for each NFT, we use this private function to avoid the stack to deep error.
    /// @param _ingresoTemporalDiario - the amount to be distributed.
    /// @param _tag - True when CalcBuilder call the function, false when Calc Holders call it.
    /// @return PrePayPerNFT - the amount to pay per NFT in base 12 (12 decimals).
    function PRBMathForBH(uint256 _ingresoTemporalDiario, bool _tag) private view returns (uint256) {
        PRBMath.UD60x18 memory ITD = PRBMath.UD60x18({value: _ingresoTemporalDiario * 1e12});
        PRBMath.UD60x18 memory multITDxPercentageM;
        if (_tag) {
            multITDxPercentageM = ITD.mul(PRBMath.UD60x18({value: percentageMinters}));
        } else {
            multITDxPercentageM = ITD.mul(PRBMath.UD60x18({value: percentageHolders}));
        }
        PRBMath.UD60x18 memory ingresoDiarioForHolders = multITDxPercentageM.div(PRBMath.UD60x18({value: 10000}));
        PRBMath.UD60x18 memory PrePayPerNFT =
            ingresoDiarioForHolders.div(PRBMath.UD60x18({value: (controlContract.seeCounter() * 1e18)}));
        return (PrePayPerNFT.value / 1e12);
    }

    /// @dev Function to calculate the user's rent rewards per collection.
    /// @param _collection - the address of the NFT collection for which rents will be calculated.
    /// @param _walletsUsers - Array of user wallets for which we must make the calculation. The relayer must filter the wallets to avoid duplicates for each collection.
    /// @param _numNFTsHolder - Array with the number of NFTs owned by each wallet, the relayer must sort the array in the same order as the wallets array.
    function CalcRentRewardsForCollection(
        address _collection,
        address[] calldata _walletsUsers,
        uint256[] calldata _numNFTsHolder,
        uint256[] calldata _numDelayedMortgages
    ) external onlyRelayer isPaused {
        if (_walletsUsers.length != _numNFTsHolder.length || _walletsUsers.length != _numDelayedMortgages.length) {
            revert("Array Mismatch");
        }
        if (_collection == address(0)) {
            revert("Collection cannot be the address 0");
        }
        uint256 payPerNFT;
        if (payRent == 0) {
            address vaultRentRewards = tokenInfo.getVaultRent(_collection);
            uint256 monthlyRentIncome = IVaultRent(vaultRentRewards).seeQuarter();
            // LA VARIABLE DE QUATER DEL VAULT SE DEBE RESETEAR UNA VEZ AL MES
            if (monthlyRentIncome == 0) {
                revert("No Monthly Rental Income Yet");
            }

            payPerNFT = PRBMathForRents(monthlyRentIncome, _collection);
        } else {
            payPerNFT = payRent;
        }
        UserRewardsRent memory rent;

        for (uint24 i = 0; i < _walletsUsers.length;) {
            if (_numNFTsHolder[i] != 0) {
                rent.rewardPerRent = _numNFTsHolder[i] * payPerNFT;
                rent.rewardPerRentNFT = payPerNFT;
                rent.lastTimeCalcRent = block.timestamp;
                rent.rentsRetained = _numDelayedMortgages[i] * payPerNFT;
                RControl.setRentRewards(rent, _walletsUsers[i], _collection);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to calculate the rent amount to pay for each NFT, we use this private function to avoid the stack to deep error.
    /// @param _monthlyRentIncome - the amount of rent to be distributed.
    /// @param  _collection - the NFT collection address from which we are distributing the rents.
    /// @return PayPerNFT - the rent amount to pay per NFT in base 12 (12 decimals).
    function PRBMathForRents(uint256 _monthlyRentIncome, address _collection) private view returns (uint256) {
        ILazyNFT CollectionContract = ILazyNFT(_collection);
        PRBMath.UD60x18 memory MRI = PRBMath.UD60x18({value: _monthlyRentIncome * 1e12});
        PRBMath.UD60x18 memory dailyIncome = MRI.div(PRBMath.UD60x18({value: 30 * 1e18}));
        PRBMath.UD60x18 memory PayPerNFT =
            dailyIncome.div(PRBMath.UD60x18({value: CollectionContract.totalSupply() * 1e18})); // case for mainnet
        return (PayPerNFT.value / 1e12); // Return in 6 decimal factor.
    }

    /// @dev Function to allow the user to withdraw his rewards if he is a Builder user.
    /// @param _token - the token address used to pay the Builder Rewards.
    function payBuilderReward(address _token) external validToken(_token) isPaused nonReentrant {
        UserRewardsBuilder memory rBuilder = RControl.getBuilderRewards(msg.sender);
        if (rBuilder.rewardPerBuilder == 0) {
            revert("You have no rewards available");
        }
        uint256 amountReward = rBuilder.rewardPerBuilder;
        (,, address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        RControl.setBuilderRewardsTimePay(block.timestamp, msg.sender); // set the time and rewards to 0.
        IVaultRewards(VaultRewardsContract).withdraw(amountReward, _token);

        handleTransferUser(IERC20(_token), amountReward, msg.sender, rBuilder.rewardPerBuilderNFT, address(0));
    }

    /// @dev Function to allow the user to withdraw his rewards per being a Holder of an NFT.
    /// @param _token - the token address used to pay the Holder Rewards.
    function payHolderReward(address _token) external validToken(_token) isPaused nonReentrant {
        UserRewardsHolder memory rHolder = RControl.getHolderRewards(msg.sender);
        if (rHolder.rewardPerHolder == 0) {
            revert("You have no rewards available");
        }
        uint256 amountReward = rHolder.rewardPerHolder;
        (,, address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        RControl.setHolderRewardsTimePay(block.timestamp, msg.sender);
        IVaultRewards(VaultRewardsContract).withdraw(amountReward, _token);

        handleTransferUser(IERC20(_token), amountReward, msg.sender, rHolder.rewardPerHolderNFT, address(0));
    }

    /// @dev Function to allow the user to withdraw his Rent for a collection where He holds an NFT.
    /// @param _collection - the address of the NFT collection from which the user wants to claim his rents.
    /// @param _token - the token address used to pay the Rents.
    function payRentReward(address _collection, address _token) external validToken(_token) isPaused nonReentrant {
        UserRewardsRent memory rents = RControl.getRent(msg.sender, _collection);
        uint256 rentsToClaim = rents.rewardPerRent - rents.rentsRetained;
        if (rentsToClaim == 0) {
            revert("You have no rewards available");
        }
        address VaultRentRewards = tokenInfo.getVaultRent(_collection);
        IVaultRent(VaultRentRewards).withdraw(rentsToClaim, _token);

        // memory to memory crea referencias por lo que los cambios en una variable en memoria, lo puden ver todas las otras referencias que apuntan a la misma memoria.

        RControl.setRentRewardsTimePay(block.timestamp, msg.sender, _collection);
        handleTransferUser(IERC20(_token), rentsToClaim, msg.sender, rents.rewardPerRentNFT, _collection);
    }

    /// @dev Function to allow the user to withdraw all his rewards from builder, holder and rents.
    /// @param _collections - An array with the addresses of the NFT collections in which the user owns NFTs.
    /// @param _token - the token address used to pay the Rewards.
    function payAllRewards(address[] calldata _collections, address _token)
        external
        validToken(_token)
        isPaused
        nonReentrant
    {
        uint256 amountRents = 0;
        uint256 amountRentFinal = 0;
        for (uint16 i = 0; i < _collections.length;) {
            UserRewardsRent memory rents = RControl.getRent(msg.sender, _collections[i]);
            amountRents = rents.rewardPerRent - rents.rentsRetained;

            address VaultRentRewards = tokenInfo.getVaultRent(_collections[i]);
            IVaultRent(VaultRentRewards).withdraw(amountRents, _token);

            if (amountRents > 0) {
                amountRentFinal += amountRents;
                RControl.setRentRewardsTimePay(block.timestamp, msg.sender, _collections[i]);
            }
            unchecked {
                ++i;
            }
        } // Fin For

        uint256 amountRewards = RControl.getOnlyRewardsBH(msg.sender);
        if (amountRewards == 0 && amountRentFinal == 0) {
            revert("No Rewards to claim yet");
        }
        RControl.setBuilderRewardsTimePay(block.timestamp, msg.sender);
        RControl.setHolderRewardsTimePay(block.timestamp, msg.sender);
        (,, address VaultRewardsContract) = tokenInfo.getVaultInfo(_token);
        IVaultRewards(VaultRewardsContract).withdraw(amountRewards, _token);

        uint256 finalAmountToClaim = amountRewards + amountRentFinal;
        handleTransferUser(IERC20(_token), finalAmountToClaim, msg.sender, 0, address(0));
    }

    /// @dev Function to update the amount of Rents to pay per NFT.
    function updatePayPerNFT(uint256 _newPayPerNFT) external onlyDev {
        payRent = _newPayPerNFT;
    }

    /// @dev Function to update the Control contract address.
    /// @param _newControl - The address of the new Control Contract.
    function updateControl(address _newControl) external onlyDev {
        controlContract = IControl(_newControl);
    }

    /// @dev Function to update the Mortgage Control address.
    /// @param _newMcontrol - The address of the new Mortgage Control Contract.
    function updateMortgageControl(address _newMcontrol) external onlyDev {
        mortgageControl = IMortgageControl(_newMcontrol);
    }

    /// @dev Function to update the address of the Token Info Contract.
    /// @param _tokenInfo - The address of the new Token Info Contract.
    function updateTokenInfo(address _tokenInfo) external onlyDev {
        tokenInfo = TokenInfo(_tokenInfo);
    }

    /// @dev Function to update the address of the Rewards Control Contract.
    /// @param _rewControl - The address of the new Rewards Control Contract.
    function updateRewardsControl(address _rewControl) external onlyDev {
        RControl = IRewardsControl(_rewControl);
    }

    /// @dev Function to approve the contracts to transfer the money to pay the Rewards.
    /// @param _token - The address of the token to transfer.
    /// @param _lender - the address of the Vault Lenders Contract.
    /// @param _rewards - the address of the Vault Rewards B&H Contract.
    /// @param lendersRewards - the address of the Vault Lenders Rewards Contract.
    function permissions(address _token, address _lender, address _rewards, address lendersRewards)
        public
        onlyDev
        validToken(_token)
    {
        IERC20(_token).approve(_lender, MAX_UINT);
        IERC20(_token).approve(_rewards, MAX_UINT);
        IERC20(_token).approve(lendersRewards, MAX_UINT);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

/// @title Vault Rewards Builder & Holders Interface.
/// @author Panoram Finance.
/// @notice Use this interface in other contracts to connect to the Vault Rewards Builder & Holders Contract.
interface IVaultRewards {

    /// @dev Function to deposit money in the vault.
    function deposit(uint256 _amount,  address _token) external;

    /// @dev Function to withdraw money from the vault.
    function withdraw(uint256 amount, address _token) external;

    /// @dev Function for the Multisig to withdraw all the money from the vault if necessary in an emergency.
    function withdrawAll() external;

    /// @dev Function to read the amount of rewards to distribute each day.
    function seeDaily() external returns (uint256 tempRewards);

    /// @dev Function to get the last time the seeDaily flag was calculated.
    function getLastCall() external view returns(uint256 _last);

    /// @dev Function to get the available rewards in the vault to distribute.
    function getAvaibleRewards() external view returns(uint256 _avaible);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18Typed
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
/// @dev This is the same as PRBMathUD59x18, except that it works with structs instead of raw uint256s.
library PRBMathUD60x18Typed {
    /// STORAGE ///

    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Adds two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @param x The first summand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second summand as an unsigned 60.18-decimal fixed-point number.
    /// @param result The sum as an unsigned 59.18 decimal fixed-point number.
    function add(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        unchecked {
            uint256 rValue = x.value + y.value;
            if (rValue < x.value) {
                revert PRBMathUD60x18__AddOverflow(x.value, y.value);
            }
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            uint256 rValue = (x.value >> 1) + (y.value >> 1) + (x.value & y.value & 1);
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        if (xValue > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(xValue);
        }

        uint256 rValue;
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(xValue, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            rValue := add(xValue, mul(delta, gt(remainder, 0)))
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        result = PRBMath.UD60x18({ value: PRBMath.mulDiv(x.value, SCALE, y.value) });
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: 2_718281828459045235 });
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (xValue >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(xValue);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x.value * LOG2_E;
            PRBMath.UD60x18 memory exponent = PRBMath.UD60x18({ value: (doubleScaleProduct + HALF_SCALE) / SCALE });
            result = exp2(exponent);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x.value >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x.value);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x.value << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.UD60x18({ value: PRBMath.exp2(x192x64) });
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        uint256 rValue;
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(xValue, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            rValue := sub(xValue, mul(remainder, gt(remainder, 0)))
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        uint256 rValue;
        assembly {
            rValue := mod(xValue, SCALE)
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = PRBMath.UD60x18({ value: x * SCALE });
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        if (x.value == 0) {
            return PRBMath.UD60x18({ value: 0 });
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x.value * y.value;
            if (xy / x.value != y.value) {
                revert PRBMathUD60x18__GmOverflow(x.value, y.value);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.UD60x18({ value: PRBMath.sqrt(xy) });
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = PRBMath.UD60x18({ value: 1e36 / x.value });
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            uint256 rValue = (log2(x).value * SCALE) / LOG2_E;
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        if (xValue < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(xValue);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        uint256 rValue;

        // prettier-ignore
        assembly {
            switch xValue
            case 1 { rValue := mul(SCALE, sub(0, 18)) }
            case 10 { rValue := mul(SCALE, sub(1, 18)) }
            case 100 { rValue := mul(SCALE, sub(2, 18)) }
            case 1000 { rValue := mul(SCALE, sub(3, 18)) }
            case 10000 { rValue := mul(SCALE, sub(4, 18)) }
            case 100000 { rValue := mul(SCALE, sub(5, 18)) }
            case 1000000 { rValue := mul(SCALE, sub(6, 18)) }
            case 10000000 { rValue := mul(SCALE, sub(7, 18)) }
            case 100000000 { rValue := mul(SCALE, sub(8, 18)) }
            case 1000000000 { rValue := mul(SCALE, sub(9, 18)) }
            case 10000000000 { rValue := mul(SCALE, sub(10, 18)) }
            case 100000000000 { rValue := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { rValue := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { rValue := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { rValue := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { rValue := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { rValue := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { rValue := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { rValue := 0 }
            case 10000000000000000000 { rValue := SCALE }
            case 100000000000000000000 { rValue := mul(SCALE, 2) }
            case 1000000000000000000000 { rValue := mul(SCALE, 3) }
            case 10000000000000000000000 { rValue := mul(SCALE, 4) }
            case 100000000000000000000000 { rValue := mul(SCALE, 5) }
            case 1000000000000000000000000 { rValue := mul(SCALE, 6) }
            case 10000000000000000000000000 { rValue := mul(SCALE, 7) }
            case 100000000000000000000000000 { rValue := mul(SCALE, 8) }
            case 1000000000000000000000000000 { rValue := mul(SCALE, 9) }
            case 10000000000000000000000000000 { rValue := mul(SCALE, 10) }
            case 100000000000000000000000000000 { rValue := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { rValue := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { rValue := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { rValue := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { rValue := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { rValue := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { rValue := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { rValue := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { rValue := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { rValue := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { rValue := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { rValue := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { rValue := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { rValue := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { rValue := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { rValue := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { rValue := mul(SCALE, 59) }
            default {
                rValue := MAX_UD60x18
            }
        }

        if (rValue != MAX_UD60x18) {
            result = PRBMath.UD60x18({ value: rValue });
        } else {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                rValue = (log2(x).value * SCALE) / 3_321928094887362347;
                result = PRBMath.UD60x18({ value: rValue });
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        uint256 xValue = x.value;
        if (xValue < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(xValue);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(xValue / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            uint256 rValue = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = xValue >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return PRBMath.UD60x18({ value: rValue });
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    rValue += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result = PRBMath.UD60x18({ value: rValue });
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        result = PRBMath.UD60x18({ value: PRBMath.mulDivFixedPoint(x.value, y.value) });
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: 3_141592653589793238 });
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        if (x.value == 0) {
            return PRBMath.UD60x18({ value: y.value == 0 ? SCALE : uint256(0) });
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(PRBMath.UD60x18 memory x, uint256 y) internal pure returns (PRBMath.UD60x18 memory result) {
        // Calculate the first iteration of the loop in advance.
        uint256 xValue = x.value;
        uint256 rValue = y & 1 > 0 ? xValue : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            xValue = PRBMath.mulDivFixedPoint(xValue, xValue);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                rValue = PRBMath.mulDivFixedPoint(rValue, xValue);
            }
        }
        result = PRBMath.UD60x18({ value: rValue });
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (PRBMath.UD60x18 memory result) {
        result = PRBMath.UD60x18({ value: SCALE });
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(PRBMath.UD60x18 memory x) internal pure returns (PRBMath.UD60x18 memory result) {
        unchecked {
            if (x.value > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x.value);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.UD60x18({ value: PRBMath.sqrt(x.value * SCALE) });
        }
    }

    /// @notice Subtracts one unsigned 60.18-decimal fixed-point number from another one, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @param x The minuend as an unsigned 60.18-decimal fixed-point number.
    /// @param y The subtrahend as an unsigned 60.18-decimal fixed-point number.
    /// @param result The difference as an unsigned 60.18 decimal fixed-point number.
    function sub(PRBMath.UD60x18 memory x, PRBMath.UD60x18 memory y)
        internal
        pure
        returns (PRBMath.UD60x18 memory result)
    {
        unchecked {
            if (x.value < y.value) {
                revert PRBMathUD60x18__SubUnderflow(x.value, y.value);
            }
            result = PRBMath.UD60x18({ value: x.value - y.value });
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(PRBMath.UD60x18 memory x) internal pure returns (uint256 result) {
        unchecked {
            result = x.value / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

interface IControl {

   function getNFTInfo(address _collection, uint256 _id)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint32
        );

    function getNFTMinted(address _wallet) external view returns (uint256 _minted);

    function getNFTQuantity(address _wallet, address _collection)external view returns (uint256 _quantity);

    function getNFTTotal(address _wallet) external view returns (uint256 _total);

    function addRegistry(address _collection, uint256 _nftId, address _wallet,uint32 _timestamp) external;

    function removeRegistry(address _collection, uint256 _nftId) external;

    function addQuantity(address _wallet,address _collection,uint256 _amount) external;

    function removeQuantity(address _wallet,address _collection, uint256 _amount) external;

    function addMinted(address _wallet,uint256 _amount) external;

    function addCounter() external;

    function seeCounter() external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

interface IVaultRent {
    function deposit(uint256 _amount,  address _token) external;

    function withdraw(uint256 amount, address _token) external;

    function withdrawAll() external;

    function seeQuarter() external view returns (uint256 tempRewards);
    
    function Name() external view returns (string memory _name);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyNFT is IERC165{
    
    function redeem(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function preSale(
        address _redeem,
        uint256 _amount
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory base);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory, uint256 _length);

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);
     
    function getPrice() external view returns (uint256);
    
    function getPresale() external view returns (uint256);

    function getPresaleStatus() external view returns (bool);

    function nftValuation() external view returns (uint256 _nftValuation);

    function getValuation() external view returns (uint256 _valuation);

    function setApprovalForAll(address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Helper Rewards Contract.
/// @author Panoram Finance.
/// @notice This contract was create it as a helper to reduce the size of the rewards contract.
contract HelperRewardsContract is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 internal constant DEV_ROLE = keccak256("DEV_ROLE");

    /// @dev Percentages in base 10k
    uint16 public percentageHolders = 8180; // 81.80%
    uint16 public percentageMinters = 1820; // 18.20%
    bool internal paused = false;

    // ********* CAMBIAR EL ADDRESS DEL RELAYER BEFORE DEPLOYMENT ********* //

    address internal relayAddress = 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23; // 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23; //0x988F94C0Ef61815AacD775789Af297713408D3B8;
    address public walletPanoram = 0x30268390218B20226FC101cD5651A51b12C07470; // Cambiar por el multisig

    event withdrawSuccess(address indexed walletUser, uint256 amountReward, uint256 payPerNFT, address collection);

    /// @dev Modifier to check if an Address has the  Dev Role to use admin functions.
    modifier onlyDev() {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("Not enough Permissions");
        }
        _;
    }

    /// @dev Modifier to prevent the use of the function if the contract is paused.
    modifier isPaused() {
        if (paused) {
            revert("contract paused");
        }
        _;
    }

    /// @dev constructor to set the roles.
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); // Cambiar por el MULTISIG.
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); // Cambiar por el MULTISIG.
        _setupRole(DEV_ROLE, relayAddress);
        _setupRole(DEV_ROLE, msg.sender);
    }

    /// @dev Function to handle the transfer of tokens to pay the rewards.
    /// @param _token - The address of the toke to transfer.
    /// @param _amount - The amount to transfer.
    /// @param _wallet - The address of the beneficiary of the transfer.
    /// @param _payPerNFT - The amount paid per NFT.
    /// @param _collection - The address of the collection from which the user claim the rent.
    function handleTransferUser(
        IERC20 _token,
        uint256 _amount,
        address _wallet,
        uint256 _payPerNFT,
        address _collection
    ) internal {
        _token.safeTransfer(_wallet, _amount);
        emit withdrawSuccess(_wallet, _amount, _payPerNFT, _collection);
    }

    /// @dev Function to update the Holders percentage.
    /// @param _newPercentage - the new Percentage for Holders.
    /// @notice Estas funciones tienes que dar una suma 100% en total porque ya se tiene separado el 50% de panoram en multisign.
    function updatePercentageHolders(uint8 _newPercentage) external onlyDev {
        percentageHolders = _newPercentage;
    }

    /// @dev Function to update the Minters percentage.
    /// @param _newPercentage - the new Percentage for Minters.
    function updatePercentageMinters(uint8 _newPercentage) external onlyDev {
        percentageMinters = _newPercentage;
    }

    /// @dev Function to update the address of the panoram wallet.
    /// @param _newWalletPanoram - the address of the new Panoram Wallet.
    function updatePanoramWallet(address _newWalletPanoram) external onlyDev {
        walletPanoram = _newWalletPanoram;
    }

    /// @dev Function to update the address of the Relayer.
    /// @param _relayer - the address of the new Relayer.
    function updateRelayer(address _relayer) external onlyDev {
        relayAddress = _relayer;
    }

    /// @dev Function to pause or unpause the contract if necessary.
    /// @param _Status - True = Pause , False = Unpause.
    function updatePaused(bool _Status) external onlyDev {
        paused = _Status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.11;

/// @title Vault Lenders Interface.
/// @author Panoram Finance.
/// @notice You can use this interface to connect to the Vault Lenders contract.
interface IVaultLenders {
    /// @dev Function to deposit tokens in the vault.
    function deposit(uint256,address) external;

    /// @dev Function to deposit Capital payments for loans.
    function depositCapital(uint256,address) external;

    /// @dev Function to withdraw money when a loan is created
    function withdraw(uint256,address) external;

    /// @dev Function for the multisign to withdraw all the money in the vault if necessary.
    function withdrawAll() external;

    /// @dev Function to get the variable totalSupply, that represents the total tokens in the vault.
    function totalSupply() external view returns (uint256);

    /// @dev Function to get the total borrowed money.
    function getBorrows() external view returns(uint256 _borrows);

    /// @dev Function to get the available money for loans.
    function getAvaible() external view returns(uint256 _avaible);

    /// @dev Function to add a withdrawal request for the money that the user deposited in lending. 
    /// @dev They will be able to withdraw the money when the withdrawal waiting time is over.
    function addRequest(uint256 _amount) external;

    /// @dev Function to delete a withdrawals request when the user cancel the request.
    function deleteRequest(uint256 _amount) external;

    /// @dev Function to transfer money from the vault to the lending contract to fulfill a user's withdrawal request.
    function claimRequest(uint256 _amount) external;

    /// @dev Function to get the amount of money requested for withdrawal.
    function getMoneyRequest() external view returns(uint256);

    /// @dev Function to get the maximum amount that can be deposit into the vault.
    function getMaxDeposit() external view returns(uint256);

    /// @dev Function to get the minimum amount that can be deposit into the vault.
    function getMinDeposit() external view returns(uint256);

    /// @dev Function to get the percentage of the vault used in loans, based on scale of 10k.
    function usageRatio() external view returns(uint256 _usage);
}

// SPDX-License-Identifier: MIT

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

/// @title User rewards Interface.
/// @author Panoram Finance.
/// @notice This interface is used to declare the structures that hold the variables for the differents Rewards.
interface IUserRewards {
    /// @dev Struct to register the data need it to calculate the user's builder rewards.
    struct UserRewardsBuilder {
        uint256 rewardPerBuilder; // amount of rewards per being a Builder.
        uint256 lastTimePayBuilder; // last time the user claims the rewards.
        uint256 lastTimeCalcBuilder; // last time the rewards were calculated.
        uint256 rewardPerBuilderNFT; // Builder Reward amount paid for each NFT.
    }

    /// @dev Struct to register the data need it to calculate the user's holder rewards.
    struct UserRewardsHolder {
        uint256 rewardPerHolder; // amount of rewards per being a Holder.
        uint256 lastTimePayHolder; // last time the user claims the rewards.
        uint256 lastTimeCalcHolder; // last time the rewards were calculated.
        uint256 rewardPerHolderNFT; // Holder Reward amount paid for each NFT.
    }

    /// @dev struct used to register the rents assigned to the user.
    struct UserRewardsRent {
        uint256 rewardPerRent; // amount of rent to be paid to the user for being a holder of NFTs
        uint256 lastTimePayRent; // last time the user claims the rents.
        uint256 lastTimeCalcRent; // last time the rents were calculated.
        uint256 rewardPerRentNFT; // amount of rent paid for each NFT.
        uint256 rentsRetained; // Amount of Rents retained for being delayed in a mortgage payments
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract TokenInfo is AccessControl {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    
    modifier onlydev() {
         if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("have no dev role");
        }
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23); 
    }

    struct Vaults{
        address lender;
        address lenderRewards;
        address rewards;
    }
    //registration and control of approved tokens
    mapping(address => bool) internal tokens;
    //save the token contract and the vault for it
    mapping(address => Vaults) internal vaultsInfo;
    //save the collection contract and the rental vault contract to be used for each collection
    mapping(address => address) internal collectionToVault;

    function addToken(address _token) public onlydev {
        tokens[_token] = true;
    }

    function removeToken(address _token) public onlydev {
        tokens[_token] = false;
    }

    function getToken(address _token) public view returns(bool _ok){
        return tokens[_token];
    }

    function addVaultRegistry(address _token, address _lender,address _lenderRewards,address _rewards) public onlydev  {
        vaultsInfo[_token].lender = _lender;
        vaultsInfo[_token].lenderRewards = _lenderRewards;
        vaultsInfo[_token].rewards = _rewards;
    }

    function removeVaultRegistry(address _token) public onlydev  {
        vaultsInfo[_token].lender = address(0);
        vaultsInfo[_token].lenderRewards = address(0);
        vaultsInfo[_token].rewards = address(0);
    }

    function getVaultInfo(address _token) public view returns(address _lender, address _lenderRewards,address _rewards){
        return ( vaultsInfo[_token].lender,
        vaultsInfo[_token].lenderRewards,
        vaultsInfo[_token].rewards);
    }

    function addVaultRent(address _collection, address _vault) public onlydev {
        collectionToVault[_collection] = _vault;
    }

    function removeVaultRent(address _collection) public onlydev {
        collectionToVault[_collection] = address(0);
    }

    function getVaultRent(address _collection) public view returns(address _vault){
        return collectionToVault[_collection];
    }
}

// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

// Changes v2

pragma solidity 0.8.16;

interface IMortgageInterest {
    struct MortgageInterest {
        uint256 totalDebt; // para guardar lo que adeuda el cliente despues de cada pago
        uint256 capitalDailyPay; // pago de capital diario
        uint256 interestDailyPay; // pago total de intereses diarios.
        uint256 interestPanoramDaily; // intereses diarios a pagar a panoram.
        uint256 interestRewardLender; // intereses diarios a pagar al vault de Rewards Lenders.
        uint256 lateInterestDaily; // pago total de intereses moratorios diarios.
        uint256 lateInterestPanoramDaily; // intereses moratorios diarios a pagar a panoram.
        uint256 lateInterestRewardLender; // intereses moratorios diarios a pagar al vault de Rewards Lenders.
        uint256 lastTimePayment; // guardamos la fecha de su ultimo pago para calcular el siguiente pago desde esta fecha
        uint256 interestLendersPaid; // cantidad pagada con las rentas retenidas de los intereses para lenders, al momento de la liquidacion.
        uint256 interestPanoramPaid; // cantidad pagada con las rentas retenidas de los intereses de Panoram, al momento de la liquidacion.
        uint8 strikes; // cuando sean 2 se pasa a liquidacion. Resetear estas variables cuando se haga el pago
        bool isMonthlyPaymentDelayed; // validar si el pago es moratorio
        bool liquidate; // true si el credito se liquido, se liquida cuando el user tiene 3 meses sin pagar
        bool soldAtAuction; // true cuando la hipoteca se vendio y pago en una Subasta por liquidacion.
    }

    ///@notice structure and mapping that keeps track of mortgage
    struct Information {
        address collection;
        uint256 nftId;
        address wrapContract;
        uint256 loan; // total prestado
        uint256 downPay;
        uint256 capitalPay;
        uint256 price;
        uint256 startDate;
        uint256 period; //months
        uint256 payCounter; //Start in zero
        bool isPay; //default is false
        bool mortgageAgain; //default is false
        uint256 linkId; //link to the new mortgage
    }
}

// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

import "./IMortgageInterest.sol";

interface IMortgageControl is IMortgageInterest {
    function addIdInfo(uint256 id, address wallet) external;

    function updateCapitalPay(uint256 id, address wallet, uint256 _newDebt) external;

    function getTotalMortgages() external view returns (uint256);

    function getCapitalPay(address _user, uint256 _mortgageId) external view returns (uint256 _capitalPay);

    function getDebtInfo(address _user, uint256 _mortgageId) external view returns (uint256, uint256, uint256);

    function getMortgageLiquidationStatus(address _user, uint256 _mortgageId) external view returns (bool _status);

    function mortgageLink(address _user, uint256 _mortgageId)
        external
        view
        returns (bool _mortgageAgain, uint256 _linkId);

    function getMortgagesForWallet(address _wallet, address _collection)
        external
        view
        returns (uint256[] memory _idMortgagesForCollection);

    function getuserToMortgageInterest(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (MortgageInterest memory);

    // Get FrontEnd Data
    // Changes v2
    function getFrontMortgageData(address _wallet, uint256 _IdMortage)
        external
        view
        returns (
            uint256 totalDebt,
            uint256 lastTimePayment,
            uint8 strikes,
            bool isMonthlyPaymentDelayed,
            bool liquidate
        );

    function getIdInfo(uint256 id) external view returns (address _user);

    function getInterestRate() external view returns (uint64 _interest);

    function getMortgageId(address _collection, uint256 _nftId) external view returns (uint256 _mortgageId);

    function getStartDate(address _wallet, uint256 _mortgageID) external view returns (uint256);

    function getUserInfo(address _user, uint256 _mortgageId)
        external
        view
        returns (address, uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, bool, bool, uint256);

    function getMortgageStatus(address _user, uint256 _mortgageId) external view returns (bool _status);

    function addMortgageId(address _collection, uint256 _nftId, uint256 _loanId) external;

    function eraseMortgageId(address _collection, uint256 _nftId) external;

    function addRegistry(
        uint256 id,
        address wallet,
        address _collection,
        address _wrapContract,
        uint256 _nftId,
        uint256 _loan,
        uint256 _downPay,
        uint256 _price,
        uint256 _startDate,
        uint256 _period
    ) external;

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

    function updateMortgageState(uint256 id, address wallet, bool _state) external;

    function updateMortgagePayment(uint256 id, address wallet) external;

    function resetDebt(address _wallet, uint256 _idMortgage) external;

    function updateTotalDebt(address _wallet, uint256 _idMortgage, uint256 _totalDebt) external;

    function updateLastTimePayment(address _wallet, uint256 _idMortgage, uint256 _lastPayment) external;

    function migrateMortgateInterest(address _wallet, uint256 _IdMortgage, MortgageInterest calldata mort) external;

    function migrateMortgateDebt(address _wallet, uint256 _IdMortgage, Information calldata _debt) external;

    // Changes v2
    function saveMortgageInterestData(
        uint256 _id,
        address _wallet,
        uint256 _DailyInt,
        uint256 _DailyPanoramInt,
        uint256 _DayRewardLenderInt,
        uint256 _DelayedIntDaily,
        uint256 _DelayedIntPanoramDaily,
        uint256 _DelayedIntRewLender
    ) external;

    function resetStrikes(uint256 _id, address _user) external;

    function updateStrikes(uint256 _idMortgage, address _user, uint256 _payPerNFT, address collection)
        external
        returns (bool liquidated, uint256 amountLiquidated);

    function updateMonthlyPaymentDelayed(address _wallet, uint256 _idMortgage, bool _state) external;

    function updateSoldAtAuction(uint256 id, address wallet, bool _state) external;

    function getCollection(address _wallet, uint256 _mortgageID) external view returns (address _collection);

    function reduceDelayedMortgages(address _wallet, address _collection) external;

    function getRetainedRent(address _user, address _collection, uint256 _mortgageID)
        external
        view
        returns (uint256 _userRetainedRents);

    function resetRentRetained(address _user, address _collection, uint256 _mortgageID) external;

    /// @dev Function to set the interest amount paid to Lenders with the retained rents when the user is liquidated.
    function setInterestLendersPaidOnLiquidation(uint256 _idMortgage, address _user, uint256 _amountLenders) external;

    /// @dev Function to set the interest amount paid to Lenders with the retained rents when the user is liquidated.
    function setInterestPanoramPaidOnLiquidation(uint256 _idMortgage, address _user, uint256 _amountPanoram) external;

    /// @dev Function to get the amount of interest paid with the retained rents.
    function getInterestPaid(address _user, uint256 _mortgageID)
        external
        view
        returns (uint256 LendersInterest, uint256 PanoramInterest);
}

// SPDX-License-Identifier: MIT

// Smart Contract v2.0.0 - (May 9, 2023).

pragma solidity 0.8.16;

import "./IUserRewards.sol";

/// @title Rewards Control Interface.
/// @author Panoram Finance.
/// @notice You can use this interface in other contracts to connect to the Rewards Control Contract.
interface IRewardsControl is IUserRewards {
    /// @dev Function to get the user's Rewards for being a Builder.
    function getBuilderRewards(address _user) external view returns (UserRewardsBuilder memory _userBuilderRewards);

    /// @dev Function to get the user's Rewards for being a Holder.
    function getHolderRewards(address _user) external view returns (UserRewardsHolder memory _userHolderRewards);

    /// @dev Function to get the user's Rents.
    function getRent(address _user, address _collection) external view returns (UserRewardsRent memory _userRents);

    /// @dev Function to set the user's Rewards per being a Builder.
    function setBuilderRewards(UserRewardsBuilder calldata _rewardsB, address _user) external;

    /// @dev Function to set the user's Rewards per being a Holder.
    function setHolderRewards(UserRewardsHolder calldata _rewardsH, address _user) external;

    /// @dev Function to set the user's Rents Rewards.
    function setRentRewards(UserRewardsRent calldata _rent, address _user, address _collection) external;

    /// @dev Function to set the date the user claims his builder Rewards and set Builders Rewards to 0.
    function setBuilderRewardsTimePay(uint256 _timePay, address _user) external;

    /// @dev Function to set the date the user claims his Holder Rewards and set Holders Rewards to 0.
    function setHolderRewardsTimePay(uint256 _timePay, address _user) external;

    /// @dev Function to set the date the user claims his Rent and set Rents to 0.
    function setRentRewardsTimePay(uint256 _timePay, address _user, address _collection) external;

    /// @dev Function to get only the Rewards register in the Structs for Builders & Holders.
    function getOnlyRewardsBH(address _user) external view returns (uint256 userRewardsBH);

    /// @dev Function to get the user's Rents Pay Per NFT.
    function getPayPerNFT(address _user, address _collection) external view returns (uint256 _payPerNFT);

    /// @dev Function to get the user's Rents Retained.
    function getRentRetained(address _user, address _collection) external view returns (uint256 _rentRetained);

    /// @dev Function to update the Rents Retained of the user, the function rest the amount sent to the original value of Rent Retained.
    function updateRentRetained(address _user, address _collection, uint256 _restRentRetained) external;

    /// @dev Function to update the Rents Accumulated of the user if one mortgage is liquidated, the function rest the amount sent to the original value of Rent Reward.
    function updateAccumulatedRent(address _user, address _collection, uint256 _restRentRetained) external;

    /// @dev Function to migrate the data from old Rewards Payer contract to the new Rewards Control contract.
    function setMigrationData(
        UserRewardsBuilder calldata _bRewards,
        UserRewardsHolder calldata _hRewards,
        address _user
    ) external;

    function setMigrationRentData(UserRewardsRent calldata _rents, address _collection, address _user) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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