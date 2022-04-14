// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EpInterface.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@(((((((@@@@@@@@@@@@#(((((@@@@@@@@@@@@@(((((((@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@((((%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((#@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((@@@@@@@@@(((((((@@@@@@@@@@@@#(((((((@@@@@@@@@(((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((@@@@@@@@(((((((((@@@@@@@@@@@(((((((((@@@@@@@@(((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((@@@@@@@@@(((((((@@@@@@@@@@@@@(((((((@@@@@@@@@(((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((((((((((%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@#((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   IIIIIIIIII   SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTT
E::::::::::::::::::::EP::::::::::::::::P  I::::::::I SS:::::::::::::::ST:::::::::::::::::::::T
E::::::::::::::::::::EP::::::PPPPPP:::::P I::::::::IS:::::SSSSSS::::::ST:::::::::::::::::::::T
EE::::::EEEEEEEEE::::EPP:::::P     P:::::PII::::::IIS:::::S     SSSSSSST:::::TT:::::::TT:::::T
  E:::::E       EEEEEE  P::::P     P:::::P  I::::I  S:::::S            TTTTTT  T:::::T  TTTTTT
  E:::::E               P::::P     P:::::P  I::::I  S:::::S                    T:::::T        
  E::::::EEEEEEEEEE     P::::PPPPPP:::::P   I::::I   S::::SSSS                 T:::::T        
  E:::::::::::::::E     P:::::::::::::PP    I::::I    SS::::::SSSSS            T:::::T        
  E:::::::::::::::E     P::::PPPPPPPPP      I::::I      SSS::::::::SS          T:::::T        
  E::::::EEEEEEEEEE     P::::P              I::::I         SSSSSS::::S         T:::::T        
  E:::::E               P::::P              I::::I              S:::::S        T:::::T        
  E:::::E       EEEEEE  P::::P              I::::I              S:::::S        T:::::T        
EE::::::EEEEEEEE:::::EPP::::::PP          II::::::IISSSSSSS     S:::::S      TT:::::::TT      
E::::::::::::::::::::EP::::::::P          I::::::::IS::::::SSSSSS:::::S      T:::::::::T      
E::::::::::::::::::::EP::::::::P          I::::::::IS:::::::::::::::SS       T:::::::::T      
EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          IIIIIIIIII SSSSSSSSSSSSSSS         TTTTTTTTTTT      
*/

contract EPQuestion is Ownable  {

    struct Question { 
        address owner;
        bool active;
        uint256 startBlock;
        uint256 expireAfter;
        uint256 delegateAmount;
    }

    mapping(string => Question) public questionsInfo;

    uint256 public feePercent;
    uint256 public stakingPercent;
    uint256 public questionMinAmount;
    uint256 public cumulatedFee;

    address public stakingPool;
    ERC20 private token;

    constructor(
        address _tokenAddress, 
        address _stakePoolAddress,
        uint256 _questionMinAmount,
        uint256 _feePercent,
        uint256 _stakingPercent
    ) {
        token = ERC20(_tokenAddress);
        stakingPool = _stakePoolAddress;
        questionMinAmount = _questionMinAmount;
        feePercent = _feePercent;
        stakingPercent = _stakingPercent;
    }

    function adjustQuestionMinAmount(uint256 _questionMinAmount) public onlyOwner {
       questionMinAmount = _questionMinAmount;
       emit parameterAdjusted("questionMinAmount", _questionMinAmount);
    }

    function adjustFeePercent(uint256 _feePercent) public onlyOwner {
        feePercent = _feePercent;
        emit parameterAdjusted("feePercent", feePercent);
    }

    function adjustStakingPercent(uint256 _stakingPercent) public onlyOwner {
        stakingPercent = _stakingPercent;
        emit parameterAdjusted("stakingPercent", stakingPercent);
    }

    function withdrawTeamFee() public onlyOwner {
        token.approve(address(this), cumulatedFee);
        token.transferFrom(address(this), msg.sender, cumulatedFee);
        cumulatedFee = 0;
    }

    function postQuestion(string memory id, uint256 amount, uint256 expireAfter) public {
        require(token.balanceOf(msg.sender) >= amount, "Insufficnet amount to delegate");
        require(amount >= questionMinAmount, "minimum question fee required");
        require(questionsInfo[id].owner == address(0), "duplicate question id");
        token.transferFrom(msg.sender, address(this), amount);
        questionsInfo[id].owner = msg.sender;
        questionsInfo[id].active = true;
        questionsInfo[id].delegateAmount = amount;
        questionsInfo[id].startBlock = block.number;
        questionsInfo[id].expireAfter = expireAfter;
        emit questionCreated(id, amount);
    }

    function closeQuestion(string memory id, address[] memory account, uint256[] memory weight) public {
        require(questionsInfo[id].owner == msg.sender, 'invalid question creator');
        require(questionsInfo[id].active, "Question closed");
        questionsInfo[id].active = false;
        uint256 delegateAmount = questionsInfo[id].delegateAmount;
        token.approve(address(this), delegateAmount);
        uint256 teamFee = delegateAmount * feePercent / 100;
        cumulatedFee += teamFee;
        uint256 stakingReserved = delegateAmount * stakingPercent / 100;
        uint256 rewardAmount = delegateAmount - teamFee - stakingReserved;
        uint256 distributedReward = 0;
        for(uint i = 0; i < account.length; i++) {
            require(weight[i] <= 100, "Invalid weight parameters");
            require(account[i] != msg.sender, "Owner cannot claim reward itself");
            uint256 userRewarded = rewardAmount * weight[i] / 100;
            token.transferFrom(address(this), account[i], userRewarded);
            distributedReward += userRewarded;
        }
        require(rewardAmount == distributedReward, "Rewards did not all distributed");
        token.transferFrom(address(this), stakingPool, stakingReserved);
        emit questionClosed(id);
    }

    function closeExpiredQuestion(string[] memory ids) external onlyOwner {
        for(uint i = 0; i < ids.length; i++) {
            string memory id = ids[i];
            require(questionsInfo[id].active, "Question closed");
            require(
                questionsInfo[id].startBlock + questionsInfo[id].expireAfter <= block.number, 
                'Question not expired yet'
            );
            questionsInfo[id].active = false;
            token.approve(address(this), questionsInfo[id].delegateAmount);
            token.transferFrom(address(this), stakingPool, questionsInfo[id].delegateAmount);
            emit questionExpired(id);
        }
    }

    event parameterAdjusted(string name, uint256 amount);
    event questionCreated(string id, uint256 amount);
    event questionClosed(string id);
    event questionExpired(string id);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 allowance) external;
    function increaseAllowance(address spender, uint256 addedValue) external;
    function decreaseAllowance(address spender, uint256 subtractedValue) external;
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