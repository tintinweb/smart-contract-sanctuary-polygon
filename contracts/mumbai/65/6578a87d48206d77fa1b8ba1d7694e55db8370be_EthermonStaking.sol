/**
 *Submitted for verification at polygonscan.com on 2022-09-29
*/

// File: 1_Storage_flat.sol


// File: contracts/1_Storage.sol

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol


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

// File: openzeppelin-solidity/contracts/utils/Address.sol


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
            if (returndata.length > 0) {
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
        uint256 endTime;
        uint256 lastCalled;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint256 balance;
        uint16 badge;
        address owner;
        uint64[] monId;
        uint32[] classId;
        uint256 lockId;
        uint256 pfpId;
        uint256 emons;
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
}

// File: contracts/EthermonStaking.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface EthermonStakingInterface {
    function SumTeamPower() external returns (uint256);

    function EmonPerPeriod() external returns (uint64);

    function updateSumTeamPower(uint256 _sumTeamPower) external;

    function addTokenData(bytes calldata _data) external returns (uint256);

    function getTokenDataTup(uint256 _lockId)
        external
        returns (EthermonStakingBasic.TokenData memory);

    function removeTokenData(EthermonStakingBasic.TokenData calldata) external;

    function updateTokenReward(bytes calldata _data, uint256 _timeElapsed)
        external;

    function updateTokenData(bytes calldata _data) external;
}

interface EthermonWeightInterface {
    function getClassWeight(uint32 _classId)
        external
        view
        returns (uint256 weight);
}

contract EthermonStaking is EthermonStakingBasic {
    using SafeERC20 for IERC20;

    struct DepositeToken {
        Duration _day;
        uint256 _amount;
        uint64[] _monId;
        uint32[] _classId;
        uint64 _pfpId;
        uint16 _level;
        uint16 _badgeAdvantage;
    }

    event Deposite(
        address _owner,
        uint256 _lockId,
        uint256 _pfpId,
        uint64[] _monId,
        uint256 _emons
    );

    uint16[] daysToStake = [1, 30, 60, 90, 120, 180, 365];
    uint16[] daysAdvantage = [10, 11, 12, 13, 17, 25];
    uint16[] badgeAdvantageValues = [15, 13, 12];

    uint256 public maxDepositeValue = 100000 * 10**decimal;
    uint256 public minDepositeValue = 1000 * 10**decimal;
    uint256 public maxMonCap = 1;
    uint8 private rewardsCap = 100;
    bytes constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";

    address public verifyAddress;
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

    function setMaxMonCap(uint256 _maxMonCap) external onlyModerators {
        maxMonCap = _maxMonCap;
    }

    function setVerifyAddress(address _verifyAddress) external {
        verifyAddress = _verifyAddress;
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
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        bytes32 _token,
        DepositeToken calldata depositeData
    ) external {
        require(
            (depositeData._monId.length <= maxMonCap &&
                depositeData._classId.length <= maxMonCap) &&
                (depositeData._monId.length > 0 &&
                    depositeData._classId.length > 0),
            "Mons limit exceed"
        );

        require(
            depositeData._monId.length == depositeData._classId.length,
            "Mon ID and Class ID length should match"
        );

        address owner = msgSender();
        require(
            (getVerifyAddress(owner, _token, _v, _r, _s) == verifyAddress),
            "Not verified"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        uint256 balance = emon.balanceOf(owner);
        require(
            balance >= minDepositeValue &&
                depositeData._amount >= minDepositeValue &&
                depositeData._amount <= maxDepositeValue,
            "Balance is not valid"
        );

        uint256 currentTime = now;

        TokenData memory data;

        require(data.owner == address(0), "Token already exists");

        data.owner = owner;
        data.emons = depositeData._amount;
        data.monId = depositeData._monId;
        data.pfpId = depositeData._pfpId;
        data.classId = depositeData._classId;

        data.lastCalled = currentTime;
        data.duration = depositeData._day;
        data.endTime =
            currentTime +
            (daysToStake[uint8(depositeData._day)] * 1 minutes);
        data.badge = depositeData._badgeAdvantage;
        data.level = depositeData._level;
        data.validTeam = 1;

        data.teamPower +=
            (data.emons / 10**decimal) *
            data.level *
            getSumWeight(data.classId, data.monId) *
            daysAdvantage[uint8(data.duration)] *
            data.badge;

        uint256 teamPower = data.teamPower * 10**decimal;

        uint256 sumTeamPower = stakingData.SumTeamPower();
        uint256 hourlyEmon = (((teamPower / sumTeamPower) *
            stakingData.EmonPerPeriod() *
            (currentTime - data.lastCalled)) / (1 minutes)) * data.validTeam;
        data.balance += hourlyEmon;

        bytes memory output = abi.encode(data);
        uint256 newLockId = stakingData.addTokenData(output);

        emon.safeTransferFrom(msgSender(), address(this), data.emons);
        emit Deposite(
            data.owner,
            newLockId,
            data.pfpId,
            data.monId,
            data.emons
        );
    }

    function updateTokens(
        uint256 _lockId,
        uint16 _level,
        uint8 _validTeam
    ) external onlyModerators {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenDataTup(_lockId);
        require(
            data.owner != address(0) && data.monId.length > 0 && _level > 0,
            "Data is not valid"
        );

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        uint256 teamPower = data.teamPower * 10**decimal;
        data.validTeam = _validTeam;
        data.level = _level;
        uint256 rarity = getSumWeight(data.classId, data.monId);

        uint256 sumTeamPower = stakingData.SumTeamPower();

        if (currentTime > data.endTime) {
            timeElapsed = (data.endTime - data.lastCalled) / 1 minutes;
        }
        if (timeElapsed > 0) data.lastCalled = currentTime;

        uint256 hourlyEmon = (teamPower / sumTeamPower) *
            stakingData.EmonPerPeriod() *
            timeElapsed *
            _level *
            rarity *
            data.validTeam *
            data.badge;

        data.balance += hourlyEmon;
        bytes memory encoded = abi.encode(data);
        stakingData.updateTokenReward(encoded, timeElapsed);
    }

    function getSumWeight(uint32[] memory _classIds, uint64[] memory _monIds)
        public
        view
        returns (uint256)
    {
        uint256 rarityWeight = 0;
        EthermonWeightInterface weightData = EthermonWeightInterface(
            ethermonWeightContract
        );
        for (uint256 i = 0; i < _classIds.length; i++) {
            require(
                _classIds[i] > 0 && _monIds[i] > 0,
                "Invlid Class or Mon ID"
            );
            rarityWeight += weightData.getClassWeight(_classIds[i]);
        }
        return rarityWeight;
    }

    function withdrawRewards(uint256 _lockId) external {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenDataTup(_lockId);
        require(currentTime > data.endTime, "Time remaining to unstake");
        require(data.owner == msgSender(), "Wrong lockId");

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        uint256 teamPower = data.teamPower * 10**decimal;
        uint16 badgeAdv = data.badge > 2
            ? 10
            : badgeAdvantageValues[data.badge];

        if (timeElapsed > 0 && currentTime > data.endTime) {
            require(rewardsCap > 0, "Reward cap reached max capacity");
            rewardsCap--;

            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);
        }

        data.balance +=
            (teamPower / stakingData.SumTeamPower()) *
            stakingData.EmonPerPeriod() *
            timeElapsed *
            data.level *
            getSumWeight(data.classId, data.monId) *
            data.validTeam *
            badgeAdv;

        data.emons += data.balance;
        require(
            emon.balanceOf(address(this)) >= data.emons,
            "Contract donot have emons to dispatch"
        );
        data.lastCalled = currentTime;

        emon.safeTransfer(data.owner, data.emons);
        stakingData.removeTokenData(data);
    }

    function updateStakingData(
        uint256 _lockId,
        bytes32 _r,
        bytes32 _s,
        uint8 _v,
        bytes32 _token,
        DepositeToken calldata _depositeToken
    ) external {
        require(
            _depositeToken._monId.length <= maxMonCap &&
                _depositeToken._classId.length <= maxMonCap,
            "Mons limit exceed"
        );

        require(
            _depositeToken._monId.length == _depositeToken._classId.length,
            "Mon ID and Class ID length should match"
        );

        require(
            (getVerifyAddress(msg.sender, _token, _v, _r, _s) == verifyAddress),
            "Not verified"
        );

        uint256 currentTime = now;

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        address owner = msgSender();

        TokenData memory data = stakingData.getTokenDataTup(_lockId);

        require(data.owner != address(0), "Staking data does not exists");
        require(data.owner == owner, "Unauthorized staker");
        require(data.endTime > currentTime, "Staking time ended");

        if (_depositeToken._amount > 0) {
            require(
                emon.balanceOf(msgSender()) > _depositeToken._amount,
                "Insufficient amount to update"
            );
            data.emons += _depositeToken._amount;
        }

        uint256 sumTeamPower = stakingData.SumTeamPower();

        sumTeamPower -= data.teamPower;
        data.monId = _depositeToken._monId;

        data.pfpId = _depositeToken._pfpId;
        data.classId = _depositeToken._classId;
        data.level = _depositeToken._level;
        data.validTeam = (_depositeToken._monId.length > 0 &&
            _depositeToken._classId.length > 0)
            ? 1
            : 0;
        data.badge = _depositeToken._badgeAdvantage;

        if (_depositeToken._day > data.duration) {
            uint256 updatedTime = currentTime +
                (daysToStake[uint8(_depositeToken._day)] * 1 minutes);

            uint256 remainingTime = data.endTime - data.lastCalled;

            data.endTime = remainingTime + updatedTime;
            data.duration = _depositeToken._day;
        }

        data.teamPower =
            (data.emons / 10**decimal) *
            data.level *
            getSumWeight(data.classId, data.monId) *
            daysAdvantage[uint8(data.duration)] *
            data.badge *
            data.validTeam;

        data.lastCalled = currentTime;
        sumTeamPower += data.teamPower;
        stakingData.updateSumTeamPower(sumTeamPower);

        bytes memory encoded = abi.encode(data);
        stakingData.updateTokenData(encoded);
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

    function getVerifyAddress(
        address sender,
        bytes32 _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes32 hashValue = keccak256(abi.encodePacked(sender, _token));
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(SIG_PREFIX, hashValue)
        );
        return ecrecover(prefixedHash, _v, _r, _s);
    }

    function getVerifySignature(
        address _sender,
        uint256 nonce1,
        uint256 nonce2,
        DepositeToken memory _depositeToken
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _sender,
                    _depositeToken._day,
                    _depositeToken._amount,
                    _depositeToken._monId,
                    _depositeToken._classId,
                    _depositeToken._pfpId,
                    _depositeToken._level,
                    _depositeToken._badgeAdvantage,
                    nonce1,
                    nonce2
                )
            );
    }
}