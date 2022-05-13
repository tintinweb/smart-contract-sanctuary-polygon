// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./EPIInterface.sol";

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

contract EPIQuestion is Ownable, Pausable  {

    struct Question {
        address creator;
        address asset;
        bool notClosed;
        uint256 startTimestamp;
        uint256 expireAfterSecs;
        uint256 delegateAmount;
    }

    mapping(string => Question) public questionsInfo;
    mapping(address => uint256) public assetMinPrice;
    mapping(address => uint256) public communityFeeMap;

    uint256 public communityPercent;
    uint256 public stakingPercent;
    address public stakingFeeReceiver;

    constructor( 
        address _stakingFeeReceiver,
        uint256 _communityPercent,
        uint256 _stakingPercent
    ) {
        stakingFeeReceiver = _stakingFeeReceiver;
        communityPercent = _communityPercent;
        stakingPercent = _stakingPercent;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setAsset(address _asset, uint256 _amount) external onlyOwner {
        assetMinPrice[_asset] = _amount;
        emit SetAsset(_asset, _amount);
    }

    function removeAsset(address _asset) external onlyOwner {
        delete assetMinPrice[_asset];
        emit RemoveAsset(_asset);
    }

    function isSupportedAsset(address _asset) public view returns (bool) {
        return assetMinPrice[_asset] > 0;
    }

    function adjustCommunityPercent(uint256 _communityPercent) external onlyOwner {
        communityPercent = _communityPercent;
        emit parameterAdjusted("communityPercent", communityPercent);
    }

    function adjustStakingPercent(uint256 _stakingPercent) external onlyOwner {
        stakingPercent = _stakingPercent;
        emit parameterAdjusted("stakingPercent", stakingPercent);
    }

    function isNativeToken(address _asset) internal pure returns (bool) {
        return _asset == address(0);
    }

    function recoverTokens(address[] memory _assets) external onlyOwner {
        for(uint i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            require(isSupportedAsset(asset), 'Asset not supported');
            if(isNativeToken(asset)) {
                payable(msg.sender).transfer(address(this).balance);
            } else {
                ERC20 token = ERC20(asset);
                uint256 tokenBalance = token.balanceOf(address(this));
                token.transfer(msg.sender, tokenBalance);
            }
        }
    }

    function withdrawCommunityFee(address[] memory _assets) external onlyOwner {
        for(uint i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            require(isSupportedAsset(asset), 'Asset not supported');
            if(isNativeToken(asset)) {
                payable(msg.sender).transfer(communityFeeMap[asset]);
            } else {
                ERC20(asset).transfer(msg.sender, communityFeeMap[asset]);
            }
            communityFeeMap[asset] = 0;
        }
    }

    function _createQuestion(address _asset, string memory _id, uint256 _amount, uint256 _expireAfterSecs) internal {
        questionsInfo[_id].creator = msg.sender;
        questionsInfo[_id].notClosed = true;
        questionsInfo[_id].delegateAmount = _amount;
        questionsInfo[_id].startTimestamp = block.timestamp;
        questionsInfo[_id].expireAfterSecs = _expireAfterSecs;
        questionsInfo[_id].asset = _asset;
        emit questionCreated(questionsInfo[_id]);
    }


    function postQuestion(address _asset, string memory _id, uint256 _amount, uint256 expireAfterSecs) payable external whenNotPaused {

        require(isSupportedAsset(_asset), 'Invalid asset');
        require(questionsInfo[_id].creator == address(0), "duplicate question ID");
        uint256 minPrice = assetMinPrice[_asset];

        if(isNativeToken(_asset)) {
            require(address(msg.sender).balance >= minPrice,  "Insufficient amount to delegate");
            require(msg.value == _amount, 'Delegate amount should equal to msg.value');
            require(msg.value >= minPrice, "Minimum question fee required");
        } else {
            require(ERC20(_asset).balanceOf(msg.sender) >= assetMinPrice[_asset], "Insufficient amount to delegate");
            require(_amount >= assetMinPrice[_asset], "Minimum question fee required");
            ERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        }

        _createQuestion(_asset, _id, _amount, expireAfterSecs);

    }

    function isQuestionExpired(string memory _id) public view returns (bool) {
        return questionsInfo[_id].startTimestamp + questionsInfo[_id].expireAfterSecs <= block.timestamp;
    }

    function closeQuestion(string memory _id, address[] memory _accounts, uint256[] memory _weights) whenNotPaused public {

        require(isQuestionExpired(_id), 'Question not expired');
        require(questionsInfo[_id].creator == msg.sender || msg.sender == owner(), 'msg.sender not authorized to close this question');
        require(questionsInfo[_id].notClosed, "Question closed");
        address asset = questionsInfo[_id].asset;

        questionsInfo[_id].notClosed = false;
        uint256 delegateAmount = questionsInfo[_id].delegateAmount;
        uint256 reservedFee = delegateAmount / 100 * communityPercent;
        communityFeeMap[asset] += reservedFee;
    
        uint256 stakingReserved = delegateAmount / 100 * stakingPercent;
        uint256 rewardAmount = delegateAmount - reservedFee - stakingReserved;
        uint256 distributedReward = 0;

        if(isNativeToken(asset)) {
            payable(stakingFeeReceiver).transfer(stakingReserved);
        } else {
            ERC20(asset).transfer(stakingFeeReceiver, stakingReserved);
        }

        for(uint i = 0; i < _accounts.length; i++) {

            require(_weights[i] <= 100, "Invalid weight parameters");
            require(_accounts[i] != msg.sender, "Question creator cannot claim reward itself");
            uint256 userRewarded = rewardAmount / 100 * _weights[i];

            if(isNativeToken(asset)) {
                payable(_accounts[i]).transfer(userRewarded);
            } else {
                ERC20(asset).transfer(_accounts[i], userRewarded);
            }

            distributedReward += userRewarded;

        }

        require(rewardAmount == distributedReward, "Rewards did not all distributed");
        emit questionClosed(_id, reservedFee, stakingReserved, _accounts, _weights);
    }

    function closeExpiredQuestion(string[] memory ids) external onlyOwner {
        address[] memory tempAddress = new address[](1);
        tempAddress[0] = stakingFeeReceiver;
        uint256[] memory tempWeight = new uint256[](1);
        tempWeight[0] = 100;
        for(uint i = 0; i < ids.length; i++) {
            closeQuestion(ids[i], tempAddress, tempWeight);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    event parameterAdjusted(string name, uint256 amount);
    event questionCreated(Question question);
    event questionClosed(string id, uint256 reservedFee, uint256 stakingReserved, address[] account, uint256[] weight);
    event SetAsset(address indexed asset, uint256 amount);
    event RemoveAsset(address indexed asset);

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ERC20 {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
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