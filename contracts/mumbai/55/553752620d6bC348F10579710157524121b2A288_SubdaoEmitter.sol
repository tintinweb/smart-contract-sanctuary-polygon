// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
    enum AccountType {
        Locked,
        Liquid
    }

    enum Tier {
        None,
        Level1,
        Level2,
        Level3
    }

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    enum EndowmentType {
        Charity,
        Normal
    }

    enum AllowanceAction {
        Add,
        Remove
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage availible,
        uint256[] storage cerAvailibleAmount, 
        string memory token
    ) public {
        bool check = true;
        for (uint8 j = 0; j < availible.length; j++) {
            if (
                keccak256(abi.encodePacked(availible[j])) ==
                keccak256(abi.encodePacked(token))
            ) {
                check = false;
            }
        }
        if (check) {
            availible.push(token);
            cerAvailibleAmount.push(0);
        }
    }

    // SHARED -- now defined by LocalRegistrar 
    // struct RebalanceDetails {
    //     bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
    //     bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
    //     ///TODO: Should be decimal type insted of uint256
    //     uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
    //     bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
    //     ///TODO: Should be decimal type insted of uint256
    //     uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    // }

    // function rebalanceDetailsDefaut()
    //     public
    //     pure
    //     returns (RebalanceDetails memory)
    // {
    //     RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
    //         rebalanceLiquidInvestedProfits: false,
    //         lockedInterestsToLiquid: false,
    //         interest_distribution: 20,
    //         lockedPrincipleToLiquid: false,
    //         principle_distribution: 0
    //     });

    //     return _tempRebalanceDetails;
    // }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        mapping(address => uint256) balancesByToken;
    }

    function addToken(
        GenericBalance storage temp,
        address tokenAddress,
        uint256 amount
    ) public {
        temp.balancesByToken[tokenAddress] += amount;
    }

    // function addTokenMem(
    //     GenericBalance memory temp,
    //     address tokenaddress,
    //     uint256 amount
    // ) public pure returns (GenericBalance memory) {
    //     bool notFound = true;
    //     for (uint8 i = 0; i < temp.CoinVerified_addr.length; i++) {
    //         if (temp.CoinVerified_addr[i] == tokenaddress) {
    //             notFound = false;
    //             temp.CoinVerified_amount[i] += amount;
    //         }
    //     }
    //     if (notFound) {
    //         GenericBalance memory new_temp = GenericBalance({
    //             coinNativeAmount: temp.coinNativeAmount,
    //             CoinVerified_amount: new uint256[](
    //                 temp.CoinVerified_amount.length + 1
    //             ),
    //             CoinVerified_addr: new address[](
    //                 temp.CoinVerified_addr.length + 1
    //             )
    //         });
    //         for (uint256 i = 0; i < temp.CoinVerified_addr.length; i++) {
    //             new_temp.CoinVerified_addr[i] = temp
    //                 .CoinVerified_addr[i];
    //             new_temp.CoinVerified_amount[i] = temp
    //                 .CoinVerified_amount[i];
    //         }
    //         new_temp.CoinVerified_addr[
    //             temp.CoinVerified_addr.length
    //         ] = tokenaddress;
    //         new_temp.CoinVerified_amount[
    //             temp.CoinVerified_amount.length
    //         ] = amount;
    //         return new_temp;
    //     } else return temp;
    // }

    function subToken(
        GenericBalance storage temp,
        address tokenAddress,
        uint256 amount
    ) public {
        temp.balancesByToken[tokenAddress] -= amount;
    }

    // function subTokenMem(
    //     GenericBalance memory temp,
    //     address tokenaddress,
    //     uint256 amount
    // ) public pure returns (GenericBalance memory) {
    //     for (uint8 i = 0; i < temp.CoinVerified_addr.length; i++) {
    //         if (temp.CoinVerified_addr[i] == tokenaddress) {
    //             temp.CoinVerified_amount[i] -= amount;
    //         }
    //     }
    //     return temp;
    // }

    // function splitBalance(
    //     uint256[] storage Coin,
    //     uint256 splitFactor
    // ) public view returns (uint256[] memory) {
    //     uint256[] memory temp = new uint256[](Coin.length);
    //     for (uint8 i = 0; i < Coin.length; i++) {
    //         uint256 result = SafeMath.div(Coin[i], splitFactor);
    //         temp[i] = result;
    //     }

    //     return temp;
    // }

    function receiveGenericBalance(
        address[] storage receiveaddr,
        uint256[] storage receiveamount,
        address[] storage senderaddr,
        uint256[] storage senderamount
    ) public {
        uint256 a = senderaddr.length;
        uint256 b = receiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (senderaddr[i] == receiveaddr[j]) {
                    flag = false;
                    receiveamount[j] += senderamount[i];
                }
            }

            if (flag) {
                receiveaddr.push(senderaddr[i]);
                receiveamount.push(senderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage receiveaddr,
        uint256[] storage receiveamount,
        address[] storage senderaddr,
        uint256[] memory senderamount
    ) public {
        uint256 a = senderaddr.length;
        uint256 b = receiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (senderaddr[i] == receiveaddr[j]) {
                    flag = false;
                    receiveamount[j] += senderamount[i];
                }
            }

            if (flag) {
                receiveaddr.push(senderaddr[i]);
                receiveamount.push(senderamount[i]);
            }
        }
    }

    function deductTokens(
        uint256 amount,
        uint256 deductamount
    ) public pure returns (uint256) {
        require(amount > deductamount, "Insufficient Funds");
        amount -= deductamount;
        return amount;
    }

    function getTokenAmount(
        address[] memory addresses,
        uint256[] memory amounts,
        address token
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < addresses.length; i++) {
            if (addresses[i] == token) {
                amount = amounts[i];
            }
        }

        return amount;
    }

    // function genericBalanceDefault()
    //     public
    //     pure
    //     returns (GenericBalance memory)
    // {
    //     GenericBalance memory empty;
    //     return empty;
    // }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint32 id;
    }

    struct IndexFund {
        uint256 id;
        string name;
        string description;
        uint32[] members;
        //Fund Specific: over-riding SC level setting to handle a fixed split value
        // Defines the % to split off into liquid account, and if defined overrides all other splits
        uint256 splitToLiquid;
        // Used for one-off funds that have an end date (ex. disaster recovery funds)
        uint256 expiryTime; // datetime int of index fund expiry
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
    }

    struct BeneficiaryData {
        uint32 endowId;
        uint256 fundId;
        address addr;
    }

    enum BeneficiaryEnum {
        EndowmentId,
        IndexFund,
        Wallet,
        None
    }

    struct Beneficiary {
        BeneficiaryData data;
        BeneficiaryEnum enumData;
    }

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory temp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({endowId: 0, fundId: 0, addr: address(0)})
        });

        return temp;
    }

    struct SplitDetails {
        uint256 max;
        uint256 min;
        uint256 defaultSplit; // for when a user splits are not used
    }

    function checkSplits(
        SplitDetails memory splits,
        uint256 userLocked,
        uint256 userLiquid,
        bool userOverride
    ) public pure returns (uint256, uint256) {
        // check that the split provided by a user meets the endowment's
        // requirements for splits (set per Endowment)
        if (userOverride) {
            // ignore user splits and use the endowment's default split
            return (100 - splits.defaultSplit, splits.defaultSplit);
        } else if (userLiquid > splits.max) {
            // adjust upper range up within the max split threshold
            return (splits.max, 100 - splits.max);
        } else if (userLiquid < splits.min) {
            // adjust lower range up within the min split threshold
            return (100 - splits.min, splits.min);
        } else {
            // use the user entered split as is
            return (userLocked, userLiquid);
        }
    }

    struct NetworkInfo {
        string name;
        uint256 chainId;
        address router; //SHARED
        address axelarGateway;
        string ibcChannel; // Should be removed
        string transferChannel;
        address gasReceiver; // Should be removed
        uint256 gasLimit; // Should be used to set gas limit
    }

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    // struct YieldVault {
    //     string addr; // vault's contract address on chain where the Registrar lives/??
    //     uint256 network; // Points to key in NetworkConnections storage map
    //     address inputDenom; //?
    //     address yieldToken; //?
    //     bool approved;
    //     EndowmentType[] restrictedFrom;
    //     AccountType acctType;
    //     VaultType vaultType;
    // }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
    }

    enum veTypeEnum {
        Constant,
        Linear,
        SquarRoot
    }

    struct veTypeData {
        uint128 value;
        uint256 scale;
        uint128 slope;
        uint128 power;
    }

    struct veType {
        veTypeEnum ve_type;
        veTypeData data;
    }

    enum TokenType {
        Existing,
        New,
        VeBonding
    }

    struct DaoTokenData {
        address existingData;
        uint256 newInitialSupply;
        string newName;
        string newSymbol;
        veType veBondingType;
        string veBondingName;
        string veBondingSymbol;
        uint256 veBondingDecimals;
        address veBondingReserveDenom;
        uint256 veBondingReserveDecimals;
        uint256 veBondingPeriod;
    }

    struct DaoToken {
        TokenType token;
        DaoTokenData data;
    }

    struct DaoSetup {
        uint256 quorum; //: Decimal,
        uint256 threshold; //: Decimal,
        uint256 votingPeriod; //: u64,
        uint256 timelockPeriod; //: u64,
        uint256 expirationPeriod; //: u64,
        uint128 proposalDeposit; //: Uint128,
        uint256 snapshotPeriod; //: u64,
        DaoToken token; //: DaoToken,
    }

    struct Delegate {
        address addr;
        uint256 expires; // datetime int of delegation expiry
    }
    
    enum DelegateAction {
        Set,
        Revoke
    }

    function canTakeAction(
        Delegate storage delegate,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        return (
            delegate.addr != address(0) &&
            sender == delegate.addr &&
            (delegate.expires == 0 || envTime <= delegate.expires)
        );
    }

    function canChange(
        SettingsPermission storage permissions,
        address sender,
        address owner,
        uint256 envTime
    ) public view returns (bool) {
        // can be changed if:
        // 1. sender is a valid delegate address and their powers have not expired
        // 2. sender is the endow owner && (no set delegate || an expired delegate) (ie. owner must first revoke their delegation)
        return !permissions.locked || canTakeAction(permissions.delegate, sender, envTime) || sender == owner;
    }

    struct SettingsPermission {
        bool locked;
        Delegate delegate;
    }

    struct SettingsController {
        SettingsPermission strategies;
        SettingsPermission lockedInvestmentManagement;
        SettingsPermission liquidInvestmentManagement;
        SettingsPermission allowlistedBeneficiaries;
        SettingsPermission allowlistedContributors;
        SettingsPermission maturityAllowlist;
        SettingsPermission maturityTime;
        SettingsPermission earlyLockedWithdrawFee;
        SettingsPermission withdrawFee;
        SettingsPermission depositFee;
        SettingsPermission balanceFee;
        SettingsPermission name;
        SettingsPermission image;
        SettingsPermission logo;
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    enum ControllerSettingOption {
        Strategies,
        lockedInvestmentManagement,
        liquidInvestmentManagement,
        AllowlistedBeneficiaries,
        AllowlistedContributors,
        MaturityAllowlist,
        EarlyLockedWithdrawFee,
        MaturityTime,
        WithdrawFee,
        DepositFee,
        BalanceFee,
        Name,
        Image,
        Logo,
        Categories,
        SplitToLiquid,
        IgnoreUserSplits
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 percentage;
    }

    uint256 constant FEE_BASIS = 1000;      // gives 0.1% precision for fees
    uint256 constant PERCENT_BASIS = 100;   // gives 1% precision for declared percentages

    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../../core/struct.sol";

import {subDaoStorage} from "./storage.sol";

library subDaoMessage {
    struct InstantiateMsg {
        uint32 id;
        address owner;
        uint256 quorum;
        uint256 threshold;
        uint256 votingPeriod;
        uint256 timelockPeriod;
        uint256 expirationPeriod;
        uint256 proposalDeposit;
        uint256 snapshotPeriod;
        AngelCoreStruct.DaoToken token;
        AngelCoreStruct.EndowmentType endowType;
        address endowOwner;
        address registrarContract;
    }

    struct QueryConfigResponse {
        address owner;
        address daoToken;
        address veToken;
        address swapFactory;
        uint256 quorum;
        uint256 threshold;
        uint256 votingPeriod;
        uint256 timelockPeriod;
        uint256 expirationPeriod;
        uint256 proposalDeposit;
        uint256 snapshotPeriod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library subDaoStorage {
    struct Config {
        address registrarContract;
        address owner;
        address daoToken;
        address veToken;
        address swapFactory;
        uint256 quorum;
        uint256 threshold;
        uint256 votingPeriod;
        uint256 timelockPeriod;
        uint256 expirationPeriod;
        uint256 proposalDeposit;
        uint256 snapshotPeriod;
    }

    struct State {
        uint256 pollCount;
        uint256 totalShare;
        uint256 totalDeposit;
    }

    enum VoteOption {
        Yes,
        No
    }

    struct VoterInfo {
        VoteOption vote;
        uint256 balance;
        bool voted;
    }

    // struct TokenManager {
    //     uint256 share;                        // total staked balance
    //     VoterInfo lockedBalance; // maps pollId to weight voted
    // }

    struct ExecuteData {
        uint256[] order;
        address[] contractAddress;
        bytes[] execution_message;
    }

    enum PollStatus {
        InProgress,
        Passed,
        Rejected,
        Executed,
        Expired
    }

    struct Poll {
        uint256 id;
        address creator;
        PollStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 startBlock;
        uint256 startTime;
        uint256 endHeight;
        string title;
        string description;
        string link;
        ExecuteData executeData;
        uint256 depositAmount;
        /// Total balance at the end poll
        uint256 totalBalanceAtEndPoll;
        uint256 stakedAmount;
    }
}

contract Storage {
    subDaoStorage.Config config;
    subDaoStorage.State state;

    mapping(uint256 => subDaoStorage.Poll) poll;
    mapping(uint256 => subDaoStorage.PollStatus) poll_status;

    mapping(uint256 => mapping(address => subDaoStorage.VoterInfo)) voting_status;

    uint256 constant MIN_TITLE_LENGTH = 4;
    uint256 constant MAX_TITLE_LENGTH = 64;
    uint256 constant MIN_DESC_LENGTH = 4;
    uint256 constant MAX_DESC_LENGTH = 1024;
    uint256 constant MIN_LINK_LENGTH = 12;
    uint256 constant MAX_LINK_LENGTH = 128;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {subDaoMessage} from "./message.sol";
import {subDaoStorage} from "./storage.sol";

contract SubdaoEmitter {
    bool initialized = false;
    address accountsContract;

    function initEmitter(address accountscontract) public {
        require(
            accountscontract != address(0),
            "Invalid accounts contract address"
        );
        require(!initialized, "Already Initialized");
        initialized = true;
        accountsContract = accountscontract;
    }

    mapping(address => bool) isSubdao;
    modifier isOwner() {
        require(msg.sender == accountsContract, "Unauthorized");
        _;
    }
    modifier isEmitter() {
        require(isSubdao[msg.sender], "Unauthorized");
        _;
    }
    event SubdaoInitialized(
        address subdao,
        subDaoMessage.InstantiateMsg instantiateMsg
    );
    event SubdaoUpdateConfig(address subdao, subDaoStorage.Config config);
    event SubdaoTransferFrom(
        address subdao,
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    );
    event SubdaoUpdateState(address subdao, subDaoStorage.State state);
    event SubdaoUpdatePoll(address subdao, uint256 id, subDaoStorage.Poll poll);
    event SubdaoUpdatePollStatus(
        address subdao,
        uint256 id,
        subDaoStorage.PollStatus pollStatus
    );
    event SubdaoTransfer(
        address subdao,
        address tokenAddress,
        address recipient,
        uint amount
    );
    event SubdapUpdateVotingStatus(
        address subdao,
        uint256 pollId,
        address voter,
        subDaoStorage.VoterInfo voterInfo
    );

    function initializeSubdao(
        address subdao,
        subDaoMessage.InstantiateMsg memory instantiateMsg
    ) public isOwner {
        isSubdao[subdao] = true;
        emit SubdaoInitialized(msg.sender, instantiateMsg);
    }

    function updateSubdaoConfig(
        subDaoStorage.Config memory config
    ) public isEmitter {
        emit SubdaoUpdateConfig(msg.sender, config);
    }

    function transferFromSubdao(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) public isEmitter {
        emit SubdaoTransferFrom(msg.sender, tokenAddress, from, to, amount);
    }

    function updateSubdaoState(
        subDaoStorage.State memory state
    ) public isEmitter {
        emit SubdaoUpdateState(msg.sender, state);
    }

    function updateSubdaoPoll(
        uint256 id,
        subDaoStorage.Poll memory poll
    ) public isEmitter {
        emit SubdaoUpdatePoll(msg.sender, id, poll);
    }

    function transferSubdao(
        address tokenAddress,
        address recipient,
        uint amount
    ) public isEmitter {
        emit SubdaoTransfer(msg.sender, tokenAddress, recipient, amount);
    }

    function updateVotingStatus(
        uint256 pollId,
        address voter,
        subDaoStorage.VoterInfo memory voterInfo
    ) public isEmitter {
        emit SubdapUpdateVotingStatus(msg.sender, pollId, voter, voterInfo);
    }

    function updateSubdaoPollAndStatus(
        uint256 id,
        subDaoStorage.Poll memory poll,
        subDaoStorage.PollStatus pollStatus
    ) public isEmitter {
        emit SubdaoUpdatePoll(msg.sender, id, poll);
        emit SubdaoUpdatePollStatus(msg.sender, id, pollStatus);
    }
}