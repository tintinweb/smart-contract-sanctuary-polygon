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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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
pragma solidity 0.8.17;

interface IYousovStructs {
    enum AccountType {
        REGULAR,
        PSEUDO
     }
    enum Gender {
        MALE,
        FEMALE,
        OTHER
    }
    enum UserStatus {
        OPT_IN,
        OPT_OUT

    }
    enum UserRole {
        SENIOR,
        JUNIOR,
        STANDARD,
        DENIED
    }
    struct PII {
        string firstName;
        string middelName;
        string lastName;
        string birthPlace;
        string uid;
        uint256 birthDateTimeStamp;
        Gender gender;
    }
    struct Wallet{
        address publicAddr;
        string walletPassword;
        string privateKey;
    }
    struct Challenge {
        string question;
        string answer;
        string id;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRecovery {
    event AgentAddedToRecovery(address user);
    event RecoveryReadyToStart(address userRecovery);
    function user() view external returns (address user);
    function addNewAgentToRecovery() external;
    function deleteAgentFromRecovery(address _agentAddress) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRecoveryFactory {
    event RecoveryCreated( address recoveryAddress);
    function createRecovery() external;
    function addActiveAgent(address newActiveAgent) external;
    function deleteActiveAgent(address _agentAddress) external;
    function getLegalSelectableAgents(address _currentRecovery) external returns(address[] memory _legalSelectableAgents);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IRecovery.sol";
import "./interface/IRecoveryFactory.sol";
import "../Users/interface/IUser.sol";
contract Recovery is IRecovery {
    address public user;
    address[]  agentList;
    address recoveryFactory;
    constructor(address _user,address _recoveryFactory) {
        recoveryFactory = _recoveryFactory;
        user= _user;   
    }
    function addNewAgentToRecovery() external override {
        require(agentList.length < IUser(user).userChallenges().length, "YOUSOV : Recovery selection is over");
        agentList.push(msg.sender);
        IRecoveryFactory(recoveryFactory).addActiveAgent(msg.sender);
        emit AgentAddedToRecovery(msg.sender);
        if (agentList.length == IUser(user).userChallenges().length) {
            emit RecoveryReadyToStart(address(this)); 
        }    
    }

    function deleteAgentFromRecovery(address _agentAddress) external override {
        bool _agentExists = false;
        for (uint i = 0; i < agentList.length; i++) {
            if (agentList[i] == _agentAddress) {
              agentList[i] =  agentList[agentList.length-1];
              _agentExists = true;
              break;  
            }
        }
        if (_agentExists) {
        agentList.pop();
        }
        IRecoveryFactory(recoveryFactory).deleteActiveAgent(_agentAddress);

    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interface/IRecoveryFactory.sol";
import "../lib/TransferHelper.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../EZR/interface/IERC20.sol";
import "./Recovery.sol";
import "../Users/interface/IUserFactory.sol";
import "../Users/interface/IUser.sol";
contract RecoveryFactory is IRecoveryFactory {
    using SafeMath for uint256;
    address public ezr;
    address[] public recoveries;
    address public agentPayrollWallet ;
    address[] public activeAgentsInRecoveries;
    address public userFactory;
    constructor(address _ezr, address _agentPayrollWallet, address _userFactory){
        ezr = _ezr;
        agentPayrollWallet = _agentPayrollWallet;
        userFactory = _userFactory;

    }

    function createRecovery() external override {
        // Pay the recovery
        TransferHelper.safeTransferFrom(ezr, msg.sender, agentPayrollWallet, 5 * 10**17 );        
        TransferHelper.safeTransferFrom(ezr, msg.sender,address(0) , 3 * 10**17);        
        TransferHelper.safeTransferFrom(ezr, msg.sender, 0xD44d5088f6eb0a0Aed56B2065478737030acEA94, 2 * 10**17 );
        //  create the recovery
        address _newRecovery = address(new Recovery(msg.sender, address(this)));
        recoveries.push(_newRecovery);      
        emit RecoveryCreated(_newRecovery);
    }
    function recoveryExist(address _recovery) internal view returns (bool) {
        for (uint i = 0; i < recoveries.length; i++) {
            if (_recovery == recoveries[i]) {
                return true;
            }
        }
        return false;
        
    }
    function addActiveAgent(address newActiveAgent) external override {
        activeAgentsInRecoveries.push(newActiveAgent);
    }
    function deleteActiveAgent(address _agentAddress) external override {
        bool _agentExists = false;
        for (uint i = 0; i < activeAgentsInRecoveries.length; i++) {
            if (activeAgentsInRecoveries[i] == _agentAddress) {
              activeAgentsInRecoveries[i] =  activeAgentsInRecoveries[activeAgentsInRecoveries.length-1];
              _agentExists = true;
              break;  
            }
        }
        if (_agentExists) {
        activeAgentsInRecoveries.pop();
        }
    }
    function getLegalSelectableAgents(address _currentRecovery) external view override returns(address[] memory) {
        // TODO : case when we sleect amoung just qualified ?
        require(recoveryExist(_currentRecovery),"YOUSOV : Recovery don't exist");
        address[] memory _legalSelectableAgents ;
        address[] memory _userList = IUserFactory(userFactory).yousovUserList();
        uint256 _counter = 0;
        for (uint i = 0; i < _userList.length ; i++) {
            bool excludAgent =  false;
            // don't select users that are currently in an agent role doing a recovery
            for (uint j = 0; j< activeAgentsInRecoveries.length; j++) {
                if (activeAgentsInRecoveries[i] == IUser(_userList[i]).getWalletDetails().publicAddr ) {
                    excludAgent =true;
                    break;
                }
            }
            // don't select users that are lunching recoveries
            for (uint y = 0; y < recoveries.length; y++) {
                 if (IRecovery(_currentRecovery).user() == IUser(_userList[i]).getWalletDetails().publicAddr ) {
                    excludAgent =true;
                    break;
                }
            }
            if (!excludAgent) {
                _legalSelectableAgents[_counter]=_userList[i];
                _counter++;
            }

        }
        return _legalSelectableAgents;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUser is IYousovStructs {
    function pseudonym() view external returns (string memory pseudonym);
    function userChallenges() view external returns(string[] memory _userChallenges) ;
    function setSecret(string memory newSecret) external ;
    function setPseudoym(string memory newPseudonym) external ;
    function setPII(PII memory newPII) external ;
    function setWallet(string memory walletPassword) external ;
    function getWalletDetails() external view  returns (Wallet memory);
    function setAccountType(AccountType newAccountType) external;
    function getAccountType() external view  returns (AccountType);
    function setThreashold(uint256 newThreashold) external;
    function getPII() external view  returns (PII memory);
    function switchUserStatus(UserStatus newStatus) external;
    function updateUserAccountTypeFromPiiToPseudo(string memory pseudo) external;
    function updateUserAccountTypeFromPseudoToPii(PII memory newPII) external;
    function setChallenges(Challenge[] memory newChallenges , uint256 newThreashold ) external;
    function checkWalletPassword(string memory walletPassword) view external  returns (Wallet memory wallet);
    event SecretUpdated();
    event PseudonymUpdated();
    event PIIUpdated();
    event ChallengesUpdated();
    event WalletUpdated();
    event AccountTypeUpdated();
    event ThreasholdUpdated();
    event UpdateUserIdentityFromPIIToPseudo();
    event UpdateUserIdentityFromPseudoToPII();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;
import "../../interface/IYousovStructs.sol";
interface IUserFactory is IYousovStructs {
    function yousovUserList() external view returns (address[] memory );
    function newUser(PII memory pii , Wallet memory wallet, Challenge[] memory challenges, string memory pseudonym , AccountType accountType, uint256 threashold ) external;
    function deleteUser() external;
    function checkUnicity(AccountType userAccountTpe , PII memory userPII , string memory userPseudo) external view returns(bool exists, address userContractAddr);
    event UserCreated();
    event UserDeleted(address userDeletedAddress);
   
}