/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

pragma solidity >=0.6.0 <0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

 
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

  
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

 
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity >=0.6.2 <0.8.0;


library Address {
    
    function isContract(address account) internal view returns (bool) {
      

        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

   
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

  
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

 
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

 
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
      

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonStakingBasic.sol

pragma solidity 0.6.6;

contract EthermonStakingBasic is BasicAccessControl {
    struct TokenData {
        address owner;
        uint64 monId;
        uint256 emons;
        uint256 endTime;
        uint256 lastCalled;
        uint64 lockId;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint16 badge;
        uint256 balance;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_365
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }

    event Withdraw(
        address _from,
        address _to,
        uint64 _monId,
        uint256 _emons,
        uint256 _endTime,
        uint256 _lastCalled,
        uint64 _lockId,
        uint16 _level,
        uint8 _validTeam,
        uint256 _teamPower,
        uint16 _badge,
        uint256 _balance,
        uint8 _duration
    );

    event Deposite(
        address _from,
        address _to,
        uint64 _monId,
        uint256 _emons,
        uint256 _endTime,
        uint64 _lockId,
        uint16 _level,
        uint256 _teamPower,
        uint16 _badge,
        uint8 _duration
    );

    event UpdateRewards(
        address _owner,
        uint64 _lockId,
        uint256 timeElapsed,
        uint256 _endTime,
        uint256 _teamPower,
        uint256 _sumTeamPower,
        uint16 _level,
        uint256 _balance,
        uint8 _duration
    );

    event UpdateData(
        address _owner,
        uint64 _lockId,
        uint64 _monId,
        uint16 _level,
        uint16 _createdIndex
    );
}

// File: contracts/EthermonStaking.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface EthermonStakingInterface {
    function SumTeamPower() external returns (uint256);

    function addTokenData(bytes calldata _data) external;

    function getTokenData(uint256 _pfpTokenId)
        external
        returns (EthermonStakingBasic.TokenData memory);

    function removeTokenData(EthermonStakingBasic.TokenData calldata _data)
        external;

    function updateTokenData(
        uint256 _balance,
        uint256 _timeElapsed,
        uint256 _lastCalled,
        uint256 _lockId,
        uint8 _validTeam
    ) external;
}

interface EthermonWeightInterface {
    function getClassWeight(uint32 _classId)
        external
        view
        returns (uint256 weight);
}

contract EthermonStaking is EthermonStakingBasic {
    using SafeERC20 for IERC20;

    uint16[] daysToStake = [1, 30, 60, 90, 120, 180, 365];
    uint16[] daysAdvantage = [10, 11, 12, 13, 17, 25];
    uint16[] pfpRaritiesArr = [10, 12, 3, 4, 5, 6];
    uint16[] badgeAdvantageValues = [15, 13, 12];

    uint256 maxDepositeValue = 100000 * 10**decimal;
    uint256 minDepositeValue = 1000 * 10**decimal;
    uint8 public emonPerPeriod = 1;
    uint8 private rewardsCap = 100;
    bytes32 public appHash;

    address public stakingDataContract;
    address public ethermonWeightContract;

    IERC20 emon;

    constructor(
        address _stakingDataContract,
        address _ethermonWeightContract,
        address _emon
    ) public {
        stakingDataContract = _stakingDataContract;
        ethermonWeightContract = _ethermonWeightContract;
        emon = IERC20(_emon);
    }

    function setAppHash(bytes32 _appSecret) public onlyModerators {
        appHash = keccak256(abi.encodePacked(_appSecret));
    }

    function setContracts(
        address _stakingDataContract,
        address _ethermonWeightContract,
        address _emon
    ) public onlyModerators {
        stakingDataContract = _stakingDataContract;
        ethermonWeightContract = _ethermonWeightContract;
        emon = IERC20(_emon);
    }

    function setEmonPerPeriod(uint8 _emonPerPeriod) external onlyModerators {
        emonPerPeriod = _emonPerPeriod;
    }

    function setDepositeValues(
        uint256 _minDepositeValue,
        uint256 _maxDepositeValue
    ) public onlyModerators {
        minDepositeValue = _minDepositeValue;
        maxDepositeValue = _maxDepositeValue;
    }

    function changeRewardCap(uint8 _rewardCap) external onlyModerators {
        require(_rewardCap > 0, "Invlaid reward cap value");
        rewardsCap = _rewardCap;
    }

    function depositeTokens(
        Duration _day,
        uint256 _amount,
        uint64 _monId,
        uint32 _classId,
        uint64 _lockId,
        uint16 _level,
        uint16 _createdIndex,
        bytes32 _appSecret
    ) external {
        require(
            keccak256(abi.encodePacked(_appSecret)) == appHash,
            "Application hash doesn't match"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        address owner = msgSender();
        uint256 balance = emon.balanceOf(owner);
        require(
            balance >= minDepositeValue &&
                _amount >= minDepositeValue &&
                _amount <= maxDepositeValue,
            "Balance is not valid."
        );

        uint16 badgeAdvantage = (_createdIndex > 2)
            ? 10
            : badgeAdvantageValues[_createdIndex];

        uint256 currentTime = now;
        uint256 dayTime = currentTime + (daysToStake[uint8(_day)] * 1 minutes);

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId == 0, "Token already exists");

        EthermonWeightInterface weight = EthermonWeightInterface(
            ethermonWeightContract
        );

        data.owner = owner;
        data.duration = _day;
        data.emons = _amount;
        data.lastCalled = currentTime;
        data.monId = _monId;
        data.endTime = dayTime;
        data.lockId = _lockId;
        data.badge = _createdIndex;
        data.level = _level;
        uint256 rarity = weight.getClassWeight(_classId);
        data.validTeam = 1;

        uint256 emonsInDecimal = data.emons / 10**decimal;
        data.teamPower =
            emonsInDecimal *
            data.level *
            rarity *
            daysAdvantage[uint8(data.duration)] *
            badgeAdvantage;

        uint256 teamPower = data.teamPower * 10**decimal;

        uint256 sumTeamPower = stakingData.SumTeamPower();
        uint256 hourlyEmon = (((teamPower / sumTeamPower) *
            emonPerPeriod *
            (currentTime - data.lastCalled)) / (1 minutes)) * data.validTeam;
        data.balance += hourlyEmon;
        bytes memory output = abi.encode(data);
        stakingData.addTokenData(output);

        emon.safeTransferFrom(msgSender(), address(this), data.emons);
    }

    function updateTokens(
        uint256 _lockId,
        uint16 _level,
        uint32 _classId,
        uint256 _badge,
        uint8 validTeam
    ) external onlyModerators {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        EthermonWeightInterface weightData = EthermonWeightInterface(
            ethermonWeightContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId > 0 && _level > 0, "Data is not valid");

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        data.lastCalled = currentTime;

        uint256 teamPower = data.teamPower * 10**decimal;
        data.validTeam = validTeam;
        data.level = _level;
        uint256 rarity = weightData.getClassWeight(_classId);

        //Withdraw be restricted to some < 10X;
        if (timeElapsed > 0 && currentTime > data.endTime) {
            require(rewardsCap > 0, "Reward cap reached max capacity");
            rewardsCap--;

            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);

            data.balance +=
                (teamPower / stakingData.SumTeamPower()) *
                emonPerPeriod *
                timeElapsed *
                _level *
                rarity *
                data.validTeam *
                badgeAdvantageValues[_badge];

            data.emons += data.balance;

            if (emon.balanceOf(address(this)) >= data.emons) {
                emon.safeTransfer(data.owner, data.emons);
                stakingData.removeTokenData(data);
            }
            return;
        }

        uint256 hourlyEmon = (teamPower / stakingData.SumTeamPower()) *
            emonPerPeriod *
            timeElapsed *
            _level *
            rarity *
            data.validTeam *
            badgeAdvantageValues[_badge];

        data.balance += hourlyEmon;
        uint256 lockId = _lockId;
        stakingData.updateTokenData(
            data.balance,
            timeElapsed,
            data.lastCalled,
            lockId,
            data.validTeam
        );

        emit UpdateRewards(
            data.owner,
            data.lockId,
            timeElapsed,
            data.endTime,
            data.teamPower,
            stakingData.SumTeamPower(),
            data.level,
            data.balance,
            uint8(data.duration)
        );
    }

    function withDrawRewards(uint256 _lockId) external {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId != 0, "Data is not present");

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        data.lastCalled = currentTime;

        uint256 teamPower = data.teamPower * 10**decimal;

        if (timeElapsed > 0 && currentTime > data.endTime) {
            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);

            data.balance +=
                (teamPower / stakingData.SumTeamPower()) *
                emonPerPeriod *
                timeElapsed *
                data.validTeam;

            data.emons += data.balance;

            emon.safeTransfer(data.owner, data.emons);

            stakingData.removeTokenData(data);
        }
    }

    function updateStakingData(
        uint64 _lockId,
        uint64 _monId,
        uint16 _level,
        uint16 _createdIndex,
        bytes32 _appSecret
    ) external {
        require(
            keccak256(abi.encodePacked(_appSecret)) == appHash,
            "Application hash doesn't match"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        address owner = msgSender();

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.owner == owner, "PFP do not belongs to you.");
        require(data.monId > 0, "Staking data does not exists");

        data.monId = _monId;
        data.level = _level;
        data.badge = _createdIndex;

        bytes memory output = abi.encode(data);
        stakingData.addTokenData(output);
        emit UpdateData(owner, _lockId, _monId, _level, _createdIndex);
    }

    function depositeEmons(uint256 _amount) external {
        require(
            _amount > 0 && _amount <= emon.balanceOf(msgSender()),
            "Invalid amount"
        );
        emon.safeTransferFrom(msgSender(), address(this), _amount);
    }

    function withdrawEmon(address _sendTo) external onlyModerators {

        uint256 balance = emon.balanceOf(address(this));
        emon.safeTransfer(_sendTo, balance);
    }
}